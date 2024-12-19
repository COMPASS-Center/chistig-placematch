# Create a CSV file to feed target stats into the calibration process

#######################################
# Read in target stats (for netstats) #
#######################################

# Dataframe with target stats should be stored on HPC for this step
# old_target_df <- read.csv("./from_chistig/target_values_full.csv")
# target_df <- read.csv("./data/synthpop_gen/target_values_v4_1_uniform_age_dist.csv")

library(dplyr)
library(yaml)

args <- commandArgs(trailingOnly = TRUE)
yamlfname <- args[1]
yamldata <- yaml.load_file(yamlfname)
expname <- yamldata$expname

targetdf_fname <- paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$target.dataframe.fname)

target_df <- read.csv(targetdf_fname)

# Function for quickly extracting target values from dataframe
target_extract = function(df = target_df, term, model) {
  this_row <- which(df$X == term)
  this_col <- which(colnames(df) == paste("mean_", model, sep = ""))
  target_val <- df[this_row, this_col]
  return(target_val)
}


apps_main <- 278.07
apps_casual <- 794.72
apps_onetime <- target_extract(term = "fuzzynodematch.apps_all.TRUE", model = "one.time")

# My best guess is that venue target stats should be close to
### Main: 162
# venues_main <- target_extract(term = "fuzzynodematch.venues_all.TRUE", model = "main") + c(-50)
venues_main <- (19.56929 + c(0:-8))
### Casual: 138
venues_casual <- 17.60886 # target_extract(term = "fuzzynodematch.venues_all.TRUE", model = "casual") + c(-50)
### One-time: 4
venues_onetime <- 1.951811 # target_extract(term = "fuzzynodematch.venues_all.TRUE", model = "one.time") + c(-5)

drate_mat <- data.frame(experiment = expname,
                        drate_main = .0018,
                        drate_cas = .0014,
                        apps_main = rep(apps_main, length(apps_main)),
                        apps_casual = rep(apps_casual, each = length(apps_main)),
                        apps_onetime = apps_onetime,
                        venues_main = venues_main,
                        venues_casual = venues_casual,
                        venues_onetime = venues_onetime) %>%
  dplyr::mutate(fit_no = dplyr::row_number()) %>%
  dplyr::select(fit_no, dplyr::everything())


# print(drate_mat)

drate_mat_output_fname <- paste(yamldata$repo.dir, yamldata$calibration.subdir, expname, "/", yamldata$calibration.matrix.fname, "_", expname, '.csv', sep="")

# Save `drate_mat` as a CSV to be called on in next step
# write.table(drate_mat, file = drate_mat_output_fname, sep = "\t", row.names = FALSE, quote = FALSE)
write.csv(drate_mat, drate_mat_output_fname, row.names = FALSE, quote = FALSE)
