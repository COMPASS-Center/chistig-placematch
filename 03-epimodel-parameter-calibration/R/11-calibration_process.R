##
## 11. Epidemic Model Parameter Calibration, Processing of the simulation files
##

# Libraries --------------------------------------------------------------------
library("dplyr")
library("future.apply")

# Settings ---------------------------------------------------------------------
source("./R/utils-0_project_settings.R")
context <- if (!exists("context")) "local" else "hpc"

if (context == "local") {
  plan(sequential)
} else if (context == "hpc") {
  plan(multisession, workers = ncores)
} else  {
  stop("The `context` variable must be set to either 'local' or 'hpc'")
}

# ------------------------------------------------------------------------------
source("./R/utils-targets.R")
batches_infos <- EpiModelHPC::get_scenarios_batches_infos(calib_dir)

process_one_batch <- function(scenario_infos) {
  # d_sim <- readRDS(scenario_infos$file_name) %>% as_tibble()
  d_sim <- readRDS("./data/intermediate/calibration/sim__1__1.rds")# %>% as_tibble()

  plot(d_sim, y = "incid", main = "Population Size, Katie's Recommended a.rate")


  d_sim <- d_sim %>%
    mutate_calibration_targets()

  # Number and proportion of nodes by race (seems fine)
  d_sim %>% select(time, num, num.B, num.H, num.O, num.W) %>%
    mutate(prop.B = num.B/num,
           prop.H = num.H/num,
           prop.O = num.O/num,
           prop.W = num.W/num) %>%
    mutate(dev.B = prop.B - .2494,
           dev.H = prop.H - .3094,
           dev.O = prop.O - .111,
           dev.W = prop.W - .33) %>%
    select(time, starts_with("dev")) %>%
    tidyr::pivot_longer(cols = starts_with("dev"),
                        names_to = "race",
                        values_to = "val") %>%
    ggplot(aes(x = time, y = val, group = race, color = race)) +
    geom_line()

  # Number of new infections (Not sure if this is actually being logged, check modules)
  d_sim %>% select(time, num, num.B, num.H, num.O, num.W) %>%
    mutate(prop.B = num.B/num,
           prop.H = num.H/num,
           prop.O = num.O/num,
           prop.W = num.W/num) %>%
    mutate(dev.B = prop.B - .2494,
           dev.H = prop.H - .3094,
           dev.O = prop.O - .111,
           dev.W = prop.W - .33) %>%
    select(time, starts_with("dev")) %>%
    tidyr::pivot_longer(cols = starts_with("dev"),
                        names_to = "race",
                        values_to = "val") %>%
    ggplot(aes(x = time, y = val, group = race, color = race)) +
    geom_line()

  # INCIDENCE TAKES A SHARP DROP FROM THE START, NOT SURE WHY. HOW CAN WE BEST
  # KEEP TRACK OF NUMBER OF SEX ACTS OCCURRING IN TIME PERIOD?
  # Incidence
  d_sim %>% select(time, incid, incid.B, incid.H, incid.O, incid.W) %>%
    mutate(dev = incid - 5.08,
           dev.B = 3.02,
           dev.H = 1.15,
           dev.O = 0.31,
           dev.W = 0.6) %>%
    select(time, starts_with("dev")) %>%
    tidyr::pivot_longer(cols = starts_with("dev"),
                        names_to = "race",
                        values_to = "val") %>%
    ggplot(aes(x = time, y = val, group = race, color = race)) +
    geom_line()

  d_sim %>% select(time, incid, incid.B, incid.H, incid.O, incid.W) %>%
    tidyr::pivot_longer(cols = starts_with("incid"),
                        names_to = "race",
                        values_to = "val") %>%
    ggplot(aes(x = time, y = val, group = race, color = race)) +
    geom_line()

  # Diagnosed (proportion infected currently diagnosed)
  # Parameters to adjust: `hiv.test.rate`, `hiv.test.late.prob`
  d_sim %>% select(time, starts_with("cc.dx")) %>%
    mutate(dev.B = cc.dx.B - .804,
           dev.H = cc.dx.H - .799,
           dev.O = cc.dx.O - .826,
           dev.W = cc.dx.W - .881) %>%
    select(time, starts_with("dev")) %>%
    tidyr::pivot_longer(cols = starts_with("dev"),
                        names_to = "race",
                        values_to = "val") %>%
    ggplot(aes(x = time, y = val, group = race, color = race)) +
    geom_line()

  d_sim %>% select(time, starts_with("ir100")) %>%
    mutate(dev.B = ir100.B - 6.42,
           dev.H = ir100.H - 2.04,
           dev.O = ir100.O - 1.71,
           dev.W = ir100.W - 0.73) %>%
    select(time, starts_with("ir100")) %>%
    tidyr::pivot_longer(cols = starts_with("ir100"),
                        names_to = "race",
                        values_to = "val") %>%
    ggplot(aes(x = time, y = val, group = race, color = race)) +
    geom_line()

  d_sim %>% select(time, starts_with("endo.ir100")) %>%
    mutate(dev.B = ir100.B - (6.42 - mean(c(1.438, 1.798))),
           dev.H = ir100.H - (2.04 - mean(c(0.653, 0.816))),
           dev.O = ir100.O - (1.71 - mean(c(0.506, 0.633))),
           dev.W = ir100.W - (0.73 - mean(c(0.257, 0.3212)))) %>%
    select(time, starts_with("endo.ir100")) %>%
    tidyr::pivot_longer(cols = starts_with("endo.ir100"),
                        names_to = "race",
                        values_to = "val") %>%
    ggplot(aes(x = time, y = val, group = race, color = race)) +
    geom_line()

  d_sim %>% select(time, starts_with("exo.ir100")) %>%
    mutate(dev.B = ir100.B - (mean(c(1.438, 1.798))),
           dev.H = ir100.H - (mean(c(0.653, 0.816))),
           dev.O = ir100.O - (mean(c(0.506, 0.633))),
           dev.W = ir100.W - (mean(c(0.257, 0.3212)))) %>%
    select(time, starts_with("exo.ir100")) %>%
    tidyr::pivot_longer(cols = starts_with("exo.ir100"),
                        names_to = "race",
                        values_to = "val") %>%
    ggplot(aes(x = time, y = val, group = race, color = race)) +
    geom_line()



  d_sim2 <- d_sim %>% # from "R/utils-targets.R"
    filter(time >= max(time) - 52) # %>%

  d_sim3 <- d_sim2 %>%
  select(sim, any_of(names(targets))) #%>%
    group_by(sim) %>%
    summarise(across(
      everything(),
      ~ mean(.x, na.rm = TRUE)
    )) %>%
    ungroup()

  d_sim <- mutate(d_sim,
      scenario_name = scenario_infos$scenario_name,
      batch_number = scenario_infos$batch_number
    )

  select(d_sim, scenario_name, batch_number, sim, everything())
}

assessments_raw <- future_lapply(
  seq_len(nrow(batches_infos)),
  function(i) process_one_batch(batches_infos[i, ])
)

assessments_raw <- bind_rows(assessments_raw)
saveRDS(assessments_raw, "./data/intermediate/calibration/assessments_raw.rds")

assessments <- assessments_raw %>%
  select(- c(sim, batch_number)) %>%
  group_by(scenario_name) %>%
  summarise(across(
    everything(),
    list(
      q1 = ~ quantile(.x, 0.25, na.rm = TRUE),
      q2 = ~ quantile(.x, 0.50, na.rm = TRUE),
      q3 = ~ quantile(.x, 0.75, na.rm = TRUE)
    ),
    .names = "{.col}__{.fn}"
  ))

# Save the result --------------------------------------------------------------
saveRDS(assessments, "./data/intermediate/calibration/assessments.rds")
