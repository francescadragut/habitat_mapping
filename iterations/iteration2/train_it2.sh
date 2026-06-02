#!/bin/bash
#SBATCH --job-name=habitat_train_it2
#SBATCH --time=500:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=8
#SBATCH --output=logs/training/train_it2_%j.out

module load anaconda 2>/dev/null || module load miniconda 2>/dev/null
source $(conda info --base)/etc/profile.d/conda.sh

conda activate habitat-mapping

python iterations/iteration2/train_it2.py
python iterations/iteration2/test_it2.py


