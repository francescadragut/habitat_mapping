import os
import sys
import time
import random
import logging
import numpy as np
import rasterio
import torch
import torch.nn.functional as F
import torch.optim as optim
import segmentation_models_pytorch as smp
from torch.utils.data import Dataset, DataLoader

# ==============================
# ðŸ“ HPC SAFE CONFIG
# ==============================

BASE_DIR = os.environ.get("HABITAT_OUTPUT", os.path.expanduser("~/habitat_mapping/output/output_it2"))
DATA_BASE = os.environ.get("HABITAT_DATA", os.path.expanduser("~/habitat_mapping/input/model_data"))

TRAIN_IMG = os.path.join(DATA_BASE, "tiles/training")
TRAIN_MASK = os.path.join(DATA_BASE, "masks_it2/training")
VAL_IMG = os.path.join(DATA_BASE, "tiles/validation")
VAL_MASK = os.path.join(DATA_BASE, "masks_it2/validation")
TEST_IMG = os.path.join(DATA_BASE, "tiles/test")
TEST_MASK = os.path.join(DATA_BASE, "masks_it2/test")

MODEL_DIR = os.path.join(BASE_DIR, "models")
os.makedirs(MODEL_DIR, exist_ok=True)

# ==============================
# ðŸ§¾ LOGGING
# ==============================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(os.path.join(BASE_DIR, "run.log")),
        logging.StreamHandler(sys.stdout),
    ],
)

def log(msg):
    logging.info(msg)

# ==============================
# ðŸ” ENV CHECK
# ==============================

def check_environment():
    log("=== ENVIRONMENT CHECK ===")
    log(f"Python: {sys.executable}")
    log(f"Working dir: {os.getcwd()}")
    log(f"PyTorch: {torch.__version__}")
    log(f"CUDA available: {torch.cuda.is_available()}")

    for name, path in {
        "TRAIN_IMG": TRAIN_IMG,
        "TRAIN_MASK": TRAIN_MASK,
        "VAL_IMG": VAL_IMG,
        "VAL_MASK": VAL_MASK,
        "TEST_IMG": TEST_IMG,
        "TEST_MASK": TEST_MASK,
    }.items():
        if not os.path.exists(path):
            raise FileNotFoundError(f"{name} missing: {path}")
        log(f"{name}: OK")

    log("Environment OK\n")

# ==============================
# ðŸŽ² SEED
# ==============================

random.seed(42)
np.random.seed(42)
torch.manual_seed(42)

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
log(f"Using device: {device}")

# ==============================
# ðŸ“¦ DATASET (CLEAN + SAFE)
# ==============================

class HabitatDataset(Dataset):
    def __init__(self, image_dir, mask_dir):
        self.image_files = sorted([f for f in os.listdir(image_dir) if f.endswith(".tif")])
        self.mask_files = sorted([f for f in os.listdir(mask_dir) if f.endswith(".tif")])

        self.image_dir = image_dir
        self.mask_dir = mask_dir

        assert len(self.image_files) > 0, f"No images in {image_dir}"

    def __len__(self):
        return len(self.image_files)

    def __getitem__(self, idx):
        img_path = os.path.join(self.image_dir, self.image_files[idx])
        mask_path = os.path.join(self.mask_dir, self.mask_files[idx])

        with rasterio.open(img_path) as src:
            img = src.read(1).astype(np.float32)

        with rasterio.open(mask_path) as src:
            mask = src.read(1).astype(np.float32)

        # clean NaNs safely
        img = np.nan_to_num(img, nan=0.0)
        mask = np.nan_to_num(mask, nan=0.0)

        # classes: 1â€“9 â†’ 0â€“8
        mask = mask.astype(np.int64) - 1

        # clamp invalid values into valid range
        mask = np.clip(mask, 0, 8)

        img = torch.from_numpy(img).unsqueeze(0)
        mask = torch.from_numpy(mask).long()

        return img, mask

# ==============================
# ðŸ”¥ LOSS (NO MASKING NEEDED)
# ==============================

def loss_fn(logits, targets):
    return F.cross_entropy(logits, targets)

# ==============================
# ðŸš€ TRAINING
# ==============================

def train(model, epochs=30):
    log("=== TRAIN START ===")

    train_ds = HabitatDataset(TRAIN_IMG, TRAIN_MASK)
    val_ds = HabitatDataset(VAL_IMG, VAL_MASK)

    train_loader = DataLoader(train_ds, batch_size=4, shuffle=True)
    val_loader = DataLoader(val_ds, batch_size=4)

    model.to(device)
    optimizer = optim.Adam(model.parameters(), lr=1e-3)

    best_val = float("inf")

    for epoch in range(epochs):
        model.train()
        total_loss = 0

        for i, (x, y) in enumerate(train_loader):
            x, y = x.to(device), y.to(device)

            optimizer.zero_grad()
            out = model(x)
            loss = loss_fn(out, y)

            loss.backward()
            optimizer.step()

            total_loss += loss.item()

            if i % 10 == 0:
                log(f"Epoch {epoch+1} Batch {i} Loss {loss.item():.4f}")

        avg_train = total_loss / len(train_loader)
        log(f"Epoch {epoch+1} Train Loss: {avg_train:.4f}")

        # validation
        model.eval()
        val_loss = 0

        with torch.no_grad():
            for x, y in val_loader:
                x, y = x.to(device), y.to(device)
                out = model(x)
                val_loss += loss_fn(out, y).item()

        val_loss /= len(val_loader)
        log(f"Epoch {epoch+1} Val Loss: {val_loss:.4f}")

        if val_loss < best_val:
            best_val = val_loss
            torch.save(model.state_dict(), os.path.join(MODEL_DIR, "best_model.pth"))
            log("Saved best model")

# ==============================
# ðŸ§ª TEST
# ==============================

def test(model):
    log("=== TEST START ===")

    ds = HabitatDataset(TEST_IMG, TEST_MASK)
    loader = DataLoader(ds, batch_size=1)

    for x, _ in loader:
        x = x.to(device)
        pred = torch.argmax(model(x), dim=1).cpu().numpy()[0]

        log(f"Processed sample, unique classes: {np.unique(pred)}")

# ==============================
# ðŸ§  MAIN
# ==============================

if __name__ == "__main__":
    try:
        check_environment()

        model = smp.Unet(
            encoder_name="resnet34",
            encoder_weights=None,
            in_channels=1,
            classes=9,
        )

        train(model, epochs=30)

        model.load_state_dict(torch.load(os.path.join(MODEL_DIR, "best_model.pth")))
        model.to(device)
        model.eval()

        test(model)

        log("PIPELINE COMPLETE")

    except Exception as e:
        log(f"FATAL ERROR: {e}")
        raise

