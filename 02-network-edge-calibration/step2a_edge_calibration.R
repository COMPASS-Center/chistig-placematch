### libraries
library(yaml)
library(dplyr)
library(ARTnetData)
library(EpiModelHIV)
library(ARTnet)

### Load yaml and other commandline arguments
args <- commandArgs(trailingOnly = TRUE)
# sbatch_run_num <- args[1]
yamlfname <- args[1]
yamldata <- yaml.load_file(yamlfname)


### Name datafiles 
# egos_fname <- paste0(yamldata$repo.dir, yamldata$synthpop.subdir, yamldata$synthpop.fname)

# epistats_fname <- paste0(yamldata$repo.dir, yamldata$prelim.subdir, yamldata$epistats.fname)
# artnet_duration_dissolution_fname <- paste0(yamldata$repo.dir, yamldata$prelim.subdir, yamldata$artnet.duration.dissolution.fname)

netstats_fname <- paste0(yamldata$repo.dir, yamldata$netstats.subdir, yamldata$netstats.fname)

# targetstats_fname <- paste0(yamldata$repo.dir, yamldata$synthpop.subdir, yamldata$target.dataframe.fname)

#drate_mat_fname <- paste0(yamldata$repo.dir, yamldata$calibration.matrix.subdir, yamldata$)
calibration_matrix_fname <- paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$calibration.matrix.fname)


if (is.null(yamldata$interim.data.subdir)) {
  outdir <- paste(yamldata$repo.dir, yamldata$calibration.subdir, sep="")
} else {
  outdir <- paste(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$interim.data.subdir, sep="")
}

### Read in epistats
# readRDS("./data/intermediate/estimates/epistats-local.rds")
# epistats <- readRDS(epistats_fname)
# source(artnet_compute_duration_dissolution_fname)
# dur_coefs <- readRDS(artnet_duration_dissolution_fname)


### Read in the calibration input matrix 
calibration_matrix_full <- read.csv(calibration_matrix_fname)
num_calibration_scenarios <- max(calibration_matrix_full$fit_no)



####################################################
# Obtain the base netstats object from prelim step #
####################################################
netstats_base <- readRDS(netstats_fname)



##############################################################
# Setup and compute netstats object for each calibration set #
##############################################################
calibration_matrix <- calibration_matrix_full[num_calibration_scenarios, ]


# Netstats
for (i in 1:num_calibration_scenarios){
    
    calibration_matrix <- calibration_matrix_full[i, ]

    netstats <- netstats_base

    # update main partnership d.rate parameters
    netstats$main$diss.homog$d.rate <- calibration_matrix$drate_main
    netstats$main$dissolution$d.rate <- calibration_matrix$drate_main
    netstats$main$diss.byage$d.rate <- calibration_matrix$drate_main

    # update main partnership apps/venues target values 
    netstats$main$fuzzynodematch_venues.all <- calibration_matrix$venues_main
    netstats$main$fuzzynodematch_apps.all <- calibration_matrix$apps_main

    # update casual partnership d.rate parameters
    netstats$casl$diss.homog$d.rate <- calibration_matrix$drate_cas
    netstats$casl$dissolution$d.rate <- calibration_matrix$drate_cas
    netstats$casl$diss.byage$d.rate <- calibration_matrix$drate_cas

    # update casual partnership apps/venues target values 
    netstats$casl$fuzzynodematch_venues.all <- calibration_matrix$venues_casual
    netstats$casl$fuzzynodematch_apps.all <- calibration_matrix$apps_casual

    # update one-time partnership apps/venues target values 
    netstats$inst$fuzzynodematch_venues.all <- calibration_matrix$venues_onetime
    netstats$inst$fuzzynodematch_apps.all <- calibration_matrix$apps_onetime

	# print(paste0(yamldata$repo.dir, yamldata$netest.subdir, "netstats_", yamldata$expname, "_", calibration_matrix$fit_no, ".rds"))
	saveRDS(netstats, paste0(outdir, "netstats_", calibration_matrix$fit_no, ".rds"))

}
