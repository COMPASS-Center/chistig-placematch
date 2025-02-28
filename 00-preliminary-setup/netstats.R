###############################################################################
# Script Name:    netstats.R
# Purpose:        Code for generating initial netstats object
# Author:         Sara Rimer, Tom Wolff
# Date Created:   2025-01-22
# Last Modified:  2025-01-22
# Dependencies:
# Notes:
###############################################################################


# =========================
# libraries
# =========================

library("EpiModelHIV")
# library(tidyverse)
library(yaml)


# =========================
# read in yaml file
# =========================

args <- commandArgs(trailingOnly = TRUE)
yamlfname <- args[1]
yamldata <- yaml.load_file(yamlfname)


# =========================
# setup YAML parameters
# =========================

randomseed <- as.integer(yamldata$random.seed)
set.seed(randomseed)


# =========================
# define filenames/directories from YAML
# =========================
dur_coefs <- readRDS(paste0(yamldata$artnet.output.dir, yamldata$artnet.output.fname)) # nolint # Duration/dissolution coefficients based on ARTNet data.
target_df <- read.csv(paste0(yamldata$synthpop.data.dir, yamldata$synthpop.target.values.fname)) # nolint
egos <- read.csv(paste0(yamldata$synthpop.data.dir, yamldata$synthpop.egos.fname)) # nolint
epistats <- readRDS(paste0(yamldata$epistats.dir, yamldata$epistats.fname)) # nolint

netstats_output_fname <- paste0(yamldata$netstats.dir, yamldata$netstats.fname)


# =========================
# target stats function
# =========================

# Function for quickly extracting target values from dataframe
target_extract = function(df = target_df, term, model) {
  this_row <- which(df$X == term)
  this_col <- which(colnames(df) == paste("mean_", model, sep = ""))
  target_val <- df[this_row, this_col]
  return(target_val)
}


# =========================
# format and setup egos
# =========================
egos <- egos %>%
  dplyr::mutate(race_art = dplyr::case_when(
                                    race_ethnicity == "whiteNH" ~ "white",
                                    race_ethnicity == "blackNH" ~ "black",
                                    race_ethnicity == "hispanic" ~ "hispanic",
                                    race_ethnicity == "otherNH" ~ "other",
                                    TRUE ~ NA),
                race_art2 = dplyr::case_when(
                                    race_ethnicity == "whiteNH" ~ "4_white",
                                    race_ethnicity == "blackNH" ~ "1_black",
                                    race_ethnicity == "hispanic" ~ "2_hispanic",
                                    race_ethnicity == "otherNH" ~ "3_other",
                                    TRUE ~ NA),
                race = dplyr::case_when(
                                race_ethnicity == "whiteNH" ~ 4,
                                race_ethnicity == "blackNH" ~ 1,
                                race_ethnicity == "hispanic" ~ 2,
                                race_ethnicity == "otherNH" ~ 3,
                                TRUE ~ NA),
                age.grp = agegroup,
                age = age,
                deg.main = init_ser_cat,
                deg.casl = init_cas_cat,
                deg.tot = init_pers_cat,
                venues_all = venue_list_1week
  )


# =========================
# set up age-sex-specific mortality rates
# =========================

## Age-sex-specific mortality rates (B, H, W)
#  in 1-year age decrements starting with age 1
#  from CDC NCHS Underlying Cause of Death database (for 2020)
asmr.B <- c(0.00079, 0.00046, 0.00030, 0.00025, 0.00024, 0.00025, 0.00019,
            0.00019, 0.00021, 0.00020, 0.00026, 0.00026, 0.00038, 0.00056,
            0.00077, 0.00100, 0.00151, 0.00227, 0.00271, 0.00264, 0.00297,
            0.00302, 0.00315, 0.00319, 0.00322, 0.00319, 0.00336, 0.00337,
            0.00330, 0.00363, 0.00396, 0.00392, 0.00407, 0.00428, 0.00411,
            0.00453, 0.00485, 0.00486, 0.00533, 0.00513, 0.00575, 0.00580,
            0.00628, 0.00671, 0.00669, 0.00750, 0.00773, 0.00858, 0.00934,
            0.00947, 0.00999, 0.01141, 0.01216, 0.01360, 0.01432, 0.01517,
            0.01699, 0.01853, 0.02021, 0.02099, 0.02366, 0.02547, 0.02877,
            0.02979, 0.03104, 0.03467, 0.03653, 0.03941, 0.04114, 0.04320,
            0.04487, 0.04879, 0.05100, 0.05678, 0.05611, 0.06384, 0.06891,
            0.07399, 0.07682, 0.08209, 0.08938, 0.09737, 0.10400, 0.11336,
            0.16336)
