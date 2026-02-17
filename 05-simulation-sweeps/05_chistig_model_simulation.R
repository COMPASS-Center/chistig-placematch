# Libraries  -------------------------------------------------------------------
library("chiSTIGmodules")
library("EpiModelHIV")
library(yaml)
library(stringr)
library(reticulate)
library(argparse)

all_args <- commandArgs(trailingOnly = TRUE)
all_args <- all_args[-1]
param_string <- paste(all_args, collapse = " ")
args_vector <- strsplit(param_string, " ")[[1]]

parser <- ArgumentParser()
parser$add_argument("--replicate", type="integer")
parser$add_argument("--simparamsyamlfname", type="character", help="Path to simulation parameter file")
parser$add_argument("--siminstance", type="integer", help="The instance of the sweep test")
parser$add_argument("--runno", type="integer")

args <- parser$parse_args()


random_seed <- as.integer(args$replicate)
sim_instance <- args$siminstance
yamlfname <- args$simparamsyamlfname
yamldata <- yaml.load_file(yamlfname)

# set random seed
set.seed(random_seed)


# Define which "Treatment" we're running here
treatment <- "venues"


### 0. Set up python and R environments ###
# working directory
project_dir <- yamldata$repo.dir
this_dir <- paste0(project_dir, yamldata$param.sweep.subdir) #TODO

# necessary subdirectories
utils_subdir <- paste0(project_dir, yamldata$utils.subdir)
disease_params_subdir <- paste0(project_dir, yamldata$disease.params.subdir)
abm_params_subdir <- paste0(project_dir, yamldata$abm.params.subdir)
epistats_subdir <- paste0(project_dir, yamldata$epistats.subdir)
network_fit_subdir <- paste0(project_dir, yamldata$netest.subdir)

# output_subdir <- paste0(this_dir, yamldata$model.simulation.interim.subdir)

print(utils_subdir)
print(disease_params_subdir)
print(abm_params_subdir)
print(epistats_subdir)
print(network_fit_subdir)

# # load python instance
# reticulate::use_python("/projects/p32153/condaenvs/conda-chistig/bin/python")
# reticulate::use_python("/home/parallels/.local/python-projects/venv/bin/python")
reticulate::use_python(yamldata$reticulate.python.instance)


#### ChiSTIG model prelim ------------------------------------------------------
chistig_colocation_model <- yamldata$chistig.colocation.model.fname
print(chistig_colocation_model)
chistig_colocation_model <- str_remove(chistig_colocation_model, "\\.py$")
python_chistig <- import(chistig_colocation_model)


# # load the necessary chistig data for the chistig colocation model
chistig_colocation_params_fname <- paste0(abm_params_subdir, yamldata$colocation.params.fname)
print(chistig_colocation_params_fname)
chistig_colocation_params <- python_chistig$create_params(chistig_colocation_params_fname)

print("")
print(chistig_colocation_params$agent.log.file)

# rename the agent_log file with the specific experiment
# chistig_colocation_params$agent.log.file <- paste0(output_subdir, "agent-log_", treatment_run, "_", experiment_name, ".txt") #TODO
chistig_colocation_params$agent.log.file <- "agent_log.txt"

print("")
print(chistig_colocation_params$agent.log.file)

# # set the random seed in the colocation
# python_chistig$set_random_seed(random_seed)

# # set up the model
# python_chistig$run(chistig_colocation_params)

# # have agents attend their first sets of venues
# python_chistig$next_step()


# # Settings ---------------------------------------------------------------------
# source(paste0(utils_subdir, "utils-0_project_settings.R"))
# source(paste0(utils_subdir, "utils-epi_trackers.R"))
# source(paste0(utils_subdir, "utils-targets.R"))
# #
# # Network fit files
# epistats <- readRDS(paste0(epistats_subdir, yamldata$epistats.fname))
# netstats <- readRDS(paste0(network_fit_subdir, yamldata$netstats.fname, "_", sim_instance, ".rds"))
# est <- readRDS(paste0(network_fit_subdir, yamldata$netest.venues.fname, "_", sim_instance, ".rds"))



