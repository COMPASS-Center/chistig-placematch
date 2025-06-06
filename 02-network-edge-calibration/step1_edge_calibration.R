# Create a CSV file to feed target stats into the calibration process

#######################################
# Read in target stats (for netstats) #
#######################################

library(dplyr)
library(yaml)

args <- commandArgs(trailingOnly = TRUE)
yamlfname <- args[1]
yamldata <- yaml.load_file(yamlfname)
expname <- yamldata$expname

targetdf_fname <- paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$target.dataframe.fname)

target_df <- read.csv(targetdf_fname)

# Function for quickly extracting target stats for ERGMs from dataframe.
# These values serve as a good starting point for the edge calibration process,
# since we have already used them to create the ERGM fits in `01-networks-estimation`
target_extract = function(df = target_df, term, model) {
  this_row <- which(df$X == term)
  this_col <- which(colnames(df) == paste("mean_", model, sep = ""))
  target_val <- df[this_row, this_col]
  return(target_val)
}

# The lines of code below store numeric objects/vectors of potential values
# related to fitting ERGMs. Most of the objects below store the value,
# that we found to result in successful edge calibration. For the purposes
# of illustration, however, we store a range of potential values in the
# `venues.main` object to show what the output of this script should look like.

### The departure rate (or `d.rate`) is a parameter that specifies the departure
### rate in our temporal ERGMs. In practice, this parameter allows the model to
### adjust for the rate at which people exit the network in a way that allows
### the number of edges in the network to remain stable over time.
### For our simulations, we calibrate two `d.rate` parameters: one for our main
### partnership model and the other for our casual partnership model. Since
### one-time partnership dissolve as soon as they formed, no `d.rate` value is
### needed for the one-time partnership model.

### Our calibration process found the below two values to be what is needed for
### successful edge calibration, which we provide in hopes that you will not need
### to recalibrate these parameters.
drate_main <- .0018
drate_cas <- .0014

### These three objects store values to test for the "target stats" that inform
### how many ties in our partnership networks should feature colocation on
### dating apps between the two nodes they connect. Our study only compares differences
### between ERGMs that include colocation on physical venues and those that do not,
### so there is no need to calibrate target stats for dating app colocation to
### replicate our study. However, we leave these objects here in case future
### extensions of our project with to include dating app colocation in their
### simulations.
apps_main <- 278.07
apps_casual <- 794.72
##### We found that our original target stat for app colocation didn't need to be changed,
##### so we extract it from our target stats sheet here:
apps_onetime <- target_extract(term = "fuzzynodematch.apps_all.TRUE", model = "one.time")

### These three objects store values to test for the "target stats" that inform
### how many ties in our partnership networks should feature colocation in
### physical spaces between the two nodes they connect.
##### As mentioned above, we store a range of potential values in the
##### `venues.main` object to show what the output of this script
##### should look like.
venues_main <- (19.56929 + c(0:-8))
venues_casual <- 17.60886
venues_onetime <- 1.951811

# Once the above objects are stored, we use the `expand.grid` function
# to create a data frame storing all possible combinations of values
# for our `d.rate` parameters and target stats
scenario_mat <- expand.grid(experiment = expname,
                            drate_main = drate_main,
                            drate_cas = drate_cas,
                            apps_main = apps_main,
                            apps_casual = apps_casual,
                            apps_onetime = apps_onetime,
                            venues_main = venues_main,
                            venues_casual = venues_casual,
                            venues_onetime = venues_onetime) %>%
     dplyr::mutate(fit_no = dplyr::row_number()) %>%
     dplyr::select(fit_no, dplyr::everything())



# Save `scenario_mat` as a CSV to be called on in next step
### Specify file name
scenario_mat_output_fname <- paste(yamldata$repo.dir, yamldata$calibration.subdir, expname, "/", yamldata$calibration.matrix.fname, "_", expname, '.csv', sep="")
### Save CSV
write.csv(scenario_mat, scenario_mat_output_fname, row.names = FALSE, quote = FALSE)
