"""
Downloads the fruit/vegetable ingredient dataset from Hugging Face
and saves it to disk as JPEG files organized by class, e.g.:

    ai_models/dataset/train/tomato/0001.jpg
    ai_models/dataset/train/tomato/0002.jpg
    ai_models/dataset/test/tomato/0001.jpg

Run from ai_models/ with the venv activated:
    venv\\Scripts\\python.exe scripts\\download_dataset.py
"""

import os
from datasets import load_dataset

DATASET_NAME = "Nattakarn/fruit-and-vegetable-image-recognition"
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "dataset")


def save_split(split_name, split_data, class_names):
    split_dir = os.path.join(OUTPUT_DIR, split_name)

    counters = {}

    for example in split_data:
        label_id = example["label"]
        class_name = class_names[label_id]

        class_dir = os.path.join(split_dir, class_name)
        os.makedirs(class_dir, exist_ok=True)

        counters[class_name] = counters.get(class_name, 0) + 1
        filename = f"{counters[class_name]:04d}.jpg"

        image = example["image"].convert("RGB")
        image.save(os.path.join(class_dir, filename), "JPEG")

    print(f"{split_name}: saved {sum(counters.values())} images across {len(counters)} classes")


def main():
    print(f"Downloading {DATASET_NAME} from Hugging Face...")

    dataset = load_dataset(DATASET_NAME)

    class_names = dataset["train"].features["label"].names
    print(f"Classes ({len(class_names)}): {class_names}")

    save_split("train", dataset["train"], class_names)
    save_split("test", dataset["test"], class_names)

    print(f"Done. Dataset saved to {os.path.abspath(OUTPUT_DIR)}")


if __name__ == "__main__":
    main()
