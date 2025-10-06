import random
import yaml 
import sys
import pandas as pd
import os

yamlfname = sys.argv[1]

with open(yamlfname) as stream:
    try:
        yamldata = yaml.safe_load(stream)
    except yaml.YAMLError as exc:
        print(exc)


###########################
# setup the directory structure
###########################
repo_dir = yamldata['repo.dir']
model_sim_subdir = f"{repo_dir}{yamldata['model.simulation.subdir']}"
model_sim_interim_subdir = f"{model_sim_subdir}{yamldata['model.simulation.interim.subdir']}"
model_sim_output_subdir = f"{model_sim_subdir}{yamldata['model.simulation.output.subdir']}"

if not os.path.exists(model_sim_interim_subdir):
    os.mkdir(model_sim_interim_subdir)

if not os.path.exists(model_sim_output_subdir):
    os.mkdir(model_sim_output_subdir)


# NOTE: this is the subdirectory from which the scripts submitted to the cluster will be made
# This could be changed to the "interim" subdirectory specified above
# However, if this subdirectory were to change, the dependent files need to also be in the same subdirectory
sbatch_subdir = model_sim_subdir


###########################
# setup the arguments for the batch runs  
###########################
experiment_name = yamldata['experiment.name']

treatments_dict = {'control': 'c', 'venues': 'v', 'apps': 'a', 'both':'b'}
treatments_list = yamldata['treatment.types']
treatments = {}
for treatment in treatments_list:
      treatments[treatment] = treatments_dict[treatment]
num_runs_per_treatment = yamldata['number.runs.per.treatment']

random_seed_max = int(yamldata['random.seed.max'])
random_seeds = random.sample(range(random_seed_max + 1), num_runs_per_treatment)


###########################
# write sbatch input args file
###########################
model_run_args_fname = yamldata['batch.runs.args.fname']
model_run_args_file = f'{sbatch_subdir}{model_run_args_fname}'

run = 0
with open(model_run_args_file, 'w') as file:
    for thistreatment in treatments:
        for thistreatmentrun, thisrandomseed in enumerate(random_seeds):
            line = f"{run}\t{treatments[thistreatment]}{thistreatmentrun+1}\t{experiment_name}\t{thisrandomseed}\t{yamlfname}\n"
            file.write(line)
            run += 1


###########################
# write sbatch script file
###########################
sbatch_bash_commands_outfile = f"{sbatch_subdir}{yamldata['sbatch.outfile.fname']}"


sbatch = f"""
#SBATCH --account=p32153  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition={yamldata['sbatch.partition']}  ### PARTITION (buyin, short, normal, etc)
#SBATCH --array=0-{run-1} ## number of jobs to run "in parallel"
#SBATCH --nodes=1 ## how many computers do you need
#SBATCH --ntasks-per-node=1 ## how many cpus or processors do you need on each computer
#SBATCH --time={yamldata['sbatch.walltime.hours']}:{yamldata['sbatch.walltime.minutes']}:00 ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem={yamldata['sbatch.memory']}
#SBATCH --job-name=%A.{yamldata['experiment.name']} ## When you run squeue -u NETID this is how you can identify the job
#SBATCH --output={model_sim_interim_subdir}%a_{run}.%A.out ## standard out and standard error goes to this file
#SBATCH --error={model_sim_interim_subdir}%a_{run}.%A.err
#SBATCH --mail-type=ALL ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (complet$
#SBATCH --mail-user={yamldata['sbatch.email']} ## your email

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

IFS=$'\\n' read -d '' -r -a input_args < {model_run_args_file}
echo ${{input_args[$SLURM_ARRAY_TASK_ID]}}

SECONDS=0
Rscript {yamldata['model.simulation.rscript.fname']} ${{input_args[$SLURM_ARRAY_TASK_ID]}}
echo $SECONDS

"""

outfile_temp = f'{sbatch_subdir}temp.sh'
# outfile_temp = f'temp.sh'
with open(outfile_temp, 'w') as f:
	f.write(sbatch)
open(f'{sbatch_bash_commands_outfile}', "w").write("#!/bin/bash\n" + open(outfile_temp).read())
