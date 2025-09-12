#!/bin/bash

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

yaml_file="$1"
echo "$yaml_file"


# set up the calibration matrix
# reads in the YAML file and outputs the edge_target_calibration_vals.csv 
# both the YAML file and .csv file are saved in the ".../chistig-placematch/02-network-edge-calibration" directory
Rscript step1_edge_calibration.R "$yaml_file"

# create the netest objects for each of the calibration sets
# reads in the YAML file and outputs the netest data objects
Rscript step2a_edge_calibration.R "$yaml_file"

# create the Sbatch file for running the ERGM fits for each calibration set, partnership type, and treatment type 
# reads in the YAML file
# outputs a step2_ergm_fit_procedure_input_args_<expname>.txt data file that sets up each of the ergm fit runs
# outputs an sbatch bash file for the ergm fit procedure on Quest: step2b_sbatch_ergm_fit_procedure_<expname>.sh
python step2b_setup_ergm_fit_procedure.py "$yaml_file"

# make the sbatch file executable
chmod +x step2b_sbatch_ergm_fit_procedure.sh

# submit the sbatch script to quest
sbatch step2b_sbatch_ergm_fit_procedure.sh

