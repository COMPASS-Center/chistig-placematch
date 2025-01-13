# Libraries --------------------------------------------------------------------
library("tidyverse")
library("future.apply")
library("EpiModelHIV")

# Data ------------------------------------------------------------------------
#sim_targets <- readRDS("./data/intermediate/alldata_oct26.rds")
# netstats <- readRDS("~/Desktop/chiSTIG_hpc/data/intermediate/estimates/netstats-level-local_00018_00014_alt.rds")
netstats <- readRDS("~/Desktop/chiSTIG_hpc/data/intermediate/estimates/netstats-local.rds")



# Necessary files
context <- "local"
est_dir <- "blah"
prep_start = 52*2
source("~/Desktop/chiSTIG_hpc/R/utils-chistig_basic_inputs.R") # generate `path_to_est`, `param` and `initchis`
# path_to_est <- "./data/intermediate/estimates/basic_netest-local.rds"
# path_to_est      <- "/Users/wms1212/Desktop/ChiSTIG_model/epimodel/data/intermediate/estimates/venue_only_netest-local.rds"
path_to_est <- "~/Desktop/chiSTIG_hpc/data/intermediate/estimates/basic_netest-local.rds"
# Controls
source("~/Desktop/chiSTIG_hpc/R/utils-targets.R")


# Directory containing runs
this_dir <- "~/Desktop/chiSTIG_data/directory"

files <- list.files(this_dir)
files <- files[stringr::str_detect(files, "^test23")]

process_start <- Sys.time()

# This is a vector to store the number of unique nodes that were in the network
# over the course of each simulation
max_ids <- c()

# For each control simulation file
for (i in 1:length(files)) {

  # Read in simulation data
  this_file <- readRDS(paste(this_dir, files[[i]], sep = "/"))

  # How many unique nodes were in this simulation? Store value in `max_ids`
  max_ids[[i]] <- max(this_file[[1]]$attr$numeric.id)

  # Process various outcome and diagnostic measures
  this_targets <- as.data.frame(this_file[[1]]$epi) %>%
    mutate_calibration_targets() %>%
    mutate(# AIDS-Related Deaths, Total
           dep.AIDS = dep.AIDS.on.tx + dep.AIDS.off.tx,

           i.prev.disp.BW = i.prev.B - i.prev.W,
           i.prev.disp.HW = i.prev.H - i.prev.W,
           cc.dx.B = ifelse(is.nan(cc.dx.B), 0, cc.dx.B),
           cc.dx.H = ifelse(is.nan(cc.dx.H), 0, cc.dx.H),
           cc.dx.O = ifelse(is.nan(cc.dx.O), 0, cc.dx.O),
           cc.dx.W = ifelse(is.nan(cc.dx.W), 0, cc.dx.W),

           num_diagnosed.B = cc.dx.B*i.num.B,
           num_diagnosed.H = cc.dx.H*i.num.H,
           num_diagnosed.O = cc.dx.O*i.num.O,
           num_diagnosed.W = cc.dx.W*i.num.W,
           num_diagnosed = num_diagnosed.B + num_diagnosed.H + num_diagnosed.O
           + num_diagnosed.W,
           cc.dx = num_diagnosed/i.num,
           sim = i,

           treat = case_when(str_detect(files[[i]], "apps") ~ "Apps",
           str_detect(files[[i]], "both") ~ "Venues and Apps",
           str_detect(files[[i]], "control") ~ "Control",
           str_detect(files[[i]], "venues") ~ "Venues",
           TRUE ~ NA),

           trial = str_extract(files[[i]], "calset\\d*"),
           trial = str_extract(files[[i]], "\\d*.rds")#,
           #target_shift = stringr::str_detect(files[[i]], "plus")
           ) %>%
 mutate(trial = as.numeric(str_replace_all(files[[i]], "_", "")))

this_targets$trial <- as.numeric(str_replace_all(this_targets$trial, "calset", ""))

  this_targets$time <- 1:nrow(this_targets)

  if (i == 1) {
    sim_targets <- this_targets
  } else {
    sim_targets <- dplyr::bind_rows(sim_targets, this_targets)
  }
}

sim_targets_end <- Sys.time()

# Annualized Incidence Counts --------------------------------------------------

mean_incid <-  sim_targets %>%
  # mutate(sim = treat) %>%
  mutate(total.incid.B = incid.B + exo.incid.B,
         total.incid.H = incid.H + exo.incid.H,
         total.incid.O = incid.O + exo.incid.O,
         total.incid.W = incid.W + exo.incid.W) %>%
  group_by(treat, trial, time) %>%
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

            dep.AIDS.on.tx = mean(dep.AIDS.on.tx),
            dep.AIDS.off.tx = mean(dep.AIDS.off.tx),
            dep.AIDS = mean(dep.AIDS)

            # For Nov 11 Check
            #original = mean(original)


  ) %>%
  ungroup()

mean_incid2 <- mean_incid %>% dplyr::filter(time > 3000)


for (j in 1:nrow(mean_incid2)) {
  this_row <- mean_incid2[j,]
  past_year <- mean_incid2 %>%
    filter(time <= this_row$time & time > (this_row$time-52)) %>%
    filter(treat == this_row$treat)
  sums <- as.data.frame(t(colSums(past_year[,3:ncol(past_year)])))
  sums$treat <- this_row$treat
  sums$trial <- this_row$trial
  sums$time <- this_row$time

  if (j == 1) {
    annual_incid <- sums
  } else {
    annual_incid <- dplyr::bind_rows(annual_incid, sums)
  }
}

