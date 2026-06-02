#!/bin/bash
#SBATCH --job-name=test_it2
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH --output=logs/testing/test_it2_%j.out

source $(conda info --base)/etc/profile.d/conda.sh
conda activate habitat-mapping

python iterations/iteration2/test_it2.py

