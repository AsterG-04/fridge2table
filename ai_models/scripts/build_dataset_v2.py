"""
Builds ai_models/dataset_v2/ — the original 36 fruit/vegetable classes
PLUS 4 new dairy classes (milk, sour cream, sour milk, yoghurt) sourced
from the MIT-licensed Grocery Store Dataset (marcusklasson/GroceryStoreDataset
on GitHub).

Does NOT touch ai_models/dataset/ or ai_models/model/ — this is purely
additive, so the existing working v1 model/dataset are never at risk.

Run from ai_models/ with the venv activated:
    venv\\Scripts\\python.exe scripts\\build_dataset_v2.py
"""

import os
import shutil
import urllib.request

BASE_DIR = os.path.join(os.path.dirname(__file__), "..")
V1_DATASET_DIR = os.path.join(BASE_DIR, "dataset")
V2_DATASET_DIR = os.path.join(BASE_DIR, "dataset_v2")

GITHUB_RAW_BASE = (
    "https://raw.githubusercontent.com/marcusklasson/GroceryStoreDataset"
    "/master/dataset"
)

# Grocery Store Dataset folder name -> our class name
DAIRY_CATEGORIES = {
    "Milk": "milk",
    "Sour-Cream": "sour cream",
    "Sour-Milk": "sour milk",
    "Yoghurt": "yoghurt",
}


def copy_v1_classes():
    print("Copying existing 36 fruit/vegetable classes into dataset_v2...")

    for split in ("train", "test"):
        src_split_dir = os.path.join(V1_DATASET_DIR, split)
        dst_split_dir = os.path.join(V2_DATASET_DIR, split)
        os.makedirs(dst_split_dir, exist_ok=True)

        for class_name in os.listdir(src_split_dir):
            src_class_dir = os.path.join(src_split_dir, class_name)
            dst_class_dir = os.path.join(dst_split_dir, class_name)

            if os.path.exists(dst_class_dir):
                continue

            shutil.copytree(src_class_dir, dst_class_dir)

    print("Done copying v1 classes.")


def download_split_list(split):
    filename = f"{split}.txt"
    url = f"{GITHUB_RAW_BASE}/{filename}"

    with urllib.request.urlopen(url) as response:
        return response.read().decode("utf-8").splitlines()


def download_dairy_classes():
    print("Downloading dairy images from Grocery Store Dataset...")

    for split, grocery_split in [("train", "train"), ("test", "test")]:
        lines = download_split_list(grocery_split)

        counters = {name: 0 for name in DAIRY_CATEGORIES.values()}

        for line in lines:
            path = line.split(",")[0].strip()

            for folder_name, class_name in DAIRY_CATEGORIES.items():
                prefix = f"{grocery_split}/Packages/{folder_name}/"
                if not path.startswith(prefix):
                    continue

                class_dir = os.path.join(V2_DATASET_DIR, split, class_name)
                os.makedirs(class_dir, exist_ok=True)

                counters[class_name] += 1
                dst_path = os.path.join(
                    class_dir, f"{counters[class_name]:04d}.jpg"
                )

                image_url = f"{GITHUB_RAW_BASE}/{path}"
                urllib.request.urlretrieve(image_url, dst_path)
                break

        print(f"{split}: {counters}")

    print("Done downloading dairy classes.")


def main():
    os.makedirs(V2_DATASET_DIR, exist_ok=True)
    copy_v1_classes()
    download_dairy_classes()

    train_classes = sorted(os.listdir(os.path.join(V2_DATASET_DIR, "train")))
    print(f"\ndataset_v2 has {len(train_classes)} classes: {train_classes}")


if __name__ == "__main__":
    main()
