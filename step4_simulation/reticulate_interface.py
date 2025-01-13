import sys
import math
import pandas as pd
import numpy as np
from typing import Dict, Tuple
from mpi4py import MPI
from dataclasses import dataclass
import random 

from repast4py import core, schedule, logging, parameters
from repast4py import context as ctx






# TODOs for the reticulate interface
# - have an agent attend venues
# - create module for mainting constant population spread as agents age
# - update agent relationship status
# - update agent age
# - have agent use apps based on relationship status
# - create a new agent (two types: (1) born into model (2) move into the Chicago area)
#   - assign empirical ego
#   - assign agent age
#   - assign agent race/ethnicity
#   - assign venue attendance behavior
#   - assign relationship status
#   - assign appuse behavior


# Other
# - convert the empirical data into an object so that I can assign what is necessary when I initialize the model (so no longer build the Synthpop first, can do it from the model package)
# - update agent connections between each other?
# - update agent HIV status? (this might be only necessary for )
# - Repast4py/reticulate stuff
#   - maybe I want to create an environmental space of venues and apps just so we can use it as an example for future Repast4py