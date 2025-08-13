###############################################################################
# Script Name:    01b_networks_estimation.R
<<<<<<< HEAD
# Purpose:        Combine the initial networks together into the same file for the next steps 
=======
# Purpose:        Initialize the different networks 
>>>>>>> b4eedde34b99339794e45ee3d3784aa53ed308f8
# Author:         Sara Rimer, Tom Wolff
# Date Created:   2025-02-24
# Last Modified:  2025-03-05
# Dependencies:   yaml
<<<<<<< HEAD
# Notes: This file checks if any networks didn't converge. If so, it throws an error unless the error is overridden
# TODO: add in a check on any files that might be missing 
=======
# Notes: This file combines network objects from step 01a
# TODO: 
# - add in the YAML arguments for the directory locations
# - add in a check to see which of the scenarios and partnership types actually converged. Right now, it is assumed all have converged and there are datafiles for all of them
# - similarly, add in the ability to define which scenarios and partnership types we want to actually build objects from. right now we assume all 
>>>>>>> b4eedde34b99339794e45ee3d3784aa53ed308f8
###############################################################################


# =========================
# libraries
# =========================

<<<<<<< HEAD
library("EpiModelHIV")
=======
>>>>>>> b4eedde34b99339794e45ee3d3784aa53ed308f8
library(yaml)
library(dplyr)
library(argparse)


<<<<<<< HEAD
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
=======
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
>>>>>>> b4eedde34b99339794e45ee3d3784aa53ed308f8


# =========================
# setup YAML parameters
# =========================

# yamldata <- yaml.load_file(args$yamlfname)

<<<<<<< HEAD
# TODO: read in the ptypes and mtypes from YAML and run a flag if there should be a netest file that isn't there
ptypes <- c("main", "casual", "onetime")
mtypes <- c("control", "venues", "apps", "venuesapps")
=======
# # set the random seed to be whatever if passed in
# # if nothing is passed in, uses the default as defined in the yaml file
# randomseed <- as.integer(
#     ifelse(is.null(args$randomseed), yamldata$random.seed, args$randomseed)
# )
>>>>>>> b4eedde34b99339794e45ee3d3784aa53ed308f8

# =========================
# define filenames/directories from YAML
# =========================

# define the experiment directory where input and outputs are saved
expdir <- "./"

<<<<<<< HEAD
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
=======
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
>>>>>>> b4eedde34b99339794e45ee3d3784aa53ed308f8
