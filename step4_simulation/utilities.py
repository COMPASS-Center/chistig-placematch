import pandas as pd
import numpy as np
from collections import defaultdict
from scipy.special import comb
import time
import json
import yaml
from typing import Dict
import random

# from repast4py import random


# demographic recoding functions
def recode_age(agerange):
	if agerange == 'under20' or agerange == '16to20':
		new_agerange = '<20'
	else:
		# assert (agerange == '20to29')
		new_agerange = '21+'
	return new_agerange


def recode_raceeth(raceeth):
	if raceeth == 'whiteNH':
		new_raceeth = 'W'
	elif raceeth == 'blackNH':
		new_raceeth = 'B'
	elif raceeth == 'otherNH':
		new_raceeth = 'O'					
	else:
		assert (raceeth == 'hispanic')
		new_raceeth = 'H'
	return new_raceeth

def recode_hiv(hivstatus):
	if hivstatus == 'neg':
		new_status = 'hiv-'
	else:
		assert (hivstatus == 'pos')
		new_status = 'hiv+'
	return new_status

def demo_description(race, age, hiv):
	description = str(race) + '/' + str(age) + '/' + str(hiv)
	return description


def parse_params(parameters_file: str, parameters: str) -> Dict:
    """Performs model property / parameter parsing.

    Parameter parsing reads the parameters file, overrides
    any of those properties with those in the parameters string,
    and then executes the code that creates the derived parameters.

    Args:
        parameters_file: yaml format file containing model parameters
        parameters: json format string that overrides those in the file

    Returns:
        A dictionary containing the final model parameters.
    """
    params = {}
    with open(parameters_file) as f_in:
        params = yaml.load(f_in, Loader=yaml.SafeLoader)
    if parameters != '':
        params.update(json.loads(parameters))

    # # Set seed from params, but before derived params are evaluated.
    # if 'random.seed' in params:
    #     random.init(int(params['random.seed']))
    # else:
    #     # repast4py should do this when random is imported
    #     # but for now do it explicitly here
    #     random.init(int(time.time()))

    return params