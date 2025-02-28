###############################################################################
# Script Name:    radar_prelim.R
# Purpose:        set up parnership type data from RADAR
# Author:         Sara Rimer, Tom Wolff
# Date Created:   2025-01-22
# Last Modified:  2025-01-22
# Dependencies:   tidyverse, lubridate, yaml
# Notes:          RAW dataset is not stored on repository.
#                 Must use in conjunction with local data
###############################################################################


# =========================
# libraries
# =========================

library(tidyverse)
library(lubridate)
library(yaml)

# =========================
# read in yaml file
# =========================

args <- commandArgs(trailingOnly = TRUE)
print(args)
yamlfname <- args[1]
yamldata <- yaml.load_file(yamlfname)

# =========================
# setup parameters from YAML
# =========================

randomseed <- as.integer(yamldata$random.seed)
set.seed(randomseed)
time_unit <- yamldata$time.unit

# =========================
# define filenames/directories from YAML
# =========================

radar_alter_fname <- paste0(yamldata$radar.alter.data.dir, yamldata$radar.alter.data.fname) # nolint: line_length_linter.
radar_prep_fname <- paste0(yamldata$radar.prep.data.dir, yamldata$prep, yamldata$radar.prep.data.fname) # nolint
output_fname <- paste0(yamldata$radar.output.dir, yamldata$radar.output.fname) # nolint: line_length_linter.

# =========================
# User functions
# =========================

# From EpiModel team, custom function for anonymizing GLM outputs:
strip_glm <- function(cm){
  root_elts <- c("y", "model", "residuals", "fitted.values", "effects",
                 "linear.predictors", "weights", "prior.weights", "data")
  for (elt in root_elts) cm[[elt]] <- c()
  family_elts <- c("variance", "dev.resids", "aic", "validmu", "simulate")
  for (elt in family_elts) cm$family[[elt]] <- c()
  cm$qr$qr <- c()
  attr(cm$terms, ".Environment") <- c()
  attr(cm$formula, ".Environment") <- c()
  return(cm)
}


# Sets race combo for the race/ethnicity groups of RADAR data
# Original race combo set as follows:
#  race.combo <- c(1, 4, 6, 2, 3, 5)[race.combo]
#  NOTE:   In the empirical data from RADAR from which we are training these models,
#  there are no persistent partnerships that would be coded `5` (other/other).
#  To handle this absence, we are going to collapse categories `5` and `6` into
#  a single category (ego is OtherNH) and proceed from there.
get_race_combo <- function(race_p1, race_p2) {
  race.combo <- ifelse(race_p1 == race_p2, race_p1, race_p1 + 4)
  race.combo <- c(1, 3, 5, 7, 2, 4, 6, 8)[race.combo]
  race.combo <- ifelse(race.combo > 5, (race.combo - 1), race.combo)
  return(race.combo)
}

# =========================
# Read in and format alter and PrEP use data
# =========================

# Date formatting is different across the ego and alter datasets.
# Need to convert them to proper date objects to get workable duration measures
radar_alter <- read.csv(radar_alter_fname) %>%
  mutate(
    first_sex2 = as.Date(dyad_edge.firstSex, format = "%m/%d/%Y"),
    last_sex2 = as.Date(dyad_edge.lastSex, format = "%m/%d/%Y"),
    duration = as.numeric(last_sex2 - first_sex2),
    ego.race = case_when(
        RaceEth4_ego == "BlackNH" ~ 1,
        RaceEth4_ego == "Latinx" ~ 2,
        RaceEth4_ego == "OtherNH" ~ 3,
        RaceEth4_ego == "WhiteNH" ~ 4,
        TRUE ~ NA
        ),
    alter.race = case_when(
        RaceEth4_alter == "BlackNH" ~ 1,
        RaceEth4_alter == "Latinx" ~ 2,
        RaceEth4_alter == "OtherNH" ~ 3,
        RaceEth4_alter == "WhiteNH" ~ 4,
        TRUE ~ NA
        ),
    race.combo = get_race_combo(ego.race, alter.race),
    comb.age = age + alter.age,
    ptype = case_when(
        seriousRel == 1 ~ 1,
        one_night_stand_flag == 1 ~ 3,
        TRUE ~ 2
        ),
    hiv.concord.pos = case_when(
        hiv == 1 & dyad_edge.hivStatus == "HIV Positive" ~ 1,
        TRUE ~ 0
        ),
    # `acts` should be weekly rate of anal sex
    acts = case_when(
        dyad_edge.firstSexBefore6Months == TRUE ~ dyad_edge.analFreq / 26,
        TRUE ~ dyad_edge.analFreq / (duration / 7)
        ),
    condom_acts = case_when(
        dyad_edge.firstSexBefore6Months == TRUE ~ dyad_edge.analCondomFreq / 26,
        TRUE ~ dyad_edge.analCondomFreq / (duration / 7)),
    prob.cond = condom_acts / acts,
    prob.cond = ifelse(is.nan(prob.cond), NA, prob.cond),
    any.cond = prob.cond > 0,
    never.cond = prob.cond == 0,
    geogYN = ifelse(alter.resid_cat == "Chicago", 1, 0)
  )


