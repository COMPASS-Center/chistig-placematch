# Libraries --------------------------------------------------------------------
library("tidyverse")
library("future.apply")
library("EpiModelHIV")

# Data ------------------------------------------------------------------------
netstats <- readRDS("./01-networks-estimation/netstats.rds")

# Necessary files
context <- "local"
est_dir <- "blah"
prep_start = 52*2
source("./utils/utils-epi_trackers.R")
source("./utils/utils-targets.R") # generate `path_to_est`, `param` and `initchis`

# Directory containing runs
this_dir <- "./02-network-edge-calibration/interim/"

files <- list.files(this_dir)
files <- files[stringr::str_detect(files, "^simout")]

process_start <- Sys.time()

# This is a vector to store the number of unique nodes that were in the network
# over the course of each simulation
max_ids <- c()

# For each control simulation file
for (i in 1:length(files)) {

  print(i)

  # Read in simulation data
  this_file <- readRDS(paste(this_dir, files[[i]], sep = "/"))

  # How many unique nodes were in this simulation? Store value in `max_ids`
  max_ids[[i]] <- max(this_file[[1]]$attr$numeric.id)

  # Process various outcome and diagnostic measures
  this_targets <- as.data.frame(this_file$epi)
  colnames(this_targets) <- names(this_file$epi)



  this_targets <- this_targets %>%
    dplyr::mutate(time = 1:dplyr::n(),
                  treat = case_when(str_detect(files[[i]], "-apps_") ~ "Apps",
                                    str_detect(files[[i]], "-venuesapps_") ~ "Venues and Apps",
                                    str_detect(files[[i]], "-control_") ~ "Control",
                                    str_detect(files[[i]], "-venues_") ~ "Venues",
                                    TRUE ~ NA),
                  # Which run within calibration set
                  run = as.numeric(stringr::str_replace(stringr::str_extract(files[[i]], "no-\\d*"), "no-", "")),
                  # Which calibration set (set of ERGM fits)
                  calset = as.numeric(stringr::str_replace(stringr::str_extract(files[[i]], "set-\\d*"), "set-", ""))
                  ) %>%
    dplyr::select(calset, treat, run, time, dplyr::everything())


  if (i == 1) {
    sim_targets <- this_targets
  } else {
    sim_targets <- dplyr::bind_rows(sim_targets, this_targets)
  }
}

sim_targets_end <- Sys.time()

# Main Partnerships ------------------------------------------------------------

sim_targets %>%
  ggplot(aes(x = time, y = mean_deg_main, color = treat)) +
  geom_line(alpha = .2) +
  geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  geom_hline(yintercept = 0.239467091) +
  geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  filter(treat %in% c("Venues", "Control")) %>%
  ggplot(aes(x = time, y = mean_deg_main, color = treat)) +
  geom_line(alpha = .2) +
  geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  geom_hline(yintercept = 0.239467091) +
  geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

# Casual Partnerships ----------------------------------------------------------

