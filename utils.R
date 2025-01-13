###################################
#                                 #
#    C H I S T I G   U T I L S    #
#                                 #
###################################

#############################################################
#    U T I L S - 0   ( P R O J E C T   S E T T I N G S )    #
#############################################################

##
## 00. Shared variables setup
##

est_dir <- yaml$est_dir
diag_dir <- yaml$diag_dir
calib_dir <- yaml$calib_dir
scenarios_dir <- yaml$scenarios_dir

# Information for the HPC workflows
current_git_branch <- yaml$current_git_branch
mail_user <- yaml$mail_user # or any other mail provider

# Relevant time steps for the simulation
calibration_end    <- 52 * yaml$calibration_end
restart_time       <- calibration_end + 1
prep_start         <- yaml$prep_start
intervention_start <- yaml$intervention_start
intervention_end   <- yaml$intervention_end



#################################
#    B A S I C   I N P U T S    #
#################################

# if (!context %in% c("local", "hpc")) {
#   stop("The `context` variable must be set to either 'local' or 'hpc'")
# }

context <- "hpc"

epistats <- readRDS("./data/intermediate/estimates/epistats-local.rds")
netstats <- readRDS("./data/intermediate/estimates/netstats-local.rds")
# netstats <- readRDS("data/intermediate/estimates/netstats-local.rds")
# Is the aging out of the older initial nodes driving HIV extinction?
# Let's level out the age distribution and find out
netstats$attr$age <- sample(16:29, length(netstats$attr$age), replace = TRUE)
netstats$attr$age <- netstats$attr$age + sample(1:1000, length(netstats$attr$age), replace = TRUE)/1000

##### `est` object for basic ERGMs (no venues or apps)
path_to_est <- "./data/intermediate/estimates/basic_netest-local.rds"
path_to_restart <- paste0(est_dir, "restart-", context, ".rds")

# `netsim` Parameters
prep_start <- 52 * 2
param <- EpiModel::param.net(
  data.frame.params = readr::read_csv("data/input/params_chistig_apr18.csv"),
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = yaml$prep_start,
  riskh.start       = yaml$riskh.start
)

# Initial conditions (default prevalence initialized in epistats)
# For models without bacterial STIs, these must be initialized here
# with non-zero values
# init <- init_msm(
#   prev.ugc = 0.1,
#   prev.rct = 0.1,
#   prev.rgc = 0.1,
#   prev.uct = 0.1
# )
init <- EpiModelHIV::init_msm()


#################################
#    E P I   T R A C K E R S    #
#################################

library("EpiModel")

# Utilities --------------------------------------------------------------------

#' Takes a list of epi_trackers factory and return a list of epi_trackers
#'
#' This function accept epi_tracers factories as input. These are function
#' with one argument `races_set` that return an epi_tracker specific to a set of
#' races.
#' This function is used when the same trackers are used for different races
#'
#' @param trackers_list a list of epi_trackers factories
#' @param races the races of interest using the internal identifiers (here
#'   integers)
#' @param races_names character names to identify the races (here B, H W)
#' @param individual_trackers should a tracker be created for each of the
#'   `races`? (default = TRUE)
#' @param global_trackers should a tracker be created for the population as a
#'   whole, i.e. not stratified by race? (default = TRUE)
epi_trackers_by_races <- function(trackers_list,
                                  races = c(1, 2, 3, 4),
                                  races_names = c("B", "H", "O", "W"),
                                  individual_trackers = TRUE,
                                  global_trackers = TRUE) {
  races_list <- if (individual_trackers) as.list(races) else list()
  races_names <- if (individual_trackers) races_names else c()

  if (global_trackers) {
    races_list <- c(races_list, list(races))
    races_names <- c(races_names, "ALL")
  }

  epi_trackers <- lapply(
    races_list,
    function(races) {
      lapply(trackers_list, do.call, args = list(races_set = races))
    }
  )

  epi_trackers <- unlist(epi_trackers)
  names(epi_trackers) <- paste0(
    names(epi_trackers), "___",
    unlist(lapply(races_names, rep, times = length(trackers_list)))
  )

  return(epi_trackers)
}

# Trackers ---------------------------------------------------------------------
epi_n <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "active")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & active == 1, na.rm = TRUE)
    })
  }
}

# HIV Trackers
epi_s <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 0, na.rm = TRUE)
    })
  }
}

# eligible to prep
epi_s_prep_elig <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status", "prepElig")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 0 & prepElig == 1, na.rm = TRUE)
    })
  }
}

