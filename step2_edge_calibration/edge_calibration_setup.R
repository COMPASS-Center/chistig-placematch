
# Create a CSV file to feed target stats into the calibration process

library(tidyverse)

#######################################
# Read in target stats (for netstats) #
#######################################

# Dataframe with target stats should be stored on HPC for this step
old_target_df <- read.csv("./from_chistig/target_values_full.csv")
target_df <- read.csv("./data/synthpop_gen/target_values_v4_1_uniform_age_dist.csv")

# Function for quickly extracting target values from dataframe
target_extract = function(df = target_df, term, model) {
  this_row <- which(df$X == term)
  this_col <- which(colnames(df) == paste("mean_", model, sep = ""))
  target_val <- df[this_row, this_col]
  return(target_val)
}


apps_main <- target_extract(term = "fuzzynodematch.apps_all.TRUE", model = "main") # + c(-100, )
apps_casual <- target_extract(term = "fuzzynodematch.apps_all.TRUE", model = "casual") # + c(25, 50, 75)
apps_onetime <- target_extract(term = "fuzzynodematch.apps_all.TRUE", model = "one.time")

# My best guess is that venue target stats should be close to
### Main: 162
venues_main <- target_extract(term = "fuzzynodematch.venues_all.TRUE", model = "main")   + c(-100, -142)
### Casual: 138
venues_casual <- target_extract(term = "fuzzynodematch.venues_all.TRUE", model = "casual") + c(-200)
### One-time: 4
venues_onetime <- target_extract(term = "fuzzynodematch.venues_all.TRUE", model = "one.time") + c(-11)


drate_mat <- data.frame(drate_main = .0018,
                        drate_cas = .0014,
                        apps_main = apps_main, # rep(apps_main, length(apps_main)),
                        apps_casual = apps_casual, # rep(apps_casual, each = length(apps_main)),
                        apps_onetime = apps_onetime,
                        venues_main = venues_main,
                        venues_casual = venues_casual,
                        venues_onetime = venues_onetime) %>%
  dplyr::mutate(fit_no = dplyr::row_number()) %>%
  dplyr::select(fit_no, dplyr::everything())

# Save `drate_mat` as a CSV to be called on in next step
#### Make sure this directory is correct on HPC
write.csv(drate_mat, "./data/intermediate/estimates/edge_target_calibration_vals.csv")


