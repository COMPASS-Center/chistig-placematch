###############################################################################
# Script Name:    01_networks_estimation.R
# Purpose:        Initialize the different networks 
# Author:         Sara Rimer, Tom Wolff
# Date Created:   2025-02-24
# Last Modified:  2025-03-05
# Dependencies:   yaml
# Notes: This file does an initial estimates the ERGMs. 
# Need to add in the installation of the argparse library for the conda environment  
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

# The following allows us to setup which of the ERGM fits we are running
# If no arguments are passed in via the command line, we assume that ALL ERGM fits are to be run together 
parser <- ArgumentParser(description = "Process command line arguments for which network estimation is occurring and which random seed to use") #nolint

# parser$add_argument("--yamlfname", required=TRUE, help="The YAML file that needs to be passed in") #nolint
parser$add_argument("--randomseed", required=FALSE, help="The random seed to use for this attempt of ERGM network estimate") #nolint
parser$add_argument(
    "--partnershiptype",
    required = FALSE,
    choices = c("main", "casual", "onetime"),
    help = "The partnership type of the ERGM network being estimated." #nolint
)
parser$add_argument(
    "--modeltype",
    required = FALSE,
    choices = c("control", "venues", "apps", "venuesapps"),
    help = "The model counterfactual of ERGM network being estimated." #nolint
)

# parse the arguments
args <- parser$parse_args()

# assign which ERGM network is being fit
# if nothing is passed, then create a ALL variable that runs everything
ptype <- if (is.null(args$partnershiptype)) NA_character_ else args$partnershiptype #nolint
mtype <- if (is.null(args$modeltype)) NA_character_ else args$modeltype #nolint
if ((is.na(ptype)) || (is.na(mtype))) {
    runall <- TRUE
} else {
    runall <- FALSE
}

randomseed <- as.integer(
    ifelse(is.null(args$randomseed), 15, args$randomseed)
)


# =========================
# setup YAML parameters
# =========================

# yamldata <- yaml.load_file(args$yamlfname)

# # set the random seed to be whatever if passed in
# # if nothing is passed in, uses the default as defined in the yaml file
# randomseed <- as.integer(
#     ifelse(is.null(args$randomseed), yamldata$random.seed, args$randomseed)
# )

# # =========================
# # define filenames/directories from YAML
# # =========================

# define the experiment directory where input and outputs are saved
expdir <- "./"

# interim outfile directory
outdir <- paste0(expdir, "interim/")

# read in netstats
netstats <- readRDS(paste0(expdir, "netstats.rds"))

# # define the output files
# control_netest_out_fname <- paste0(expdir, "netest-control.rds")
# venuesonly_netest_out_fname <- paste0(expdir, "netest-venues.rds")
# appsonly_netest_out_fname <- paste0(expdir, "netest-apps.rds")
# venuesapps_netest_out_fname <- paste0(expdir, "netest-venuesapps.rds")


# =========================
# Initialize networks from netstats
# =========================

numegos <- netstats$demog$num
nw <- network::network.initialize(n = numegos,
                         loops = FALSE,
                         directed = FALSE)


attr_names <- names(netstats$attr)
attr_values <- netstats$attr

nw_main <- EpiModel::set_vertex_attribute(nw, attr_names, attr_values)
nw_casl <- nw_main
nw_inst <- nw_main


# =========================
# Set up the different counterfactual models to be tested
# =========================

# computational settings for running the ergm fits
ergm_fit_ctrl_settings <- list(
    parallel = 4,
    MCMC.interval = 10000,
    MCMLE.effectiveSize = NULL,
    MCMC.burnin = 1000,
    MCMC.samplesize = 20000,
    SAN.maxit = 20,
    SAN.nsteps.times = 10
)

# --------------------------------------------------------------
# MAIN PARTNERSHIPS --------------------------------------------
# --------------------------------------------------------------

