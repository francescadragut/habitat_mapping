#!/bin/bash
#SBATCH --job-name=create_r_env
#SBATCH --output=create_r_env_%j.out
#SBATCH --error=create_r_env_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00

set -euo pipefail

# load conda
source $(conda info --base)/etc/profile.d/conda.sh

ENV_NAME="r_gis_env"

# remove old env (optional but recommended if broken)
conda env remove -n $ENV_NAME -y || true

echo "Creating environment..."

conda env create -f environments/r/geo_env_r.yml

echo "Done."

conda env list