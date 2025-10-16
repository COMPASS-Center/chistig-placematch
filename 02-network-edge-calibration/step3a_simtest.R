# Libraries  -------------------------------------------------------------------
library("chiSTIGmodules")
library("EpiModelHIV")
library(yaml)
library(stringr)
library(reticulate)


# Read in the arguments from the commandline
args <- commandArgs(trailingOnly = TRUE)
sbatch_run_num <- args[1]
calibration_set_num <- args[2]
treatment_type <- args[3]
treatment_run_num <- as.integer(args[4])
experiment_name <- args[5]
random_seed <- as.integer(args[6])
yamlfname <- args[7]
yamldata <- yaml.load_file(yamlfname)


# set random seed
set.seed(random_seed)


# # Define which "Treatment" we're running here
# treatment_run_letter <- str_extract(treatment_run, "[a-zA-Z]+")
# treatment_run_number <- as.integer(str_extract(treatment_run, "[0-9]+"))



# if (treatment_run_letter == "c") { # "Control" Simulation (No apps, no venues)
#   treatment <- "control"
# } else if (treatment_run_letter == "a") { # "apps" - Apps, no venues
#   treatment <- "apps"
# } else if (treatment_run_letter == "v") { # "venues" - Venues, no apps
#   treatment <- "venues"
# } else if (treatment_run_letter == "b") { # "both" - Venues and Apps
#   treatment <- "both"
# } else {
#   print("ERROR: invalid treatment type code provided")
# }


### 0. Set up python and R environments ###
# working directory
# this_dir <- "/media/psf/dev/repos/ChiSTIG/ChiSTIG_model/"
# repo_dir <- "/projects/p32153/chistig-placematch/"
repo_dir <- yamldata$repo.dir
calibration_subdir <- paste0(repo_dir, yamldata$calibration.subdir)
calibration_interim_subdir <- paste0(calibration_subdir, yamldata$interim.data.subdir)

utils_subdir <- paste0(repo_dir, yamldata$utils.subdir)
epistats_subdir <- paste0(repo_dir, yamldata$epistats.subdir)
params_subdir <- paste0(repo_dir, yamldata$params.subdir)

# params_subdir <- paste0(project_dir, yamldata$params.subdir)
# output_subdir <- paste0(this_dir, yamldata$model.simulation.interim.subdir)


# load python instance
# reticulate::use_python("/projects/p32153/condaenvs/conda-chistig/bin/python")
reticulate::use_python(yamldata$reticulate.python.instance)


print("")

#### ChiSTIG model prelim ------------------------------------------------------
# python_chistig <- environment(reticulate::source_python(paste0(this_dir,"chistig/chistig_colocation_model.py")))
# python_chistig <- import("chistig_colocation_model_reticulate")
chistig_colocation_model <- yamldata$chistig.colocation.model.fname
chistig_colocation_model <- str_remove(chistig_colocation_model, "\\.py$")
python_chistig <- import(chistig_colocation_model)

# load the necessary chistig data for the chistig colocation model
# chistig_colocation_params <- python_chistig$create_params(paste0(this_dir, "params/model_params.yaml"))
chistig_colocation_params <- python_chistig$create_params(paste0(calibration_interim_subdir, yamldata$simulation.params.fname))

# rename the agent_log file with the specific experiment
# chistig_colocation_params$agent.log.file <- paste0(this_dir, "output/agent_log_", treatment_type, "_", experiment_name, "_", calibration_set_num, ".txt")
chistig_colocation_params$agent.log.file <- paste0(calibration_interim_subdir, "agent-log-", treatment_type, "_run-no-", treatment_run_num, "_calibration-set-", calibration_set_num, ".txt")

# set the random seed in the colocation
python_chistig$set_random_seed(random_seed)

# set up the model
python_chistig$run(chistig_colocation_params)

# have agents attend their first sets of venues
python_chistig$next_step()


# Settings ---------------------------------------------------------------------
source(paste0(utils_subdir, "utils-epi_trackers.R"))
source(paste0(utils_subdir, "utils-targets.R"))

# Necessary files
epistats <- readRDS(paste0(epistats_subdir, yamldata$epistats.fname))
netstats <- readRDS(paste0(calibration_interim_subdir, "netstats_", calibration_set_num, ".rds"))

if (treatment_type == 'venues'){
  est <- readRDS(paste0(calibration_interim_subdir, "netest-venues_", calibration_set_num, ".rds"))
} else if (treatment_type == 'apps'){
  est <- readRDS(paste0(calibration_interim_subdir, "netest-apps_", calibration_set_num, ".rds"))
} else if (treatment_type == 'venuesapps'){
  est <- readRDS(paste0(calibration_interim_subdir, "netest-venuesapps_", calibration_set_num, ".rds"))
} else if (treatment_type == 'control') {
  est <- readRDS(paste0(calibration_interim_subdir, "netest-control_", calibration_set_num, ".rds"))
} else {
  print("ERROR: invalid treatment type code provided")
}

epistats$age.breaks <- c(16, 20, 30)
epistats$age.limits <- c(16, 30)

netstats$attr$age <- sample(16:29, length(netstats$attr$age), replace = TRUE)
netstats$attr$age <- netstats$attr$age + sample(1:1000, length(netstats$attr$age), replace = TRUE)/1000


epimodel_params_df <- readr::read_csv(paste0(params_subdir, yamldata$epimodel.calibration.params.fname))
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
# start_time <- Sys.time()
# # Epidemic simulation
# sim <- netsim(est, param, init, control)
# end_time <- Sys.time()


simout_fname <- paste0(calibration_interim_subdir, "simout-", treatment_type, "_run-no-", treatment_run_num, "_calibration-set-", calibration_set_num, ".rds")
print(simout_fname)
# saveRDS(sim, paste0(this_dir, "output/", treatment, "_", treatment_run_number, "_", experiment_name, "_", calibration_set_num,".rds"))
# saveRDS(sim, paste0(this_dir, "output/", experiment_name, "_calset", calibration_set_num, "_", treatment, "_sim", treatment_run_number, ".rds")) 
# saveRDS(sim, paste0(calibration_interim_dir, "calset_", calibration_set_num, "_", treatment, "_sim", treatment_run_number, ".rds")) 
# saveRDS(sim, paste0(calibration_interim_subdir, "simout-", treatment_type, "_run-no-", treatment_run_num, "_calibration-set-", calibration_set_num, ".rds"))