for (j in 1:nrow(mean_incid2)) {
  this_row <- mean_incid2[j,]
  past_year <- mean_incid2 %>%
    filter(time <= this_row$time & time > (this_row$time-52)) %>%
    filter(treat == this_row$treat) %>%
    filter(trial == this_row$trial)
  means <- as.data.frame(t(colMeans(past_year[,3:ncol(past_year)])))
  means$treat <- this_row$treat
  means$time <- this_row$time
  means$trial <- this_row$trial

  if (j == 1) {
    annual_incid2 <- means
  } else {
    annual_incid2 <- dplyr::bind_rows(annual_incid2, means)
  }
}

annual_incid2$total.incid.rate.dispar.BW <- annual_incid2$total.incid.B - annual_incid2$total.incid.W
annual_incid2$total.incid.rate.dispar.HW <- annual_incid2$total.incid.H - annual_incid2$total.incid.W

annual_incid2$ir100.dispar.BW <- annual_incid2$ir100.B - annual_incid2$ir100.W
annual_incid2$ir100.dispar.HW <- annual_incid2$ir100.H - annual_incid2$ir100.W

process_end <- Sys.time()


# sim_targets <- sim_targets %>% dplyr::filter(time >= 3000)
# annual_incid <- annual_incid %>% dplyr::filter(time >= 3000)
# annual_incid2 <- annual_incid2 %>% dplyr::filter(time >= 3000)

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = mean_deg_main, color = treat)) +
  geom_line(alpha = .2) +
  geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  geom_hline(yintercept = 0.239467091) +
  geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()# +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  filter(treat %in% c("Apps", "Control")) %>%
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
  # filter(treat == "Trial 3" | treat == "Trial 4") %>%
  # filter(treat == "Apps") %>%
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
  # filter(treat == "Trial 3" | treat == "Trial 4") %>%
  filter(treat == c("Apps", "Control")) %>%
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
  # filter(treat == "Trial 3" | treat == "Trial 4") %>%
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


sim_targets %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime, color = treat)) +
  geom_line(alpha = .4) +
  # geom_hline(yintercept = 0.271944955, linetype = "dotted") +
  # geom_hline(yintercept = 0.339925924) +
  # geom_hline(yintercept = 0.407906894, linetype = "dotted") +
  geom_hline(yintercept = netstats$inst$edges) +
  labs(title = "Number of Edges, Onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic()

sim_targets %>%
  filter(treat %in% c("Apps", "Control")) %>%
  ggplot(aes(x = time, y = n_edges_onetime, color = treat)) +
  geom_line(alpha = .4) +
  # geom_hline(yintercept = 0.271944955, linetype = "dotted") +
  # geom_hline(yintercept = 0.339925924) +
  # geom_hline(yintercept = 0.407906894, linetype = "dotted") +
  geom_hline(yintercept = netstats$inst$edges) +
  labs(title = "Number of Edges, Onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic() #+
  facet_grid(cols = vars(trial))



#### COMPOSITIONAL CHECKS

######### Mean degree main by race
sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.B, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships (Both Black)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.H, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships (Both Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.O, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships (Both Other)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.W, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships (Both White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))


sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.BH, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships (Black-Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.BO, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships (Black-Other)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.BW, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships (Black-White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.HO, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships (Hispanic-Other)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.HW, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships (Hispanic-White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.OW, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Main Partnerships (Other-White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

######### Mean degree Casual by race
sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.B, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships (Both Black)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.H, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships (Both Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.O, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships (Both Other)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.W, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships (Both White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))


sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.BH, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships (Black-Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.BO, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships (Black-Other)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.BW, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships (Black-White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.HO, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships (Hispanic-Other)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.HW, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships (Hispanic-White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.OW, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Casual Partnerships (Other-White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

######### Mean degree Onetime by race
sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.B, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Onetime Partnerships (Both Black)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.H, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Onetime Partnerships (Both Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.O, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Onetime Partnerships (Both Other)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.W, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Onetime Partnerships (Both White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))


sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.BH, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Onetime Partnerships (Black-Hispanic)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.BO, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Onetime Partnerships (Black-Other)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.BW, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Onetime Partnerships (Black-White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.HO, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Onetime Partnerships (Hispanic-Other)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.HW, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Onetime Partnerships (Hispanic-White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.OW, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, Onetime Partnerships (Other-White)",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))


######### Mean degree Main by age
sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.under21, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.over21, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_main.diffage, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))


######### Mean degree casual by age
sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.under21, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.over21, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_casual.diffage, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))



######### Mean degree onetime by age
sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.under21, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.over21, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))

sim_targets %>%
  # filter(treat == "Trial 1" | treat == "Trial 2") %>%
  # filter(treat == "Apps") %>%
  ggplot(aes(x = time, y = n_edges_onetime.diffage, color = treat)) +
  geom_line(alpha = .2) +
  # geom_hline(yintercept = 0.200339524, linetype = "dotted") +
  # geom_hline(yintercept = 0.239467091) +
  # geom_hline(yintercept = 0.278594658, linetype = "dotted") +
  labs(title = "Mean Degree, onetime Partnerships",
       x = "Time",
       y = NULL) +
  theme_classic() +
  facet_grid(cols = vars(original))




