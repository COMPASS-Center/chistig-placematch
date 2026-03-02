#!/bin/bash

#SBATCH --account=p32153  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=normal  ### PARTITION (buyin, short, normal, etc)
#SBATCH --nodes=1 ## how many computers do you need
#SBATCH --ntasks-per-node=1 ## how many cpus or processors do you need on each computer
#SBATCH --time=24:00:00 ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem=3G
#SBATCH --job-name=step5_test ## When you run squeue -u NETID this is how you can identify the job
#SBATCH --output=/projects/p32153/chistig-placematch/05-simulation-sweeps/step5_test.out ## standard out and standard error goes to this file
#SBATCH --error=/projects/p32153/chistig-placematch/05-simulation-sweeps/step5_test.err
#SBATCH --mail-type=ALL ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (complet$
#SBATCH --mail-user=spr4854@northwestern.edu ## your email

module purge all
conda activate /projects/p32153/condaenvs/conda-swift

R --version

SECONDS=0
Rscript /projects/p32153/chistig-placematch/05-simulation-sweeps/05_chistig_model_simulation.R --runno 1 --siminstance 1 --replicate 1 --simparamsyamlfname /projects/p32153/chistig-placematch/05-simulation-sweeps/05-model-simulation.yaml
echo $SECONDS
