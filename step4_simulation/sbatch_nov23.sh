#!/bin/bash

#SBATCH --account=p32153  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=normal  ### PARTITION (buyin, short, normal, etc)
#SBATCH --array=0-479 ## number of jobs to run "in parallel" 
#SBATCH --nodes=1 ## how many computers do you need
#SBATCH --ntasks-per-node=1 ## how many cpus or processors do you need on each computer
#SBATCH --time=08:00:00 ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem=3G
#SBATCH --job-name="nov23_\${SLURM_ARRAY_TASK_ID}" ## When you run squeue -u NETID this is how you can identify the job
#SBATCH --output=nov23.%A_%a.out ## standard out and standard error goes to this file
#SBATCH --mail-type=ALL ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (completed, failed, etc)
#SBATCH --mail-user=tom.wolff@northwestern.edu ## your email

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version


IFS=$'\n' read -d '' -r -a input_args < input_args_nov23.txt
echo ${input_args[$SLURM_ARRAY_TASK_ID]}

SECONDS=0
Rscript simtest_23nov2024.R ${input_args[$SLURM_ARRAY_TASK_ID]}
echo $SECONDS

