#!/bin/bash

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

yaml_file=$1

# set up the calibration matrix
# reads in the YAML file and outputs the edge_target_calibration_vals_<expname>.csv 
# both the YAML file and .csv file are saved in the ".../ChiSTIG_model/calibration/<expname>/" directory
#Rscript edge_calibration_setup_test18oct.R test_yaml.yaml
Rscript step1_edge_calibration.R test22oct.yaml

# create the netest objects for each of the calibration sets
# reads in the YAML file and outputs the netest data objects
# the YAML file is in the ".../ChiSTIG_model/calibration/<expname>/" directory
# the output netest objects are in the ".../ChiSTIG_model/data/input/" directory
#Rscript edge_calibration_est_step1.R test_yaml.yaml
Rscript step2a_edge_calibration.R test22oct.yaml

# create the Sbatch file for running the ERGM fits for each calibration set, partnership type, and treatment type 
# reads in the YAML file
# outputs a step2_ergm_fit_procedure_input_args_<expname>.txt data file that sets up each of the ergm fit runs
# outputs an sbatch bash file for the ergm fit procedure on Quest: step2b_sbatch_ergm_fit_procedure_<expname>.sh
#Rscript edge_calibration_est_step2.R test_yaml.yaml
python step2b_setup_ergm_fit_procedure.py test22oct.yaml

# make the sbatch file executable
chmod +x step2b_sbatch_ergm_fit_procedure.sh

# submit the sbatch script to quest
sbatch step2b_sbatch_ergm_fit_procedure.sh