# 1. Target stats
target_stats_main <- c(
    edges = netstats$main$edges,
    nodematch_age.grp = netstats$main$nodematch_age.grp,
    concurrent = netstats$main$concurrent,
    nodefactor_race = netstats$main$nodefactor_race[1:3],
    nodematch_race = netstats$main$nodematch_race,
    nodefactor_deg.casl = netstats$main$nodefactor_deg.casl[-1],
    fuzzynodematch_venues.all = netstats$main$fuzzynodematch_venues.all,
    fuzzynodematch_apps.all = netstats$main$fuzzynodematch_apps.all
)

target_stats_main_control <- target_stats_main[
    setdiff(names(target_stats_main),
    c("fuzzynodematch_venues.all", "fuzzynodematch_apps.all"))
]
target_stats_main_control <- unname(target_stats_main_control)

target_stats_main_venuesonly <- target_stats_main[
    setdiff(names(target_stats_main),
    "fuzzynodematch_apps.all")
]
target_stats_main_venuesonly <- unname(target_stats_main_venuesonly)

target_stats_main_appsonly <- target_stats_main[
    setdiff(names(target_stats_main),
    "fuzzynodematch_venues.all")
]
target_stats_main_appsonly <- unname(target_stats_main_appsonly)

target_stats_main_venuesapps <- target_stats_main
target_stats_main_venuesapps <- unname(target_stats_main_venuesapps)


# 2. Formation model formula
model_terms_main_control <- c(
    "edges",
    "nodematch('age.grp', diff = TRUE)",
    "concurrent",
    "nodefactor('race', levels=-4)",
    "nodematch('race')",
    "nodefactor('deg.casl', levels=-1)"
)
model_terms_main_venuesonly <- c(
    model_terms_main_control,
    "fuzzynodematch('venues.all', binary = TRUE)"
)
model_terms_main_appsonly <- c(
    model_terms_main_control,
    "fuzzynodematch('apps.all', binary = TRUE)"
)
model_terms_main_venuesapps <- c(
    model_terms_main_control,
    "fuzzynodematch('venues.all', binary = TRUE)",
    "fuzzynodematch('apps.all', binary = TRUE)"
)

# model formation
model_form_main_control <- as.formula(
    paste("~", paste(model_terms_main_control, collapse = " + "))
)
model_form_main_venuesonly <- as.formula(
    paste("~", paste(model_terms_main_venuesonly, collapse = " + "))
)
model_form_main_appsonly <- as.formula(
    paste("~", paste(model_terms_main_appsonly, collapse = " + "))
)
model_form_main_venuesapps <- as.formula(
    paste("~", paste(model_terms_main_venuesapps, collapse = " + "))
)

# 3. Fit the network model to the target stats

