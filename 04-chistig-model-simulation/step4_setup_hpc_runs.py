import random 


experiment_name = "step4"
num_runs_per_treatment = 120

# treatments = {'control': 'c', 'venues': 'v', 'apps': 'a', 'both':'b'}
treatments = {'control': 'c', 'venues': 'v'}
random_seed_max = 800
random_seeds = random.sample(range(random_seed_max + 1), num_runs_per_treatment)
output_file = f'{experiment_name}_input_args.txt'

run = 0
with open(output_file, 'w') as file:
	for thistreatment in treatments:
		for thistreatmentrun, thisrandomseed in enumerate(random_seeds):
			line = f"{run}\t{treatments[thistreatment]}{thistreatmentrun+1}\t{experiment_name}\t{thisrandomseed}\n"
			file.write(line)
			run += 1