asmr.H <- c(0.00032, 0.00021, 0.00018, 0.00011, 0.00011, 0.00009, 0.00010,
            0.00009, 0.00009, 0.00012, 0.00013, 0.00015, 0.00016, 0.00025,
            0.00036, 0.00058, 0.00076, 0.00106, 0.00125, 0.00134, 0.00145,
            0.00156, 0.00164, 0.00166, 0.00164, 0.00159, 0.00176, 0.00172,
            0.00201, 0.00198, 0.00192, 0.00191, 0.00202, 0.00204, 0.00219,
            0.00223, 0.00251, 0.00246, 0.00272, 0.00272, 0.00298, 0.00307,
            0.00321, 0.00351, 0.00367, 0.00391, 0.00442, 0.00484, 0.00512,
            0.00521, 0.00616, 0.00649, 0.00714, 0.00790, 0.00863, 0.00938,
            0.00992, 0.01094, 0.01222, 0.01217, 0.01464, 0.01483, 0.01630,
            0.01731, 0.01850, 0.02054, 0.02269, 0.02321, 0.02515, 0.02734,
            0.02937, 0.03064, 0.03349, 0.03670, 0.03980, 0.04387, 0.04724,
            0.05151, 0.05591, 0.05902, 0.06345, 0.07317, 0.07849, 0.08617,
            0.13436)
asmr.W <- c(0.00034, 0.00023, 0.00019, 0.00014, 0.00014, 0.00010, 0.00010,
            0.00009, 0.00009, 0.00012, 0.00014, 0.00015, 0.00022, 0.00028,
            0.00036, 0.00050, 0.00059, 0.00082, 0.00096, 0.00104, 0.00126,
            0.00128, 0.00134, 0.00144, 0.00153, 0.00163, 0.00172, 0.00186,
            0.00194, 0.00205, 0.00220, 0.00225, 0.00238, 0.00245, 0.00247,
            0.00264, 0.00274, 0.00280, 0.00306, 0.00312, 0.00324, 0.00329,
            0.00344, 0.00354, 0.00371, 0.00405, 0.00442, 0.00479, 0.00511,
            0.00547, 0.00599, 0.00653, 0.00706, 0.00768, 0.00827, 0.00922,
            0.00978, 0.01065, 0.01151, 0.01235, 0.01349, 0.01437, 0.01548,
            0.01664, 0.01730, 0.01879, 0.01986, 0.02140, 0.02263, 0.02419,
            0.02646, 0.02895, 0.03031, 0.03625, 0.03753, 0.04268, 0.04631,
            0.05235, 0.05724, 0.06251, 0.06934, 0.07589, 0.08669, 0.09582,
            0.16601)
