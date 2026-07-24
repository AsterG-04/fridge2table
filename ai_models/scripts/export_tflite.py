"""
Converts the trained v4 Keras model to a quantized TFLite model for
on-device inference, saving:

    ai_models/model/ingredient_classifier_v4.tflite

The exported model takes raw [0, 255] pixel input directly (the
MobileNetV2 [-1, 1] rescaling is baked into the model graph itself),
so the Flutter side does not need to replicate any preprocessing math.

Run from ai_models/ with the venv activated:
    venv\\Scripts\\python.exe scripts\\export_tflite.py
"""

import os

import numpy as np
import tensorflow as tf

BASE_DIR = os.path.join(os.path.dirname(__file__), "..")
MODEL_DIR = os.path.join(BASE_DIR, "model")
KERAS_MODEL_PATH = os.path.join(MODEL_DIR, "ingredient_classifier_v4.keras")
TFLITE_MODEL_PATH = os.path.join(MODEL_DIR, "ingredient_classifier_v4.tflite")

IMAGE_SIZE = (224, 224)


def build_inference_model():
    trained_model = tf.keras.models.load_model(KERAS_MODEL_PATH)

    inputs = tf.keras.Input(shape=IMAGE_SIZE + (3,), dtype=tf.float32)
    # Bake MobileNetV2 preprocessing (scale [0,255] -> [-1,1]) into the graph
    x = tf.keras.layers.Rescaling(scale=1.0 / 127.5, offset=-1.0)(inputs)
    outputs = trained_model(x, training=False)

    return tf.keras.Model(inputs, outputs)


def convert_to_tflite(inference_model):
    converter = tf.lite.TFLiteConverter.from_keras_model(inference_model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    tflite_model = converter.convert()

    with open(TFLITE_MODEL_PATH, "wb") as f:
        f.write(tflite_model)

    print(f"Saved TFLite model to {TFLITE_MODEL_PATH}")
    print(f"Size: {os.path.getsize(TFLITE_MODEL_PATH) / 1024:.1f} KB")


def sanity_check(inference_model):
    """Compares Keras vs TFLite predictions on a random raw-pixel image."""

    sample = np.random.randint(0, 256, size=(1,) + IMAGE_SIZE + (3,)).astype(
        "float32"
    )

    keras_pred = inference_model.predict(sample, verbose=0)[0]

    interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL_PATH)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    interpreter.set_tensor(input_details[0]["index"], sample)
    interpreter.invoke()
    tflite_pred = interpreter.get_tensor(output_details[0]["index"])[0]

    max_diff = np.max(np.abs(keras_pred - tflite_pred))
    print(f"Keras top class: {np.argmax(keras_pred)}, "
          f"TFLite top class: {np.argmax(tflite_pred)}, "
          f"max prob diff: {max_diff:.5f}")


def main():
    inference_model = build_inference_model()
    convert_to_tflite(inference_model)
    sanity_check(inference_model)


if __name__ == "__main__":
    main()
