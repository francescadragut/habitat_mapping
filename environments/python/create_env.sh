#!/bin/bash
#SBATCH --job-name=create_env
#SBATCH --time=00:30:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --output=create_env_%j.out

# Load Conda (adjust depending on your cluster)
module load anaconda 2>/dev/null || module load miniconda 2>/dev/null

# Initialize conda for non-interactive shell
source $(conda info --base)/etc/profile.d/conda.sh

# Create environment from YAML file
conda env create -f environments/python/environment.yml

# Optional: verify creation
conda activate habitat-mapping
python -c "import geopandas, rasterio; print('Environment created successfully')"