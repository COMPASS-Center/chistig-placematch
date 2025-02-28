###############################################################################
# Script Name:    01_networks_estimation.R
# Purpose:        Initialize the different networks 
# Author:         Sara Rimer, Tom Wolff
# Date Created:   2025-02-24
# Last Modified:  2025-02-26
# Dependencies:   yaml
# Notes: This file does an initial estimates the ERGMs.  
###############################################################################

# =========================
# libraries
# =========================

library("EpiModelHIV")
library(yaml)
library(dplyr)



# =========================
# read in yaml file
# =========================

# args <- commandArgs(trailingOnly = TRUE)
# yamlfname <- args[1]
# yamldata <- yaml.load_file(yamlfname)


# =========================
# setup YAML parameters
# =========================

randomseed <- as.integer(yamldata$random.seed)
set.seed(randomseed)


# =========================
# define filenames/directories from YAML
# =========================

# define the experiment directory where input and outputs are saved
expdir <- "./"

# read in netstats
netstats <- paste0(expdir, "netstats.rds")

# define the output files
control_netest_out_fname <- paste0(expdir, "netest-control.rds")
venuesonly_netest_out_fname <- paste0(expdir, "netest-venues.rds")
appsonly_netest_out_fname <- paste0(expdir, "netest-apps.rds")
venuesapps_netest_out_fname <- paste0(expdir, "netest-venuesapps.rds")


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
ergm_fit_control_settings <- list(
    parallel = 4,
    MCMC.interval = 10000,
    MCMLE.effectiveSize = NULL,
    MCMC.burnin = 1000,
    MCMC.samplesize = 20000,
    SAN.maxit = 20,
    SAN.nsteps.times = 10
)

# MAIN PARTNERSHIPS --------------------------------------------

