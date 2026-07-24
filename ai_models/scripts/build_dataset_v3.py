"""
Builds ai_models/dataset_v3/ -- the existing 40 v2 classes PLUS 16 new
classes sourced from the same MIT-licensed Grocery Store Dataset
(marcusklasson/GroceryStoreDataset on GitHub) that supplied v2's dairy
classes:

  Fruit (10 new):  avocado, melon, nectarine, papaya, passion fruit,
                    peach, plum, grapefruit, satsuma, lime
  Vegetables (4 new): asparagus, leek, mushroom, zucchini
  Dairy-alternative (2 new): oat milk, soy milk

Note: this source dataset has NO egg category at all -- eggs need a
different data source (or user-supplied photos) and are NOT covered by
this script. Flagging rather than silently skipping.

Does NOT touch ai_models/dataset_v2/ or ai_models/model/ -- purely
additive, so the current working v2 dataset/model are never at risk.

Run from ai_models/ with the venv activated:
    venv\\Scripts\\python.exe scripts\\build_dataset_v3.py
"""

import os
import shutil
import urllib.request

BASE_DIR = os.path.join(os.path.dirname(__file__), "..")
V2_DATASET_DIR = os.path.join(BASE_DIR, "dataset_v2")
V3_DATASET_DIR = os.path.join(BASE_DIR, "dataset_v3")

GITHUB_RAW_BASE = (
    "https://raw.githubusercontent.com/marcusklasson/GroceryStoreDataset"
    "/master/dataset"
)

# Grocery Store Dataset subfolder prefix -> our class name. Prefixes are
# matched against the *fine-grained* subfolder (not just the coarse
# category) so classes like Melon and Mushroom can pull specific
# sub-varieties without accidentally sweeping in Watermelon (already its
# own separate v2 class) or other unwanted siblings.
NEW_CATEGORIES = {
    "Fruit/Avocado/": "avocado",
    "Fruit/Melon/Cantaloupe/": "melon",
    "Fruit/Melon/Galia-Melon/": "melon",
    "Fruit/Melon/Honeydew-Melon/": "melon",
    "Fruit/Nectarine/": "nectarine",
    "Fruit/Papaya/": "papaya",
    "Fruit/Passion-Fruit/": "passion fruit",
    "Fruit/Peach/": "peach",
    "Fruit/Plum/": "plum",
    "Fruit/Red-Grapefruit/": "grapefruit",
    "Fruit/Satsumas/": "satsuma",
    "Fruit/Lime/": "lime",
    "Vegetables/Asparagus/": "asparagus",
    "Vegetables/Leek/": "leek",
    # The upstream dataset is inconsistent about this one class: test.txt
    # nests it under Vegetables/Mushroom/Brown-Cap-Mushroom/, train.txt
    # has it directly under Vegetables/Brown-Cap-Mushroom/ with no
    # intermediate "Mushroom" folder. Both prefixes are needed or the
    # train split silently ends up with zero images for this class.
    "Vegetables/Mushroom/": "mushroom",
    "Vegetables/Brown-Cap-Mushroom/": "mushroom",
    "Vegetables/Zucchini/": "zucchini",
    "Packages/Oat-Milk/": "oat milk",
    "Packages/Soy-Milk/": "soy milk",
}


def copy_v2_classes():
    print("Copying existing 40 v2 classes into dataset_v3...")

    for split in ("train", "test"):
        src_split_dir = os.path.join(V2_DATASET_DIR, split)
        dst_split_dir = os.path.join(V3_DATASET_DIR, split)
        os.makedirs(dst_split_dir, exist_ok=True)

        for class_name in os.listdir(src_split_dir):
            src_class_dir = os.path.join(src_split_dir, class_name)
            dst_class_dir = os.path.join(dst_split_dir, class_name)

            if os.path.exists(dst_class_dir):
                continue

            shutil.copytree(src_class_dir, dst_class_dir)

    print("Done copying v2 classes.")


def download_split_list(split):
    url = f"{GITHUB_RAW_BASE}/{split}.txt"
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read().decode("utf-8").splitlines()


def download_new_classes():
    print("Downloading new classes from Grocery Store Dataset...")

    for split in ("train", "test"):
        lines = download_split_list(split)

        counters = {name: 0 for name in set(NEW_CATEGORIES.values())}

        for line in lines:
            path = line.split(",")[0].strip()

            for prefix, class_name in NEW_CATEGORIES.items():
                full_prefix = f"{split}/{prefix}"
                if not path.startswith(full_prefix):
                    continue

                class_dir = os.path.join(V3_DATASET_DIR, split, class_name)
                os.makedirs(class_dir, exist_ok=True)

                counters[class_name] += 1
                dst_path = os.path.join(class_dir, f"{counters[class_name]:04d}.jpg")

                image_url = f"{GITHUB_RAW_BASE}/{path}"
                try:
                    urllib.request.urlretrieve(image_url, dst_path)
                except Exception as e:
                    print(f"  Failed to download {path}: {e}")
                break

        print(f"{split}: {counters}")

    print("Done downloading new classes.")


def main():
    os.makedirs(V3_DATASET_DIR, exist_ok=True)
    copy_v2_classes()
    download_new_classes()

    train_classes = sorted(os.listdir(os.path.join(V3_DATASET_DIR, "train")))
    print(f"\ndataset_v3 has {len(train_classes)} classes: {train_classes}")
    print(
        "\nNote: no egg category was available in the source dataset -- "
        "eggs still need a separate data source or user-supplied photos."
    )


if __name__ == "__main__":
    main()
