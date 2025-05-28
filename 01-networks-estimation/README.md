This step runs the initial ERGM fits for the four "treatments" (i.e. counterfactual scenarios) for each experiment. The four treatments include the following:
1. Control - ERGM fits do not take into account apps or venue colocation
2. Venues - ERGM fits only on venue colocation only
3. Apps - ERGM fits only on app colocation only
3. Venues + Apps - ERGM fits only on both venue and app colocation 

To run this step, first sign in to your HPC environment (e.g., Quest).

Next, ensure the full `00_preliminary_setup` is carried out. If so, there should be a `netsats.rds` object now in the `chistig-placematch/01-network-estimation/` subdirectory.

In the terminal, ensure you are in the `chistig-placematch/01-network-estimation/` subdirectory (check this by using the command `pwd`). 

Then setup the Quest Python/R computing environment with the following:
```sh
module purge all 
conda activate /projects/p32153/condaenvs/conda-chistig
```
For those using a different computing setup, please replicate our conda environment by installing the packages listed in `conda_environment_packages.txt` in the main directory.  

Next, run the script 
```
Rscript 01a_networks_estimation.R
```
This script creates the initial ergm fits for each combination of relationship type (main, casual, one-time) and treatment (control, venues, apps, venues + apps), resulting in 12 fitted rds files in the `interim` folder.

Once all the fits are created, run the next script to consolidate the networks across the relationship types:
```
Rscript 01b_networks_estimation.R
```
This should result in two rds files (coefficients and network estimates) per treatment, in the `01-networks-estimation` folder.

Note that, due to the stochastic fitting procedure, some estimates in `01a_networks_estimation.R1` may not converge the first time they run, and so the fitting procedure may have to run more than once to yield all 12 rds files. Please inspect the output in the `interim` folder and ensure all 12 rds files are present before calling `01b_networks_estimation.R`.  

> **NOTE:** We do not have YAML arguments yet for this Rscript. That will change in the future.


Future TODOs:
- When future YAML is updated, ensure the yaml arguments is completed in the beginning of the script
- Create a setup for an "experiment directory" which is where we can access the netstats file and where we save the network estimation files
- Add the experiment directory to the broader .yaml file 
- create .yaml file that can be used for the full set of runs for an experiment 
- Add in the following HPC settings forStep 3 (these details were in an earlier consolidated settings.R )

<!--
# =======================
# TODO: add in the settings details for if this is run via HPC
# =======================
# When run locally `context == "local"` it fits
# ## 5k nodes networks. They can be used for local testing of the project.
# ## When run on the HPC (`context` is set in the workflow definition to "hpc"),
# ## 100k nodes networks are used.        

# context <- if (!exists("context")) "local" else context
# source("R/utils-0_project_settings.R") # TODO change this

# if (context == "local") {
#   networks_size   <- 5 * 1e3
#   estimation_method <- "Stochastic-Approximation"
#   estimation_ncores <- 1
# } else if (context == "hpc") {
#   networks_size   <- 100 * 1e3
# } else  {
#   stop("The `context` variable must be set to either 'local' or 'hpc'")
# }
--> 
