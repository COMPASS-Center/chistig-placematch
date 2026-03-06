# Libraries  -------------------------------------------------------------------
library("chiSTIGmodules")
library("EpiModelHIV")
library(yaml)
library(stringr)

Sys.setenv(RETICULATE_PYTHON = "/projects/p32153/condaenvs/conda-swift/bin/python")
library(reticulate)

options(flush.console = TRUE)

args_vector_raw <- commandArgs(trailingOnly = TRUE)
args_vector <- unlist(strsplit(args_vector_raw, "\\s+"))

parse_args <- function(args) {
  result <- list()
  i <- 1
  while (i <= length(args)) {
    if (grepl("^--", args[i])) {
      key <- sub("^--", "", args[i])
      result[[key]] <- args[i + 1]
      i <- i + 2
    } else {
      i <- i + 1
    }
  }
  return(result)
}

args <- parse_args(args_vector)

run_no <- as.integer(args$runno)
random_seed <- as.integer(args$replicate)
sim_instance <- as.integer(args$siminstance)
yamlfname <- args$simparamsyamlfname
yamldata <- yaml.load_file(yamlfname)

# set random seed
set.seed(random_seed)

# Define which "Treatment" we're running here
treatment <- "venues"

writeLines("script output location is here", paste0("dummy_file_", run_no, ".txt"))

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

# print(utils_subdir)
# print(disease_params_subdir)
# print(abm_params_subdir)
# print(epistats_subdir)
# print(network_fit_subdir)

# Show which python reticulate is using

chistig_colocation_model <- yamldata$chistig.colocation.model.fname

print(paste("this_dir:", this_dir))
print(paste("chistig_colocation_model:", chistig_colocation_model))
chistig_colocation_model <- str_remove(chistig_colocation_model, "\\.py$")
print(chistig_colocation_model)
print("")

# Print the full sys.path Python is searching
reticulate::py_run_string("import sys; print('sys.path:', sys.path)")
print("")

# Print PYTHONPATH environment variable
reticulate::py_run_string("import os; print('PYTHONPATH:', os.environ.get('PYTHONPATH', 'NOT SET'))")
print("")

