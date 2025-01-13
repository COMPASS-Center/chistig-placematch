##
## 10. Epidemic Model Parameter Calibration, Local simulation runs
##

# Libraries --------------------------------------------------------------------
 library("EpiModelHIV")

# load reticulate
#library(reticulate)
# point to python binary
#reticulate::use_python("/Users/wms1212/Library/r-miniconda-arm64/envs/r-reticulate/bin/python")

#
# #### ChiSTIG model prelim ------------------------------------------------------
# # specifying the python script to use
# # specifying the python script to use
# # python_funs <- environment(reticulate::source_python(paste0(this_dir,"chistig_reticulate_python_script.py")))
# python_funs <- environment(reticulate::source_python("~/Desktop/chistig_debug/chistig_reticulate_python_script.py"))
#
# # necessary emppop files
# empop_demo_file = "~/Desktop/chistig_debug/data/input/empop_egoid_demo_def.csv"
# empop_vmatrix_file = "~/Desktop/chistig_debug/data/input/empop_ego_venue_matrix.csv"
# empop_amatrix_file = "~/Desktop/chistig_debug/data/input/empop_ego_app_matrix_binary.csv"
# empop_relbin_file = "~/Desktop/chistig_debug/data/input/ser_rel_data.csv"
#
# # necessary synthpop files
# efile <- "~/Desktop/chistig_debug/data/input/egos_v4_0.csv"
# vfile <- "~/Desktop/chistig_debug/data/input/venue-attendance_v4_0.csv"
#
# # necessary app and venue files
# atypefile <- "~/Desktop/chistig_debug/data/input/empop_appid_type_def.csv"
# vtypefile <- "~/Desktop/chistig_debug/data/input/empop_venueid_type_def.csv"
#
# # format the empirical population datasets
# empopdfs <- python_funs$init_empop(empop_demo_file, empop_vmatrix_file, empop_amatrix_file, empop_relbin_file)
# empopegos2venues <- python_funs$create_emppop_venue_attendance_dict(empopdfs$vmatrix)
# empopegos2demos <- python_funs$create_emppop_buckets(empopdfs$demo)
# empopegos2apps <- python_funs$create_emppop_appuse_dict(empopdfs$amatrix)
# empopegos2rel <- python_funs$create_rel_binary_emppop_buckets(empopegos2demos, empopdfs$rel)
#
# # setting up the mapping of venues to venue type
# venues2types <- python_funs$categorize_venues(vtypefile)
#
# # setting up initial synthetic population and attendance/appuse objects
# segos2venues <- python_funs$obtain_egos_vdict(vfile)
# # save(segos2venues, file = paste0(this_dir,"segos2venues.RData"))
# segos2apps <- python_funs$categorize_apps_segos(efile, atypefile)
# sego2apps_norel <- python_funs$assign_apps_norel(efile, segos2apps)
# # save(segos2apps, file = paste0(this_dir,"segos2apps.RData"))
#
# # set a variable to toggle whether or not appuse is assigned via relationship status
# appuse_by_rel_status <- FALSE

# Settings ---------------------------------------------------------------------
context <- "local"
source("./R/utils-0_project_settings.R")

# Run the simulations ----------------------------------------------------------

# Necessary files
source("./R/utils-chistig_basic_inputs.R") # generate `path_to_est`, `param` and `init`
# path_to_est <- "./data/intermediate/estimates/basic_netest-local.rds"
# path_to_est      <- "/Users/wms1212/Desktop/ChiSTIG_model/epimodel/data/intermediate/estimates/venue_only_netest-local.rds"
path_to_est <- "./data/intermediate/estimates/basic_netest-local.rds"
# Controls
 source("./R/utils-targets.R")



# Install custom chiSTIG modules
# devtools::install_github("Tom-Wolff/chiSTIGmodules", force = TRUE)


control <- EpiModelHIV::control_msm(
  nsteps              = calibration_end,
  nsims               = 10,
  ncores              = 10,
  # cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = FALSE,
  # raw.output          = TRUE,
  initialize.FUN =              chiSTIGmodules::initialize_msm_chi,
  aging.FUN =                   chiSTIGmodules::aging_msm_chi,
  departure.FUN =               chiSTIGmodules::departure_msm_chi,
  arrival.FUN =                 chiSTIGmodules::arrival_msm_chi,
  # venues.FUN =                  chiSTIGmodules:::venues_msm_chi,
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

  module.order = c("aging.FUN", "departure.FUN", "arrival.FUN", # "venues.FUN",
                   "partident.FUN", "hivtest.FUN", "hivtx.FUN", "hivprogress.FUN",
                   "hivvl.FUN", "resim_nets.FUN", "acts.FUN", "condoms.FUN",
                   "position.FUN", "prep.FUN", "hivtrans.FUN", "exotrans.FUN",
                   "stitrans.FUN", "stirecov.FUN", "stitx.FUN", "prev.FUN", "cleanup.FUN")
)


