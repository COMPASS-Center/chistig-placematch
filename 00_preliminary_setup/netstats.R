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
library(tidyverse)


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
artnet_out <- readRDS(paste0(yamldata$artnet.output.dir, yamldata$artnet.output.fname)) # nolint
target_df <- read.csv(paste0(yamldata$synthpop.data.dir, yamldata$synthpop.target.values.fname)) # nolint
egos <- read.csv(paste0(yamldata$synthpop.data.dir, yamldata$synthpop.egos.fname)) # nolint
epistats <- readRDS(paste0(yamldata$epistats.dir, yamldata$epistats.fname)) # nolint

netstats_output_fname <- paste0(yamldata$netstats.dir, yamldata$netstats.fname)

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


# Netstats
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
    ##### age (`1:100`)
    ##### vec.asmr.B (something black)
    ##### vec.asmr.H (something hispanic)
    ##### vec.asmr.W (somethign white/other; adjust for our own categorization)

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
    # For now give everyone "versatile"
    # role.class = rep(2, nrow(egos)),

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
#    nodematch_age.grp = target_extract(term = "nodematch.age", model = "main"),
    nodematch_age.grp = c(target_extract(term = "nodematch.age.16to20", model = "main"),
                          target_extract(term = "nodematch.age.21to29", model = "main")),

    # nodefactor_age.grp
    # nodefactor_age.grp = c(target_extract(term = "nodefactor.age.16to20", model = "main"),
    #                        target_extract(term = "nodefactor.age.21to29", model = "main")),

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
    # nodematch_age.grp = target_extract(term = "nodematch.age", model = "casual"),
    nodematch_age.grp = c(target_extract(term = "nodematch.age.16to20", model = "casual"),
                          target_extract(term = "nodematch.age.21to29", model = "casual")),


    # nodefactor_age.grp
    # nodefactor_age.grp = c(target_extract(term = "nodefactor.age.16to20", model = "casual"),
    #                        target_extract(term = "nodefactor.age.21to29", model = "casual")),

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
    # nodematch_age.grp = c(target_extract(term = "nodematch.age.16to20", model = "one.time"),
    #                       target_extract(term = "nodematch.age.21to29", model = "one.time")),

    # nodefactor_age.grp
    # nodefactor_age.grp = c(target_extract(term = "nodefactor.age.16to20", model = "one.time"),
    #                        target_extract(term = "nodefactor.age.21to29", model = "one.time")),

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

    # edges
    # nodefactor_race
    # nodematch_race
    # nodematch_race_diffF (Ask)
    # nodefactor_age.grp
    # nodematch_age.grp
    # absdiff_age
    # absdiff_sqrtage
    # nodefactor_deg.tot
    # concurrent
    # nodefactor_diag.status

  )
)

saveRDS(netstats, netstats_output_fname)