reticulate::py_run_string(paste0("
import sys, os
results = [(p, os.path.exists(os.path.join(p, '", chistig_colocation_model, ".py'))) for p in sys.path]
for path, found in results:
    print(f'  {path}: {found}')
"))


print("testing mpi initialization before importing module...")
reticulate::py_run_string("
from mpi4py import MPI
if not MPI.Is_initialized():
    MPI.Init()
print('MPI initialized:', MPI.Is_initialized(), flush=True)
print('MPI rank:', MPI.COMM_WORLD.Get_rank(), flush=True)
")

#reticulate::py_run_string(paste0("import os; print('Module file exists:', os.path.exists('", this_dir, "/", chistig_colocation_model, ".py'))"))


#tryCatch({
#  reticulate::py_run_string(paste0("import sys; sys.path.insert(0, '", this_dir, "')"))
#  print("sys.path insert succeeded")
#}, error = function(e) print(paste("sys.path insert FAILED:", conditionMessage(e))))

#tryCatch({
#  chistig_colocation_model <- str_remove(chistig_colocation_model, "\\.py$")
#  python_chistig <- import(chistig_colocation_model)
#  print("import succeeded")
#}, error = function(e) print(paste("import FAILED:", conditionMessage(e))))

#tryCatch({
#  testreticulate <- python_chistig$test_reticulate()
#  print(paste("test_reticulate succeeded:", testreticulate))
#}, error = function(e) print(paste("test_reticulate FAILED:", conditionMessage(e))))



#cat("Python path:", py_config()$python, "\n")
#cat("Python version:", py_config()$version, "\n")
#cat("Virtual env / conda env:", py_config()$virtualenv, "\n")

# Show full config
#py_config()

# # load python instance
# reticulate::use_python("/projects/p32153/condaenvs/conda-chistig/bin/python")
# reticulate::use_python("/home/parallels/.local/python-projects/venv/bin/python")
#reticulate::use_python(yamldata$reticulate.python.instance)

# Show which python reticulate is using
#cat("Python path:", py_config()$python, "\n")
#cat("Python version:", py_config()$version, "\n")
#cat("Virtual env / conda env:", py_config()$virtualenv, "\n")

#print("")
#reticulate::py_run_string("import os; print(os.environ.get('PYTHONPATH', 'NOT SET'))")
#print("")

# Show full config
#print(py_config())

#### ChiSTIG model prelim ------------------------------------------------------
#reticulate::py_run_string(paste0("import sys; sys.path.insert(0, '", this_dir, "')"))
#chistig_colocation_model <- yamldata$chistig.colocation.model.fname


#chistig_colocation_model <- paste0(this_dir, yamldata$chistig.colocation.model.fname)
#print(chistig_colocation_model)

#tryCatch({
#  chistig_colocation_model <- str_remove(chistig_colocation_model, "\\.py$")
#  python_chistig <- import(chistig_colocation_model)
#  print("import succeeded")
#}, error = function(e) print(paste("import FAILED:", conditionMessage(e))))

#tryCatch({
#  testreticulate <- python_chistig$test_reticulate()
#  print(paste("test_reticulate succeeded:", testreticulate))
#}, error = function(e) print(paste("test_reticulate FAILED:", conditionMessage(e))))

print("about to test the ctypes...")

reticulate::py_run_string("
import ctypes.util
original_find = ctypes.util.find_library
def traced_find(name):
    result = original_find(name)
    print(f'ctypes looking for: {name} -> {result}', flush=True)
    return result
ctypes.util.find_library = traced_find
")
python_chistig <- import(chistig_colocation_model)




#reticulate::py_run_string("
#import importlib, sys

## Monkey-patch __import__ to trace imports
#original_import = __builtins__.__import__
#def tracing_import(name, *args, **kwargs):
#    print(f'Importing: {name}', flush=True)
#    return original_import(name, *args, **kwargs)
#__builtins__.__import__ = tracing_import
#")
#reticulate::py_run_string("
#import ctypes.util
#original_find = ctypes.util.find_library
#def traced_find(name):
#    result = original_find(name)
#    print(f'ctypes looking for: {name} -> {result}', flush=True)
#    return result
#ctypes.util.find_library = traced_find
#")


#chistig_colocation_model <- str_remove(chistig_colocation_model, "\\.py$")
#python_chistig <- import(chistig_colocation_model)

print("chistig python module imported successfully!")

print(python_chistig$hello_world())

testreticulate <- python_chistig$test_reticulate()
print(testreticulate)

print("chistig testing reticulate functioning correctly!")



# # load the necessary chistig data for the chistig colocation model
chistig_colocation_params_fname <- paste0(abm_params_subdir, yamldata$colocation.params.fname)
# print(chistig_colocation_params_fname)
chistig_colocation_params <- python_chistig$create_params(chistig_colocation_params_fname)

print("params loaded successfully")

# print("")
# print(chistig_colocation_params$agent.log.file)

# rename the agent_log file with the specific experiment
# chistig_colocation_params$agent.log.file <- paste0(output_subdir, "agent-log_", treatment_run, "_", experiment_name, ".txt") #TODO
# chistig_colocation_params$agent.log.file <- "agent_log.txt"

# print("")
# print(chistig_colocation_params$agent.log.file)

# set the random seed in the colocation
python_chistig$set_random_seed(random_seed)

print("random seed set successfully")
# set up the model
python_chistig$run(chistig_colocation_params)

print("initial model setup carried out successfully")
# have agents attend their first sets of venues
python_chistig$next_step()

print("first step of agents carried out successfully")
# Settings ---------------------------------------------------------------------
source(paste0(utils_subdir, "utils-0_project_settings.R"))
source(paste0(utils_subdir, "utils-epi_trackers.R"))
source(paste0(utils_subdir, "utils-targets.R"))
#
# Network fit files
epistats <- readRDS(paste0(epistats_subdir, yamldata$epistats.fname))
netstats <- readRDS(paste0(network_fit_subdir, yamldata$netstats.fname, "_", sim_instance, ".rds"))
est <- readRDS(paste0(network_fit_subdir, yamldata$netest.venues.fname, "_", sim_instance, ".rds"))

epistats$age.breaks <- c(16, 20, 30)
epistats$age.limits <- c(16, 30)

netstats$attr$age <- sample(16:29, length(netstats$attr$age), replace = TRUE)
netstats$attr$age <- netstats$attr$age + sample(1:1000, length(netstats$attr$age), replace = TRUE)/1000


epimodel_params_df <- readr::read_csv(paste0(disease_params_subdir, yamldata$epimodel.params.fname))
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
sim <- netsim(est, param, init, control)
end_time <- Sys.time()

sim$sim_date <- end_time

saveRDS(sim, "simout.rds")
# saveRDS(sim, paste0(output_subdir, "simout-", treatment, "_run-no-", treatment_run_number, ".rds")) #TODO 
