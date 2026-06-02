#!/bin/bash
#SBATCH --job-name=env_check
#SBATCH --time=00:10:00
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1
#SBATCH --output=env_check_%j.out

# Load Conda (adjust depending on your cluster)
module load anaconda 2>/dev/null || module load miniconda 2>/dev/null

# Initialize conda for non-interactive shell
source $(conda info --base)/etc/profile.d/conda.sh

# Activate existing environment (DO NOT create it here)
conda activate habitat-mapping

# Verify that key packages are available
python -c "import geopandas, rasterio; print('Environment OK')"
