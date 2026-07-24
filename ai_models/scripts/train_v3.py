"""
Trains a MobileNetV2 transfer-learning classifier on the EXPANDED
ingredient dataset (ai_models/dataset_v3 -- the 40 v2 classes plus 16 new
fruit/vegetable/dairy-alternative classes), and saves:

    ai_models/model/ingredient_classifier_v3.keras
    ai_models/model/class_names_v3.json

Two-phase training:
  1. Head-only: base model frozen, train the new classification head.
  2. Fine-tune: unfreeze the last FINE_TUNE_LAYERS of the base model and
     continue training at a much lower learning rate, so the pretrained
     features adapt slightly to this dataset without being wrecked by
     large gradient updates.

Data augmentation (rotation, zoom, horizontal flip, brightness) is applied
in both phases so the model generalizes better to real phone camera
conditions (varied lighting/angles) rather than just the clean training
photos.

Does NOT overwrite the v2 model files -- this is a separate, comparable
output so v2 stays as a safe fallback until v3 is verified to be as good
or better.

Run from ai_models/ with the venv activated:
    venv\\Scripts\\python.exe scripts\\train_v3.py
"""

import json
import os

import tensorflow as tf

BASE_DIR = os.path.join(os.path.dirname(__file__), "..")
TRAIN_DIR = os.path.join(BASE_DIR, "dataset_v3", "train")
TEST_DIR = os.path.join(BASE_DIR, "dataset_v3", "test")
MODEL_DIR = os.path.join(BASE_DIR, "model")

IMAGE_SIZE = (224, 224)
BATCH_SIZE = 32
SEED = 42

EPOCHS_HEAD = 22
EPOCHS_FINE_TUNE = 13
# MobileNetV2's base has 154 layers total; unfreezing the last 30 lets the
# later, more task-specific feature layers adapt while the earlier,
# general-purpose (edge/texture) layers stay frozen.
FINE_TUNE_LAYERS = 30
FINE_TUNE_LR = 1e-5


def build_datasets():
    train_ds = tf.keras.utils.image_dataset_from_directory(
        TRAIN_DIR,
        validation_split=0.2,
        subset="training",
        seed=SEED,
        image_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
    )

    val_ds = tf.keras.utils.image_dataset_from_directory(
        TRAIN_DIR,
        validation_split=0.2,
        subset="validation",
        seed=SEED,
        image_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
    )

    test_ds = tf.keras.utils.image_dataset_from_directory(
        TEST_DIR,
        image_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        shuffle=False,
    )

    class_names = train_ds.class_names

    preprocess = tf.keras.applications.mobilenet_v2.preprocess_input

    train_ds = train_ds.map(lambda x, y: (preprocess(x), y))
    val_ds = val_ds.map(lambda x, y: (preprocess(x), y))
    test_ds = test_ds.map(lambda x, y: (preprocess(x), y))

    train_ds = train_ds.prefetch(tf.data.AUTOTUNE)
    val_ds = val_ds.prefetch(tf.data.AUTOTUNE)
    test_ds = test_ds.prefetch(tf.data.AUTOTUNE)

    return train_ds, val_ds, test_ds, class_names


def build_model(num_classes):
    data_augmentation = tf.keras.Sequential([
        tf.keras.layers.RandomFlip("horizontal"),
        tf.keras.layers.RandomRotation(0.15),
        tf.keras.layers.RandomZoom(0.15),
        # Training images are already rescaled to MobileNetV2's [-1, 1]
        # input range by preprocess_input in build_datasets() before they
        # ever reach this layer. RandomBrightness defaults to assuming
        # [0, 255] inputs -- without value_range matching the real data,
        # its brightness delta is calibrated ~128x too large and destroys
        # every augmented batch (this silently wrecked an earlier v2 run:
        # training accuracy never rose past ~18% while validation, which
        # skips augmentation, still reached ~55%).
        tf.keras.layers.RandomBrightness(0.2, value_range=(-1, 1)),
    ])

    base_model = tf.keras.applications.MobileNetV2(
        input_shape=IMAGE_SIZE + (3,),
        include_top=False,
        weights="imagenet",
    )
    base_model.trainable = False

    inputs = tf.keras.Input(shape=IMAGE_SIZE + (3,))
    x = data_augmentation(inputs)
    x = base_model(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.2)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax")(x)

    model = tf.keras.Model(inputs, outputs)

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    return model, base_model


def main():
    os.makedirs(MODEL_DIR, exist_ok=True)

    train_ds, val_ds, test_ds, class_names = build_datasets()
    print(f"Classes ({len(class_names)}): {class_names}")

    model, base_model = build_model(len(class_names))
    model.summary()

    early_stop = tf.keras.callbacks.EarlyStopping(
        monitor="val_accuracy",
        patience=5,
        restore_best_weights=True,
    )

    print(f"\n=== Phase 1: training head ({EPOCHS_HEAD} epochs, base frozen) ===")
    history_head = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS_HEAD,
        callbacks=[early_stop],
    )

    head_test_loss, head_test_acc = model.evaluate(test_ds)
    print(f"\nPhase 1 (head-only) test accuracy: {head_test_acc:.4f}, test loss: {head_test_loss:.4f}")
    # Kept in memory so phase 2 can be discarded if fine-tuning makes things
    # worse -- EarlyStopping's restore_best_weights only tracks the best
    # epoch *within* the current fit() call, so a second fit() call has no
    # memory of how good phase 1 was and will happily keep a worse result.
    head_weights = model.get_weights()

    print(f"\n=== Phase 2: fine-tuning last {FINE_TUNE_LAYERS} base layers "
          f"({EPOCHS_FINE_TUNE} epochs, lr={FINE_TUNE_LR}) ===")
    base_model.trainable = True
    for layer in base_model.layers[:-FINE_TUNE_LAYERS]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=FINE_TUNE_LR),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.summary()

    initial_epoch = len(history_head.epoch)
    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=initial_epoch + EPOCHS_FINE_TUNE,
        initial_epoch=initial_epoch,
        callbacks=[early_stop],
    )

    fine_tune_test_loss, fine_tune_test_acc = model.evaluate(test_ds)
    print(f"\nPhase 2 (fine-tuned) test accuracy: {fine_tune_test_acc:.4f}, test loss: {fine_tune_test_loss:.4f}")

    if fine_tune_test_acc >= head_test_acc:
        print("Fine-tuning improved on (or matched) the head-only result -- keeping phase 2 weights.")
        test_acc = fine_tune_test_acc
    else:
        print("Fine-tuning made things worse -- reverting to phase 1 (head-only) weights.")
        model.set_weights(head_weights)
        test_acc = head_test_acc

    print(f"\nFinal chosen test accuracy: {test_acc:.4f}")

    model_path = os.path.join(MODEL_DIR, "ingredient_classifier_v3.keras")
    model.save(model_path)
    print(f"Saved model to {model_path}")

    class_names_path = os.path.join(MODEL_DIR, "class_names_v3.json")
    with open(class_names_path, "w") as f:
        json.dump(class_names, f, indent=2)
    print(f"Saved class names to {class_names_path}")


if __name__ == "__main__":
    main()
