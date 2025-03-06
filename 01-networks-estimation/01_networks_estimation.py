import random
import yaml 
import sys
import pandas as pd


yamlfname = sys.argv[1]

with open(yamlfname) as stream:
    try:
        yamldata = yaml.safe_load(stream)
    except yaml.YAMLError as exc:
        print(exc)

num_convergence_attempts = yamldata['num.ergm.convergence.attempts']
random_seed_max = yamldata['max.random.seed']


# setup args input filename 
expiriment_dir = f"{yamldata['repo.dir']}{yamldata['calibration.subdir']}{yamldata['expname']}/"
output_fname = f"{yamldata['step2b.inputargs.fname']}_{yamldata['expname']}.txt"
output_file = f"{expiriment_dir}{output_fname}"
# output_file = "test_output_step2.txt"

# obtain the length of the calibration set matrix 
calibration_df_fname = f"{yamldata['calibration.matrix.fname']}_{yamldata['expname']}.csv"
calibration_df_dir = f"{yamldata['repo.dir']}{yamldata['calibration.subdir']}{yamldata['expname']}/"
calibration_df = pd.read_csv(calibration_df_fname)
num_calibration_sets = max(calibration_df['fit_no'])

sbatch_bash_commands_outfile = f"{expiriment_dir}{yamldata['step2b.sbatch.fname']}.sh"
#sbatch_bash_commands_outfile = f"{yamldata['step2b.sbatch.fname']}_{yamldata['expname']}.sh"

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
#SBATCH --job-name="{yamldata['expname']}_%A" ## When you run squeue -u NETID this is how you can identify the job
#SBATCH --output=%a_{run}.%A.{yamldata['expname']}.out ## standard out and standard error goes to this file
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

outfile_temp = f'{expiriment_dir}temp.sh'
# outfile_temp = f'temp.sh'
with open(outfile_temp, 'w') as f:
	f.write(sbatch)
open(f'{sbatch_bash_commands_outfile}', "w").write("#!/bin/bash\n" + open(outfile_temp).read())

