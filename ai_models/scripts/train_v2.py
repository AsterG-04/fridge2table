"""
Trains a MobileNetV2 transfer-learning classifier on the EXPANDED
ingredient dataset (ai_models/dataset_v2 -- the original 36 classes
plus 4 dairy classes), and saves:

    ai_models/model/ingredient_classifier_v2.keras
    ai_models/model/class_names_v2.json

Does NOT overwrite the v1 model files -- this is a separate, comparable
output so v1 stays as a safe fallback until v2 is verified to be as
good or better.

Run from ai_models/ with the venv activated:
    venv\\Scripts\\python.exe scripts\\train_v2.py
"""

import json
import os

import tensorflow as tf

BASE_DIR = os.path.join(os.path.dirname(__file__), "..")
TRAIN_DIR = os.path.join(BASE_DIR, "dataset_v2", "train")
TEST_DIR = os.path.join(BASE_DIR, "dataset_v2", "test")
MODEL_DIR = os.path.join(BASE_DIR, "model")

IMAGE_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 15
SEED = 42


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
        tf.keras.layers.RandomRotation(0.1),
        tf.keras.layers.RandomZoom(0.1),
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

    return model


def main():
    os.makedirs(MODEL_DIR, exist_ok=True)

    train_ds, val_ds, test_ds, class_names = build_datasets()
    print(f"Classes ({len(class_names)}): {class_names}")

    model = build_model(len(class_names))
    model.summary()

    early_stop = tf.keras.callbacks.EarlyStopping(
        monitor="val_accuracy",
        patience=4,
        restore_best_weights=True,
    )

    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS,
        callbacks=[early_stop],
    )

    test_loss, test_acc = model.evaluate(test_ds)
    print(f"Test accuracy: {test_acc:.4f}, test loss: {test_loss:.4f}")

    model_path = os.path.join(MODEL_DIR, "ingredient_classifier_v2.keras")
    model.save(model_path)
    print(f"Saved model to {model_path}")

    class_names_path = os.path.join(MODEL_DIR, "class_names_v2.json")
    with open(class_names_path, "w") as f:
        json.dump(class_names, f, indent=2)
    print(f"Saved class names to {class_names_path}")


if __name__ == "__main__":
    main()
