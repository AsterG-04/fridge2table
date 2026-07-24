"""
Builds ai_models/dataset_v4/ -- the existing 56 v3 classes PLUS 12 new
fruit/vegetable classes sourced from Fruits-360 (MIT License, Mihai
Oltean & Horea Muresan -- https://github.com/Horea94/Fruit-Images-Dataset),
found while auditing recipe/dataset coverage for genuinely uncovered
ingredients:

    strawberry, blueberry, raspberry, cherry, fig, dates, guava, lychee,
    rambutan, dragon fruit, mangosteen, kohlrabi

Fruits-360 has ~260 classes total (mostly densely-sampled fruit varieties
photographed on a rotating turntable against a plain background) -- only
the 12 above are pulled here, capped per class, since the full dataset is
both far larger than needed and mostly irrelevant sub-varieties (e.g. 7
different apple cultivars) already well covered by the existing dataset.

Meat/protein classes were investigated too but skipped -- no MIT/CC0
dataset for raw meat *species* classification (chicken vs. beef vs. pork)
was found; what exists is either freshness/spoilage binary classifiers or
partial/CC-BY object-detection sets missing pork and fish entirely.

Does NOT touch ai_models/dataset_v3/ or ai_models/model/ -- purely
additive, so the current working v3 dataset/model are never at risk.

Run from ai_models/ with the venv activated:
    venv\\Scripts\\python.exe scripts\\build_dataset_v4.py
"""

import json
import os
import shutil
import urllib.parse
import urllib.request

BASE_DIR = os.path.join(os.path.dirname(__file__), "..")
V3_DATASET_DIR = os.path.join(BASE_DIR, "dataset_v3")
V4_DATASET_DIR = os.path.join(BASE_DIR, "dataset_v4")

GITHUB_API_TREE = (
    "https://api.github.com/repos/Horea94/Fruit-Images-Dataset/git/trees/master?recursive=1"
)
GITHUB_RAW_BASE = "https://raw.githubusercontent.com/Horea94/Fruit-Images-Dataset/master"

# Fruits-360 source folder name -> our class name. Multiple source folders
# can map to the same class (e.g. several cherry varieties all become one
# generic "cherry" class, matching how the rest of this app's ingredient
# vocabulary is genus-level rather than cultivar-level).
NEW_CATEGORIES = {
    "Strawberry": "strawberry",
    "Strawberry Wedge": "strawberry",
    "Blueberry": "blueberry",
    "Raspberry": "raspberry",
    "Cherry 1": "cherry",
    "Cherry 2": "cherry",
    "Cherry Rainier": "cherry",
    "Cherry Wax Black": "cherry",
    "Cherry Wax Red": "cherry",
    "Cherry Wax Yellow": "cherry",
    "Fig": "fig",
    "Dates": "dates",
    "Guava": "guava",
    "Lychee": "lychee",
    "Rambutan": "rambutan",
    "Pitahaya Red": "dragon fruit",
    "Mangostan": "mangosteen",
    "Kohlrabi": "kohlrabi",
}

# Fruits-360 images are near-identical rotating-turntable frames of the
# same handful of physical fruit -- a big per-class count buys little
# extra generalization here and mostly just adds download time.
MAX_TRAIN_PER_SOURCE_FOLDER = 120
MAX_TEST_PER_SOURCE_FOLDER = 30


def copy_v3_classes():
    print("Copying existing 56 v3 classes into dataset_v4...")

    for split in ("train", "test"):
        src_split_dir = os.path.join(V3_DATASET_DIR, split)
        dst_split_dir = os.path.join(V4_DATASET_DIR, split)
        os.makedirs(dst_split_dir, exist_ok=True)

        for class_name in os.listdir(src_split_dir):
            src_class_dir = os.path.join(src_split_dir, class_name)
            dst_class_dir = os.path.join(dst_split_dir, class_name)

            if os.path.exists(dst_class_dir):
                continue

            shutil.copytree(src_class_dir, dst_class_dir)

    print("Done copying v3 classes.")


def fetch_tree():
    req = urllib.request.Request(
        GITHUB_API_TREE,
        headers={"Accept": "application/vnd.github+json", "User-Agent": "fridge2table-dataset-build"},
    )
    with urllib.request.urlopen(req, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


def download_new_classes():
    print("Fetching Fruits-360 repo file tree...")
    tree = fetch_tree()
    all_paths = [entry["path"] for entry in tree.get("tree", []) if entry["type"] == "blob"]
    print(f"Repo has {len(all_paths)} files total.")

    # Some source folders (e.g. Strawberry, Rambutan, Raspberry) only exist
    # under Test/ in the upstream repo, not Training/ -- pooling both splits
    # per class and doing our own train/test split sidesteps that
    # inconsistency instead of silently ending up with zero training images
    # for those classes (the same class of bug fixed for Mushroom in v3).
    by_class = {}
    for source_folder, class_name in NEW_CATEGORIES.items():
        for github_dir in ("Training", "Test"):
            prefix = f"{github_dir}/{source_folder}/"
            matching = sorted(p for p in all_paths if p.startswith(prefix))
            by_class.setdefault(class_name, []).extend(matching)

    counters = {"train": {}, "test": {}}
    for class_name, paths in by_class.items():
        # Sorted + fixed-size slices, not random shuffling -- deterministic
        # and reproducible across reruns without needing a seeded RNG.
        train_paths = paths[:MAX_TRAIN_PER_SOURCE_FOLDER]
        test_paths = paths[MAX_TRAIN_PER_SOURCE_FOLDER:MAX_TRAIN_PER_SOURCE_FOLDER + MAX_TEST_PER_SOURCE_FOLDER]

        for split, split_paths in (("train", train_paths), ("test", test_paths)):
            class_dir = os.path.join(V4_DATASET_DIR, split, class_name)
            os.makedirs(class_dir, exist_ok=True)
            succeeded = 0
            for i, path in enumerate(split_paths, start=1):
                dst_path = os.path.join(class_dir, f"{i:04d}.jpg")
                if os.path.exists(dst_path):
                    succeeded += 1
                    continue
                # Path segments (e.g. "Cherry 1", "Pitahaya Red") contain
                # spaces, which urlretrieve rejects unencoded -- quote each
                # segment but keep the "/" separators literal.
                encoded_path = "/".join(urllib.parse.quote(part) for part in path.split("/"))
                image_url = f"{GITHUB_RAW_BASE}/{encoded_path}"
                try:
                    urllib.request.urlretrieve(image_url, dst_path)
                    succeeded += 1
                except Exception as e:
                    print(f"  Failed to download {path}: {e}")
            counters[split][class_name] = succeeded

    print(f"train: {counters['train']}")
    print(f"test: {counters['test']}")
    print("Done downloading new classes.")


def main():
    os.makedirs(V4_DATASET_DIR, exist_ok=True)
    copy_v3_classes()
    download_new_classes()

    train_classes = sorted(os.listdir(os.path.join(V4_DATASET_DIR, "train")))
    print(f"\ndataset_v4 has {len(train_classes)} classes: {train_classes}")


if __name__ == "__main__":
    main()