# on prep
epi_s_prep <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status", "prepStat")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 0 & prepStat == 1, na.rm = TRUE)
    })
  }
}

epi_i <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 1, na.rm = TRUE)
    })
  }
}

epi_i_dx <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status", "diag.status")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 1 & diag.status == 1, na.rm = TRUE)
    })
  }
}

epi_i_tx <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status", "tx.status")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 1 & tx.status == 1, na.rm = TRUE)
    })
  }
}

epi_i_sup <- function(races_set) {
  function(dat) {
    at <- get_current_timestep(dat)
    needed_attributes <- c("race", "status", "vl.last.supp")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 1 & vl.last.supp == at, na.rm = TRUE)
    })
  }
}

epi_i_sup_dur <- function(races_set) {
  function(dat) {
    at <- get_current_timestep(dat)
    needed_attributes <- c("race", "status", "vl.last.usupp")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set &
            status == 1 &
            at - vl.last.usupp >= 52,
          na.rm = TRUE
      )
    })
  }
}

# linked in less than `weeks` step
epi_linked_time <- function(weeks) {
  function(races_set) {
    function(dat) {
      needed_attributes <- c("race", "tx.init.time", "diag.time")
      with(get_attr_list(dat, needed_attributes), {
        sum(
          race %in% races_set &
            tx.init.time - diag.time <= weeks,
          na.rm = TRUE
        )
      })
    }
  }
}

# STI trackers
epi_gc_i <- function(hiv_status) {
  function(races_set) {
    function(dat) {
      needed_attributes <- c("race", "rGC", "uGC", "status")
      with(get_attr_list(dat, needed_attributes), {
        sum(
          race %in% races_set &
            status %in% hiv_status &
            (rGC == 1 | uGC == 1),
          na.rm = TRUE
        )
      })
    }
  }
}

epi_ct_i <- function(hiv_status) {
  function(races_set) {
    function(dat) {
      needed_attributes <- c("race", "rCT", "uCT", "status")
      with(get_attr_list(dat, needed_attributes), {
        sum(
          race %in% races_set &
            status %in% hiv_status &
            (rCT == 1 | uCT == 1),
          na.rm = TRUE
        )
      })
    }
  }
}

epi_gc_s <- function(hiv_status) {
  function(races_set) {
    function(dat) {
      needed_attributes <- c("race", "rGC", "uGC", "status")
      with(get_attr_list(dat, needed_attributes), {
        sum(
          race %in% races_set &
            status %in% hiv_status &
            (rGC == 0 & uGC == 0),
          na.rm = TRUE
        )
      })
    }
  }
}

epi_ct_s <- function(hiv_status) {
  function(races_set) {
    function(dat) {
      needed_attributes <- c("race", "rCT", "uCT", "status")
      with(get_attr_list(dat, needed_attributes), {
        sum(
          race %in% races_set &
            status %in% hiv_status &
            (rCT == 0 & uCT == 0),
          na.rm = TRUE
        )
      })
    }
  }
}

epi_prep_ret <- function(ret_steps) {
  function(races_set) {
    function(dat) {
      at <- get_current_timestep(dat)
      needed_attributes <- c("race", "prepStartTime")
      with(get_attr_list(dat, needed_attributes), {
        retained <- sum(
          race %in% races_set &
            prepStartTime == at - ret_steps,
          na.rm = TRUE
        )
      })
    }
  }
}


#######################
#    T A R G E T S    #
#######################

library("dplyr")
library("EpiModel")

