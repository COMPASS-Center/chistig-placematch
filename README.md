# chistig-placematch
Analysis of venue attendance on HIV incidence over time. To carry out this anaylsis, we have four major steps, described as the following:

0. Prior to anything from this repository, we use the output from the [#chistig-place-and-pop](https://github.com/COMPASS-Center/chistig-place-and-pop) repository, which creates a synthetic population of agents between the ages of 16-29, who are assigned a race/ethcnicity, age, and corresponding set of venues and venue attendance behavior. Additionally, a set of target edges based on this synthetic population is delineated.
1. Our first step is creating an estimated network estimation objects for our synthetic population based on everything _except_ venue colocation.
2. Next, we refine our network estimation objects to fit our set of target edges using our agents' venues.
3. Third, we calibrate the parameters for our disease transmission portion of the simulation using these network objects.
4. Finally, we run a full simulation that models disease transmission of our synthetic population over time as they colocate at venues.

# Preliminaries

This repository is a second iteration of our chiSTIG project that is an effort to combine all of the disparate procedures, scripts, and repositories that were developed/used for the four steps above. A few notes on the disparate procedures/scripts/repositories we are building from are described here.

## Old repositories used

The repositories that were developed/used previously and are relevent here are the following:

- `ChiSTIG_model` - repository developed by Sara and implements the colocation module that uses repast4py, and is where the simulations + edge calibration steps were carried out ([link to ChiSTIG_model](https://github.com/jozik/ChiSTIG_model))
- `chistigmodules` - repository developed by Tom that implement the `control_msm` module overrides and allow us to have a module for `fuzzynodematch` for our venue and appuse colocation. This module was previously compiled and called as an R package for our procedures. Instead, we plan to implement the `control_msm` override via the EpimodelHIV-p branch we will create. Thus, we will only need to install our version of the `EpimodelHIV-p` package to utilize this.
- `chiSTIG_HPC` - repository developed by Tom that was a copy of the epimodel template for a standard epimodel model development/implementation. The main component of this repository that is useful is the automated workflow for calibration. In this repository, we will instead just copy over the relevent individual `.R` files for the calibration.   

## Terms

### Partnership types
We have three types of sexual networks that we are simulating based on partnership types. Our three partnership types are:

  - Main
  - Casual
  - One-time 

### Treatment types
We then run our chiSTIG simulations to test how disease transmission differs based on behavioral dynamics of our synthetic population. The four sets of experiments we define as _treatment types_ and are as follows:

  - Control - does not take into consideration of agents attending and colocating at venues, or using apps 
  - Appuse only -  *does not* take into consideration of agents attending and colocating at venues; *does* consider colocating virtually based on app use
  - Venue attendance only - takes into consideration of agents attending and colocating at venues; *does not* consider colocating virtually based on app use
  - Appuse + venue attendance - takes into consideration of agents attending and colocating at venues *and* colocating virtually based on app use

 
# Structure of this repository

## List of required files for our repository

### Pre-generated/written

- A `chistig_colocation.py` module written in Python using Repast4py for agent-based colocation of synthetic population and implemented via the reticulate package
- A `params.yaml` file that contains the following:
  -  the empirical population details for when new synthetic egos enter the simulation and need to be assigned behavior for their corresponding demographic (e.g. venue attendance behavior)
  -  simulation details, such as length of simulation
  -  directory details for where to read in files from and where to write files out to
- An `initial_synthpop.csv` initial synthetic population in a .csv file that is with a uniform age (?) 
- A `utils.R` file that contains functions useful for keeping track of epimodel specifics taken from
- A `target_values.csv` that contains the target edge values for the formation components of our network ERGMs for each partnership type and treatment type
- An `automated_calibration_workflow.R` file that carries out the parameter calibration procedure described below and derived from: https://github.com/Tom-Wolff/chiSTIG_HPC/blob/main/R/workflow_06b-test-automated-calibration.R
- A `network_estimation.R` file that carries out the initial network ERGM fits described in the initial ERGM fit procedure below and derived from: https://github.com/Tom-Wolff/chiSTIG_HPC/blob/main/R/01-networks_estimation.R

### Generated/created through procedures documented below

- An `epistats.rds` R-object file that will come from the edge calibration procedure
- A `netstats.rds` R-object file that will come from the edge calibration procedure
- A set of four `netest_<treatment type>.rds` R-object files that will come from the edge calibration procedure for each of our "treatment types" (i.e. control, apps-only, venues-only, venues+apps)
- A `params.csv` file that contains the epimodel calibrated parameters from the epimodelhiv parameter calibration procedure
- `.sh` files used for running sets of simulations/procedures in Quest 

TODO:

- put `R/utils-0_project_settings.R` file into a broader `utils.R` file
- put `R/utils-epi_trackers.R` file into a broader `utils.R` file
- put `R/utils-targets.R` file into a broader `utils.R` file
- implement the following file into our branch of the epimodelHIV-p repository: https://github.com/Tom-Wolff/chiSTIG_HPC/blob/main/R/04-test_netsim.R#L122
- write an `.R` script that explicitly calls on the `ARTnet` and `ARTnetData` packages and extracts explicitly what we need from those two packages so we only need to call upon them once for all of our procedures.
  - This includes the `acts_setup.R` script

## Overview of our directory 

- python/
- input/
- output/
- R/
- package_dependency_archives/
- params/
   - yaml file 

## Other requirements

External packages that are needed:

- `repast4py`
- `slurmworkflow` - Workflow from EpimodelHIV to use with their template for calibration
- `ARTnet` - set of initial datapoints and estimations used for our epimodel simulation
- `reticulate` - used to communicate back and forth between epimodel in R and chistig colocation in python

# Procedures for the paper/simulation results

## 1. Initial ERGM fits
The first step of our work are initial ERGM fits of our network.

### Main files used
- `01-networks_estimation.R`

### Packages/components needed
- `EpiModelHIV-p`
- `ARTnet`

### Input files/data required
- From [#chistig-place-and-pop](https://github.com/COMPASS-Center/chistig-place-and-pop):
  - `egos_v4_1_uniform_age_dist.csv`
  - `target_values_v4_1_uniform_age_dist.csv`
- Other:
 - `utils-0_project_settings.R`
 - `dur_coefs.R`
 - `acts_setup.R`

### Output created:
The following are created by this and then used in the edge calibration procedure
- An initial `netest` RDS object
- An initial `epistats` RDS object
- An initial `netstats` RDS object

### NOTES
- Originally, used the `chiSTIG_HPC` repo to carry out this, but it is not necessary as there is only one script from that repository that is used and run once
- Instead, we only need the source called files of the following from from the chiSTIG_HPC repository:
  - `R/utils-0_project_settings.R`
  - `01-networks_estimation.R`  

### TODO 
- [X] look for other source called files from `chiSTIG_HPC` that are used to build this
- [ ] streamline the writing of the `01-networks_estimation.R` network estimation file into a `network_estimation.R` script for this repository
- [ ] write a comprehensive `utils.R` file that combines all of the utility functions previously created across multiple files (e.g. `R/utils-targets.R`)
- [ ] consider how to run this without needing the ArtNET package

## 2. Edge calibration 
After creating our initial network fits, our edge calibration allows us to calibrate our `netest`, `epistats`, and `netstats` objects for our target edge counts. The procedure for running this is laid out in the `./02-network-edge-calibration/README.md`. 

### Main files used
- `./02-network-edge-calibration/edge_calibration_procedure_ONE.sh`
- `./02-network-edge-calibration/edge_calibration_procedure_TWO.sh`
- `testXX.yaml`

### Packages/components needed
- `repast4py`
- `epimodelhiv-p` that implements our `chistigmodules` functions 

### Input files/data required
- From step #1
  - Initial `netest` RDS object
  - Initial `epistats` RDS object
  - Initial `netstats` RDS object
- Predifined scripts in `./02-network-edge-calibration/`
  - `step1_edge_calibration.R` 
  - `step2a_edge_calibration.R` 
  - `step2b_edge_calibration.R`
  - `step2b_sbatch_ergm_fit_procedure.sh`
  - `step2b_sbatch_model_convergence.sh`
  - `step2b_setup_ergm_fit_procedure`
  - `step2c_edge_calibration.R`
  - `step3a_edge_calibration.py`
  - `simtestXX.R`
- Other files
  - `chistig_params.yaml`
  - `chistig_colocation_model_reticulate.py`
  - `dur_coeffs.R`
  - target values of our edges

### Interim files created
- `.rds` fit objects for each of the four treatment types
- `.csv` files for coefficients for each of the four treatment types
- `.out` files for the output from the simulations
- `calibration_sets_that_did_not_converge.txt`
- `edge_target_calibration_vals.csv`
-  `step2_ergm_fit_procedure_input_args.txt`

### Output created
- `netest` objects for each of the treatment scenarios
  - `netest_control.rds`
  - `netest_venues.rds`
  - `netest_apps.rds`
  - `netest_both.rds`
- updated `epistats` 
- updated `netstats` 



## 3. Epimodelhiv parameter calibration
Now we run the epimodel parameter calibration. We use a calibration method that is developed by the EpimodelHIV team and implemented via the Epimodel template repository. It implicitly creates and runs the necessary SLURM files to carry out the calibration on the Quest cluster. The package dependencies are organized/installed via the `.renv` lock file.  

### Main files used
### Packages/components needed
### Input files/data required
### Output created:
### NOTES
### TODO 



Packages/components needed:
- `epimodelhiv-p`
- `slurmworkflow` - the package used to carry out the implicit automated workflow via the epimodel template method
- chistigHPC (quest setup is implicit via slurmworkflow, copy of the epimodel template)
  - uses workflow-06_XX .R from https://github.com/Tom-Wolff/chiSTIG_HPC/blob/main/R/workflow_06-automated-calibration.R
 
 NOTEs:
 - Automated calibration doesn't actually converge to the final parameter values because of population size
   - Namely, the transscale parameters is where it gets stuck
   - This is because the epimodel team usually calibrates on a larger population, and ours is much smaller causing the halt in the calibration
 - Automated calibration gets us to a narrow range
   - where narrow range is "as close to convergence as the automated calibration gets"
 - We use manual calibration to finalize it
   - i.e. tom running it on his personal machine
- The main issue here is our package dependencies in R and how they are installed
  - for automated calibration, uses .renv lock file from chiSTIG_HPC
  - for manual calibration, also uses .renv lock file from chiSTIG_HPC
  - We did two sets of parameter calibration
  - first set was ran via Quest using .renv lock file installed via R
    - instructions for how to do this are in the readme file of chiSTIG_HPC
    - https://github.com/Tom-Wolff/chiSTIG_HPC/tree/main

Output:
- updated `params.csv` file for epimodel that also includes the transcale parameters
    
TODO:
- Sara runs this herself and tries out these steps
- Sara sets up procedure to use the `.renv` lock file for running this on Quest
- Move/rewrite the `workflow-06_XX .R` script from the epimodel template (and chistigHPC repository) here to have a clean method for how to run this

## 4. Simulations 
Once we have the calibrations carried out, we can actually carry out the epimodel simulations. That is, we will simulate hiv incidence over time with venue attendance.

Packages/components needed:
- `repast4py`
- `epimodelhiv-p` that implements the overwrite functions of the `chistigmodules` repository
- explicit quest setup


### Main files used
### Packages/components needed
### Input files/data required
### Output created:
### NOTES
### TODO 




Scratch notes: 

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
    

Rscripts to move from ChiSTIG_model to this repository:
- network_estimation.R
- edge_calibration.R
- parameter_calibration.R
- chistig_simulation.R
Other:
- chistig_colocation.py
- quest explicit 