# 1. Target stats
target_stats_main <- c(
    edges = netstats$main$edges,
    concurrent = netstats$main$concurrent,
    nodematch_age.grp = netstats$main$nodematch_age.grp,
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
    "concurrent",
    "nodematch('age.grp', diff = TRUE)",
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
fit_main_control <- netest(
    nw = nw_main,
    formation = model_form_main_control,
    target.stats = target_stats_main_control,
    coef.diss = netstats$main$diss.byage,
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_main_control <- trim_netest(fit_main_control)

fit_main_venuesonly <- netest(
    nw = nw_main,
    formation = model_form_main_venuesonly,
    target.stats = target_stats_main_venuesonly,
    coef.diss = netstats$main$diss.byage,
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_main_venuesonly <- trim_netest(fit_main_venuesonly)

fit_main_appsonly <- netest(
    nw = nw_main,
    formation = model_form_main_appsonly,
    target.stats = target_stats_main_appsonly,
    coef.diss = netstats$main$diss.byage,
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_main_appsonly <- trim_netest(fit_main_appsonly)

fit_main_venuesapps <- netest(
    nw = nw_main,
    formation = model_forma_main_venuesapps,
    target.stats = target_stats_main_venuesapps,
    coef.diss = netstats$main$diss.byage,
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_main_venuesapps <- trim_netest(fit_main_venuesapps)


# CASUAL PARTNERSHIPS --------------------------------------------

# 1. Target stats
target_stats_casl <- c(
    edges =  netstats$casl$edges,
    concurrent =  netstats$casl$concurrent,
    nodematch_age.grp = netstats$casl$nodematch_age.grp,
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
    "concurrent",
    "nodematch('age.grp', diff = TRUE)",
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
fit_casl_control <- netest(
    nw = nw_casl,
    formation = model_form_casl_control,
    target.stats = target_stats_casl_control,
    coef.diss = netstats$casl$diss.byage,
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_casl_control <- trim_netest(fit_casl_control)

fit_casl_venuesonly <- netest(
    nw = nw_casl,
    formation = model_form_casl_venuesonly,
    target.stats = target_stats_casl_venuesonly,
    coef.diss = netstats$casl$diss.byage,
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_casl_venuesonly <- trim_netest(fit_casl_venuesonly)

fit_casl_appsonly <- netest(
    nw = nw_casl,
    formation = model_form_casl_appsonly,
    target.stats = target_stats_casl_appsonly,
    coef.diss = netstats$casl$diss.byage,
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_casl_appsonly <- trim_netest(fit_casl_appsonly)

fit_casl_venuesapps <- netest(
    nw = nw_casl,
    formation = model_form_casl_venuesapps,
    target.stats = target_stats_casl_venuesapps,
    coef.diss = netstats$casl$diss.byage,
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_casl_venuesapps <- trim_netest(fit_casl_venuesapps)


# ONE-TIME PARTNERSHIPS --------------------------------------------

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
    "nodefactor('race', levels=-4)",
    "nodematch('race')",
    "nodefactor('deg.main', levels=-1)"
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
fit_inst_control <- netest(
    nw = nw_inst,
    formation = model_form_inst_control,
    target.stats = target_stats_inst_control,
    coef.diss = dissolution_coefs(~offset(edges), duration = 1),
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_inst_control <- trim_netest(fit_inst_control)

fit_inst_venuesonly <- netest(
    nw = nw_inst,
    formation = model_form_inst_venuesonly,
    target.stats = target_stats_inst_venuesonly,
    coef.diss = dissolution_coefs(~offset(edges), duration = 1),
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_inst_venuesonly <- trim_netest(fit_inst_venuesonly)

fit_inst_appsonly <- netest(
    nw = nw_inst,
    formation = model_form_inst_appsonly,
    target.stats = target_stats_inst_appsonly,
    coef.diss = dissolution_coefs(~offset(edges), duration = 1),
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_inst_appsonly <- trim_netest(fit_inst_appsonly)

fit_inst_venuesapps <- netest(
    nw = nw_inst,
    formation = model_form_inst_venuesapps,
    target.stats = target_stats_inst_venuesapps,
    coef.diss = dissolution_coefs(~offset(edges), duration = 1),
    set.control.ergm = do.call(control.ergm, ergm_fit_control_settings)
)
fit_inst_venuesapps <- trim_netest(fit_inst_venuesapps)

# =========================
# Save the ERGM fits 
# =========================

# A. CONTROL --------------------------------- 

out_control <- list(
    fit_main = fit_main_control,
    fit_casl = fit_casl_control,
    fit_inst = fit_inst_control
)
saveRDS(out_control, control_netest_out_fname)

# B. VENUES ONLY ---------------------------------

out_venuesonly <- list(
    fit_main = fit_main_venuesonly,
    fit_casl = fit_casl_venuesonly,
    fit_inst = fit_inst_venuesonly
)
saveRDS(out_venuesonly, venuesonly_netest_out_fname)


# C. APPS ONLY ---------------------------------

out_appsonly <- list(
    fit_main = fit_main_appsonly,
    fit_casl = fit_casl_appsonly,
    fit_inst = fit_inst_appsonly
)
saveRDS(out_appsonly, appsonly_netest_out_fname)


# D. VENUES + APPS ---------------------------------

out_venuesapps <- list(
    fit_main = fit_main_venuesapps,
    fit_casl = fit_casl_venuesapps,
    fit_inst = fit_inst_venuesapps
)
saveRDS(out_venuesapps, venuesapps_netest_out_fname)


# =========================
# Crete dataframes of coefficients for each treatment/scenario
# =========================

# A. CONTROL ---------------------------------

coef_df_control <- data.frame(
                treatment = "control",
                model = "main",
                term = names(fit_main_control$coef.form),
                estimate = fit_main_control$coef.form
            )

casl_df <- data.frame(
                treatment = "control",
                model = "casual",
                term = names(fit_casl_control$coef.form),
                estimate = fit_casl_control$coef.form
            )

inst_df <- data.frame(
                treatment = "control",
                model = "onetime",
                term = names(fit_inst_control$coef.form),
                estimate = fit_inst_control$coef.form
            )

coef_df_control <- dplyr::bind_rows(coef_df_control, casl_df)
coef_df_control <- dplyr::bind_rows(coef_df_control, inst_df)


# B. VENUES ONLY ---------------------------------

coef_df_venuesonly <- data.frame(
                treatment = "venues",
                model = "main",
                term = names(fit_main_venuesonly$coef.form),
                estimate = fit_main_venuesonly$coef.form
            )

casl_df <- data.frame(
                treatment = "venues",
                model = "casual",
                term = names(fit_casl_venuesonly$coef.form),
                estimate = fit_casl_venuesonly$coef.form
            )

inst_df <- data.frame(
                treatment = "venues",
                model = "onetime",
                term = names(fit_inst_venuesonly$coef.form),
                estimate = fit_inst_venuesonly$coef.form
            )

coef_df_venuesonly <- dplyr::bind_rows(coef_df_venuesonly, casl_df)
coef_df_venuesonly <- dplyr::bind_rows(coef_df_venuesonly, inst_df)

out_venuesonly <- list(
    fit_main = fit_main_venuesonly,
    fit_casl = fit_casl_venuesonly,
    fit_inst = fit_inst_venuesonly
)
saveRDS(out_venuesonly, paste0(est_dir, "netest-venues", context, ".rds"))

# C. APPS ONLY ---------------------------------

coef_df_appsonly <- data.frame(
                treatment = "apps",
                model = "main",
                term = names(fit_main_appsonly$coef.form),
                estimate = fit_main_appsonly$coef.form
            )

casl_df <- data.frame(
                treatment = "apps",
                model = "casual",
                term = names(fit_casl_appsonly$coef.form),
                estimate = fit_casl_appsonly$coef.form
            )

inst_df <- data.frame(
                treatment = "apps",
                model = "onetime",
                term = names(fit_inst_appsonly$coef.form),
                estimate = fit_inst_appsonly$coef.form
            )

coef_df_appsonly <- dplyr::bind_rows(coef_df_appsonly, casl_df)
coef_df_appsonly <- dplyr::bind_rows(coef_df_appsonly, inst_df)



# D. VENUES + APPS ---------------------------------

coef_df_venuesapps <- data.frame(
                treatment = "venuesapps",
                model = "main",
                term = names(fit_main_venuesapps$coef.form),
                estimate = fit_main_venuesapps$coef.form
            )

casl_df <- data.frame(
                treatment = "venuesapps",
                model = "casual",
                term = names(fit_casl_venuesapps$coef.form),
                estimate = fit_casl_venuesapps$coef.form
            )

inst_df <- data.frame(
                treatment = "venuesapps",
                model = "onetime",
                term = names(fit_inst_venuesapps$coef.form),
                estimate = fit_inst_venuesapps$coef.form
            )

coef_df_venuesapps <- dplyr::bind_rows(coef_df_venuesapps, casl_df)
coef_df_venuesapps <- dplyr::bind_rows(coef_df_venuesapps, inst_df)