targets <- c(
  num = 11612,
  # 1st calibration set (all independant)
  cc.dx.B                                 = 0.546535643,
  cc.dx.H                                 = 0.5431367893,
  cc.dx.O                               = 0.5601310,
  cc.dx.W                                 = 0.5988779867,
  cc.linked1m.B                           = 0.828,
  cc.linked1m.H                           = 0.867,
  cc.linked1m.O                         = 0.875,
  cc.linked1m.W                           = 0.936,
  # CombPrev appendix 8.2.2
  # 2nd calibration set (all independant)
  cc.vsupp.B                              = 0.571,
  cc.vsupp.H                              = 0.675,
  cc.vsupp.O                              = 0.586,
  cc.vsupp.W                              = 0.617,
  # STIs
  ir100.gc                                = 12.81,
  ir100.ct                                = 14.59,
  # 3rd calibration set
  i.prev.dx.B                             = 0.33,
  i.prev.dx.H                             = 0.127,
  i.prev.dx.O                             = 0.084,
  i.prev.dx.W                             = 0.084,
  i.prev.dx                               = 0.17, # not used yet but maybe?
  cc.prep.ind.B                           = 0.387,
  cc.prep.ind.H                           = 0.379,
  cc.prep.ind.O                           = 0.407,
  cc.prep.ind.W                           = 0.407,
  cc.prep.ind                             = 0.402,
  cc.prep.B                               = 0.206,
  cc.prep.H                               = 0.237,
  cc.prep.O                               = 0.332,
  cc.prep.W                               = 0.332,
  cc.prep                                 = 0.203,
  prep_prop_ret1y                         = 0.56, # DOI: 10.1002/jia2.25252 and 10.1093/cid/ciaa037 (54%)
  prep_prop_ret2y                         = 0.41,
  disease.mr100                           = 0.273,
  # Incidence Rates for chiSTIG
  ### Exogenous incidence rate
  exo.ir100.B = 1.618,
  exo.ir100.H = 0.7345,
  exo.ir100.O = 0.5695,
  exo.ir100.W = 0.2891,
  log.exo.ir100.B = log(1.618),
  log.exo.ir100.H = log(0.7345),
  log.exo.ir100.O = log(0.5695),
  log.exo.ir100.W = log(0.2891),
  ### Total incidence rate
  ir100.B = 6.42,
  ir100.H = 2.04,
  ir100.O = 1.71,
  ir100.W = 0.73,
  log.ir100.B = log(6.42),
  log.ir100.H = log(2.04),
  log.ir100.O = log(1.71),
  log.ir100.W = log(0.73),
  ### Endogenous incidence rate
  endo.ir100.B = 6.42 - 1.618,
  endo.ir100.H = 2.04 - 0.7345,
  endo.ir100.O = 1.71 - 0.5695,
  endo.ir100.W = 0.73 - 0.2891,
  log.endo.ir100.B = log(6.42 - 1.618),
  log.endo.ir100.H = log(2.04 - 0.7345),
  log.endo.ir100.O = log(1.71 - 0.5695),
  log.endo.ir100.W = log(0.73 - 0.2891)

)


targets_plot_infos <- list(
  cc.dx = list(
    names = paste0("cc.dx.", c("B", "H", "O", "W")),
    window_size = 13
  ),
  cc.linked1m = list(
    names = paste0("cc.linked1m.", c("B", "H", "O", "W")),
    window_size = 13
  ),
  cc.vsupp = list(
    names = paste0("cc.vsupp.", c("B", "H", "O", "W")),
    window_size = 13
  ),
  i.prev.dx = list(
    names = paste0("i.prev.dx.", c("B", "H", "O", "W")),
    window_size = 13
  ),
  ir100.sti = list(
    names = c("ir100.gc", "ir100.ct"),
    window_size = 52
  ),
  cc.prep.ind = list(
    names = paste0("cc.prep.ind.", c("B", "H", "O", "W")),
    window_size = 13
  ),
  cc.prep = list(
    names = paste0("cc.prep.", c("B", "H", "O", "W")),
    window_size = 13
  ),
  disease.mr100 = list(
    names = "disease.mr100",
    window_size = 13
  )
)

# function to calculate the calibration target
mutate_calibration_targets <- function(d) {
  d %>% mutate(
    cc.dx.B         = i_dx__B / i__B,
    cc.dx.H         = i_dx__H / i__H,
    cc.dx.O         = i_dx__O / i__O,
    cc.dx.W         = i_dx__W / i__W,
    cc.linked1m.B   = linked1m__B / i_dx__B,
    cc.linked1m.H   = linked1m__H / i_dx__H,
    cc.linked1m.O   = linked1m__O / i_dx__O,
    cc.linked1m.W   = linked1m__W / i_dx__W,
    cc.vsupp.B      = i_sup__B / i_dx__B,
    cc.vsupp.H      = i_sup__H / i_dx__H,
    cc.vsupp.O      = i_sup__O / i_dx__O,
    cc.vsupp.W      = i_sup__W / i_dx__W,
    gc_s            = gc_s__B + gc_s__H + gc_s__O + gc_s__W,
    ir100.gc        = incid.gc / gc_s * 5200,
    ct_s            = ct_s__B + ct_s__H + ct_s__O + ct_s__W,
    ir100.ct        = incid.ct / ct_s * 5200,
    i.prev.dx.B     = i_dx__B / n__B,
    i.prev.dx.H     = i_dx__H / n__H,
    i.prev.dx.O     = i_dx__O / n__O,
    i.prev.dx.W     = i_dx__W / n__W,
    cc.prep.B       = s_prep__B / s_prep_elig__B,
    cc.prep.H       = s_prep__H / s_prep_elig__H,
    cc.prep.O       = s_prep__O / s_prep_elig__O,
    cc.prep.W       = s_prep__W / s_prep_elig__W,
    # Adding additional measures where denominator is all MSM
    cc.prep.B_all       = s_prep__B / n__B,
    cc.prep.H_all       = s_prep__H / n__H,
    cc.prep.O_all       = s_prep__O / n__O,
    cc.prep.W_all       = s_prep__W / n__W,

    prep_users      = s_prep__B + s_prep__H + s_prep__O + s_prep__W,
    prep_elig       = s_prep_elig__B + s_prep_elig__H + s_prep__O + s_prep_elig__W,
    cc.prep         = prep_users / prep_elig,
    prep_prop_ret1y = prep_ret1y / lag(prep_startat, 52),
    prep_prop_ret2y = prep_ret2y / lag(prep_startat, 104)
  )
}

