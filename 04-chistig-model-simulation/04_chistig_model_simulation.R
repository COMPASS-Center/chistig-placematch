# Libraries  -------------------------------------------------------------------
library("chiSTIGmodules")
library("EpiModelHIV")
library(yaml)
library(stringr)
library(reticulate)


# Read in the arguments from the commandline
args <- commandArgs(trailingOnly = TRUE)
sbatch_run_num <- args[1]
treatment_run <- args[2]
experiment_name <- args[3]
random_seed <- as.integer(args[4])
yamlfname <- args[5]
yamldata <- yaml.load_file(yamlfname)


# set random seed
set.seed(random_seed)


# Define which "Treatment" we're running here
treatment_run_letter <- str_extract(treatment_run, "[a-zA-Z]+")
treatment_run_number <- as.integer(str_extract(treatment_run, "[0-9]+"))
print(treatment_run_number)
print(treatment_run_letter)

if (treatment_run_letter == "c") { # "Control" Simulation (No apps, no venues)
  treatment <- "control"
} else if (treatment_run_letter == "a") { # "apps" - Apps, no venues
  treatment <- "apps"
} else if (treatment_run_letter == "v") { # "venues" - Venues, no apps
  treatment <- "venues"
} else if (treatment_run_letter == "b") { # "both" - Venues and Apps
  treatment <- "both"
} else {
  print("ERROR: invalid treatment type code provided")
}


### 0. Set up python and R environments ###
# working directory
# project_dir <- "/projects/p32153/chistig-placematch/"
project_dir <- yamldata$repo.dir
# this_dir <- paste0(project_dir, "04-chistig-model-simulation/")
this_dir <- paste0(project_dir, yamldata$model.simulation.subdir)
utils_subdir <- paste0(project_dir, yamldata$utils.subdir)
params_subdir <- paste0(project_dir, yamldata$params.subdir)
epistats_subdir <- paste0(project_dir, yamldata$epistats.subdir)
network_fit_subdir <- paste0(project_dir, yamldata$netest.subdir)

output_subdir <- paste0(this_dir, yamldata$model.simulation.interim.subdir)

print(project_dir)
print(this_dir)

# # load python instance
# reticulate::use_python("/projects/p32153/condaenvs/conda-chistig/bin/python")
reticulate::use_python(yamldata$reticulate.python.instance)
# reticulate::use_python("/home/parallels/.local/python-projects/venv/bin/python")


print("")

#### ChiSTIG model prelim ------------------------------------------------------
# python_chistig <- environment(reticulate::source_python(paste0(this_dir,"chistig/chistig_colocation_model.py")))
# python_chistig <- import("chistig_colocation_model_reticulate")

chistig_colocation_model <- yamldata$chistig.colocation.model.fname
chistig_colocation_model <- str_remove(chistig_colocation_model, "\\.py$")
python_chistig <- import(chistig_colocation_model)


# load the necessary chistig data for the chistig colocation model
# chistig_colocation_params <- python_chistig$create_params(paste0(this_dir, "params/model_params.yaml"))
# chistig_colocation_params <- python_chistig$create_params(paste0(this_dir, "params/model_params.yaml"))
# chistig_colocation_params <- python_chistig$create_params(paste0(project_dir, "params/model_params_step2.yaml"))
chistig_colocation_params_fname <- paste0(params_subdir, yamldata$colocation.params.fname)
chistig_colocation_params <- python_chistig$create_params(chistig_colocation_params_fname)


# rename the agent_log file with the specific experiment
# chistig_colocation_params$agent.log.file <- paste0(this_dir, "output/agent_log_", treatment_run, "_", experiment_name, ".txt")
chistig_colocation_params$agent.log.file <- paste0(output_subdir, treatment_run, "_", experiment_name, ".txt")

# set the random seed in the colocation
python_chistig$set_random_seed(random_seed)

# set up the model
python_chistig$run(chistig_colocation_params)

# have agents attend their first sets of venues
python_chistig$next_step()


# Settings ---------------------------------------------------------------------
source(paste0(utils_subdir, "utils-0_project_settings.R"))
source(paste0(utils_subdir, "utils-epi_trackers.R"))
source(paste0(utils_subdir, "utils-targets.R"))
#
# Network fit files
epistats <- readRDS(paste0(epistats_subdir, yamldata$epistats.fname))
netstats <- readRDS(paste0(network_fit_subdir, yamldata$netstats.fname))

