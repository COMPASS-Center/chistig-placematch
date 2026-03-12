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
# 3. Incidence 
### ---------------------------------------

# Annualized Incidence Counts --------------------------------------------------

# read
mean_incid2 <- readRDS("/projects/p32153/chistig-placematch/05-simulation-sweeps/data_processing/mean_incid_intermediary.rds")

# for (j in 1:nrow(mean_incid2)) {
#
#   if (j %% 1000 == 0) {
#     print(j)
#   }
#
#   this_row <- mean_incid2[j,]
#   past_year <- mean_incid2 %>%
#     filter(time <= this_row$time & time > (this_row$time-52)) %>%
#     filter(siminstance == this_row$siminstance)
#   sums <- as.data.frame(t(colSums(past_year[,3:ncol(past_year)])))
#   sums$siminstance <- this_row$siminstance
#   sums$replicate <- this_row$replicate
#   sums$time <- this_row$time
#
#   if (j == 1) {
#     annual_incid <- sums
#   } else {
#     annual_incid <- dplyr::bind_rows(annual_incid, sums)
#   }
# }

# for (j in 1:nrow(mean_incid2)) {

#   if (j %% 1000 == 0) {
#     print(j)
#   }

#   this_row <- mean_incid2[j,]
#   past_year <- mean_incid2 %>%
#     filter(time <= this_row$time & time > (this_row$time-52)) %>%
#     filter(siminstance == this_row$siminstance) %>%
#     filter(replicate == this_row$replicate)
#   means <- as.data.frame(t(colMeans(past_year[,3:ncol(past_year)])))
#   means$siminstance <- this_row$siminstance
#   means$time <- this_row$time
#   means$replicate <- this_row$replicate

#   if (j == 1) {
#     annual_incid2 <- means
#   } else {
#     annual_incid2 <- dplyr::bind_rows(annual_incid2, means)
#   }
# }

results_list <- mclapply(1:nrow(mean_incid2), function(j) {
  
  this_row <- mean_incid2[j, ]
  past_year <- mean_incid2 %>%
    filter(time <= this_row$time & time > (this_row$time - 52)) %>%
    filter(siminstance == this_row$siminstance) %>%
    filter(replicate == this_row$replicate)
  
  means <- as.data.frame(t(colMeans(past_year[, 3:ncol(past_year)])))
  means$siminstance <- this_row$siminstance
  means$time <- this_row$time
  means$replicate <- this_row$replicate
  
  means
}, mc.cores = num_workers)

annual_incid2 <- dplyr::bind_rows(results_list)

annual_incid2$total.incid.rate.dispar.BW <- annual_incid2$total.incid.B - annual_incid2$total.incid.W
annual_incid2$total.incid.rate.dispar.HW <- annual_incid2$total.incid.H - annual_incid2$total.incid.W

annual_incid2$ir100.dispar.BW <- annual_incid2$ir100.B - annual_incid2$ir100.W
annual_incid2$ir100.dispar.HW <- annual_incid2$ir100.H - annual_incid2$ir100.W
annual_incid2$ir100.dispar.OW <- annual_incid2$ir100.O - annual_incid2$ir100.W


annual_incid_final <- annual_incid2 %>% dplyr::filter(time > (max(time)-520)) %>%
  dplyr::select(treat = siminstance, trial = replicate, time, dplyr::everything())


write.csv(annual_incid_final, "/projects/p32153/chistig-placematch/05-simulation-sweeps/data_processing/annual_incid.csv")