process_one_calibration <- function(file_name, nsteps = 52) {
  # keep only the file name without extension and split around `__`
  name_elts <- fs::path_file(file_name) %>%
    fs::path_ext_remove() %>%
    strsplit(split = "__")

  scenario_name <- name_elts[[1]][2]
  batch_num <- as.numeric(name_elts[[1]][3])

  d <- as_tibble(readRDS(file_name))
  d <- d %>%
    filter(time >= max(time) - (nsteps + 52 * 3)) %>% # margin for prep_ret2y
    mutate_calibration_targets() %>%
    filter(time >= max(time) - nsteps) %>%
    select(c(sim, any_of(names(targets)))) %>%
    group_by(sim) %>%
    summarise(across(
      everything(),
      ~ mean(.x, na.rm = TRUE)
    )) %>%
    mutate(
      scenario_name = scenario_name,
      batch = batch_num
    )

  return(d)
}

# required trackers for the calibration step
# source("R/utils-epi_trackers.R")
# source("/Users/wms1212/Desktop/ChiSTIG_model/epimodel/R/utils-epi_trackers.R")


# Named list of trackers required for computing the calibration targets
# the `epi_` functions are function factories (see https://adv-r.hadley.nz/function-factories.html?q=factory#function-factories). They take as argument the `race`
# set to include in the calculation (1, 2, 3 or 1:3).
# They return a "tracker function". See the "Working with Custom Attributes and
# Summary Statistics in EpiModel" vignette from EpiModel
calibration_trackers <- list(
  n__B           = epi_n(1),
  n__H           = epi_n(2),
  n__O           = epi_n(3),
  n__W           = epi_n(4),
  i__B           = epi_i(1),
  i__H           = epi_i(2),
  i__O           = epi_i(3),
  i__W           = epi_i(4),
  i_dx__B        = epi_i_dx(1),
  i_dx__H        = epi_i_dx(2),
  i_dx__O        = epi_i_dx(3),
  i_dx__W        = epi_i_dx(4),
  i_sup__B       = epi_i_sup(1),
  i_sup__H       = epi_i_sup(2),
  i_sup__O       = epi_i_sup(3),
  i_sup__W       = epi_i_sup(4),
  linked1m__B    = epi_linked_time(3)(1),
  linked1m__H    = epi_linked_time(3)(2),
  linked1m__O    = epi_linked_time(3)(3),
  linked1m__W    = epi_linked_time(3)(4),
  gc_s__B        = epi_gc_s(c(0, 1))(1), # gc susceptible HIV+ and -
  gc_s__H        = epi_gc_s(c(0, 1))(2),
  gc_s__O        = epi_gc_s(c(0, 1))(3),
  gc_s__W        = epi_gc_s(c(0, 1))(4),
  ct_s__B        = epi_ct_s(c(0, 1))(1),
  ct_s__H        = epi_ct_s(c(0, 1))(2),
  ct_s__O        = epi_ct_s(c(0, 1))(3),
  ct_s__W        = epi_ct_s(c(0, 1))(4),
  s_prep__B      = epi_s_prep(1),
  s_prep__H      = epi_s_prep(2),
  s_prep__O      = epi_s_prep(3),
  s_prep__W      = epi_s_prep(4),
  s_prep_elig__B = epi_s_prep_elig(1),
  s_prep_elig__H = epi_s_prep_elig(2),
  s_prep_elig__O = epi_s_prep_elig(3),
  s_prep_elig__W = epi_s_prep_elig(4),
  prep_startat   = epi_prep_ret(0)(1:4),  # n starting at `at`
  prep_ret1y     = epi_prep_ret(52)(1:4), # n starting at `at - 52`
  prep_ret2y     = epi_prep_ret(104)(1:4) # n starting at `at - 104`
)


