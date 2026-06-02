#!/bin/bash
#SBATCH --job-name=test_it3
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH --output=logs/testing/test_it3_%j.out

source $(conda info --base)/etc/profile.d/conda.sh
conda activate habitat-mapping

python iterations/iteration3/test_it3.py