asmr.O <- c(0.00034, 0.00023, 0.00019, 0.00014, 0.00014, 0.00010, 0.00010,
            0.00009, 0.00009, 0.00012, 0.00014, 0.00015, 0.00022, 0.00028,
            0.00036, 0.00050, 0.00059, 0.00082, 0.00096, 0.00104, 0.00126,
            0.00128, 0.00134, 0.00144, 0.00153, 0.00163, 0.00172, 0.00186,
            0.00194, 0.00205, 0.00220, 0.00225, 0.00238, 0.00245, 0.00247,
            0.00264, 0.00274, 0.00280, 0.00306, 0.00312, 0.00324, 0.00329,
            0.00344, 0.00354, 0.00371, 0.00405, 0.00442, 0.00479, 0.00511,
            0.00547, 0.00599, 0.00653, 0.00706, 0.00768, 0.00827, 0.00922,
            0.00978, 0.01065, 0.01151, 0.01235, 0.01349, 0.01437, 0.01548,
            0.01664, 0.01730, 0.01879, 0.01986, 0.02140, 0.02263, 0.02419,
            0.02646, 0.02895, 0.03031, 0.03625, 0.03753, 0.04268, 0.04631,
            0.05235, 0.05724, 0.06251, 0.06934, 0.07589, 0.08669, 0.09582,
            0.16601)

# transformed to rates by time unit
trans.asmr.H <- 1 - (1 - asmr.H)^(1 / (364 / epistats$time.unit))
trans.asmr.W <- 1 - (1 - asmr.W)^(1 / (364 / epistats$time.unit))
trans.asmr.B <- 1 - (1 - asmr.B)^(1 / (364 / epistats$time.unit))
trans.asmr.O <- 1 - (1 - asmr.O)^(1 / (364 / epistats$time.unit))

# Transformed rates, 85+ rate for ages 85 - 100
vec.asmr.B <- c(trans.asmr.B, rep(tail(trans.asmr.B, n = 1), 15))
vec.asmr.H <- c(trans.asmr.H, rep(tail(trans.asmr.H, n = 1), 15))
vec.asmr.W <- c(trans.asmr.W, rep(tail(trans.asmr.W, n = 1), 15))
vec.asmr.O <- c(trans.asmr.O, rep(tail(trans.asmr.O, n = 1), 15))

asmr <- data.frame(age = 1:100,
                   vec.asmr.B,
                   vec.asmr.H,
                   vec.asmr.W,
                   vec.asmr.O)

# Setting deterministic mortality prob = 1 at upper age limit
max.age <- epistats$age.limits[2]
asmr[asmr$age >= max.age, ] <- 1



# =========================
# create initial netstats object for main, casual, and one-time partnerships
# =========================