###############################
#    H P C   C O N F I G S    #
###############################

# Must be sourced **AFTER** "./R/utils-0_project_settings.R"

swf_configs_quest <- function(partition =  yaml$hpc_partition,
                              account = yaml$hpc_account,
                              r_version = yaml$hpc_r_version,
                              conda_proj = yaml$hpc_conda_proj,
                              mail_user = yaml$mail_user) {

  hpc_configs <- list()
  hpc_configs[["default_sbatch_opts"]] <-  list(
    "partition" = partition,
    "account" = account,
    "mail-type" = "FAIL"
  )

  if (!is.null(mail_user)) {
    hpc_configs[["default_sbatch_opts"]][["mail-user"]] <- mail_user
  }

  hpc_configs[["renv_sbatch_opts"]] <- EpiModelHPC:::swf_renv_sbatch_opts()

  hpc_configs[["r_loader"]] <- c(
    "module purge all",
    paste0("module load R/", r_version),
    "module load git"
  )

  if (!is.null(conda_proj)) {
    hpc_configs[["r_loader"]] <- c(hpc_configs[["r_loader"]], c(
      "module load python-miniconda3",
      paste0("source activate /projects/", conda_proj ,"/pythonenvs/env1")
    ))
  }

  return(hpc_configs)
}

######

hpc_configs <- swf_configs_quest(
  partition = yaml$hpc_partition, # ASK ABOUT THIS
  r_version = yaml$hpc_r_version,
  mail_user = yaml$mail_suer
)
#
# hpc_configs <- EpiModelHPC::swf_configs_hyak(
#   hpc = "mox",
#   partition = "ckpt",
#   r_version = "4.1.2",
#   mail_user = mail_user
# )

# hpc_configs <- EpiModelHPC::swf_configs_hyak(
#   hpc = "klone",
#   partition = "ckpt",
#   r_version = "4.1.1",
#   mail_user = mail_user
# )
#
# hpc_configs <- EpiModelHPC::swf_configs_rsph(
#   partition = c("epimodel", "preemptable")[1],
#   r_version = "4.3.0",
#   mail_user = mail_user
#   )


#############################################
#    S C E N A R I O S   O U T C O M E S    #
#############################################

# create the elements of the outcomes step by step
mutate_outcomes <- function(d) {
  d %>%
    mutate(
      cc.prep.B  = s_prep__B / s_prep_elig__B,
      cc.prep.H  = s_prep__H / s_prep_elig__H,
      cc.prep.W  = s_prep__W / s_prep_elig__W,
      prep_users = s_prep__B + s_prep__H + s_prep__W
    )
}

# make the outcomes calculated on the same year
make_last_year_outcomes <- function(d) {
  d %>%
    filter(time >= max(time) - 52) %>%
    group_by(scenario_name, batch_number, sim) %>%
    summarise(across(starts_with("cc.prep."), mean)) %>%
    ungroup()
}

# make the outcomes cumulative over the intervention period
make_cumulative_outcomes <- function(d) {
  d %>%
    filter(time >= intervention_start) %>%
    group_by(scenario_name, batch_number, sim) %>%
    summarise(
      cuml_prep_users = sum(prep_users, na.rm = TRUE)
    ) %>%
    ungroup()
}

# each batch of sim is processed in turn
# the output is a data frame with one row per simulation in the batch
# each simulation can be uniquely identified with `scenario_name`,
# `batch_number` and `sim` (all 3 are needed)
process_one_scenario_batch <- function(scenario_infos) {
  sim <- readRDS(scenario_infos$file_name)
  d_sim <- as_tibble(sim)
  d_sim <- mutate_outcomes(d_sim)
  d_sim <- mutate(
    d_sim,
    scenario_name = scenario_infos$scenario_name,
    batch_number = scenario_infos$batch_number
  )

  d_last <- make_last_year_outcomes(d_sim)
  d_cum <- make_cumulative_outcomes(d_sim)

  left_join(d_last, d_cum, by = c("scenario_name", "batch_number", "sim"))
}