# insert test values here
# n_scenarios <- 5
# scenarios_df <- tibble(
#   # mandatory columns
#   .scenario.id = as.character(seq_len(n_scenarios)),
#   .at          = 1,
#   # parameters to test columns
#   # ugc.prob     = seq(0.3225, 0.3275, length.out = n_scenarios),
#   # rgc.prob     = plogis(qlogis(ugc.prob) + log(1.25)),
#   # uct.prob     = seq(0.29, 0.294, length.out = n_scenarios),
#   # rct.prob     = plogis(qlogis(uct.prob) + log(1.25))
#   hiv.urai.prob = seq(0.008938, .01, length.out = n_scenarios)
# )

# Per

# Receptive(102-186)/10000
# Insertive (1-19)/10000
n_scenarios <- 4
scenarios_df <- tibble(
  # mandatory columns
  .scenario.id = as.character(seq_len(n_scenarios)),
  .at          = 1,
  # parameters to test columns
  # ugc.prob     = seq(0.3225, 0.3275, length.out = n_scenarios),
  # rgc.prob     = plogis(qlogis(ugc.prob) + log(1.25)),
  # uct.prob     = seq(0.29, 0.294, length.out = n_scenarios),
  # rct.prob     = plogis(qlogis(uct.prob) + log(1.25))

  # tx.init.rate_1 = rep(0.3745406, n_scenarios),
  # tx.init.rate_2 = seq(0.3940459, 0.4070230, length.out = n_scenarios),
  # tx.init.rate_3 = seq(0.3936905, 0.4291270, length.out = n_scenarios),
  # tx.init.rate_4 = rep(0.5, n_scenarios)

  # Arrival Rate (Population Size)
  # a.rate = seq(0.001386813, 0.001386813, length.out = n_scenarios)#,

  # Exogenous Infection Rates
  # exo.trans.prob.B = seq(0.4900, 0.4900, length.out = n_scenarios), #
  # exo.trans.prob.H = seq(0.2000, 0.2000, length.out = n_scenarios),
  # exo.trans.prob.O = seq(0.1725, 0.1725, length.out = n_scenarios),
  # exo.trans.prob.W = seq(0.0900, 0.0900, length.out = n_scenarios),
 #
  # HIV Testing Rate
   # hiv.test.rate_1 = seq(0.0041, 0.0041, length.out = n_scenarios),
   # hiv.test.rate_2 = seq(0.004192807, 0.004192807, length.out = n_scenarios),
   # hiv.test.rate_3 = seq(.0042, 0.0048, length.out = n_scenarios),
   # hiv.test.rate_4 = seq(0.0055, 0.0055, length.out = n_scenarios),
 #
 #  # Probability that an HIV+ node will initiate ART treatment
 #  tx.init.rate_1 = seq(0.3622703, 0.3622703, length.out = n_scenarios),
 #  tx.init.rate_2 = seq(0.39, 0.39, length.out = n_scenarios),
 #  tx.init.rate_3 = seq(0.42, 0.42, length.out = n_scenarios),
 #  tx.init.rate_4 = seq(.52, .52, length.out = n_scenarios),
 #
 #
 # # Does starting PrEP require a negative test?
 # prep.require.lnt = rep(FALSE, n_scenarios),
 #
 # # PrEP Initiation
 # prep.start.prob_1 = seq(     0.634375,      1, length.out = n_scenarios),
 # prep.start.prob_2 = seq(     0.775,      1, length.out = n_scenarios),
 # prep.start.prob_3 = seq(     0.765625,      1, length.out = n_scenarios),
 # prep.start.prob_4 = seq(     0.765625,      1, length.out = n_scenarios),

 #  # ART halting
  # tx.halt.partial.rate_1 = seq(     0.004825257,      0.004825257, length.out = n_scenarios),
  # tx.halt.partial.rate_2 = seq(     0.00453566,      0.00453566, length.out = n_scenarios),
  # tx.halt.partial.rate_3 = seq(     0.003050059,      0.003050059, length.out = n_scenarios),
  # tx.halt.partial.rate_4 = seq(     0.003050059,      0.003050059, length.out = n_scenarios),

  # tx.halt.full.or_1 = seq(     0.9,      0.9, length.out = n_scenarios),
  # tx.halt.full.or_2 = seq(     0.63,      0.63, length.out = n_scenarios),
  # tx.halt.full.or_3 = seq(     1.45,      1.45, length.out = n_scenarios),
  # tx.halt.full.or_4 = seq(     1.25,      1.25, length.out = n_scenarios),
 #
 #
 # # ART reinitiation after disengagement (Keep Fixed for now,
 # # these values were used in CombPrev)
 #  tx.reinit.partial.rate_1 = seq(     0.1326,      0.1326, length.out = n_scenarios),
 #  tx.reinit.partial.rate_2 = seq(     0.1326,      0.1326, length.out = n_scenarios),
 #  tx.reinit.partial.rate_3 = seq(     0.1326,      0.1326, length.out = n_scenarios),
 #  tx.reinit.partial.rate_4 = seq(     0.1326,      0.1326, length.out = n_scenarios),

 # tx.reinit.full.or_1 = seq(     -1.3,      -1.5, length.out = n_scenarios),
 # tx.reinit.full.or_2 = seq(     -1.3,      -1.3, length.out = n_scenarios),
 # tx.reinit.full.or_3 = seq(     -1.5,      -1.8, length.out = n_scenarios),
 # tx.reinit.full.or_4 = seq(     -1.5,      -1.8, length.out = n_scenarios)
 #
 #
 # `trans.scale` "fudge factor" parameter
 # This was for calibrating on incidence
 # hiv.trans.scale_1 = seq(     8.166667,       8.7, length.out = n_scenarios),
 # hiv.trans.scale_2 = seq(     3.8,      4.2, length.out = n_scenarios),
 # hiv.trans.scale_3 = seq(     2.633333,      3.033333, length.out = n_scenarios),
 # hiv.trans.scale_4 = seq(     0.8,      1.2, length.out = n_scenarios)

 # This was for calibrating on prevalence
 hiv.trans.scale_1 = c(1, seq(       17.5, 17.5, length.out = n_scenarios-1)),
 hiv.trans.scale_2 = c(1, seq(     5.2,      5.2, length.out = n_scenarios-1)),
 hiv.trans.scale_3 = c(1, seq(     3.04,      3.04, length.out = n_scenarios-1)),
 hiv.trans.scale_4 = c(1, seq(     .25,      1, length.out = n_scenarios-1))

  # tt.partial.supp.prob_1 = c(0, .2),
  # tt.partial.supp.prob_2 = c(0, .2),
  # tt.partial.supp.prob_3 = c(0, .2),
  # tt.partial.supp.prob_4 = c(0, .2),‚
  #
  # tt.full.supp.prob_1 = c(1, .4),
  # tt.full.supp.prob_2 = c(1, .4),
  # tt.full.supp.prob_3 = c(1, .4),
  # tt.full.supp.prob_4 = c(1, .4),
  #
  # tt.durable.supp.prob_1 = c(0, .4),
  # tt.durable.supp.prob_2 = c(0, .4),
  # tt.durable.supp.prob_3 = c(0, .4),
  # tt.durable.supp.prob_4 = c(0, .4)
)
#
# annual_incid_calc <- function(rate, n) {
#   rate <- rate/100
#   val <- (1-exp(-rate))*n
#   return(val)
# }
#
# netstats <- readRDS("data/intermediate/estimates/netstats-novenues-local.rds")
#
# annual_incid_calc(
# rate = 6.42,
# n = sum(netstats$attr$race == 1 & netstats$attr$diag.status == 0)
# )
#
# annual_incid_calc(
#   rate = 2.04,
#   n = sum(netstats$attr$race == 2 & netstats$attr$diag.status == 0)
# )
#
# annual_incid_calc(
#   rate = 1.71,
#   n = sum(netstats$attr$race == 3 & netstats$attr$diag.status == 0)
# )
#
# annual_incid_calc(
#   rate = .73,
#   n = sum(netstats$attr$race == 4 & netstats$attr$diag.status == 0)
# )
#
# (1-exp(-0.0652))*2897

scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

# Each scenario will be run exactly 3 times using up to 3 CPU cores.
# The results are save in the "data/intermediate/test04" folder using the
# following pattern: "sim__<scenario name>__<batch number>.rds".
# See ?EpiModelHPC::netsim_scenarios for details
start_time <- Sys.time()

EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control, scenarios_list,
  n_rep = 20,
  n_cores = 10,
  output_dir = "data/intermediate/calibration",
  #libraries = NULL,
  libraries = c("slurmworkflow", "EpiModelHPC", "chiSTIGmodules"),
  save_pattern = "simple"
)

end_time <- Sys.time()

# Check the files produced
list.files("data/intermediate/calibration")


