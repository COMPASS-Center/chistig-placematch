get_race_combo <- function(race_p1, race_p2) {
  race.combo <- ifelse(race_p1 == race_p2, race_p1, race_p1 + 4)
  # Original
  # race.combo <- c(1, 4, 6, 2, 3, 5)[race.combo]
  race.combo <- c(1, 3, 5, 7, 2, 4, 6, 8)[race.combo]
  # In the empirical data from RADAR from which we're training these models,
  # there are no persistent partnerships that would be coded `5` (other/other).
  # To handle this absence, we're going to collapse categories `5` and `6` into
  # a single category (ego is OtherNH) and proceed from there.
  race.combo <- ifelse(race.combo > 5, (race.combo - 1), race.combo)
  return(race.combo)
}

library(tidyverse)
library(lubridate)

time.unit = 7

radar_alter <- read.csv("/Volumes/fsmresfiles/MSS/Birkett_Lab/Projects/chiSTIG/Data/Internal/chiSTIG/Final Datasets/alterlevel_11aug22.csv") %>%
  # Date formatting is different across the ego and alter datasets. Need to
  # convert them to proper date objects to get workable duration measures
  mutate(first_sex2 = as.Date(dyad_edge.firstSex, format = "%m/%d/%Y"),
         last_sex2 = as.Date(dyad_edge.lastSex, format = "%m/%d/%Y"),
         duration = as.numeric(last_sex2 - first_sex2),
         ego.race = case_when(RaceEth4_ego == "BlackNH" ~ 1,
                              RaceEth4_ego == "Latinx" ~ 2,
                              RaceEth4_ego == "OtherNH" ~ 3,
                              RaceEth4_ego == "WhiteNH" ~ 4,
                              TRUE ~ NA),
         alter.race = case_when(RaceEth4_alter == "BlackNH" ~ 1,
                                RaceEth4_alter == "Latinx" ~ 2,
                                RaceEth4_alter == "OtherNH" ~ 3,
                                RaceEth4_alter == "WhiteNH" ~ 4,
                                TRUE ~ NA),
         race.combo = get_race_combo(ego.race, alter.race),
         comb.age = age + alter.age,
         ptype = case_when(seriousRel == 1 ~ 1,
                           one_night_stand_flag == 1 ~ 3,
                           TRUE ~ 2),
         hiv.concord.pos = case_when(hiv == 1 & dyad_edge.hivStatus == "HIV Positive" ~ 1,
                                     TRUE ~ 0),
         # `acts` should be weekly rate of anal sex
         acts = case_when(dyad_edge.firstSexBefore6Months == TRUE ~ dyad_edge.analFreq/26,
                          TRUE ~ dyad_edge.analFreq/(duration/7)),
         condom_acts = case_when(dyad_edge.firstSexBefore6Months == TRUE ~ dyad_edge.analCondomFreq/26,
                                 TRUE ~ dyad_edge.analCondomFreq/(duration/7)),
         prob.cond = condom_acts/acts,
         prob.cond = ifelse(is.nan(prob.cond), NA, prob.cond),
         any.cond = prob.cond > 0,
         never.cond = prob.cond == 0,
         geogYN = ifelse(alter.resid_cat == "Chicago", 1, 0)
         # PrEP use. For now, I'm randomly assigning 1s based on mean
         # rate of use in ARTNet
         # prep = rbinom(n(), size = 1, prob = .1930576)
         )

# Read in PrEP use measure
radar_prep <- read.csv("/Volumes/fsmresfiles/MSS/Birkett_Lab/Projects/chiSTIG/Data/Internal/RADAR/Data Pull/prepData_2023-08-15.csv") %>%
  rename(egoid = radarid,
         wavenumber = visit) %>%
  # PrEP use is originally coded as 1 = yes, 0 = no, and NA if HIV positive
  # We need to recode NAs to 0s in this use case
  mutate(prep = ifelse(prep02 == 1, 1, 0),
         prep = ifelse(is.na(prep), 0, prep)) %>%
  select(-prep02)

radar_alter <- radar_alter %>%
  left_join(radar_prep, by = c("egoid", "wavenumber"))

persistent <- radar_alter %>%
  filter(one_night_stand_flag == 0) %>%
  select(alter.alter_id,
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
         never.cond)

#one-off
one_off <- radar_alter %>%
  filter(one_night_stand_flag == 1) %>%
  # Because there's no time duration for one-offs, rates of condom use
  # need to be calculated differently
  mutate(acts = dyad_edge.analFreq,
         cp.acts = dyad_edge.analCondomFreq,
         prob.cond = cp.acts/acts,
         prob.cond = ifelse(is.nan(prob.cond), NA, prob.cond),
         any.cond = prob.cond > 0,
         never.cond = prob.cond == 0) %>%
  select(alter.alter_id,
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
         never.cond)



radar_alter %>%
  filter(ego.race == 3) %>%
  group_by(one_night_stand_flag) %>%
  summarize(count = n())

# Poisson model of sexual acts within partnership

acts.mod = glm(floor(acts*364/time.unit) ~
  # Partnership duration
  # duration.time + I(duration_time^2) +
  # Race/ethnicity
  as.factor(race.combo) +
  # Partnership type
  as.factor(ptype) +
  # Duration*partnership type interaction
 # duration.time*as.factor(ptype) +
  # Combined Age
  comb.age + I(comb.age^2) +
  # Combined HIV status
  hiv.concord.pos,
family = poisson(), data = persistent)


# Binomial model of condom use (persistent partnerships)
cond.mc.mod = glm(any.cond ~
                 # Partnership duration
                 # duration.time + I(duration_time^2) +
                 # Race/ethnicity
                 as.factor(race.combo) +
                 # Partnership type
                 as.factor(ptype) +
                 # Duration*partnership type interaction
                 # duration.time*as.factor(ptype) +
                 # Combined Age
                 comb.age + I(comb.age^2) +
                 # Combined HIV status
                 hiv.concord.pos +
                 # PrEP use
                 prep +
                 # geogYN (not sure why)
                 geogYN,
               family = binomial(), data = persistent)

# Binomial model of condom use (one-offs)
cond.oo.mod = glm(prob.cond ~
                    # Race/ethnicity
                    as.factor(race.combo) +
                    # Combined Age
                    comb.age + I(comb.age^2) +
                    # Combined HIV status
                    hiv.concord.pos +
                    # PrEP use
                    prep +
                    # geogYN (not sure why)
                    geogYN,
                  family = binomial(), data = one_off)
