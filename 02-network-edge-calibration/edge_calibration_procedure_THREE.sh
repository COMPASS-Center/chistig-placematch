#!/bin/bash

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

yaml_file="$1"
echo "$yaml_file"


# Create the simulation runs input args file and writes it into the interim directory as defined in the yaml file
# This also creates the sbatch file to run the set of simulations on the cluster
# Finally, this copies the simulation Rscript from the parent step2 directory to the interim directory 
python step3a_edge_calibration.py "$yaml_file" 


cp "$yaml_file" interim/
cd interim/
sbatch step3a_simulation_sbatch.sh "$yaml_file"

