import random 


experiment_name = "nov23"
num_runs_per_treatment = 120

treatments = {'control': 'c', 'venues': 'v', 'apps': 'a', 'both':'b'}
random_seed_max = 800
random_seeds = random.sample(range(random_seed_max + 1), num_runs_per_treatment)
output_file = f'input_args_{experiment_name}.txt'

run = 0
with open(output_file, 'w') as file:
	for thistreatment in treatments:
		for thistreatmentrun, thisrandomseed in enumerate(random_seeds):
			line = f"{run}\t{treatments[thistreatment]}{thistreatmentrun+1}\t{experiment_name}\t{thisrandomseed}\n"
			file.write(line)
			run += 1