# epistats$age.breaks <- c(16, 20, 30)
# epistats$age.limits <- c(16, 30)

# netstats$attr$age <- sample(16:29, length(netstats$attr$age), replace = TRUE)
# netstats$attr$age <- netstats$attr$age + sample(1:1000, length(netstats$attr$age), replace = TRUE)/1000


# epimodel_params_df <- readr::read_csv(paste0(disease_params_subdir, yamldata$epimodel.params.fname))
# param <- EpiModel::param.net(
#   data.frame.params = epimodel_params_df,
#   netstats          = netstats,
#   epistats          = epistats,
#   prep.start        = Inf,
#   riskh.start       = Inf
# )


# print(param)


# # Initial conditions
# init <- EpiModelHIV::init_msm()

# # Control settings
# control <- control_msm(
#   nsteps = 52 * 70,
#   nsims  = 1,
#   ncores = 1,
#   raw.output = TRUE,
#   cumulative.edgelist = TRUE,
#   .tracker.list       = calibration_trackers,

#   initialize.FUN =              chiSTIGmodules::initialize_msm_chi,
#   aging.FUN =                   chiSTIGmodules::aging_msm_chi,
#   departure.FUN =               chiSTIGmodules::departure_msm_chi,
#   arrival.FUN =                 chiSTIGmodules::arrival_msm_chi,
#   venues.FUN =                  chiSTIGmodules:::venues_msm_chi,
#   partident.FUN =               chiSTIGmodules::partident_msm_chi,
#   hivtest.FUN =                 chiSTIGmodules::hivtest_msm_chi,
#   hivtx.FUN =                   chiSTIGmodules::hivtx_msm_chi,
#   hivprogress.FUN =             chiSTIGmodules::hivprogress_msm_chi,
#   hivvl.FUN =                   chiSTIGmodules::hivvl_msm_chi,
#   resim_nets.FUN =              chiSTIGmodules::simnet_msm_chi,
#   acts.FUN =                    chiSTIGmodules::acts_msm_chi,
#   condoms.FUN =                 chiSTIGmodules::condoms_msm_chi,
#   position.FUN =                chiSTIGmodules::position_msm_chi,
#   prep.FUN =                    chiSTIGmodules::prep_msm_chi,
#   hivtrans.FUN =                chiSTIGmodules::hivtrans_msm_chi,
#   exotrans.FUN =                chiSTIGmodules:::exotrans_msm_chi,
#   stitrans.FUN =                chiSTIGmodules::stitrans_msm_chi,
#   stirecov.FUN =                chiSTIGmodules::stirecov_msm_chi,
#   stitx.FUN =                   chiSTIGmodules::stitx_msm_chi,
#   prev.FUN =                    chiSTIGmodules::prevalence_msm_chi,
#   cleanup.FUN =                 chiSTIGmodules::cleanup_msm_chi,

#   module.order = c("aging.FUN", "departure.FUN", "arrival.FUN", "venues.FUN",
#                    "partident.FUN", "hivtest.FUN", "hivtx.FUN", "hivprogress.FUN",
#                    "hivvl.FUN", "resim_nets.FUN", "acts.FUN", "condoms.FUN",
#                    "position.FUN", "prep.FUN", "hivtrans.FUN", "exotrans.FUN",
#                    "stitrans.FUN", "stirecov.FUN", "stitx.FUN", "prev.FUN", "cleanup.FUN")
# )


# #
# start_time <- Sys.time()
# sim <- netsim(est, param, init, control)
# end_time <- Sys.time()

# sim$sim_date <- end_time


# saveRDS(sim, "simout.rds")
# # saveRDS(sim, paste0(output_subdir, "simout-", treatment, "_run-no-", treatment_run_number, ".rds")) #TODO 
