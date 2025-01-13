
# Libraries  -------------------------------------------------------------------
library(reticulate)


this_dir <- "/projects/p32153/ChiSTIG_model/"
reticulate::use_python("/projects/p32153/condaenvs/conda-chistig/bin/python")
python_chistig <- import("chistig_colocation_model_reticulate")
chistig_colocation_params <- python_chistig$create_params(paste0(this_dir, "params/model_params_unittest.yaml"))

# optional if you want to set a random seed from the params file
#python_chistig$run(chistig_colocation_params$random.seed)


# This initiates the first timestep and attendance 
python_chistig$next_step()


#TODO: define active_egos
#TODO: define newly21_nodes <- this is optional - only if you want to test this function
#TODO: define new_nodes <- again, optional if you only want to test this function 


# this makes sure the egos in the colocation model match the egos in the Epimodel 
python_chistig$update_egos(active_egos)

# this takes the newly 21 year olds and puts them in new demographic groups
python_chistig$update_age_groups(newly21_nodes)

# this creates a new set of egos to add to the simulation
# NOTE: this assumes they are entering 16 year olds
python_chistig$add_agents_to_simulation(new_nodes)

# This moves the simulation forward one timestep 
python_chistig$next_step()

# these provide the venue attendance and appuse of the active egos
egos2venues <- python_chistig$obtain_venue_attendance(active_egos)
egos2apps <- python_chistig$obtain_app_use(active_egos)