netstats <- list(
  # demog : list of demographic information for network
  demog = list(

    # num : network size (nodes)
    num = nrow(egos),

    # props : proportion of nodes in each racial/ethnic category
    # Looks like it's a data frame
    props = data.frame("White" = sum(egos$race == 4) / nrow(egos),
                       "Black" = sum(egos$race == 1) / nrow(egos),
                       "Hispanic" = sum(egos$race == 2) / nrow(egos),
                       "Other" = sum(egos$race == 3) / nrow(egos)),

    # num.B : proportion of nodes black
    num.B = sum(egos$race == 1)/nrow(egos),

    # num.H : proportion of nodes hispanic
    num.H = sum(egos$race == 2)/nrow(egos),

    # num.W : proportion of nodes white/other (adjust for our own categorization
    # schema)
    num.W = sum(egos$race == 4)/nrow(egos),

    # num.O : proportion of nodes other race?
    num.O = sum(egos$race == 3)/nrow(egos),

    # asmr : dataframe containing 100 rows (possible age range) with age-specific
    # mortality rates
    asmr = asmr,

    # ages : vector of valid age values in simulation
    ages = epistats$age.limits[[1]]:epistats$age.limits[[2]],

    # age.breaks : vector of categorical age cutoffs
    age.breaks = epistats$age.breaks),

  # geog.lvl : character of geographic level
  geog.lvl = NULL,

  # race : logical if things should be broken down by race
  race = TRUE,

  # time.unit : numeric value indicating number of days in each network step
  time.unit = 7,

  # attr : list of node-level attributs
  attr = list(

    # Original ego identifiers
    numeric.id = egos$numeric_id,
    egoid = egos$egoid,

    # age : numeric vector of node ages
    age = egos$age,

    # sqrt.age : square root of ages
    sqrt.age = egos$sqrt.age,

    # age.grp : numeric designation of age group membership
    age.grp = egos$age.grp,

    # active.sex : 1/0 indicator of if node is sexually active
    active.sex = egos$active.sex,

    # race : numeric designation of racial/ethnic categorization
    race = egos$race,

    # deg.casl : degree in casual network
    deg.casl = egos$deg.casl,

    # deg.main : degree in main network
    deg.main = egos$deg.main,

    # deg.tot : total degree
    deg.tot = egos$deg.tot,

    # risk.grp : risk group (investigate for what this means practically)

    # role.class : Preference for sexual position during acts
    # Randomly assign to nodes according to proportions derived from RADAR by
    # Morgan et al. (2021)
    role.class = sample(0:2, size = nrow(egos), replace = TRUE, prob = c(73, 87, 475)/sum(c(73, 87, 475))),

    # diag.status : I believe this is HIV status
    diag.status = egos$diag.status,

    # venues_all
    venues.all = egos$venues.all,

    # apps_all
    apps.all = egos$apps.all

  ),

  # main : list of target stats and dissolution model for main partnerships
  main = list(

    # edges
    edges = target_extract(df = target_df,
                           term = "edges",
                           model = "main"),

    # nodematch_age.grp
    nodematch_age.grp = c(target_extract(term = "nodematch.age.16to20", model = "main"),
                          target_extract(term = "nodematch.age.21to29", model = "main")),

    # concurrent
    concurrent = target_extract(df = target_df,
                                term = "concurrent",
                                model = "main"),

    # nodefactor race
    nodefactor_race = c(target_extract(term = "nodefactor.race_ethnicity.blackNH", model = "main"),
                        target_extract(term = "nodefactor.race_ethnicity.hispanic", model = "main"),
                        target_extract(term = "nodefactor.race_ethnicity.otherNH", model = "main"),
                        target_extract(term = "nodefactor.race_ethnicity.whiteNH", model = "main")),

    # nodematch race
    nodematch_race = target_extract(term = "nodematch.race_ethnicity", model = "main"),

    # nodematch black
    nodematch_race.1 = target_extract(term = "nodematch.race_ethnicity.blackNH", model = "main"),

    # nodefactor_init_cas_cat
    nodefactor_deg.casl = c(target_extract(term = "nodefactor.init_cas_cat.0", model = "main"),
                            target_extract(term = "nodefactor.init_cas_cat.1", model = "main"),
                            target_extract(term = "nodefactor.init_cas_cat.2+", model = "main")),

    # fuzzynodematch_venues_all
    fuzzynodematch_venues.all = target_extract(term = "fuzzynodematch.venues_all.TRUE", model = "main"),

    # fuzzynodematch_apps_all
    fuzzynodematch_apps.all = target_extract(term = "fuzzynodematch.apps_all.TRUE", model = "main"),

    # fuzzynodematch_apps_dating
    fuzzynodematch_apps.dating = target_extract(term = "fuzzynodematch.apps_dating.TRUE", model = "main"),

    # dissolution model
    dissolution = dissolution_coefs(~offset(edges), duration = 115, d.rate = 0.001386813),

    diss.homog = dissolution_coefs(dissolution = ~offset(edges),
                                             duration = artnet_out$main$durs.main.homog$mean.dur.adj,
                                             d.rate = 0.001386813),
    diss.byage = dissolution_coefs(dissolution = ~offset(edges) +
                                               offset(nodematch("age.grp", diff = TRUE)),
                                             duration = artnet_out$main$durs.main.byage$mean.dur.adj,
                                             d.rate = 0.001386813)

  ),

  # casl : same deal as above but for casual network
  casl = list(

    edges = target_extract(df = target_df,
                           term = "edges",
                           model = "casual"),

    # nodematch_age.grp
    nodematch_age.grp = c(target_extract(term = "nodematch.age.16to20", model = "casual"),
                          target_extract(term = "nodematch.age.21to29", model = "casual")),

    # concurrent
    concurrent = target_extract(df = target_df,
                                term = "concurrent",
                                model = "casual"),

    # nodefactor race
    nodefactor_race = c(target_extract(term = "nodefactor.race_ethnicity.blackNH", model = "casual"),
                        target_extract(term = "nodefactor.race_ethnicity.hispanic", model = "casual"),
                        target_extract(term = "nodefactor.race_ethnicity.otherNH", model = "casual"),
                        target_extract(term = "nodefactor.race_ethnicity.whiteNH", model = "casual")),

    # nodematch race
    nodematch_race = target_extract(term = "nodematch.race_ethnicity", model = "casual"),

    # nodematch black
    nodematch_race.1 = target_extract(term = "nodematch.race_ethnicity.blackNH", model = "casual"),

    # nodefactor_init_cas_cat
    nodefactor_deg.main = c(target_extract(term = "nodefactor.init_ser_cat.0", model = "casual"),
                            target_extract(term = "nodefactor.init_ser_cat.1+", model = "casual")),

    # fuzzynodematch_venues_all
    fuzzynodematch_venues.all = target_extract(term = "fuzzynodematch.venues_all.TRUE", model = "casual"),

    # fuzzynodematch_apps_all
    fuzzynodematch_apps.all = target_extract(term = "fuzzynodematch.apps_all.TRUE", model = "casual"),

    # fuzzynodematch_apps_dating
    fuzzynodematch_apps.dating = target_extract(term = "fuzzynodematch.apps_dating.TRUE", model = "casual"),

    # dissolution model
    dissolution = dissolution_coefs(~offset(edges), duration = 72, d.rate = 0.001386813),

    diss.homog = dissolution_coefs(dissolution = ~offset(edges),
                                             duration = artnet_out$casl$durs.casl.homog$mean.dur.adj,
                                             d.rate = 0.001386813),
    diss.byage = dissolution_coefs(dissolution = ~offset(edges) +
                                               offset(nodematch("age.grp", diff = TRUE)),
                                             duration = artnet_out$casl$durs.casl.byage$mean.dur.adj,
                                             d.rate = 0.001386813)

  ),

  # inst : more or less same as above but for one-off network
  inst = list(

    edges = target_extract(df = target_df,
                           term = "edges",
                           model = "one.time"),

    # nodefactor race
    nodefactor_race = c(target_extract(term = "nodefactor.race_ethnicity.blackNH", model = "one.time"),
                        target_extract(term = "nodefactor.race_ethnicity.hispanic", model = "one.time"),
                        target_extract(term = "nodefactor.race_ethnicity.otherNH", model = "one.time"),
                        target_extract(term = "nodefactor.race_ethnicity.whiteNH", model = "one.time")),

    # nodematch race
    nodematch_race = target_extract(term = "nodematch.race_ethnicity", model = "one.time"),

    # nodematch black
    nodematch_race.1 = target_extract(term = "nodematch.race_ethnicity.blackNH", model = "one.time"),

    # nodematch_age.grp
    nodematch_age.grp = target_extract(term = "nodematch.age", model = "one.time"),

    # nodefactor_init_pers_cat
    nodefactor_deg.tot = c(target_extract(term = "nodefactor.init_pers_cat.0", model = "one.time"),
                           target_extract(term = "nodefactor.init_pers_cat.1", model = "one.time"),
                           target_extract(term = "nodefactor.init_pers_cat.2", model = "one.time"),
                           target_extract(term = "nodefactor.init_pers_cat.3+", model = "one.time")),

    # fuzzynodematch_venues_all
    fuzzynodematch_venues.all = target_extract(term = "fuzzynodematch.venues_all.TRUE", model = "one.time"),

    # fuzzynodematch_apps_all
    fuzzynodematch_apps.all = target_extract(term = "fuzzynodematch.apps_all.TRUE", model = "one.time"),

    # fuzzynodematch_apps_dating
    fuzzynodematch_apps.dating = target_extract(term = "fuzzynodematch.apps_dating.TRUE", model = "one.time")

  )
)

saveRDS(netstats, netstats_output_fname)
