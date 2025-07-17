# Libraries --------------------------------------------------------------------
library("tidyverse")
library("future.apply")
library("EpiModelHIV")

# Data ------------------------------------------------------------------------
netstats <- readRDS("./03-epimodel-parameter-calibration/data/intermediate/estimates/netstats-local.rds")

# Necessary files
context <- "local"
est_dir <- "blah"
prep_start = 52*2
source("./03-epimodel-parameter-calibration/utils_03.R")
path_to_est <- "./03-epimodel-parameter-calibration/data/intermediate/estimates/basic_netest-local.rds"

# This is where the user should specify the directory containing calibration runs
this_dir <- "./03-epimodel-parameter-calibration/data/intermediate/calibration/"

files <- list.files(this_dir)
files <- files[stringr::str_detect(files, "rds$")]

for (i in 1:length(files)) {
  this_targets <- tibble::as_tibble(readRDS(paste(this_dir, files[[i]], sep = "/"))) %>%
    mutate_calibration_targets() %>%
    mutate(i.prev.disp.BW = i.prev.B - i.prev.W,
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
           ### Lines for manual calibration data
           treat = stringr::str_extract(files[[i]], "^*\\d"),
           trial = stringr::str_extract(files[[i]], "\\d*.rds"),
           trial = stringr::str_replace_all(trial, ".rds", "")
           )

  this_targets$trial <- as.numeric(str_replace_all(this_targets$trial, "calset", ""))

  if (i == 1) {
    sim_targets <- this_targets
  } else {
    sim_targets <- dplyr::bind_rows(sim_targets, this_targets)
  }
}


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



  ) %>%
  ungroup()


for (j in 1:nrow(mean_incid)) {
  this_row <- mean_incid[j,]
  past_year <- mean_incid %>%
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

for (j in 1:nrow(mean_incid)) {
  this_row <- mean_incid[j,]
  past_year <- mean_incid %>%
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


###########################################################
#    D I A G N O S T I C   V I S U A L I Z A T I O N S    #
###########################################################


# Custom function for generating summary plots ---------------------------------
target_plot <- function(data, group, var, benchmark = NULL, title = NULL,
                        target_range = NULL) {

  # Create placeholder of variable we need
  data2 <- data[, c("time", group, var)]
  colnames(data2) <- c("time", "venues_treat", "this_var")

  if (is.null(target_range)) {

    this_plot <- data2 %>%
      group_by(venues_treat, time) %>%
      summarize(this_var = median(this_var)) %>%
      dplyr::ungroup() %>%
      ggplot(aes(x = time, y = this_var, color = as.factor(venues_treat))) +
      geom_line() +
      theme_minimal() +
      labs(y = var)

  } else {
    this_plot <- data2 %>%
      group_by(venues_treat, time) %>%
      summarize(this_var = median(this_var)) %>%
      dplyr::ungroup() %>%
      ggplot(aes(x = time, y = this_var, color = as.factor(venues_treat))) +
      geom_ribbon(aes(x = time, ymin = sort(target_range)[[1]], ymax = sort(target_range)[[2]]), fill = "grey", alpha = 0.15, linetype = 0) +
      geom_line() +
      theme_minimal() +
      labs(y = var)
  }

  if (!is.null(benchmark)) {
    this_plot <- this_plot +
      geom_hline(aes(yintercept = benchmark), color = "red")
  }

  if (!is.null(title)) {
    this_plot <- this_plot +
      ggtitle(title)
  }

  return(this_plot)
}


library(tidyverse)

sim_targets <- sim_targets %>%
  dplyr::filter(time >= 3000)
annual_incid <- annual_incid %>%
  dplyr::filter(time >= 3000)
annual_incid2 <- annual_incid2 %>%
  dplyr::filter(time >= 3000)

# Population Size --------------------------------------------------------------
i = 1

target_plot(data = sim_targets,
            group = "treat",
            var = "num",
            benchmark = 11612,
            title = paste("Plot ", i, ": Population Size", sep = ""))


# Proportion HIV+ Diagnosed ----------------------------------------------------

i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.dx",
            benchmark = 0.55333,
            title = paste("Plot ", i, ": Proportion of HIV+ that are Diagnosed", sep = ""))

i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.dx.B",
            benchmark = 0.546535643,
            title = paste("Plot ", i, ": Proportion of HIV+ that are Diagnosed (Black)", sep = ""))


