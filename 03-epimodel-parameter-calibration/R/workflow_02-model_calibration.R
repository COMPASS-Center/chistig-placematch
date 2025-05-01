##
## Epidemic Model Parameter Calibration, HPC setup
##

# Libraries --------------------------------------------------------------------
library("slurmworkflow")
library("EpiModelHPC")
library("EpiModelHIV")

# Settings ---------------------------------------------------------------------
source("./R/utils-0_project_settings.R")
context <- "hpc"
max_cores <- 1

source("./R/utils-chistig_basic_inputs.R") # make `path_to_est`, `param` and `init`
source("./R/utils-hpc_configs.R") # creates `hpc_configs`

# ------------------------------------------------------------------------------

# Workflow creation
wf <- create_workflow(
  wf_name = "model_calibration",
  default_sbatch_opts = hpc_configs$default_sbatch_opts
)

# Update RENV on the HPC
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_renv_restore(
    git_branch = current_git_branch,
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = hpc_configs$renv_sbatch_opts
)

# Controls
source("./R/utils-targets.R")
control <- control_msm(
  nsteps              = 52 * 60,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  # .checkpoint.dir     = "./temp/cp_calib",
  # .checkpoint.clear   = TRUE,
  # .checkpoint.steps   = 15 * 52,
  verbose             = FALSE,

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
  hiv.trans.scale_1 = c(16.75), #seq(       15.5, 17, length.out = n_scenarios),
  hiv.trans.scale_2 = c(2.792593), #seq(     2.644445,      2.866667, length.out = n_scenarios),
  hiv.trans.scale_3 = c(1.472592), #seq(     1.404444,      1.608889, length.out = n_scenarios),
  hiv.trans.scale_4 = seq(     .625,      1, length.out = n_scenarios)

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

write.csv(scenarios_df, paste("./scenarios_", Sys.Date(), ".csv", sep = ""))


scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_est, param, init, control,
    scenarios_list = scenarios_list,
    output_dir = "./data/intermediate/calibration",
    # libraries = c(#"EpiModelHIV",
    #               "slurmworkflow",
    #               "EpiModelHPC",
    #               "chiSTIGmodules"
    #               ),
    n_rep = 10,
    n_cores = max_cores,
    save_pattern = "simple",
    max_array_size = 999,
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem" = "5G"
  )
)

# # Process calibrations
# #
# # produce a data frame with the calibration targets for each scenario
# wf <- add_workflow_step(
#   wf_summary = wf,
#   step_tmpl = step_tmpl_do_call_script(
#     r_script = "./R/11-calibration_process.R",
#     args = list(
#       context = "hpc",
#       ncores = 15
#     ),
#     setup_lines = hpc_configs$r_loader
#   ),
#   sbatch_opts = list(
#     "cpus-per-task" = 15,
#     "time" = "04:00:00",
#     "mem-per-cpu" = "4G",
#     "mail-type" = "END"
#   )
# )

# Send the workflow folder to the <HPC> and run it
#
# $ scp -r ./workflows/model_calibration <HPC>:<project_dir>/workflows/
#
# on the HPC:
# $ ./workflows/model_calibration/start_workflow.sh

# Once the worfklow is finished download the data from the HPC
#
# $ scp -r <HPC>:<project_dir>/data/intermediate/calibration/assessments.rds ./data/intermediate/calibration/
#
# and analyse them locally using: "./R/12-calibration_eval.R"
