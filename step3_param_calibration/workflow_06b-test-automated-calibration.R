# ASK ABOUT WHAT WE SHOULD DO FOR PREP
#### CHECK IF THERE'S A PREP ATTRIBUTE STORED SOMEWHERE. PROBABLY ADD TO NETSTATS
##### DOUBLE CHECK TO SEE WHERE PREP CREATED AN ISSUE, BUT SEEMS TO WORK FINE

# ADD A FIRST WAVE OF CALIBRATION FOR ARRIVAL RATE

# FOR FIRST RUN, GOOD TO HAVE WIDE THRESHOLDS JUST TO SEE THAT IT WORKS OKAY
# JUST SET REALLY WIDE RANGES

# WAVE 1 POP SIZE
# WAVE 2 DIAGNOSIS AND TREATMENT
# WAVE 3 EXOTRANS
# WAVE 4 TRANS SCALE

################################################################################
# CODE CHUNK 7 (I THINK THIS IS THE OVERALL PROCESS)


library("slurmworkflow")

#### SEEMS LIKE THESE ARE NEEDED, BUT NOT SURE WHERE THEY'RE SPECIFIED
# Settings ---------------------------------------------------------------------
source("./R/utils-0_project_settings.R")
context <- "hpc"
max_cores <- 1

# Define the `model` function
model <- function(proposal) {
  warning("Started model")
  # Load all required elements
  library(EpiModelHIV)
  library(dplyr)

  warning("Loaded project settings")
  source("./R/utils-0_project_settings.R")
  context <- "hpc"
  warning(paste("Context just stored as '", context, "'", sep = ""))
  max_cores <- 1
  source("./R/utils-chistig_basic_inputs.R") # make `path_to_est`, `param` and `init`
  # epistats <- readRDS("data/intermediate/estimates/epistats-local.rds") # THESE ARE STORED IN INPUT WHERE THEY USUALLY AREN'T IN THE OTHER WORKFLOWS
  # netstats <- readRDS("data/intermediate/estimates/netstats-local.rds")
  # est      <- readRDS("data/intermediate/estimates/basic_netest-local.rds")
  #
  # param <- param.net(
  #   data.frame.params = read.csv("data/input/params_chistig_jan29.csv"),
  #   netstats          = netstats,
  #   epistats          = epistats
  # )
  #
  # init <- init_msm()
  warning("Finished basic inputs")

  est <- readRDS(path_to_est)
  warning("Finished reading in `est`")

  # I think this needs to be loaded here to get `calibration_trackers` to work
  source("./R/utils-targets.R")

  control <- control_msm(
    # nsteps = 52 * 11,
    nsteps = 100,
    nsims  = 1,
    ncores = 1,
    .tracker.list       = calibration_trackers,

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

  warning("Finished control")
  # Proposal to scenario -------------------------------------------------------
  scenario <- EpiModelHPC::swfcalib_proposal_to_scenario(proposal)
  warning("Finished scenario")
  param_sc <- EpiModel::use_scenario(param, scenario)
  warning("Finished param_sc")

  # Run the simulation ---------------------------------------------------------
  sim <- netsim(est, param_sc, init, control)

  # Process the results  -------------------------------------------------------


  results <- as_tibble(sim) |>
    mutate_calibration_targets() |>
    filter(time >= max(time) - 52) |>
    select(
      cc.dx.B, cc.dx.H, cc.dx.O, cc.dx.W,
      cc.linked1m.B, cc.linked1m.H, cc.linked1m.O, cc.linked1m.W,
      cc.vsupp.B, cc.vsupp.H, cc.vsupp.O, cc.vsupp.W,
      exo.ir100.B, exo.ir100.H, exo.ir100.O, exo.ir100.W,
      # endo.ir100.B, endo.ir100.H, endo.ir100.O, endo.ir100.W,
      ir100.B, ir100.H, ir100.O, ir100.W
      # i.prev.dx.B, i.prev.dx.H, i.prev.dx.O, i.prev.dx.W,
    ) |>
    summarise(across(everything(), ~ mean(.x, na.rm = TRUE)))

  # Return the one row `tibble`
  return(results)
}

# Create the `calib_object`
n_sims  <- 10
calib_object <- list(
  config = list(
    simulator = model,
    default_proposal = dplyr::tibble(
      # Arrival Rate
      a.rate            = 0.001386813,
      # HIV Testing Rates
      hiv.test.rate_1   = 0.0038,
      hiv.test.rate_2   = 0.004192807,
      hiv.test.rate_3   = 0.0055,
      hiv.test.rate_4   = 0.0046625,
      # ART Initiation Rates
      tx.init.rate_1    = 0.3622703,
      tx.init.rate_2    = 0.39,
      tx.init.rate_3    = 0.4202679,
      tx.init.rate_4    = 0.52,
      # ART Cessation (Full Suppression Odds Ratio)
      tx.halt.full.or_1 = 0.9,
      tx.halt.full.or_2 = 0.63,
      tx.halt.full.or_3 = 1.45,
      tx.halt.full.or_4 = 1.25,
      # Exogenous Transmission Parameter
      exo.trans.prob.B = 0.49,
      exo.trans.prob.H = 0.2,
      exo.trans.prob.O = 0.1725,
      exo.trans.prob.W = 0.09,
      # Trans Scale
      hiv.trans.scale_1 = 9.5,
      hiv.trans.scale_2 = 5.5,
      hiv.trans.scale_3 = 3.1,
      hiv.trans.scale_4 = 1
    ),
    root_directory = "data/calib",
    max_iteration = 3,
    n_sims = n_sims
  ),
  waves = list(
    # Wave 2 (Diagnosis Rates and Linked To Care)
    wave1 = list(
      job1 = list(
        targets = "cc.dx.B",
        targets_val = 0.5465356428,
        params = c("hiv.test.rate_1"), # target: 0.00385
        initial_proposals = dplyr::tibble(
          hiv.test.rate_1 = seq(0.002, 0.006, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.10, poly_n = 5)
      ),
      job2 = list(
        targets = "cc.dx.H",
        targets_val = 0.5431367893,
        params = c("hiv.test.rate_2"), # target: 0.0038
        initial_proposals = dplyr::tibble(
          hiv.test.rate_2 = seq(0.002, 0.006, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.10, poly_n = 5)
      ),
      job3 = list(
        targets = "cc.dx.O",
        targets_val = 0.5988779867,
        params = c("hiv.test.rate_3"), # target: 0.0069
        initial_proposals = dplyr::tibble(
          hiv.test.rate_3 = seq(0.002, 0.006, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.10, poly_n = 5)
      ),
      job4 = list(
        targets = "cc.dx.W",
        targets_val = 0.5614905982,
        params = c("hiv.test.rate_4"), # target: 0.0069
        initial_proposals = dplyr::tibble(
          hiv.test.rate_4 = seq(0.002, 0.006, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2), # IT WILL GUESS THE BEST VALUE FROM `poly_n` AND MAKE A NEW RANGE THAT'S TWICE AS SMALL
        get_result = swfcalib::determ_poly_end(0.10, poly_n = 5) # ASK HOW WIDE A THRESHOLD WE'RE INTERESTED IN (0.001 current setting)
      ),
      job5 = list(
        targets = paste0("cc.linked1m.", c("B", "H", "O", "W")),
        targets_val = c(0.828, 0.867, 0.875, 0.936), # Updated
        params = paste0("tx.init.rate_", 1:4),
        initial_proposals = dplyr::tibble(
          tx.init.rate_1 = sample(seq(0.1, 0.6, length.out = n_sims)), # INCREASED RANGE BASED ON WHAT I SEE LOCALLY
          tx.init.rate_2 = sample(tx.init.rate_1),
          tx.init.rate_3 = sample(tx.init.rate_1),
          tx.init.rate_4 = sample(tx.init.rate_1)
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.10, poly_n = 3)
      ),
      job6 = list(
        targets = paste0("cc.vsupp.", c("B", "H", "O", "W")),
        targets_val = c(0.571, 0.675, 0.586, 0.617),
        params = paste0("tx.halt.full.or_", 1:4),
        initial_proposals = dplyr::tibble(
          tx.halt.full.or_1 = sample(seq(0.5, 1.5, length.out = n_sims)),
          tx.halt.full.or_2 = sample(seq(0.4, 0.8, length.out = n_sims)),
          tx.halt.full.or_3 = sample(seq(1, 2, length.out = n_sims)),
          tx.halt.full.or_4 = sample(seq(1, 2, length.out = n_sims))
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.10, poly_n = 3)
      ),
      job7 = list(
        targets = paste0("exo.ir100.", c("B", "H", "O", "W")),
        targets_val = c(1.618, 0.7345, 0.5695, 0.2891),
        params = paste0("exo.trans.prob.", c("B", "H", "O", "W")),
        initial_proposals = dplyr::tibble(
          exo.trans.prob.B = sample(seq(0.1, 0.6, length.out = n_sims)), # Need to update for parameters
          exo.trans.prob.H = sample(seq(0.1, 0.6, length.out = n_sims)),
          exo.trans.prob.O = sample(seq(0.1, 0.6, length.out = n_sims)),
          exo.trans.prob.W = sample(seq(0.05, 0.30, length.out = n_sims))
        ),
        make_next_proposals =
          swfcalib::make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = swfcalib::determ_end_thresh(
          thresholds = rep(0.10, 4),
          n_enough = 100
        )
      ),
      job8 = list(
        targets = paste0("ir100.", c("B", "H", "O", "W")),
        targets_val = c(6.42, 2.04, 1.71, 0.73),
        params = paste0("hiv.trans.scale_", 1:4),
        initial_proposals = dplyr::tibble(
          hiv.trans.scale_1 = sample(seq(8, 11, length.out = n_sims)), # Need to update for parameters
          hiv.trans.scale_2 = sample(seq(4, 7, length.out = n_sims)),
          hiv.trans.scale_3 = sample(seq(2, 5, length.out = n_sims)),
          hiv.trans.scale_4 = sample(seq(0.5, 1.5, length.out = n_sims))
        ),
        make_next_proposals =
          swfcalib::make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = swfcalib::determ_end_thresh(
          thresholds = rep(0.10, 4),
          n_enough = 100
        )
      )

    )#,
    # # Wave 3 (ART Cessation and Viral Suppression)
    # wave2 = list(
    #   job1 = list(
    #     targets = paste0("cc.vsupp.", c("B", "H", "O", "W")),
    #     targets_val = c(0.571, 0.675, 0.586, 0.617),
    #     params = paste0("tx.halt.full.or_", 1:4),
    #     initial_proposals = dplyr::tibble(
    #       tx.halt.full.or_1 = sample(seq(0.5, 1.5, length.out = n_sims)),
    #       tx.halt.full.or_2 = sample(seq(0.4, 0.8, length.out = n_sims)),
    #       tx.halt.full.or_3 = sample(seq(1, 2, length.out = n_sims)),
    #       tx.halt.full.or_4 = sample(seq(1, 2, length.out = n_sims))
    #     ),
    #     make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
    #     get_result = swfcalib::determ_poly_end(0.10, poly_n = 3)
    #   )
    # )
  )
)

# REMEMBER TO SWAP PREVALENCE FOR INCIDENCE RATES FOR WAVE 4

# Workflow ---------------------------------------------------------------------

# Use preconfigured HPC settings
# hpc_configs <- EpiModelHPC::swf_configs_rsph(
#   partition = "epimodel",
#   r_version = "4.3",
#   mail_user = "tom.wolff@northwestern.edu"
# )
source("./R/utils-hpc_configs.R") # creates `hpc_configs`

wf <- create_workflow(
  wf_name = "auto_calib",
  default_sbatch_opts = hpc_configs$default_sbatch_opts
)

# Calibration step 1
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call(
    what = swfcalib::calibration_step1,
    args = list(
      n_cores = 8,
      calib_object = calib_object
    ),
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "cpus-per-task" = 8,
    "time" = "01:00:00",
    "mem-per-cpu" = "4G",
    "mail-type" = "FAIL"
  )
)

# Calibration step 2
batch_size <- 8
batch_numbers <- swfcalib:::get_batch_numbers(calib_object, batch_size)
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_map(
    FUN = swfcalib::calibration_step2,
    batch_num = batch_numbers,
    setup_lines = hpc_configs$r_loader,
    max_array_size = 500,
    MoreArgs = list(
      n_cores = batch_size,
      n_batches = max(batch_numbers),
      calib_object = calib_object
    )
  ),
  sbatch_opts = list(
    "cpus-per-task" = batch_size,
    "time" = "01:00:00",
    "mem-per-cpu" = "5G",
    "mail-type" = "FAIL"
  )
)

# Calibration step 3
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call(
    what = swfcalib::calibration_step3,
    args = list(
      calib_object = calib_object
    ),
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "01:00:00",
    "mem-per-cpu" = "8G",
    "mail-type" = "END"
  )
)