func_fit_main_control <- function() {
    cat("Fitting the CONTROL model for MAIN partnerships ...\n")
    fit_main_control <- netest(
        nw = nw_main,
        formation = model_form_main_control,
        target.stats = target_stats_main_control,
        coef.diss = netstats$main$diss.byage,
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_main_control <- trim_netest(fit_main_control)
    saveRDS(fit_main_control,
        paste0(outdir, "netest-main-control.rds")
    )
}

func_fit_main_venues <- function() {
    cat("Fitting the VENUES only model for MAIN partnerships ...\n")
    fit_main_venuesonly <- netest(
        nw = nw_main,
        formation = model_form_main_venuesonly,
        target.stats = target_stats_main_venuesonly,
        coef.diss = netstats$main$diss.byage,
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_main_venuesonly <- trim_netest(fit_main_venuesonly)
    saveRDS(fit_main_venuesonly,
        paste0(outdir, "netest-main-venues.rds")
    )
}

func_fit_main_apps <- function() {
    cat("Fitting the APPS only model for MAIN partnerships ...\n")
    fit_main_appsonly <- netest(
        nw = nw_main,
        formation = model_form_main_appsonly,
        target.stats = target_stats_main_appsonly,
        coef.diss = netstats$main$diss.byage,
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_main_appsonly <- trim_netest(fit_main_appsonly)
    saveRDS(fit_main_appsonly,
        paste0(outdir, "netest-main-apps.rds")
    )
}

func_fit_main_venuesapps <- function() {
    cat("Fitting the VENUES+APPS model for MAIN partnerships ...\n")
    fit_main_venuesapps <- netest(
        nw = nw_main,
        formation = model_form_main_venuesapps,
        target.stats = target_stats_main_venuesapps,
        coef.diss = netstats$main$diss.byage,
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_main_venuesapps <- trim_netest(fit_main_venuesapps)
    saveRDS(fit_main_venuesapps,
        paste0(outdir, "netest-main-venuesapps.rds")
    )
}

# --------------------------------------------------------------
# CASUAL PARTNERSHIPS --------------------------------------------
# --------------------------------------------------------------

# 1. Target stats
target_stats_casl <- c(
    edges =  netstats$casl$edges,
    nodematch_age.grp = netstats$casl$nodematch_age.grp,
    concurrent =  netstats$casl$concurrent,
    nodefactor_race =  netstats$casl$nodefactor_race[1:3],
    nodematch_race = netstats$casl$nodematch_race,
    nodefactor_deg.main = netstats$casl$nodefactor_deg.main[-1],
    fuzzynodematch_venues.all = netstats$casl$fuzzynodematch_venues.all,
    fuzzynodematch_apps.all = netstats$casl$fuzzynodematch_apps.all
)

target_stats_casl_control <- target_stats_casl[
    setdiff(names(target_stats_casl),
    c("fuzzynodematch_venues.all", "fuzzynodematch_apps.all"))
]
target_stats_casl_control <- unname(target_stats_casl_control)

target_stats_casl_venuesonly <- target_stats_casl[
    setdiff(names(target_stats_casl),
    "fuzzynodematch_apps.all")
]
target_stats_casl_venuesonly <- unname(target_stats_casl_venuesonly)

target_stats_casl_appsonly <- target_stats_casl[
    setdiff(names(target_stats_casl),
    "fuzzynodematch_venues.all")
]
target_stats_casl_appsonly <- unname(target_stats_casl_appsonly)

target_stats_casl_venuesapps <- target_stats_casl
target_stats_casl_venuesapps <- unname(target_stats_casl_venuesapps)


# 2. Formation model formula
model_terms_casl_control <- c(
    "edges",
    "nodematch('age.grp', diff = TRUE)",
    "concurrent",
    "nodefactor('race', levels=-4)",
    "nodematch('race')",
    "nodefactor('deg.main', levels=-1)"
)
model_terms_casl_venuesonly <- c(
    model_terms_casl_control,
    "fuzzynodematch('venues.all', binary = TRUE)"
)
model_terms_casl_appsonly <- c(
    model_terms_casl_control,
    "fuzzynodematch('apps.all', binary = TRUE)"
)
model_terms_casl_venuesapps <- c(
    model_terms_casl_control,
    "fuzzynodematch('venues.all', binary = TRUE)",
    "fuzzynodematch('apps.all', binary = TRUE)"
)

model_form_casl_control <- as.formula(
    paste("~", paste(model_terms_casl_control, collapse = " + "))
)
model_form_casl_venuesonly <- as.formula(
    paste("~", paste(model_terms_casl_venuesonly, collapse = " + "))
)
model_form_casl_appsonly <- as.formula(
    paste("~", paste(model_terms_casl_appsonly, collapse = " + "))
)
model_form_casl_venuesapps <- as.formula(
    paste("~", paste(model_terms_casl_venuesapps, collapse = " + "))
)

# 3. Fit the network model to the target stats

func_fit_casual_control <- function() {
    cat("Fitting the CONTROL model for CASUAL partnerships ...\n")
    fit_casl_control <- netest(
        nw = nw_casl,
        formation = model_form_casl_control,
        target.stats = target_stats_casl_control,
        coef.diss = netstats$casl$diss.byage,
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_casl_control <- trim_netest(fit_casl_control)
    saveRDS(fit_casl_control,
        paste0(outdir, "netest-casual-control.rds")
    )
}

func_fit_casual_venues <- function() {
    cat("Fitting the VENUES only model for CASUAL partnerships ...\n")
    fit_casl_venuesonly <- netest(
        nw = nw_casl,
        formation = model_form_casl_venuesonly,
        target.stats = target_stats_casl_venuesonly,
        coef.diss = netstats$casl$diss.byage,
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_casl_venuesonly <- trim_netest(fit_casl_venuesonly)
    saveRDS(fit_casl_venuesonly,
        paste0(outdir, "netest-casual-venues.rds")
    )
}

func_fit_casual_apps <- function() {
    cat("Fitting the APPS only model for CASUAL partnerships ...\n")
    fit_casl_appsonly <- netest(
        nw = nw_casl,
        formation = model_form_casl_appsonly,
        target.stats = target_stats_casl_appsonly,
        coef.diss = netstats$casl$diss.byage,
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_casl_appsonly <- trim_netest(fit_casl_appsonly)
    saveRDS(fit_casl_appsonly,
        paste0(outdir, "netest-casual-apps.rds")
    )
}

func_fit_casual_venuesapps <- function() {
    cat("Fitting the VENUES+APPS model for CASUAL partnerships ...\n")
    fit_casl_venuesapps <- netest(
        nw = nw_casl,
        formation = model_form_casl_venuesapps,
        target.stats = target_stats_casl_venuesapps,
        coef.diss = netstats$casl$diss.byage,
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_casl_venuesapps <- trim_netest(fit_casl_venuesapps)
    saveRDS(fit_casl_venuesapps,
        paste0(outdir, "netest-casual-venuesapps.rds")
    )
}

# --------------------------------------------------------------
# ONE-TIME PARTNERSHIPS ----------------------------------------
# --------------------------------------------------------------

# 1. Target stats
target_stats_inst <- c(
    edges =  netstats$inst$edges,
    nodematch_age.grp = netstats$inst$nodematch_age.grp,
    nodefactor_race =  netstats$inst$nodefactor_race[1:3],
    nodematch_race = netstats$inst$nodematch_race,
    nodefactor_deg.tot = netstats$inst$nodefactor_deg.tot[-1],
    fuzzynodematch_venues.all = netstats$inst$fuzzynodematch_venues.all,
    fuzzynodematch_apps.all = netstats$inst$fuzzynodematch_apps.all
)

target_stats_inst_control <- target_stats_inst[
    setdiff(names(target_stats_inst),
    c("fuzzynodematch_venues.all", "fuzzynodematch_apps.all"))
]
target_stats_inst_control <- unname(target_stats_inst_control)

target_stats_inst_venuesonly <- target_stats_inst[
    setdiff(names(target_stats_inst),
    "fuzzynodematch_apps.all")
]
target_stats_inst_venuesonly <- unname(target_stats_inst_venuesonly)

target_stats_inst_appsonly <- target_stats_inst[
    setdiff(names(target_stats_inst),
    "fuzzynodematch_venues.all")
]
target_stats_inst_appsonly <- unname(target_stats_inst_appsonly)

target_stats_inst_venuesapps <- target_stats_inst
target_stats_inst_venuesapps <- unname(target_stats_inst_venuesapps)


# 2. Formation model formula
model_terms_inst_control <- c(
    "edges",
    "nodematch('age.grp', diff = TRUE)",
    "nodefactor('race', levels = -4)",
    "nodematch('race')",
    "nodefactor('deg.tot', levels = -1)"
)
model_terms_inst_venuesonly <- c(
    model_terms_inst_control,
    "fuzzynodematch('venues.all', binary = TRUE)"
)
model_terms_inst_appssonly <- c(
    model_terms_inst_control,
    "fuzzynodematch('apps.all', binary = TRUE)"
)
model_terms_inst_venuesapps <- c(
    model_terms_inst_control,
    "fuzzynodematch('venues.all', binary = TRUE)",
    "fuzzynodematch('apps.all', binary = TRUE)"
)

model_form_inst_control <- as.formula(
    paste("~", paste(model_terms_inst_control, collapse = " + "))
)
model_form_inst_venuesonly <- as.formula(
    paste("~", paste(model_terms_inst_venuesonly, collapse = " + "))
)
model_form_inst_appsonly <- as.formula(
    paste("~", paste(model_terms_inst_appssonly, collapse = " + "))
)
model_form_inst_venuesapps <- as.formula(
    paste("~", paste(model_terms_inst_venuesapps, collapse = " + "))
)

# 3. Fit the network model to the target stats

func_fit_onetime_control <- function() {
    cat("Fitting the CONTROL model for ONE-TIME partnerships ...\n")
    fit_inst_control <- netest(
        nw = nw_inst,
        formation = model_form_inst_control,
        target.stats = target_stats_inst_control,
        coef.diss = dissolution_coefs(~offset(edges), duration = 1),
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_inst_control <- trim_netest(fit_inst_control)
    saveRDS(fit_inst_control,
        paste0(outdir, "netest-onetime-control.rds")
    )
}

func_fit_onetime_venues <- function() {
    cat("Fitting the VENUES only model for ONE-TIME partnerships ...\n")
    fit_inst_venuesonly <- netest(
        nw = nw_inst,
        formation = model_form_inst_venuesonly,
        target.stats = target_stats_inst_venuesonly,
        coef.diss = dissolution_coefs(~offset(edges), duration = 1),
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_inst_venuesonly <- trim_netest(fit_inst_venuesonly)
    saveRDS(fit_inst_venuesonly,
        paste0(outdir, "netest-onetime-venues.rds")
    )
}

func_fit_onetime_apps <- function() {
    cat("Fitting the APPS only model for ONE-TIME partnerships ...\n")
    fit_inst_appsonly <- netest(
        nw = nw_inst,
        formation = model_form_inst_appsonly,
        target.stats = target_stats_inst_appsonly,
        coef.diss = dissolution_coefs(~offset(edges), duration = 1),
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_inst_appsonly <- trim_netest(fit_inst_appsonly)
    saveRDS(fit_inst_appsonly,
        paste0(outdir, "netest-onetime-apps.rds")
    )
}

func_fit_onetime_venuesapps <- function() {
    cat("Fitting the VENUES+APPS model for ONE-TIME partnerships ...\n")
    fit_inst_venuesapps <- netest(
        nw = nw_inst,
        formation = model_form_inst_venuesapps,
        target.stats = target_stats_inst_venuesapps,
        coef.diss = dissolution_coefs(~offset(edges), duration = 1),
        set.control.ergm = do.call(control.ergm, ergm_fit_ctrl_settings)
    )
    fit_inst_venuesapps <- trim_netest(fit_inst_venuesapps)
    saveRDS(fit_inst_venuesapps,
        paste0(outdir, "netest-onetime-venuesapps.rds")
    )
}


# =========================
# Either run all of the ERGM counterfactual models to be fit
# or run the one specified by the arguments passed in via the Rscript
# =========================

# Store all model fit functions in a named list
models2fit <- list(
    "main_control" = func_fit_main_control,
    "main_venues" = func_fit_main_venues,
    "main_apps" = func_fit_main_apps,
    "main_venuesapps" = func_fit_main_venuesapps,
    "casual_control" = func_fit_casual_control,
    "casual_venues" = func_fit_casual_venues,
    "casual_apps" = func_fit_casual_apps,
    "casual_venuesapps" = func_fit_casual_venuesapps,
    "onetime_control" = func_fit_onetime_control,
    "onetime_venues" = func_fit_onetime_venues,
    "onetime_apps" = func_fit_onetime_apps,
    "onetime_venuesapps" = func_fit_onetime_venuesapps
)


if (runall) {
    cat("Running all model fits...\n")
    lapply(models2fit, function(f) f())
} else {
    func_key <- paste(ptype, mtype, sep="_")
    if (func_key %in% names(models2fit)) {
        models2fit[[func_key]]()
    } else {
        stop("Error: Invalid function selection.")
    }
}