i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.dx.H",
            benchmark = 0.5431367893,
            title = paste("Plot ", i, ": Proportion of HIV+ that are Diagnosed (Hispanic)", sep = ""))

i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.dx.O",
            benchmark = 0.5601310,
            title = paste("Plot ", i, ": Proportion of HIV+ that are Diagnosed (Other)", sep = ""))

i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.dx.W",
            benchmark = 0.5988779867,
            title = paste("Plot ", i, ": Proportion of HIV+ that are Diagnosed (White)", sep = ""))



# Proportion HIV+ Linked to Care in 1st Month ----------------------------------

i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.linked1m.B",
            benchmark = .828,
            title = paste("Plot ", i, ": Proportion of HIV+ Nodes Linked to Care within One Month (Black)", sep = ""))


i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.linked1m.H",
            benchmark = 0.867,
            title = paste("Plot ", i, ": Proportion of HIV+ Nodes Linked to Care within One Month (Hispanic)", sep = ""))

i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.linked1m.O",
            benchmark = 0.875,
            title = paste("Plot ", i, ": Proportion of HIV+ Nodes Linked to Care within One Month (Other)", sep = ""))

i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.linked1m.W",
            benchmark = 0.936,
            title = paste("Plot ", i, ": Proportion of HIV+ Nodes Linked to Care within One Month (White)", sep = ""))


# Proportion HIV+ Linked to Care in 1st Month ----------------------------------


i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.vsupp.B",
            benchmark = 0.571,
            title = paste("Plot ", i, ": Proportion of HIV+ Nodes with Viral Suppression (Black)", sep = ""))


i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.vsupp.H",
            benchmark = 0.675,
            title = paste("Plot ", i, ": Proportion of HIV+ Nodes with Viral Suppression (Hispanic)", sep = ""))

i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.vsupp.O",
            benchmark = 0.586,
            title = paste("Plot ", i, ": Proportion of HIV+ Nodes with Viral Suppression (Other)", sep = ""))

i <- i+1

target_plot(data = sim_targets,
            group = "treat",
            var = "cc.vsupp.W",
            benchmark = 0.617,
            title = paste("Plot ", i, ": Proportion of HIV+ Nodes with Viral Suppression (White)", sep = ""))


# Annualized Exogenous Incidence Rate -----------------------------------------
i <- i+1
target_plot(data = annual_incid,
            var = "exo.ir100.B",
            group = "treat",
            benchmark = mean(c(1.438, 1.798)),
            target_range = c(1.438, 1.798),
            title = paste("Plot ", i, ": Exogenous Incidence Rate (Black, Annualized)", sep = ""))

i <- i+1
target_plot(data = annual_incid,
            var = "exo.ir100.H",
            group = "treat",
            benchmark = mean(c(0.653, 0.816)),
            target_range = c(0.653, 0.816),
            title = paste("Plot ", i, ": Exogenous Incidence Rate (Hispanic, Annualized)", sep = ""))
i <- i+1
target_plot(data = annual_incid,
            var = "exo.ir100.O",
            group = "treat",
            benchmark = mean(c(0.506, 0.633)),
            target_range = c(0.506, 0.633),
            title = paste("Plot ", i, ": Exogenous Incidence Rate (Other, Annualized)", sep = ""))
i <- i+1
target_plot(data = annual_incid,
            var = "exo.ir100.W",
            group = "treat",
            benchmark = mean(c(0.257, 0.3212)),
            target_range = c(0.257, 0.3212),
            title = paste("Plot ", i, ": Exogenous Incidence Rate (White, Annualized)", sep = ""))



