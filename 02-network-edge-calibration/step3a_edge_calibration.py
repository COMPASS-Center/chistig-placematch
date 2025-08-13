import random
import yaml 
import sys
import pandas as pd
import shutil

yamlfname = sys.argv[1]

with open(yamlfname) as stream:
    try:
        yamldata = yaml.safe_load(stream)
    except yaml.YAMLError as exc:
        print(exc)

# experiment name 
# experiment_name = yamldata['expname']
# expiriment_dir = f"{yamldata['repo.dir']}{yamldata['calibration.subdir']}{yamldata['expname']}/"
expiriment_dir = f"{yamldata['repo.dir']}{yamldata['calibration.subdir']}" 

if 'expname' in yamldata:
    experiment_name = yamldata['expname']
    expiriment_dir = f"{expiriment_dir}{experiment_name}/"
else:
    experiment_name = 'NA'
    expiriment_dir = f"{expiriment_dir}"

expiriment_interim_dir = f"{expiriment_dir}{yamldata['interim.data.subdir']}"

# simulation dir 
# simulation_dir = expiriment_interim_dir
simulation_dir = expiriment_interim_dir

# params dir
params_dir = f"{yamldata['repo.dir']}{yamldata['params.subdir']}"

# # obtain the number of calibration runs
calibration_df_fname = f"{yamldata['calibration.matrix.fname']}"
calibration_df_dir = f"{yamldata['repo.dir']}{yamldata['calibration.subdir']}"
calibration_df = pd.read_csv(calibration_df_fname)
num_calibration_sets = max(calibration_df['fit_no'])

out_subdir = expiriment_interim_dir
cset2skip_fname = f"{out_subdir}{yamldata['convergence.fail.fname']}"
with open(cset2skip_fname, 'r') as file:
    cset2skip = [int(line.strip()) for line in file]

# obtain the treatments
treatments_dict = yamldata['treatment.types']
print(treatments_dict)

# the random seed max
random_seed_max = yamldata['max.random.seed']
simulation_random_seeds = random.sample(range(yamldata['max.random.seed'] + 1), yamldata['step3.num.simulation.runs.per.treatment'])

# the file names and locations
sim_args_fname = f"{simulation_dir}{yamldata['step3.simulation.args.fname']}" #nolint
sbatch_simulation_bash_commands_outfile = f"{simulation_dir}{yamldata['step3.simulation.sbatch.fname']}"

# # print(simulation_random_seeds)
# # print(sim_args_fname)
# # print(sbatch_simulation_bash_commands_outfile)
# # # print(sbatch_simulation_bash_commands_outfile)

simulation_args_dict = {}
run = 0
with open(sim_args_fname, 'w') as file:
    for setno in range(1, num_calibration_sets + 1):
        if setno in cset2skip:
            print(f"Calibration set {setno} did not converge and will not be a part of simulation runs.")
        else:
            for thistreatment in treatments_dict:
                for thistreatmentrun, thisrandomseed in enumerate(simulation_random_seeds):
                    # line = f"{run}\t{setno}\t{treatments_dict[thistreatment]}{thistreatmentrun+1}\t{experiment_name}\t{thisrandomseed}\n"
                    simulation_args_dict[run] = {}
                    simulation_args_dict[run]['calibration_set_number'] = setno
                    simulation_args_dict[run]['treatment'] = thistreatment
                    simulation_args_dict[run]['treatment_run'] = thistreatmentrun
                    simulation_args_dict[run]['experiment'] = experiment_name
                    simulation_args_dict[run]['random_seed'] = thisrandomseed
                    line = f"{run}\t{setno}\t{thistreatment}\t{thistreatmentrun+1}\t{experiment_name}\t{thisrandomseed}\n"
                    file.write(line)                                
                    run += 1


# print(simulation_args_dict)



sbatch = f"""
#SBATCH --account=p32153  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition={yamldata['sbatch.partition.sim']}  ### PARTITION (buyin, short, normal, etc)
#SBATCH --array=0-{run-1} ## number of jobs to run "in parallel"
#SBATCH --nodes=1 ## how many computers do you need
#SBATCH --ntasks-per-node=1 ## how many cpus or processors do you need on each computer
#SBATCH --time={yamldata['sbatch.walltime.hours.sim']}:{yamldata['sbatch.walltime.minutes.sim']}:00 ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem={yamldata['sbatch.memory.sim']}
#SBATCH --job-name="${{SLURM_ARRAY_TASK_ID}}_sim_{experiment_name}" ## When you run squeue -u NETID this is how you can identify the job
#SBATCH --output=%a_{run}.%A.sim.{experiment_name}.out ## standard out and standard error goes to this file
#SBATCH --mail-type=ALL ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (complet$
#SBATCH --mail-user={yamldata['sbatch.email']} ## your email

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

IFS=$'\\n' read -d '' -r -a input_args < {yamldata['step3.simulation.args.fname']}
echo ${{input_args[$SLURM_ARRAY_TASK_ID]}}

SECONDS=0
Rscript step3a_simtest.R ${{input_args[$SLURM_ARRAY_TASK_ID]}}
echo $SECONDS
"""

outfile_temp = f'{simulation_dir}temp.sh'
# outfile_temp = f'temp.sh'
with open(outfile_temp, 'w') as f:
        f.write(sbatch)
open(f'{sbatch_simulation_bash_commands_outfile}', "w").write("#!/bin/bash\n" + open(outfile_temp).read())


# create the model params yaml file for the simtest
# cycle through the base model params yaml file
# if the yamldict key is in the overwrite in the calibration, then use the overwrite; otherwise use base
# write out yaml file to the params directory but with the experiment name 
default_sim_params_fname = f"{yamldata['default.simulation.params.fname']}"
default_sim_params_file = f"{params_dir}{default_sim_params_fname}"
new_sim_params_file = f"{simulation_dir}{yamldata['simulation.params.fname']}"

with open(default_sim_params_file) as stream:
    try:
        dafault_sim_yamldata = yaml.safe_load(stream)
    except yaml.YAMLError as exc:
        print(exc)

new_sim_yamldata = {}
for thiskey, thisvalue in dafault_sim_yamldata.items():
        if thiskey in yamldata['simulation.yaml.override']:
                new_sim_yamldata[thiskey] = yamldata['simulation.yaml.override'][thiskey]
        else:
                new_sim_yamldata[thiskey] = thisvalue

with open(new_sim_params_file, 'w') as outfile:
    yaml.dump(new_sim_yamldata, outfile, default_flow_style=False, sort_keys=False)


# copy the Rscript for the simtest and rename it to match this experiment
# move it to the `ChiSTIG_model/chistig/` subdirectory 
base_sim_file = f"{expiriment_dir}{yamldata['step3a.rscript.fname']}"
testexp_sim_file = f"{simulation_dir}{yamldata['step3a.rscript.fname']}"
shutil.copy(base_sim_file, testexp_sim_file)


