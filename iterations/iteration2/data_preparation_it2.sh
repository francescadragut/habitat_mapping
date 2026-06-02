#!/bin/bash
#SBATCH --job-name=data_preparation_it2
#SBATCH --output=logs/data_preparation/data_preparation_it2_%j.out
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00

set -e

# ============================================================
# MOVE TO PROJECT ROOT
# ============================================================

cd ~/habitat_mapping

# ============================================================
# LOAD CONDA ENV
# ============================================================

source ~/.bashrc

ENV_NAME="r_gis_env"

source $(conda info --base)/etc/profile.d/conda.sh
conda activate $ENV_NAME

echo "Active env: $CONDA_DEFAULT_ENV"

which Rscript

# ============================================================
# CREATE LOG DIRS
# ============================================================

mkdir -p logs/data_preparation

# ============================================================
# RUN SCRIPTS
# ============================================================

Rscript --vanilla iterations/iteration2/data_preparation_it2.R

echo "Finished successfully"