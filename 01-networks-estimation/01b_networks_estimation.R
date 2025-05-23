###############################################################################
# Script Name:    01b_networks_estimation.R
# Purpose:        Initialize the different networks 
# Author:         Sara Rimer, Tom Wolff
# Date Created:   2025-02-24
# Last Modified:  2025-03-05
# Dependencies:   yaml
# Notes: This file combines network objects from step 01a
# TODO: 
# - add in the YAML arguments for the directory locations
# - add in a check to see which of the scenarios and partnership types actually converged. Right now, it is assumed all have converged and there are datafiles for all of them
# - similarly, add in the ability to define which scenarios and partnership types we want to actually build objects from. right now we assume all 
###############################################################################


# =========================
# libraries
# =========================

library(yaml)
library(dplyr)
library(argparse)


# # =========================
# # read in arguments
# # =========================

# # The following allows us to setup which of the ERGM fits we are running
# # If no arguments are passed in via the command line, we assume that ALL ERGM fits are to be run together 
# parser <- ArgumentParser(description = "Process command line arguments for which network estimation is occurring and which random seed to use") #nolint

# # parser$add_argument("--yamlfname", required=TRUE, help="The YAML file that needs to be passed in") #nolint
# parser$add_argument("--randomseed", required=FALSE, help="The random seed to use for this attempt of ERGM network estimate") #nolint
# parser$add_argument(
#     "--partnershiptype",
#     required = FALSE,
#     choices = c("main", "casual", "onetime"),
#     help = "The partnership type of the ERGM network being estimated." #nolint
# )
# parser$add_argument(
#     "--modeltype",
#     required = FALSE,
#     choices = c("control", "venues", "apps", "venuesapps"),
#     help = "The model counterfactual of ERGM network being estimated." #nolint
# )

# # parse the arguments
# args <- parser$parse_args()

# # assign which ERGM network is being fit
# # if nothing is passed, then create a ALL variable that runs everything
# ptype <- if (is.null(args$partnershiptype)) NA_character_ else args$partnershiptype #nolint
# mtype <- if (is.null(args$modeltype)) NA_character_ else args$modeltype #nolint
# if ((is.na(ptype)) || (is.na(mtype))) {
#     runall <- TRUE
# } else {
#     runall <- FALSE
# }

# randomseed <- as.integer(
#     ifelse(is.null(args$randomseed), 15, args$randomseed)
# )


# =========================
# setup YAML parameters
# =========================

# yamldata <- yaml.load_file(args$yamlfname)

# # set the random seed to be whatever if passed in
# # if nothing is passed in, uses the default as defined in the yaml file
# randomseed <- as.integer(
#     ifelse(is.null(args$randomseed), yamldata$random.seed, args$randomseed)
# )

# =========================
# define filenames/directories from YAML
# =========================

# define the experiment directory where input and outputs are saved
expdir <- "./"

# interim outfile directory
outdir <- paste0(expdir, "interim/")

# read in netstats
netstats <- readRDS(paste0(expdir, "netstats.rds"))

# the interim outfile directory to read the files in from 
indir <- paste0(expdir, "interim/")
outdir <- expdir

# =========================
# Read in the ERGM fits
# =========================

for (thisscenario in c("control", "venues", "apps", "venuesapps")) {

    ergm_fit_main <- readRDS(paste0(indir, "netest-main-", thisscenario, ".rds")) #nolint
    ergm_fit_casl <- readRDS(paste0(indir, "netest-casual-", thisscenario, ".rds")) #nolint
    ergm_fit_onetime <- readRDS(paste0(indir, "netest-onetime-", thisscenario, ".rds")) #nolint

    # combine the ergm fits for each partnership type to write out
    out_thisscenario <- list(
        fit_main = ergm_fit_main,
        fit_casl = ergm_fit_casl,
        fit_inst = ergm_fit_onetime
    )

    # create a dataframe of the ergm fit coefficients and write them out 
    coef_df_thisscenario <- data.frame(
                treatment = thisscenario,
                model = "main",
                term = names(ergm_fit_main$coef.form),
                estimate = ergm_fit_main$coef.form
            )

    casl_df <- data.frame(
                treatment = thisscenario,
                model = "casual",
                term = names(ergm_fit_casl$coef.form),
                estimate = ergm_fit_casl$coef.form
            )

    inst_df <- data.frame(
                treatment = thisscenario,
                model = "onetime",
                term = names(ergm_fit_onetime$coef.form),
                estimate = ergm_fit_onetime$coef.form
            )

    coef_df_thisscenario <- dplyr::bind_rows(coef_df_thisscenario, casl_df)
    coef_df_thisscenario <- dplyr::bind_rows(coef_df_thisscenario, inst_df)

    # write everything out
    saveRDS(out_thisscenario, paste0(outdir, "netest-", thisscenario, ".rds")) #nolint
    saveRDS(coef_df_thisscenario, paste0(outdir, "coef-df-", thisscenario, ".rds")) #nolint
}
