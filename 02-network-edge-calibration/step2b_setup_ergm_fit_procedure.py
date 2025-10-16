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

# setup directory names
experiment_dir = f"{yamldata['repo.dir']}{yamldata['calibration.subdir']}"
experiment_interim_dir = f"{experiment_dir}{yamldata['interim.data.subdir']}"
experiment_output_dir =  f"{experiment_dir}{yamldata['output.data.subdir']}"

# make sure that our interim/output directory exists... if not, create one
if not os.path.exists(experiment_interim_dir):
    os.mkdir(experiment_interim_dir)

if not os.path.exists(experiment_output_dir):
    os.mkdir(experiment_output_dir)


# setup args input filename and arguments
output_fname = f"{yamldata['step2b.inputargs.fname']}.txt"
output_file = f"{experiment_dir}{output_fname}"

# obtain the length of the calibration set matrix 
calibration_df_fname = f"{yamldata['calibration.matrix.fname']}"
calibration_df_dir = f"{yamldata['repo.dir']}{yamldata['calibration.subdir']}"
calibration_df = pd.read_csv(calibration_df_fname)
num_calibration_sets = max(calibration_df['fit_no'])


# other arguments from yaml file 
sbatch_bash_commands_outfile = f"{experiment_dir}{yamldata['step2b.sbatch.fname']}.sh"
num_convergence_attempts = yamldata['num.ergm.convergence.attempts']
random_seed_max = yamldata['max.random.seed']

# setup the input params arguments for running the individual simulations for each calibration instance
random_seeds_list = random.sample(range(random_seed_max + 1), yamldata['num.ergm.convergence.attempts'])
random_seeds_string = f"({' '.join(map(str,random_seeds_list))})"

run = 0
with open(output_file, 'w') as file:
	for setno in range(1, num_calibration_sets+1):
		for thistreatment in yamldata['treatment.types']:
			for thispartnership in yamldata['partnership.types']:
				line = f"{run}\t{yamlfname}\t{setno}\t{thistreatment}\t{thispartnership}\n"
				file.write(line)
				run += 1

sbatch = f"""
#SBATCH --account=p32153  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition={yamldata['sbatch.partition']}  ### PARTITION (buyin, short, normal, etc)
#SBATCH --array=0-{run-1} ## number of jobs to run "in parallel"
#SBATCH --nodes=1 ## how many computers do you need
#SBATCH --ntasks-per-node=1 ## how many cpus or processors do you need on each computer
#SBATCH --time={yamldata['sbatch.walltime.hours']}:{yamldata['sbatch.walltime.minutes']}:00 ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem={yamldata['sbatch.memory']}
#SBATCH --job-name="%A" ## When you run squeue -u NETID this is how you can identify the job
#SBATCH --output=%a_{run}.%A.out ## standard out and standard error goes to this file
#SBATCH --mail-type=ALL ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (complet$
#SBATCH --mail-user={yamldata['sbatch.email']} ## your email

module purge all
conda activate /projects/p32153/condaenvs/conda-chistig

R --version

IFS=$'\\n' read -d '' -r -a input_args < {output_fname}
echo ${{input_args[$SLURM_ARRAY_TASK_ID]}}

IFS=$'\\t' read -r runno yamlfname calibrationset treatmenttype partnershiptype  <<< "${{input_args[$SLURM_ARRAY_TASK_ID]}}"
echo "Run number in SLURM array: ${{runno}}." 
echo "YAML file name: ${{yamlfname}}."
echo "Calibration set number for ERGM fit: ${{calibrationset}}." 
echo "Treatment type for ERGM fit: ${{treatmenttype}}."
echo "Partnership type for ERGM fit: ${{partnershiptype}}."

my_random_seed_array={random_seeds_string}
max_attempts=${{#my_random_seed_array[@]}}

echo "Array of random seeds for convergence attempts: ${{my_random_seed_array[@]}}."

timeout_duration={yamldata['ergm.convergence.attempt.time']*60}

for attempt in "${{!my_random_seed_array[@]}}"; do

	random_seed=${{my_random_seed_array[attempt]}}
	echo "Random seed is $random_seed for attempt $((attempt+1)) of $max_attempts..."

	# if timeout "$timeout_duration" Rscript {yamldata['step2b.rscript.fname']} "$yamlfname" "$calibrationset" "$treatmenttype" "$partnershiptype" "${{my_random_seed_array[$attempt]}}"; then
	if timeout "$timeout_duration" Rscript step2b_edge_calibration.R "$yamlfname" "$calibrationset" "$treatmenttype" "$partnershiptype" "${{my_random_seed_array[$attempt]}}"; then
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
"""

outfile_temp = f'{experiment_interim_dir}temp.sh'
# outfile_temp = f'temp.sh'
with open(outfile_temp, 'w') as f:
	f.write(sbatch)
open(f'{sbatch_bash_commands_outfile}', "w").write("#!/bin/bash\n" + open(outfile_temp).read())


