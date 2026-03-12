#!/bin/bash

#SBATCH --account=p32153  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=short  ### PARTITION (buyin, short, normal, etc)
#SBATCH --nodes=1 ## how many computers do you need
#SBATCH --ntasks-per-node=16 ## how many cpus or processors do you need on each computer
#SBATCH --time=04:00:00 ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --job-name=step5postprocessing ## When you run squeue -u NETID this is how you can identify the job
#SBATCH --output=/projects/p32153/chistig-placematch/05-simulation-sweeps/postprocessing.out ## standard out and standard error goes to this file
#SBATCH --error=/projects/p32153/chistig-placematch/05-simulation-sweeps/postprocessing.err
#SBATCH --mem=473G
#SBATCH --mail-type=ALL ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (complet$
#SBATCH --mail-user=spr4854@northwestern.edu ## your email
#SBATCH --constraint="[quest13]"

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

SECONDS=0
Rscript /projects/p32153/chistig-placematch/05-simulation-sweeps/post_sweep_processing1.R
echo $SECONDS
