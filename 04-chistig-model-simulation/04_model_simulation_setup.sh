#!/bin/bash

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

yaml_file=$1

python 04_setup_model_simulation_batch_runs.py yaml_file