# Annualized Endogenous Incidence Rate -----------------------------------------
i <- i+1
target_plot(data = annual_incid2,
            var = "endo.ir100.B",
            group = "treat",
            benchmark = 6.42 - mean(c(1.438, 1.798)),
            target_range = c(4.44-1.438, 9.30-1.798),
            title = paste("Plot ", i, ": Endogenous Incidence Rate (Black, Annualized)", sep = ""))
i <- i+1
target_plot(data = annual_incid2,
            var = "endo.ir100.H",
            group = "treat",
            benchmark = 2.04 - mean(c(0.653, 0.816)),
            target_range = c(1.10-0.653, 3.79-0.816),
            title = paste("Plot ", i, ": Endogenous Incidence Rate (Hispanic, Annualized)", sep = ""))
i <- i+1
target_plot(data = annual_incid2,
            var = "endo.ir100.O",
            group = "treat",
            benchmark = 1.71 - mean(c(0.506, 0.633)),
            target_range = c(0.55-0.506, 5.31-0.633),
            title = paste("Plot ", i, ": Endogenous Incidence Rate (Other, Annualized)", sep = ""))
i <- i+1
target_plot(data = annual_incid2,
            var = "endo.ir100.W",
            group = "treat",
            benchmark = 0.73 - mean(c(0.257, 0.3212)),
            target_range = c(0.24, 2.26-0.3212),
            title = paste("Plot ", i, ": Endogenous Incidence Rate (White, Annualized)", sep = ""))


# Annualized Total Incidence Rate ----------------------------------------------
i <- i+1
target_plot(data = annual_incid2,
            var = "ir100.B",
            group = "treat",
            benchmark = 6.42,
            target_range = c(4.44, 9.30),
            title = paste("Plot ", i, ": Total Incidence Rate (Black, Annualized)", sep = ""))
i <- i+1
target_plot(data = annual_incid2,
            var = "ir100.H",
            group = "treat",
            benchmark = 2.04,
            target_range = c(1.10, 3.79),
            title = paste("Plot ", i, ": Total Incidence Rate (Hispanic, Annualized)", sep = ""))
i <- i+1
target_plot(data = annual_incid2,
            var = "ir100.O",
            group = "treat",
            benchmark = 1.71,
            target_range = c(0.55, 5.31),
            title = paste("Plot ", i, ": Total Incidence Rate (Other, Annualized)", sep = ""))
i <- i+1
target_plot(data = annual_incid2,
            var = "ir100.W",
            group = "treat",
            benchmark = 0.73,
            target_range = c(0.24, 2.26),
            title = paste("Plot ", i, ": Total Incidence Rate (White, Annualized)", sep = ""))


# Prevalence -------------------------------------------------------------------
se_prop <- function(p, n) {
  se <- sqrt((p*(1-p))/n)
  return(c((p-1.95*se), (p+1.95*se)))
}

i <- i+1
target_plot(data = sim_targets,
            var = "i.prev",
            group = "treat",
            benchmark = 0.165,
            target_range = se_prop(.165, 1015),
            title = paste("Plot ", i, ": Prevalence, Infected", sep = ""))

i <- i+1
target_plot(data = sim_targets,
            var = "i.prev.B",
            group = "treat",
            benchmark = 0.32,
            target_range = se_prop(.32, 244),
            title = paste("Plot ", i, ": Prevalence, Infected (Black)", sep = ""))

i <- i+1
target_plot(data = sim_targets,
            var = "i.prev.H",
            group = "treat",
            benchmark = 0.125,
            target_range = se_prop(.125, 304),
            title = paste("Plot ", i, ": Prevalence, Infected (Hispanic)", sep = ""))

i <- i+1
target_plot(data = sim_targets,
            var = "i.prev.O",
            group = "treat",
            benchmark = 0.122,
            target_range = se_prop(.122, 115),
            title = paste("Plot ", i, ": Prevalence, Infected (Other)", sep = ""))

i <- i+1
target_plot(data = sim_targets,
            var = "i.prev.W",
            group = "treat",
            benchmark = .02,
            target_range = se_prop(.02, 252),
            title = paste("Plot ", i, ": Prevalence, Infected (White)", sep = ""))




