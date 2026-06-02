import os
import sys
import logging
import numpy as np
import rasterio
import torch
import segmentation_models_pytorch as smp
from torch.utils.data import Dataset, DataLoader

# ==============================
# ðŸ“ PATH CONFIG (HPC SAFE)
# ==============================

BASE_DIR = os.environ.get("HABITAT_OUTPUT", os.path.expanduser("~/habitat_mapping/output/output_it1"))
DATA_BASE = os.environ.get("HABITAT_DATA", os.path.expanduser("~/habitat_mapping/input/model_data"))

TEST_IMG = os.path.join(DATA_BASE, "tiles/test")
TEST_MASK = os.path.join(DATA_BASE, "masks_it1/test")

MODEL_PATH = os.path.join(BASE_DIR, "models/best_model.pth")
PRED_DIR = os.path.join(BASE_DIR, "predictions")
METRIC_DIR = os.path.join(BASE_DIR, "metrics")

os.makedirs(PRED_DIR, exist_ok=True)
os.makedirs(METRIC_DIR, exist_ok=True)

# ==============================
# ðŸ§¾ LOGGING
# ==============================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(os.path.join(BASE_DIR, "eval.log")),
        logging.StreamHandler(sys.stdout),
    ],
)

def log(msg):
    logging.info(msg)

# ==============================
# âš™ï¸ DEVICE
# ==============================

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
log(f"Using device: {device}")

# ==============================
# ðŸ” DATASET (ROBUST VERSION)
# ==============================

class HabitatTestDataset(Dataset):
    def __init__(self, img_dir, mask_dir):
        self.img_dir = img_dir
        self.mask_dir = mask_dir

        raw_files = sorted([f for f in os.listdir(img_dir) if f.endswith(".tif")])

        self.pairs = []

        log("Building dataset pairs...")

        for img_name in raw_files:
            mask_name = img_name.replace("tile_", "mask_it1_")

            img_path = os.path.join(img_dir, img_name)
            mask_path = os.path.join(mask_dir, mask_name)

            if not os.path.exists(mask_path):
                log(f"Skipping (missing mask): {img_name}")
                continue

            self.pairs.append((img_path, mask_path, img_name))

        if len(self.pairs) == 0:
            raise RuntimeError("No valid image-mask pairs found!")

        log(f"Dataset ready: {len(self.pairs)} valid pairs\n")

    def __len__(self):
        return len(self.pairs)

    def __getitem__(self, idx):
        img_path, mask_path, fname = self.pairs[idx]

        # read image
        with rasterio.open(img_path) as src:
            img = src.read(1).astype(np.float32)

        # read mask
        with rasterio.open(mask_path) as src:
            mask = src.read(1).astype(np.float32)

        # clean NaNs
        img = np.nan_to_num(img, nan=0.0)
        mask = np.nan_to_num(mask, nan=0.0)

        # convert classes 1â€“9 â†’ 0â€“8
        mask = mask.astype(np.int64) - 1
        mask = np.clip(mask, 0, 8)

        img = torch.from_numpy(img).unsqueeze(0)
        mask = torch.from_numpy(mask).long()

        return img, mask, fname

# ==============================
# ðŸ“Š IOU
# ==============================

def compute_iou(conf_matrix):
    ious = []

    for i in range(conf_matrix.shape[0]):
        TP = conf_matrix[i, i]
        FP = conf_matrix[:, i].sum() - TP
        FN = conf_matrix[i, :].sum() - TP

        denom = TP + FP + FN
        iou = TP / denom if denom > 0 else 0.0
        ious.append(iou)

    return ious, np.mean(ious)

# ==============================
# ðŸš€ EVALUATION
# ==============================

def evaluate():
    log("=== EVALUATION START ===")

    dataset = HabitatTestDataset(TEST_IMG, TEST_MASK)
    loader = DataLoader(dataset, batch_size=1, shuffle=False)

    # model
    model = smp.Unet(
        encoder_name="resnet34",
        encoder_weights=None,
        in_channels=1,
        classes=9,
    )

    model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
    model.to(device)
    model.eval()

    log("Model loaded")

    num_classes = 9
    conf_matrix = np.zeros((num_classes, num_classes), dtype=np.int64)

    with torch.no_grad():
        for img, gt_mask, fname in loader:
            img = img.to(device)

            pred = torch.argmax(model(img), dim=1).cpu().numpy()[0]
            gt = gt_mask.numpy()[0]

            # update confusion matrix
            for i in range(num_classes):
                for j in range(num_classes):
                    conf_matrix[i, j] += np.sum((gt == i) & (pred == j))

            # ==========================
            # SAVE PREDICTION (SAFE)
            # ==========================
            original_path = os.path.join(TEST_IMG, fname[0])

            with rasterio.open(original_path) as src:
                meta = src.meta.copy()

            pred_save = pred + 1  # back to 1â€“9

            out_path = os.path.join(
                PRED_DIR, fname[0].replace(".tif", "_pred.tif")
            )

            with rasterio.open(out_path, "w", **meta) as dst:
                dst.write(pred_save.astype(np.uint8), 1)

            log(f"Processed: {fname[0]}")

    # ==============================
    # ðŸ“Š METRICS
    # ==============================

    ious, mean_iou = compute_iou(conf_matrix)

    log("\n=== RESULTS ===")
    for i, iou in enumerate(ious):
        log(f"Class {i+1} IoU: {iou:.4f}")

    log(f"Mean IoU: {mean_iou:.4f}")

    # save metrics
    out_file = os.path.join(METRIC_DIR, "iou.txt")
    with open(out_file, "w") as f:
        f.write("Confusion Matrix:\n")
        f.write(str(conf_matrix) + "\n\n")
        for i, iou in enumerate(ious):
            f.write(f"Class {i+1}: {iou:.4f}\n")
        f.write(f"\nMean IoU: {mean_iou:.4f}\n")

    log(f"Metrics saved to {out_file}")
    log("=== EVALUATION COMPLETE ===")

# ==============================
# ðŸ§  MAIN
# ==============================

if __name__ == "__main__":
    try:
        evaluate()
    except Exception as e:
        log(f"FATAL ERROR: {e}")
        raise

