# chistig-placematch
Analysis of venue attendance on HIV incidence over time


# Preliminaries

## Terms

- Treatment type
  - Control
  - Appuse only
  - Venue attendance only
  - Appuse + venue attendance
 
- Partnership type
  - Main
  - Casual
  - One-time 

# Structure of repo

## List of required files for our repository
- A `chistig_colocation.py` module written in Python using Repast4py for agent-based colocation of synthetic population and implemented via the reticulate package
- A `params.yaml` file that contains the following:
  -  the empirical population details for when new synthetic egos enter the simulation and need to be assigned behavior for their corresponding demographic (e.g. venue attendance behavior)
  -  simulation details, such as length of simulation
  -  directory details for where to read in files from and where to write files out to
- An `initial_synthpop.csv` initial synthetic population in a .csv file that is with a uniform age (?) 
- A `utils.R` file that contains functions useful for keeping track of epimodel specifics taken from 
- An `epistats.rds` R-object file that will come from the edge calibration procedure
- A `netstats.rds` R-object file that will come from the edge calibration procedure
- A set of four `netest_<treatment type>.rds` R-object files that will come from the edge calibration procedure for each of our "treatment types" (i.e. control, apps-only, venues-only, venues+apps)
- A `params.csv` file that contains the epimodel calibrated parameters from the epimodelhiv parameter calibration procedure
- A `target_values.csv` that contains the target edge values for the formation components of our network ERGMs for each partnership type and treatment type
- A 


TODO:
- put `R/utils-0_project_settings.R` file into a broader `utils.R` file
- put `R/utils-epi_trackers.R` file into a broader `utils.R` file
- put `R/utils-targets.R` file into a broader `utils.R` file
 

python/
input/
output/
R/
package_dependency_archives/
params/
 yaml file 

## Other requirements
External packages that are needed:
- `repast4py`
- `slurmworkflow` - Workflow from EpimodelHIV to use with their template for calibration
- `ARTnet` - set of initial 

# Steps of what we do with this repository for the paper/simulation results

## 1. initial ergm fits
The first step of our work are initial ERGM fits of our network. The 
  - empimodelhiv-p
  - output:
    - netest
    - epistats
    - netstats
    - these are used for the edge calibration
  - NOTE:
    - originally, used chiSTIG_HPC repo
    - We only need the source called files of:
      - e.g. R/utils-0_project_settings.R
      - TODO: look for other source called files
    - Uses the 01-networks_estimation.R script from the chiSTIG_HPC repository 

2. edge calibration (fits for the target values of interest)
 - components needed
  - repast4py
  - epimodelhiv-p
  - chistigmodules 
  - explicit quest setup
- input files needed:
  - dur_coeffs.R
  - target values
- output created
  - netest objects for each of the treatment scenarios
  - epistats for the updated target value fits
  - netstats for the updated target value fits 
- TODO:
  - check on if we need params file for this


3. epimodelhiv parameter calibration
  - epimodelhiv-p
  - slurmworkflow 
  - chistigHPC (quest setup is implicit via slurmworkflow, copy of the epimodel template)
    - uses 
    - workflow-06_XX .R
      - https://github.com/Tom-Wolff/chiSTIG_HPC/blob/main/R/workflow_06-automated-calibration.R
 NOTE:
 - automated calibration doesn't actually converge to the final parameter values because of population size
   - namely, the transscale parameters is where it gets stuck
   - the epimodel team usually calibrates on a larger population 
 - automated calibration gets us to a narrow range
   - where narrow range is "as close to convergence as the automated calibration gets"
 - we use manual calibration to finalize it
   - i.e. tom running it on his personal machine
- the main issue here is our package dependencies in R and how they are installed
  - for automated calibration, uses .renv lock file from chiSTIG_HPC
  - for manual calibration, also uses .renv lock file from chiSTIG_HPC
  - We did two sets of parameter calibration
  - first set was ran via Quest using .renv lock file installed via R
    - instructions for how to do this are in the readme file of chiSTIG_HPC
    - https://github.com/Tom-Wolff/chiSTIG_HPC/tree/main
- output
  - updated params.csv file
- TODO:
  - Sara runs this herself and tries out these steps 

4 simulations (simulate hiv incidence over time with venue attendance)
  - repast4py
  - epimodelhiv-p
  - chistigmodules
  - explicit quest setup



How to handle chistigmodules:
- can we just have a directory of ... where we source the scripts and use them as functions in our actual simulations
- we use these scripts as writeovers for the default control_msm defined with epimodelhiv-p
  - these functions overwrite the default functiosn that are the modules
- OR do we just use the epimodelhiv-p that is our branch of epimodelhiv-p with our version of modules
- TODO:
  - ensure our epimodelhiv-p branch is up-to-date
  - we will want to run it and make sure it works
  - Basically, we want to test running this: https://github.com/Tom-Wolff/chiSTIG_HPC/blob/main/R/04-test_netsim.R#L122
    - where we don't need chistigmodules package... instead we just need our epimodelhiv-p package
    

Rscripts:
- network_estimation.R
- edge_calibration.R
- parameter_calibration.R
- chistig_simulation.R
Other:
- chistig_colocation.py
- quest explicit 

