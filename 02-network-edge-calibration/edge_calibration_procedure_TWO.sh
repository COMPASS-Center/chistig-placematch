#!/bin/bash

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

yaml_file="$1"
echo "$yaml_file"

simdirectory="../../chistig/"
expname=$(basename "$PWD")
#sbatchname="$simdirectory/sbatch_${expname}.sh"
sbatchname="sbatch_${expname}.sh"
echo "$sbatchname"
echo "$simdirectory"

# put all of the ERGM fits together based on calibration run and treatment type 
# save these ERGM fits to the netest folder (which is .../ChiSTIG_model/data/input/)
Rscript step2c_edge_calibration.R "$yaml_file"


# write the sbatch file for the simulation runs
python step3a_edge_calibration.py "$yaml_file"


# move to the simulation directory within the project folder
#cd ../../chistig/
cd "$simdirectory"

# make the sbatch file executable
chmod +x "$sbatchname"


# submit the sbatch script to quest
sbatch "$sbatchname"



