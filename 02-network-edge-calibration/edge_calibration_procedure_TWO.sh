#!/bin/bash

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version


yaml_file="$1"
echo "$yaml_file"

# Look for the convergence.fail.fname defined in the yaml file (e.g. edge_calibration_sets_that_did_not_converge.txt)
# in the interim.data.subdir defined int he yaml file. 
# If all calibration set numbers exist in that file, then you must retry the ergm fits.
# Do so by reruning edge_calibration_procedure_ONE.sh
# This will create a new set of random values to try for each of the calibration sets. 

# If at least one calibration set succeeds with an ergm fit, then the following will combine the 
# outputs of that calibration set to then be run in step 3. 
Rscript step2c_edge_calibration.R "$yaml_file"






# simdirectory="../../chistig/"
# expname=$(basename "$PWD")
# #sbatchname="$simdirectory/sbatch_${expname}.sh"
# sbatchname="sbatch_${expname}.sh"
# echo "$sbatchname"
# echo "$simdirectory"

# # put all of the ERGM fits together based on calibration run and treatment type 
# # save these ERGM fits to the netest folder (which is .../ChiSTIG_model/data/input/)
# Rscript step2c_edge_calibration.R "$yaml_file"


# # write the sbatch file for the simulation runs
# python step3a_edge_calibration.py "$yaml_file"


# # move to the simulation directory within the project folder
# #cd ../../chistig/
# cd "$simdirectory"

# # make the sbatch file executable
# chmod +x "$sbatchname"


# # submit the sbatch script to quest
# sbatch "$sbatchname"



