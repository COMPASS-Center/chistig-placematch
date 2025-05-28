This step runs the initial ERGM fits for the four "treatments" (i.e. counterfactual scenarios) for each experiment. The four treatments include the following:
1. Control - ERGM fits do not take into account apps or venue colocation
2. Venues - ERGM fits only on venue colocation only
3. Apps - ERGM fits only on app colocation only
3. Venues + Apps - ERGM fits only on both venue and app colocation 

To run this step, first sign in to Quest.

Next, mke sure the full `00_preliminary_setup` is carried out. If so, there should be a `netsats.rds` object now in the `chistig-placematch/01-network-estimation/` subdirectory.

In the terminal, ensure you are in the `chistig-placematch/01-network-estimation/` subdirectory (check this by using the command `pwd`). 

Then setup the Quest Python/R computational environment with the following:
```sh
module purge all 
conda activate /projects/p32153/condaenvs/conda-chistig
```

Finally, run the script with the following:
```sh
Rscript 01_networks_estimation.R
```

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
