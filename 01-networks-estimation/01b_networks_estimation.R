###############################################################################
# Script Name:    01b_networks_estimation.R
# Purpose:        Combine the initial networks together into the same file for the next steps 
# Author:         Sara Rimer, Tom Wolff
# Date Created:   2025-02-24
# Last Modified:  2025-03-05
# Dependencies:   yaml
# Notes: This file checks if any networks didn't converge. If so, it throws an error unless the error is overridden
# TODO: add in a check on any files that might be missing 
###############################################################################


# =========================
# libraries
# =========================

library("EpiModelHIV")
library(yaml)
library(dplyr)
library(argparse)


# =========================
# read in arguments
# =========================
parser <- ArgumentParser(description = "Process command line arguments for which network estimation is occurring and which random seed to use") #nolint


# parser$add_argument("--yamlfname", required=TRUE, help="The YAML file that needs to be passed in") #nolint

# The following tells us to check the different partnerships/models and ensure an ERGM network for each was fit
# If not, a flag is thrown (an error if the error is TRUE)
parser$add_argument(
    "--convergenceerror",
    type = "logical",
    choices = c(TRUE, FALSE),
    required = FALSE,
    help="Throws an error if one of the ERGM networks never converged."
) #nolint
parser$add_argument(
    "--randomseed",
    type = "integer",
    required = FALSE,
    help="The random seed to use for this attempt of ERGM network estimate"
) #nolint
# parse the arguments
args <- parser$parse_args()

convergence_error <- if (is.null(args$convergenceerror)) FALSE else args$convergenceerror #nolint 
randomseed <- as.integer(
    ifelse(is.null(args$randomseed), 15, args$randomseed)
)


# =========================
# setup YAML parameters
# =========================

# yamldata <- yaml.load_file(args$yamlfname)

# TODO: read in the ptypes and mtypes from YAML and run a flag if there should be a netest file that isn't there
ptypes <- c("main", "casual", "onetime")
mtypes <- c("control", "venues", "apps", "venuesapps")

# =========================
# define filenames/directories from YAML
# =========================

# define the experiment directory where input and outputs are saved
expdir <- "./"

# interim directory
interim_dir <- paste0(expdir, "interim/")

# out directory 
outdir <- expdir


# =========================
# go through models and partnerships and combine results
# =========================

for (thismodel in mtypes) {

    # Read in the main partnership ERGM fit
    if ("main" %in% ptypes) {
        ergm_fit_main <- readRDS(paste0(interim_dir, "netest-main-", thismodel, ".rds")) #nolint
        coef_df_main <- data.frame(
            model = thismodel,
            partnership = "main",
            term = names(ergm_fit_main$coef.form),
            estimate = ergm_fit_main$coef.form
        )
    } else {
        ergm_fit_main <- NA
        coef_df_main <- NA
    }

    # Read in the casual partnership ERGM fit
    if ("casual" %in% ptypes) {
        ergm_fit_casual <- readRDS(paste0(interim_dir, "netest-casual-", thismodel, ".rds")) #nolint
        coef_df_casual <- data.frame(
            model = thismodel,
            partnership = "casual",
            term = names(ergm_fit_casual$coef.form),
            estimate = ergm_fit_casual$coef.form
        )
    } else {
        ergm_fit_casual <- NA
        coef_df_casual <- NA
    }

    # Read in the one-time partnership ERGM fit
    if ("onetime" %in% ptypes) {
        ergm_fit_onetime <- readRDS(paste0(interim_dir, "netest-onetime-", thismodel, ".rds")) #nolint
        coef_df_onetime <- data.frame(
            model = thismodel,
            partnership = "onetime",
            term = names(ergm_fit_onetime$coef.form),
            estimate = ergm_fit_onetime$coef.form
        )
    } else {
        ergm_fit_onetime <- NA
        coef_df_onetime <- NA
    }

    ergmfit_outlist <- list(
        fit_main = ergm_fit_main,
        fit_casl = ergm_fit_casual,
        fit_inst = ergm_fit_onetime
    )
    saveRDS(ergmfit_outlist, paste0(outdir, "netest-", thismodel, ".rds"))

    coef_df_list <- list(coef_df_main, coef_df_casual, coef_df_onetime)
    valid_coef_dfs <- coef_df_list[
        !sapply(
            coef_df_list, function(x) is.null(x)
            ||
            identical(x, NA) || nrow(x) == 0)
        ]
    combined_coef_df <- bind_rows(valid_coef_dfs)
    saveRDS(combined_coef_df, paste0(outdir, "coef-df-", thismodel, ".rds"))

}