#!/bin/bash

#SBATCH --account=p32153  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=normal  ### PARTITION (buyin, short, normal, etc)
#SBATCH --array=0-79 ## number of jobs to run "in parallel"
#SBATCH --nodes=1 ## how many computers do you need
#SBATCH --ntasks-per-node=1 ## how many cpus or processors do you need on each computer
#SBATCH --time=10:30:00 ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem=3G
#SBATCH --job-name="${SLURM_ARRAY_TASK_ID}_sim_NA" ## When you run squeue -u NETID this is how you can identify the job
#SBATCH --output=%a_80.%A.sim.NA.out ## standard out and standard error goes to this file
#SBATCH --mail-type=ALL ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (complet$
#SBATCH --mail-user=tom.wolff@northwestern.edu ## your email

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

IFS=$'\n' read -d '' -r -a input_args < step3a_simulation_runs_input_args.txt
echo ${input_args[$SLURM_ARRAY_TASK_ID]}

SECONDS=0
Rscript step3a_simtest.R ${input_args[$SLURM_ARRAY_TASK_ID]}
echo $SECONDS
