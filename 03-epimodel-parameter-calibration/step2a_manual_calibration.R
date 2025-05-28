##
## Epidemic Model Parameter Calibration, Local Simulation Runs
##

# Libraries --------------------------------------------------------------------
 library("EpiModelHIV")

# Settings ---------------------------------------------------------------------
context <- "local"
source("./03-epimodel-parameter-calibration/utils_03.R")

# Run the simulations ----------------------------------------------------------

# Necessary files
path_to_est <- "./03-epimodel-parameter-calibration//data/intermediate/estimates/basic_netest-local.rds"

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

  # HIV Testing Rate
   # hiv.test.rate_1 = seq(0.0041, 0.0041, length.out = n_scenarios),
   # hiv.test.rate_2 = seq(0.004192807, 0.004192807, length.out = n_scenarios),
   # hiv.test.rate_3 = seq(.0042, 0.0048, length.out = n_scenarios),
   # hiv.test.rate_4 = seq(0.0055, 0.0055, length.out = n_scenarios),

  # Probability that an HIV+ node will initiate ART treatment
   # tx.init.rate_1 = seq(0.3622703, 0.3622703, length.out = n_scenarios),
   # tx.init.rate_2 = seq(0.39, 0.39, length.out = n_scenarios),
   # tx.init.rate_3 = seq(0.42, 0.42, length.out = n_scenarios),
   # tx.init.rate_4 = seq(.52, .52, length.out = n_scenarios),

  # ART halting
   # tx.halt.partial.rate_1 = seq(     0.004825257,      0.004825257, length.out = n_scenarios),
   # tx.halt.partial.rate_2 = seq(     0.00453566,      0.00453566, length.out = n_scenarios),
   # tx.halt.partial.rate_3 = seq(     0.003050059,      0.003050059, length.out = n_scenarios),
   # tx.halt.partial.rate_4 = seq(     0.003050059,      0.003050059, length.out = n_scenarios),

   # tx.halt.full.or_1 = seq(     0.9,      0.9, length.out = n_scenarios),
   # tx.halt.full.or_2 = seq(     0.63,      0.63, length.out = n_scenarios),
   # tx.halt.full.or_3 = seq(     1.45,      1.45, length.out = n_scenarios),
   # tx.halt.full.or_4 = seq(     1.25,      1.25, length.out = n_scenarios),

  # ART reinitiation after disengagement (Keep Fixed for now, these values were used in CombPrev)
   # tx.reinit.partial.rate_1 = seq(     0.1326,      0.1326, length.out = n_scenarios),
   # tx.reinit.partial.rate_2 = seq(     0.1326,      0.1326, length.out = n_scenarios),
   # tx.reinit.partial.rate_3 = seq(     0.1326,      0.1326, length.out = n_scenarios),
   # tx.reinit.partial.rate_4 = seq(     0.1326,      0.1326, length.out = n_scenarios),

   # tx.reinit.full.or_1 = seq(     -1.3,      -1.5, length.out = n_scenarios),
   # tx.reinit.full.or_2 = seq(     -1.3,      -1.3, length.out = n_scenarios),
   # tx.reinit.full.or_3 = seq(     -1.5,      -1.8, length.out = n_scenarios),
   # tx.reinit.full.or_4 = seq(     -1.5,      -1.8, length.out = n_scenarios)

 # `trans.scale` parameter accounting for unexplained sources of racial disparities
 #    in HIV incidence/prevalence
 hiv.trans.scale_1 = c(1, seq(    17.5,     17.5, length.out = n_scenarios-1)),
 hiv.trans.scale_2 = c(1, seq(     5.2,      5.2, length.out = n_scenarios-1)),
 hiv.trans.scale_3 = c(1, seq(     3.04,    3.04, length.out = n_scenarios-1)),
 hiv.trans.scale_4 = c(1, seq(     .25,        1, length.out = n_scenarios-1))

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
  output_dir = "./03-epimodel-parameter-calibration/data/intermediate/calibration",
  #libraries = NULL,
  libraries = c("slurmworkflow", "EpiModelHPC", "chiSTIGmodules"),
  save_pattern = "simple"
)

end_time <- Sys.time()

# Check the files produced
list.files("./03-epimodel-parameter-calibration/data/intermediate/calibration")