if (treatment == 'venues'){
    # est <- readRDS(paste0(project_dir, "02-network-edge-calibration/output/venue_only_netest-local.rds"))
    est <- readRDS(paste0(network_fit_subdir, yamldata$netest.venues.fname))

} else if (treatment == 'apps'){
    # est <- readRDS(paste0(project_dir, "02-network-edge-calibration/output/apps_only_netest-local.rds"))
    est <- readRDS(paste0(project_dir, network_fit_subdir, yamldata$netest.apps.fname))
} else if (treatment == 'both'){
    # est <- readRDS(paste0(project_dir, "02-network-edge-calibration/output/venues_apps_netest-local.rds"))
    est <- readRDS(paste0(network_fit_subdir, yamldata$netest.appsvenues.fname))
} else if (treatment == 'control') {
    # est <- readRDS(paste0(project_dir, "02-network-edge-calibration/output/basic_netest-local.rds"))
    est <- readRDS(paste0(network_fit_subdir, yamldata$netest.control.fname))
} else {
  print("ERROR: invalid treatment type code provided")
}

epistats$age.breaks <- c(16, 20, 30)
epistats$age.limits <- c(16, 30)

netstats$attr$age <- sample(16:29, length(netstats$attr$age), replace = TRUE)
netstats$attr$age <- netstats$attr$age + sample(1:1000, length(netstats$attr$age), replace = TRUE)/1000


epimodel_params_df <- readr::read_csv(paste0(params_subdir, yamldata$epimodel.params.fname))
param <- EpiModel::param.net(
  data.frame.params = epimodel_params_df,
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = Inf,
  riskh.start       = Inf
)


print(param)


# Initial conditions
init <- EpiModelHIV::init_msm()

# Control settings
control <- control_msm(
  nsteps = 52 * 70,
  nsims  = 1,
  ncores = 1,
  raw.output = TRUE,
  cumulative.edgelist = TRUE,
  .tracker.list       = calibration_trackers,

  initialize.FUN =              chiSTIGmodules::initialize_msm_chi,
  aging.FUN =                   chiSTIGmodules::aging_msm_chi,
  departure.FUN =               chiSTIGmodules::departure_msm_chi,
  arrival.FUN =                 chiSTIGmodules::arrival_msm_chi,
  venues.FUN =                  chiSTIGmodules:::venues_msm_chi,
  partident.FUN =               chiSTIGmodules::partident_msm_chi,
  hivtest.FUN =                 chiSTIGmodules::hivtest_msm_chi,
  hivtx.FUN =                   chiSTIGmodules::hivtx_msm_chi,
  hivprogress.FUN =             chiSTIGmodules::hivprogress_msm_chi,
  hivvl.FUN =                   chiSTIGmodules::hivvl_msm_chi,
  resim_nets.FUN =              chiSTIGmodules::simnet_msm_chi,
  acts.FUN =                    chiSTIGmodules::acts_msm_chi,
  condoms.FUN =                 chiSTIGmodules::condoms_msm_chi,
  position.FUN =                chiSTIGmodules::position_msm_chi,
  prep.FUN =                    chiSTIGmodules::prep_msm_chi,
  hivtrans.FUN =                chiSTIGmodules::hivtrans_msm_chi,
  exotrans.FUN =                chiSTIGmodules:::exotrans_msm_chi,
  stitrans.FUN =                chiSTIGmodules::stitrans_msm_chi,
  stirecov.FUN =                chiSTIGmodules::stirecov_msm_chi,
  stitx.FUN =                   chiSTIGmodules::stitx_msm_chi,
  prev.FUN =                    chiSTIGmodules::prevalence_msm_chi,
  cleanup.FUN =                 chiSTIGmodules::cleanup_msm_chi,

  module.order = c("aging.FUN", "departure.FUN", "arrival.FUN", "venues.FUN",
                   "partident.FUN", "hivtest.FUN", "hivtx.FUN", "hivprogress.FUN",
                   "hivvl.FUN", "resim_nets.FUN", "acts.FUN", "condoms.FUN",
                   "position.FUN", "prep.FUN", "hivtrans.FUN", "exotrans.FUN",
                   "stitrans.FUN", "stirecov.FUN", "stitx.FUN", "prev.FUN", "cleanup.FUN")
)


#
start_time <- Sys.time()
# Epidemic simulation
sim <- netsim(est, param, init, control)
end_time <- Sys.time()

# saveRDS(sim, paste0(this_dir, "output/", treatment, "_", treatment_run_number, "_", experiment_name, ".rds"))
saveRDS(sim, paste0(output_subdir, "simout-", treatment, "_run-no-", treatment_run_number, ".rds"))
