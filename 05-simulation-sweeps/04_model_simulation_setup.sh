#!/bin/bash

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

yaml_file=$1

# set up the sbatch script and the input arguments
python 04_setup_model_simulation_batch_runs.py "$yaml_file"

# make the sbatch file executable
chmod +x 04_sbatch.sh

# submit the sbatch script to quest
sbatch 04_sbatch.sh