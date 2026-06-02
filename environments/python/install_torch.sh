#!/bin/bash
#SBATCH --job-name=env_add
#SBATCH --time=00:20:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --output=env_add_%j.out

module load anaconda 2>/dev/null || module load miniconda 2>/dev/null
source $(conda info --base)/etc/profile.d/conda.sh

conda activate habitat-mapping

# Install ONLY lightweight additions
pip install torch torchvision torchaudio
pip install segmentation-models-pytorch

python -c "import torch; print('Torch installed:', torch.__version__)"