sim_targets %>%
  ggplot(aes(x = time, y = mean_deg_cas, color = treat)) +
  geom_line(alpha = .4) +
  geom_hline(yintercept = 0.271944955, linetype = "dotted") +
  geom_hline(yintercept = 0.339925924) +
  geom_hline(yintercept = 0.407906894, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()


sim_targets %>%
  filter(treat == c("Venues", "Control")) %>%
  ggplot(aes(x = time, y = mean_deg_cas, color = treat)) +
  geom_line(alpha = .4) +
  geom_hline(yintercept = 0.271944955, linetype = "dotted") +
  geom_hline(yintercept = 0.339925924) +
  geom_hline(yintercept = 0.407906894, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  filter(treat == "Venues") %>%
  ggplot(aes(x = time, y = mean_deg_cas, color = treat)) +
  geom_line(alpha = .4) +
  geom_hline(yintercept = 0.271944955, linetype = "dotted") +
  geom_hline(yintercept = 0.339925924) +
  geom_hline(yintercept = 0.407906894, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

# One-Time Partnerships --------------------------------------------------------

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime, color = treat)) +
  geom_line(alpha = .4) +
  geom_hline(yintercept = netstats$inst$edges) +
  labs(title = "Number of Edges, Onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  filter(treat %in% c("Venues", "Control")) %>%
  ggplot(aes(x = time, y = n_edges_onetime, color = treat)) +
  geom_line(alpha = .4) +
  geom_hline(yintercept = netstats$inst$edges) +
  labs(title = "Number of Edges, Onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()


# Compositional Checks ---------------------------------------------------------

### Mean Degree (Main), by Race

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.B, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships (Both Black)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.H, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships (Both Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.O, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships (Both Other)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.W, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships (Both White)",
       x = "Time",
       y = NULL) +
  theme_classic()


sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.BH, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships (Black-Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.BO, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships (Black-Other)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.BW, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships (Black-White)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.HO, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships (Hispanic-Other)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.HW, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships (Hispanic-White)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.OW, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships (Other-White)",
       x = "Time",
       y = NULL) +
  theme_classic()

### Mean Degree (Casual), by Race

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.B, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships (Both Black)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.H, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships (Both Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.O, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships (Both Other)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.W, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships (Both White)",
       x = "Time",
       y = NULL) +
  theme_classic()


sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.BH, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships (Black-Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.BO, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships (Black-Other)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.BW, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships (Black-White)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.HO, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships (Hispanic-Other)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.HW, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships (Hispanic-White)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.OW, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships (Other-White)",
       x = "Time",
       y = NULL) +
  theme_classic()

### Mean Degree (One-Time), by Race

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.B, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Onetime Partnerships (Both Black)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.H, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Onetime Partnerships (Both Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.O, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Onetime Partnerships (Both Other)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.W, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Onetime Partnerships (Both White)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.BH, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Onetime Partnerships (Black-Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.BO, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Onetime Partnerships (Black-Other)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.BW, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Onetime Partnerships (Black-White)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.HO, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Onetime Partnerships (Hispanic-Other)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.HW, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Onetime Partnerships (Hispanic-White)",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.OW, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Onetime Partnerships (Other-White)",
       x = "Time",
       y = NULL) +
  theme_classic()


### Mean Degree (Main), by Age

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.under21, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.over21, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_main.diffage, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Main Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()


### Mean Degree (Casual), by Age

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.under21, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.over21, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_casual.diffage, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, Casual Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()


### Mean Degree (One-Time), by Age

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.under21, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, One-Time Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.over21, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, One-Time Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  ggplot(aes(x = time, y = n_edges_onetime.diffage, color = treat)) +
  geom_line(alpha = .2) +
  labs(title = "Mean Degree, One-Time Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()


# Quantitatively Assessing Best Calibration Set --------------------------------

step2_benchmarks <- c(mean_deg_main_lower = 0.200339524, mean_deg_main = 0.239467091, mean_deg_main_upper = 0.278594658,
                      mean_deg_cas_lower = 0.271944955, mean_deg_cas = 0.339925924, mean_deg_cas_upper = 0.407906894,
                      n_edges_onetime = 77.94033)


sim_targets$mean_deg_main - step2_benchmarks[which(step2_benchmarks$var == "mean_deg_main" & step2_benchmarks$bound == "center"), 3]

cal_results <- sim_targets %>%
  dplyr::mutate(main_dev = mean_deg_main - step2_benchmarks["mean_deg_main"],
                main_in_bounds = mean_deg_main > step2_benchmarks["mean_deg_main_lower"] & mean_deg_main < step2_benchmarks["mean_deg_main_upper"],
                cas_dev = mean_deg_cas - step2_benchmarks["mean_deg_cas"],
                cas_in_bounds = mean_deg_cas > step2_benchmarks["mean_deg_cas_lower"] & mean_deg_cas < step2_benchmarks["mean_deg_cas_upper"],
                onetime_dev = n_edges_onetime - step2_benchmarks["n_edges_onetime"]) %>%
  dplyr::group_by(calset, treat) %>%
  dplyr::summarize(prop_main_dev = mean(main_dev, na.rm = TRUE),
                   prop_main_in_bounds = mean(main_in_bounds, na.rm = TRUE),
                   prop_cas_dev = mean(cas_dev, na.rm = TRUE),
                   prop_cas_in_bounds = mean(cas_in_bounds, na.rm = TRUE),
                   mean_onetime_dev = mean(onetime_dev, na.rm = TRUE)) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(treat) %>%
  dplyr::mutate(best_main_dev = prop_main_dev == min(prop_main_dev),
                best_main_in_bounds = prop_main_in_bounds == max(prop_main_in_bounds),
                best_cas_dev = prop_cas_dev == min(prop_cas_dev),
                best_cas_in_bounds = prop_cas_in_bounds == max(prop_cas_in_bounds),
                best_onetime_dev = mean_onetime_dev == min(mean_onetime_dev)) %>%
  dplyr::ungroup()

View(cal_results)

# At this point, we recommend manually inspecting `cal_results` to see which
# set of ERGM fits works best, then manually selecting the `rds` file containing
# the corresponding `netest` object. But if you want this script to select said
# `rds` file automatically, the following code will do so:

which_best <- cal_results %>%
  dplyr::group_by(treat) %>%
  dplyr::mutate(num_best = best_main_dev + best_main_in_bounds + best_cas_dev + best_cas_in_bounds + best_onetime_dev) %>%
  dplyr::mutate(best = num_best == max(num_best)) %>%
  dplyr::ungroup()

### Is there a single calibration set that produces the best fit for all four
### treatment groups?
##### Note that some users may only be interested in comparing one treatment
##### against the control model, in which case we don't need to worry about
##### the output for the other treatments. So let's specify which treatment(s)
##### we care about here. Also note that our control model should be the same
##### for all calibration sets, so we don't need to assess its output here.
##### Accordingly, we don't store "Control" in the vector below:
active_treatments <- c("Apps", "Venues", "Venues and Apps")

which_best2 <- which_best %>%
  dplyr::filter(treat %in% active_treatments)

if (length(unique(which_best2$calset)) == 1) {
  ##### If there is a single calibration set that produces the best fit for all
  ##### treatments, save the `netest`/`rds` fies corresponding to that
  ##### calibration set.

  best_calset <- unique(which_best2$calset)

  # Check if `output` directory exists, create if missing:
  if (!("output" %in% list.files("./02-network-edge-calibration/"))) {
    dir.create("./02-network-edge-calibration/output")
  }

  ##### Saving `netstats` for best calibration set
  netstats_path <- paste("netstats_", best_calset, ".rds", sep = "")
  best_netstats <- readRDS(paste(this_dir, netstats_path, sep = ""))
  saveRDS(best_netstats, file = "./02-network-edge-calibration/output/netstats-local.rds")

  ##### Saving control model for best calibration set
  control_path <- paste("netest-control_", best_calset, ".rds", sep = "")
  best_control <- readRDS(paste(this_dir, control_path, sep = ""))
  saveRDS(best_control, file = "./02-network-edge-calibration/output/basic_netest-local.rds")

  if ("Venues" %in% active_treatments) {
  ##### Saving venues-only model for best calibration set
      venues_path <- paste("netest-venues_", best_calset, ".rds", sep = "")
      best_venues <- readRDS(paste(this_dir, venues_path, sep = ""))
      saveRDS(best_venues, file = "./02-network-edge-calibration/output/venue_only_netest-local.rds")
  }

  if ("Apps" %in% active_treatments) {
  ##### Saving apps-only model for best calibration set
      apps_path <- paste("netest-apps_", best_calset, ".rds", sep = "")
      best_apps <- readRDS(paste(this_dir, apps_path, sep = ""))
      saveRDS(best_apps, file = "./02-network-edge-calibration/output/apps_only_netest-local.rds")
  }

  if ("Venues and Apps" %in% active_treatments) {
  ##### Saving venues and apps model for best calibration set
      venuesapps_path <- paste("netest-venuesapps_", best_calset, ".rds", sep = "")
      best_va <- readRDS(paste(this_dir, venuesapps_path, sep = ""))
      saveRDS(best_va, file = "./02-network-edge-calibration/output/venues_apps_netest-local.rds")
  }


} else {
  base::message("Best edge calibration numbers span multiple ERGM specifications. Please examine `which_best2`, make necessary adjustments to `step1_edge_calibration.R`, and retry edge calibration process.")
}









