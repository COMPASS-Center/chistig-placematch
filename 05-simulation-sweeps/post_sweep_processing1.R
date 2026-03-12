# Libraries --------------------------------------------------------------------
library("tidyverse")
#library("dplyr")
library("future.apply")
library("EpiModel")
library("EpiModelHIV")
library(parallel)

options(flush.console = TRUE)

num_workers <- 15


### ---------------------------------------
# 1. Netstats 
### ---------------------------------------
# Data ------------------------------------------------------------------------
netstats_dir <- "/projects/p32153/chistig-placematch/05-simulation-sweeps/input/"

netstats_files <- list.files(netstats_dir)
netstats_files <- netstats_files[stringr::str_detect(netstats_files, "netstats")]

for (i in 1:length(netstats_files)) {
  print(i)
  this_netstats <- readRDS(paste(netstats_dir, netstats_files[i], sep = ""))

  this_ndf <- data.frame(siminstance = as.numeric(stringr::str_extract(netstats_files[i], "\\d+")),
                         venues_main = this_netstats$main$fuzzynodematch_venues.all,
                         venues_casual = this_netstats$casl$fuzzynodematch_venues.all,
                         venues_onetime = this_netstats$inst$fuzzynodematch_venues.all)

  if (i == 1) {
    netstats_df <- this_ndf
  } else {
    netstats_df <- dplyr::bind_rows(netstats_df, this_ndf)
  }
}

netstats_df <- netstats_df %>%
  dplyr::arrange(siminstance)

write.csv(netstats_df, "/projects/p32153/chistig-placematch/05-simulation-sweeps/data_processing/target_stat_values.csv")


### ---------------------------------------
# 2. Sim targets 
### ---------------------------------------

# Necessary files
context <- "local"
est_dir <- "blah"
prep_start = 52*2

source("/projects/p32153/chistig-placematch/utils/utils-epi_trackers.R")

# Controls
source("/projects/p32153/chistig-placematch/utils/utils-targets.R")

# Directory containing runs
this_dir <- "/projects/p32153/chistig-placematch/05-simulation-sweeps/emews/experiments/venues41instancesweep_9mar2026/"

instance_dirs <- list.files(this_dir)
instance_dirs <- instance_dirs[stringr::str_detect(instance_dirs, "^instance")]


results_list <- mclapply(1:length(instance_dirs), function(z) {
  print(z)
  tryCatch({
    this_simout <- tryCatch(
      readRDS(paste(this_dir, instance_dirs[z], "/simout.rds", sep = "")),
      error = function(e) NULL
    )

    if (is.null(this_simout)) return(NULL)

    this_date <- this_simout$sim_date
    this_simout$sim_date <- NULL

    out_txt  <- readLines(paste(this_dir, instance_dirs[z], "/out.txt", sep = ""), warn = FALSE)
    run_info <- out_txt[stringr::str_detect(out_txt, "^Running Rscript")]

    runno       <- as.numeric(stringr::str_extract(run_info, "(?<=--runno\\s)\\d+"))
    siminstance <- as.numeric(stringr::str_extract(run_info, "(?<=--siminstance\\s)\\d+"))
    replicate   <- as.numeric(stringr::str_extract(run_info, "(?<=--replicate\\s)\\d+"))

    tibble::as_tibble(EpiModel::process_out.net(this_simout)) %>%
      mutate_calibration_targets() %>%
      dplyr::mutate(
        i.prev.disp.BW = i.prev.B - i.prev.W,
        i.prev.disp.HW = i.prev.H - i.prev.W,
        cc.dx.B = ifelse(is.nan(cc.dx.B), 0, cc.dx.B),
        cc.dx.H = ifelse(is.nan(cc.dx.H), 0, cc.dx.H),
        cc.dx.O = ifelse(is.nan(cc.dx.O), 0, cc.dx.O),
        cc.dx.W = ifelse(is.nan(cc.dx.W), 0, cc.dx.W),
        num_diagnosed.B = cc.dx.B * i.num.B,
        num_diagnosed.H = cc.dx.H * i.num.H,
        num_diagnosed.O = cc.dx.O * i.num.O,
        num_diagnosed.W = cc.dx.W * i.num.W,
        num_diagnosed = num_diagnosed.B + num_diagnosed.H + num_diagnosed.O + num_diagnosed.W,
        cc.dx = num_diagnosed / i.num,
        runno = runno,
        siminstance = siminstance,
        replicate = replicate,
        date = this_date
      )
  }, error = function(e) {
    message("Error in iteration ", z, ": ", e$message)
    NULL
  })
}, mc.cores = num_workers)

print("Done processing the simout.rds files...")

sim_targets <- dplyr::bind_rows(Filter(Negate(is.null), results_list))

print("Done creating the sim_targets object...")

mean_incid <-  sim_targets %>%
  # mutate(sim = treat) %>%
  mutate(total.incid.B = incid.B + exo.incid.B,
         total.incid.H = incid.H + exo.incid.H,
         total.incid.O = incid.O + exo.incid.O,
         total.incid.W = incid.W + exo.incid.W,
         total.incid = incid + exo.incid) %>%
  group_by(siminstance, replicate, time) %>%
  summarize(incid.B = mean(incid.B),
            exo.incid.B = mean(exo.incid.B),
            total.incid.B = mean(total.incid.B),
            endo.ir100.B = mean(endo.ir100.B),
            exo.ir100.B = mean(exo.ir100.B),
            ir100.B = mean(ir100.B),

            incid.H = mean(incid.H),
            exo.incid.H = mean(exo.incid.H),
            total.incid.H = mean(total.incid.H),
            endo.ir100.H = mean(endo.ir100.H),
            exo.ir100.H = mean(exo.ir100.H),
            ir100.H = mean(ir100.H),

            incid.O = mean(incid.O),
            exo.incid.O = mean(exo.incid.O),
            total.incid.O = mean(total.incid.O),
            endo.ir100.O = mean(endo.ir100.O),
            exo.ir100.O = mean(exo.ir100.O),
            ir100.O = mean(ir100.O),

            incid.W = mean(incid.W),
            exo.incid.W = mean(exo.incid.W),
            total.incid.W = mean(total.incid.W),
            endo.ir100.W = mean(endo.ir100.W),
            exo.ir100.W = mean(exo.ir100.W),
            ir100.W = mean(ir100.W),

            incid = mean(incid),
            exo.incid = mean(exo.incid),
            total.incid = mean(total.incid),
            endo.ir100 = mean(endo.ir100),
            exo.ir100 = mean(exo.ir100),
            ir100 = mean(ir100)



  ) %>%
  ungroup()

print("Done creating the mean_incid...")

mean_incid2 <- mean_incid %>% dplyr::filter(time > 2900)

print("Done creating the mean_incid2...")

saveRDS(mean_incid2, "/projects/p32153/chistig-placematch/05-simulation-sweeps/data_processing/mean_incid_intermediary.rds")

print("Done saving the mean_incid2 as an intermediary data object...")

sim_targets_final <- sim_targets %>% dplyr::filter(time > (max(time)-520)) %>%
  dplyr::select(treat = siminstance, trial = replicate, time, dplyr::everything())

print("Done creating the sim_targets_final object...")

write.csv(sim_targets_final, "/projects/p32153/chistig-placematch/05-simulation-sweeps/data_processing/sim_targets.csv")

print("Done writing the sim_targets_final object...")
