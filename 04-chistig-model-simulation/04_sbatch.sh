#!/bin/bash

#SBATCH --account=p32153  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=normal  ### PARTITION (buyin, short, normal, etc)
#SBATCH --array=0-239 ## number of jobs to run "in parallel"
#SBATCH --nodes=1 ## how many computers do you need
#SBATCH --ntasks-per-node=1 ## how many cpus or processors do you need on each computer
#SBATCH --time=08:00:00 ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem=3G
#SBATCH --job-name="%A" ## When you run squeue -u NETID this is how you can identify the job
#SBATCH --output=%a_240.%A.out ## standard out and standard error goes to this file
#SBATCH --mail-type=ALL ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (complet$
#SBATCH --mail-user=tom.wolff@northwestern.edu ## your email

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

IFS=$'\n' read -d '' -r -a input_args < /Users/rimersara/dev/repos/ChiSTIG/chistig-placematch/04-chistig-model-simulation/04_input_args.txt
echo ${input_args[$SLURM_ARRAY_TASK_ID]}

SECONDS=0
Rscript 04_chistig_model_simulation.R ${input_args[$SLURM_ARRAY_TASK_ID]}
echo $SECONDS

