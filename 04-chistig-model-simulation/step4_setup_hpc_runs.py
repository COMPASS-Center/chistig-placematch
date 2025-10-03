import random 
import sys
import yaml 

yamlfname = sys.argv[1]

with open(yamlfname) as stream:
    try:
        yamldata = yaml.safe_load(stream)
    except yaml.YAMLError as exc:
        print(exc)


experiment_name = yamldata['experiment.name']
output_fname = yamldata['batch.runs.args.fname']
print(output_fname)
output_file = output_fname

treatments_dict = {'control': 'c', 'venues': 'v', 'apps': 'a', 'both':'b'}
treatments_list = yamldata['treatment.types']
treatments = {}
for treatment in treatments_list:
      treatments[treatment] = treatments_dict[treatment]
num_runs_per_treatment = yamldata['number.runs.per.treatment']

random_seed_max = int(yamldata['random.seed.max'])
random_seeds = random.sample(range(random_seed_max + 1), num_runs_per_treatment)


run = 0
with open(output_file, 'w') as file:
	for thistreatment in treatments:
		for thistreatmentrun, thisrandomseed in enumerate(random_seeds):
			line = f"{run}\t{treatments[thistreatment]}{thistreatmentrun+1}\t{experiment_name}\t{thisrandomseed}\t{yamlfname}\n"
			file.write(line)
			run += 1