# Read in and set up PrEP use measure
# NOTE: PrEP use is originally coded as 1 = yes, 0 = no, and NA if HIV positive,
# so we recode NAs to 0s in this use case
radar_prep <- read.csv(radar_prep_fname) %>%
  rename(egoid = radarid,
         wavenumber = visit) %>%

  mutate(prep = ifelse(prep02 == 1, 1, 0),
         prep = ifelse(is.na(prep), 0, prep)) %>%
  select(-prep02)


# Add PrEP use to RADAR data
radar_alter <- radar_alter %>%
  left_join(radar_prep, by = c("egoid", "wavenumber"))


# =========================
# Specify partnership type specifics
# =========================

# Setup persistent partnerships from RADAR data
persistent <- radar_alter %>%
  filter(one_night_stand_flag == 0) %>%
  select(
    alter.alter_id,
    ptype,
    duration.time = duration,
    duration.6plus = dyad_edge.firstSexBefore6Months,
    comb.age,
    geogYN,
    race.combo,
    hiv.concord.pos,
    prep = prep,
    acts,
    cp.acts = condom_acts,
    prob.cond,
    any.cond,
    never.cond
)


# Setup one-time partnerships from RADAR data
# NOTE: Because there is no time duration for one-time partnerships,
# rates of condom use need to be calculated differently
one_off <- radar_alter %>%
  filter(one_night_stand_flag == 1) %>%
  mutate(
    acts = dyad_edge.analFreq,
    cp.acts = dyad_edge.analCondomFreq,
    prob.cond = cp.acts/acts,
    prob.cond = ifelse(is.nan(prob.cond), NA, prob.cond),
    any.cond = prob.cond > 0,
    never.cond = prob.cond == 0) %>%
  select(
    alter.alter_id,
    ptype,
    duration.time = duration,
    duration.6plus = dyad_edge.firstSexBefore6Months,
    comb.age,
    geogYN,
    race.combo,
    hiv.concord.pos,
    prep = prep,
    acts,
    cp.acts = condom_acts,
    prob.cond,
    any.cond,
    never.cond
)


radar_alter %>%
  filter(ego.race == 3) %>%
  group_by(one_night_stand_flag) %>%
  summarize(count = n())


# Poisson model of sexual acts within partnership
acts.mod = glm(
  floor(acts*364/time_unit) ~
  as.factor(race.combo) + # Race/ethnicity
  as.factor(ptype) +   # Partnership type
  comb.age + I(comb.age^2) +   # Combined Age
  hiv.concord.pos,   # Combined HIV status
  family = poisson(),
  data = persistent
)

# Binomial model of condom use (persistent partnerships)
cond.mc.mod = glm(
  any.cond ~
  as.factor(race.combo) + # Race/ethnicity
  as.factor(ptype) + # Partnership type
  comb.age + I(comb.age^2) + # Combined Age
  hiv.concord.pos + # Combined HIV status
  prep + # PrEP use
  geogYN, # geogYN (for handling ARTNet-related specifications)
  family = binomial(),
  data = persistent
)

# Binomial model of condom use for one-time partnerships
cond.oo.mod = glm(
  prob.cond ~
  as.factor(race.combo) + # Race/ethnicity
  comb.age + I(comb.age^2) + # Combined Age
  hiv.concord.pos + # Combined HIV status
  prep + # PrEP use
  geogYN,  # geogYN (for handling ARTNet-related specifications)
  family = binomial(), data = one_off
)

# =========================
# Strip data from model objects
# =========================

acts.mod <- strip_glm(acts.mod)
cond.mc.mod <- strip_glm(cond.mc.mod)
cond.oo.mod <- strip_glm(cond.oo.mod)

# =========================
# Save the above model objects
# =========================

save(acts.mod, cond.mc.mod, cond.oo.mod, file = output_fname)
