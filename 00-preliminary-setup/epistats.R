###############################################################################
# Script Name:    epistats.R
# Purpose:        Initialize epistats
# Author:         Sara Rimer, Tom Wolff
# Date Created:   2025-01-22
# Last Modified:  2025-01-22
# Dependencies:   yaml
# Notes:          
###############################################################################


# =========================
# libraries
# =========================

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
# source input data 
# =========================

# load RADAR data
radar_data <- readRDS(paste0(yamldata$radar.output.dir, yamldata$radar.output.fname))
epistats_output_fname <- paste0(yamldata$epistats.dir, yamldata$epistats.fname)


# =========================
# Initialize Epistats with RADAR data
# =========================

# Epistats
epistats <- list(
  # geogYN.l : binary victor of case memberships in geographical area (long)
  geogYN.l = NULL,

  # geog.YN.d : binary vector of case memberships in geographic area (wide)
  geogYN.d = NULL,

  # geog.cat : character indicating what locale case is in (ex. "Atlanta")
  geog.cat = NULL,
  # geog.lvl : character indicating type of geographic area (ex. "city)
  geog.lvl = NULL,

  # race : logical indicating if model estimates should be stratified by
  # racial/ethnic categorization
  race = TRUE,

  # acts.mod : poisson model of number of sexual acts occurring within a
  # partnership during select time interval
  acts.mod = radar_data$acts.mod,

  # cond.mc.mod : binomial model of probability of condom use within partnership
  # (main and casual partnerships)
  cond.mc.mod = radar_data$cond.mc.mod,

  # cond.oo.mod : binomial model of probability of condom use within one-off
  # partnerships
  cond.oo.mod = radar_data$cond.oo.mod,

  # geog.l : long vector of geographic location
  geog.l = NULL,

  # geog.d : wide vector of geographic location
  geog.d = NULL,

  # age.limits : age limits specified by user
  age.limits = c(16, 30),

  # age.breaks : breaks for age categories
  age.breaks = c(16, 21, 30), # Confirm this is the right coding

  # age.grps : number of age group categories in model
  age.grps = 2,

  # age.sexual.cessation : age at which people stop having sex in the model
  age.sexual.cessation = 30,

  # sex.cess.mod :
  sex.cess.mod = FALSE,

  # init.hiv.prev : Initial HIV prevalence by each racial group
  # REPLACE WITH FINAL CDPH NUMBERS DIVIDED BY SARA'S POPULATION
  # ESTIMATES TODO: Is this done? XX
  init.hiv.prev = c(.1215, .0474, .014, .0268),

  # time.unit : Number of days in each time period
  time.unit = time_unit

)

saveRDS(epistats, epistats_output_fname)
