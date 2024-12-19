#!/bin/bash

#SBATCH --account=p32153  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=normal  ### PARTITION (buyin, short, normal, etc)
#SBATCH --array=0-107 ## number of jobs to run "in parallel"
#SBATCH --nodes=1 ## how many computers do you need
#SBATCH --ntasks-per-node=1 ## how many cpus or processors do you need on each computer
#SBATCH --time=10:30:00 ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem=3G
#SBATCH --job-name="test23oct_%A" ## When you run squeue -u NETID this is how you can identify the job
#SBATCH --output=%a_108.%A.test23oct.out ## standard out and standard error goes to this file
#SBATCH --mail-type=ALL ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (complet$
#SBATCH --mail-user=tom.wolff@northwestern.edu ## your email

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

IFS=$'\n' read -d '' -r -a input_args < step2_ergm_fit_procedure_input_args_test23oct.txt
echo ${input_args[$SLURM_ARRAY_TASK_ID]}

IFS=$'\t' read -r runno yamlfname calibrationset treatmenttype partnershiptype  <<< "${input_args[$SLURM_ARRAY_TASK_ID]}"
echo "Run number in SLURM array: ${runno}." 
echo "YAML file name: ${yamlfname}."
echo "Calibration set number for ERGM fit: ${calibrationset}." 
echo "Treatment type for ERGM fit: ${treatmenttype}."
echo "Partnership type for ERGM fit: ${partnershiptype}."

my_random_seed_array=(50 157 146 129 68 171 72 13 198 61)
max_attempts=${#my_random_seed_array[@]}

echo "Array of random seeds for convergence attempts: ${my_random_seed_array[@]}."

timeout_duration=3600

for attempt in "${!my_random_seed_array[@]}"; do

	random_seed=${my_random_seed_array[attempt]}
	echo "Random seed is $random_seed for attempt $((attempt+1)) of $max_attempts..."

	# if timeout "$timeout_duration" Rscript step2b_edge_calibration.R "$yamlfname" "$calibrationset" "$treatmenttype" "$partnershiptype" "${my_random_seed_array[$attempt]}"; then
	if timeout "$timeout_duration" Rscript step2b_edge_calibration.R "$yamlfname" "$calibrationset" "$treatmenttype" "$partnershiptype" "${my_random_seed_array[$attempt]}"; then
        echo "Attempt $((attempt+1)) completed successfully."
        break
    else
    	echo "Attempt $((attempt+1)) did not finish within the timeout period."
    fi

    # If this is the last attempt, exit the loop
    if [ $((attempt+1)) -eq $max_attempts ]; then
        echo "Reached the maximum number of attempts ($max_attempts)."
    fi

done

echo "Finished convergence attempts loop."
