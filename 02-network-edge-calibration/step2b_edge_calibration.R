### libraries
library(yaml)
library(dplyr)
library(ARTnetData)
library(EpiModelHIV)
library(ARTnet)


### Load yaml and other commandline arguments
args <- commandArgs(trailingOnly = TRUE)
yamlfname <- args[1]
yamldata <- yaml.load_file(yamlfname)
calibration_set_num <- as.integer(args[2])
# thismodel <- args[3]
thistreatmenttype <- args[3] # basic (control), venues only (venues), apps only (apps), venues+apps (both)
thispartnershiptype <- args[4] # "main" #main, casual, one-time
thisseed <- as.integer(args[5])


set.seed(thisseed)
print(paste("Random seed number:", thisseed, sep=" "))

### Name datafiles 
drate_mat_fname <- paste0(yamldata$repo.dir, yamldata$calibration.matrix.subdir, yamldata$expname, "/", yamldata$calibration.matrix.fname, "_", yamldata$expname, ".csv")
egos_fname <- paste0(yamldata$repo.dir, yamldata$synthpop.subdir, yamldata$synthpop.fname)


### Read in the calibration input matrix 
drate_mat_full <- read.csv(drate_mat_fname)
num_calibration_scenarios <- max(drate_mat_full$fit_no) 


### Load synthetic population of egos 
egos <- read.csv(egos_fname) %>%
  dplyr::mutate(race_art = dplyr::case_when(race_ethnicity == "whiteNH" ~ "white",
                                            race_ethnicity == "blackNH" ~ "black",
                                            race_ethnicity == "hispanic" ~ "hispanic",
                                            race_ethnicity == "otherNH" ~ "other",
                                            TRUE ~ NA),
                race_art2 = dplyr::case_when(race_ethnicity == "whiteNH" ~ "4_white",
                                             race_ethnicity == "blackNH" ~ "1_black",
                                             race_ethnicity == "hispanic" ~ "2_hispanic",
                                             race_ethnicity == "otherNH" ~ "3_other",
                                             TRUE ~ NA),
                race = dplyr::case_when(race_ethnicity == "whiteNH" ~ 4,
                                        race_ethnicity == "blackNH" ~ 1,
                                        race_ethnicity == "hispanic" ~ 2,
                                        race_ethnicity == "otherNH" ~ 3,
                                        TRUE ~ NA),
                age.grp = agegroup,
                age = age,
                deg.main = init_ser_cat,
                deg.casl = init_cas_cat,
                deg.tot = init_pers_cat,

                # venues_all = venue_list)

                venues_all = venue_list_1week)


egos <- egos %>%
  mutate(sqrt.age = sqrt(age),
         active.sex = 1,
         age.grp = ifelse(age.grp == "16to20", 1, 2),
         apps.all = app_list) %>%
  select(numeric_id, egoid,
         age, sqrt.age, agegroup, age.grp,
         race.ethnicity = race_ethnicity, race,
         deg.casl, deg.main, deg.tot,
         # risk.grp ?
         diag.status = hiv_status,
         venues.all = venues_all,
         apps.all,
         active.sex)


### Load netstats object
# for (i in 1:num_calibration_scenarios){
# netstats <- readRDS(paste0(yamldata$repo.dir, yamldata$netest.subdir, "netstats_", yamldata$expname, "_", i, ".rds"))
netstats <- readRDS(paste0(yamldata$repo.dir, yamldata$netest.subdir, "netstats_", yamldata$expname, "_", calibration_set_num, ".rds"))


### Initialize network
nw <- network::network.initialize(n = nrow(egos),
                                  loops = FALSE,
                                  directed = FALSE)

attr_names <- names(netstats$attr)
attr_values <- netstats$attr

nw_main <- EpiModel::set_vertex_attribute(nw, attr_names, attr_values)
nw_casl <- nw_main
nw_inst <- nw_main


if (thistreatmenttype == 'control') {

	if (thispartnershiptype == 'main') {

		print("Control - Main (A1)")

		model_main <- ~ edges +
		  # nodefactor("age.grp", levels = 1) +
		  nodematch("age.grp", diff = TRUE) +
		  # nodematch("age.grp", levels = -1) +
		  concurrent +
		  nodefactor("race", levels = -4) +
		  nodematch("race") +
		  # nodematch("race", diff = TRUE, levels = 1) +
		  nodefactor("deg.casl", levels= -1)


		target.stats.main <- c(
		  edges = netstats$main$edges,
		  # nodefactor_age.grp = netstats$main$nodefactor_age.grp[1],
		  nodematch_age.grp = netstats$main$nodematch_age.grp,
		  # nodematch_age.grp = netstats$main$nodematch_age.grp[-1],
		  concurrent = netstats$main$concurrent,
		  nodefactor_race = netstats$main$nodefactor_race[1:3],
		  nodematch_race = netstats$main$nodematch_race,
		  # nodematch_race.1 = netstats$main$nodematch_race.1,
		  nodefactor_deg.casl = netstats$main$nodefactor_deg.casl[-1]
		)
		target.stats.main <- unname(target.stats.main)


		fit_main <- netest(
		  nw = nw_main,
		  formation = model_main,
		  target.stats = target.stats.main,
		  coef.diss = netstats$main$diss.byage,
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_main <- trim_netest(fit_main)

		main_df <- data.frame(treatment = "Basic",
	                      model = "Main",
	                      term = names(fit_main$coef.form),
	                      estimate = fit_main$coef.form)

		saveRDS(fit_main, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_control_main_", calibration_set_num, ".rds"))
		write.csv(main_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_control_main_", calibration_set_num, ".csv"))
	
	} else if (thispartnershiptype == 'casual') {

		print("Control - Casual (A2)")

		model_casl <- ~ edges +
		  # nodefactor("age.grp", levels= 1) +
		  nodematch("age.grp", diff = TRUE) +
		  concurrent +
		  nodefactor("race", levels=-4) +
		  nodematch("race") +
		  # nodematch("race", diff=TRUE, levels=1) +
		  nodefactor("deg.main", levels=-1)

		target.stats.casl <- c(
		  edges =                           netstats$casl$edges,
		  # nodefactor_age.grp =            netstats$casl$nodefactor_age.grp[1],
		  nodematch_age.grp =             netstats$casl$nodematch_age.grp,
		  concurrent =                      netstats$casl$concurrent,
		  nodefactor_race =               netstats$casl$nodefactor_race[1:3],
		  nodematch_race =                netstats$casl$nodematch_race,
		  # nodematch_race.1 =              netstats$casl$nodematch_race.1,
		  nodefactor_deg.main =           netstats$casl$nodefactor_deg.main[-1]
		)
		target.stats.casl <- unname(target.stats.casl)

		fit_casl <- netest(
		  nw = nw_casl,
		  formation = model_casl,
		  target.stats = target.stats.casl,
		  coef.diss = netstats$casl$diss.byage,
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_casl <- trim_netest(fit_casl)

		casl_df <- data.frame(treatment = "Basic",
		                      model = "Casual",
		                      term = names(fit_casl$coef.form),
		                      estimate = fit_casl$coef.form)

		saveRDS(fit_casl, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_control_casual_", calibration_set_num, ".rds"))
		write.csv(casl_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_control_casual_", calibration_set_num, ".csv"))

	} else if (thispartnershiptype == 'onetime') {

		print("Control - Inst (A3)")

		model_inst <-  ~ edges +
		  # nodefactor("age.grp", levels = 1) +
		  nodematch("age.grp", diff = TRUE) +
		  nodefactor("race", levels=-4) +
		  nodematch("race") +
		  # nodematch("race", diff=TRUE, levels=1) +
		  nodefactor("deg.tot", levels=-1)

		target.stats.inst <- c(
		  edges =                           netstats$inst$edges,
		  # nodefactor_age.grp =            netstats$inst$nodefactor_age.grp[1],
		  nodematch_age.grp =             netstats$inst$nodematch_age.grp,
		  nodefactor_race =               netstats$inst$nodefactor_race[1:3],
		  nodematch_race =                netstats$inst$nodematch_race,
		  # nodematch_race.1 =              netstats$inst$nodematch_race.1,
		  nodefactor_deg.tot =           netstats$inst$nodefactor_deg.tot[-1]
		)
		target.stats.inst <- unname(target.stats.inst)

		fit_inst <- netest(
		  nw = nw_inst,
		  formation = model_inst,
		  target.stats = target.stats.inst,
		  coef.diss = dissolution_coefs(~offset(edges), duration = 1),
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_inst <- trim_netest(fit_inst)

		inst_df <- data.frame(treatment = "Basic",
		                      model = "Onetime",
		                      term = names(fit_inst$coef.form),
		                      estimate = fit_inst$coef.form)

		saveRDS(fit_inst, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_control_onetime_", calibration_set_num, ".rds"))
		write.csv(inst_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_control_onetime_", calibration_set_num, ".csv"))

	} else {

		print("ERROR: PARTNERSHIP TYPE NOT CORRECTLY SPECIFIED")

	}

} else if (thistreatmenttype == 'both') {

	if (thispartnershiptype == 'main') {

		print("Both - Main (B1)")

		model_main <- ~ edges +
		  # nodefactor("age.grp", levels= 1) +
		  nodematch("age.grp", diff = TRUE) +
		  concurrent +
		  nodefactor("race", levels = -4) +
		  nodematch("race") +
		  # nodematch("race", diff = TRUE, levels = 1) +

		  nodefactor("deg.casl", levels= -1) +
		  fuzzynodematch("venues.all", binary=TRUE) +
		  fuzzynodematch("apps.all", binary = TRUE)
		# fuzzynodematch("apps_nondating", binary=TRUE)


		target.stats.main <- c(
		  edges = netstats$main$edges,
		  # nodefactor_age.grp = netstats$main$nodefactor_age.grp[1],
		  nodematch_age.grp = netstats$main$nodematch_age.grp,
		  concurrent = netstats$main$concurrent,
		  nodefactor_race = netstats$main$nodefactor_race[1:3],
		  nodematch_race = netstats$main$nodematch_race,
		  # nodematch_race.1 = netstats$main$nodematch_race.1,

		  nodefactor_deg.casl = netstats$main$nodefactor_deg.casl[-1],
		  fuzzynodematch_venues.all = netstats$main$fuzzynodematch_venues.all,
		  fuzzynodematch_apps.all = netstats$main$fuzzynodematch_apps.all
		  # fuzzynodematch_apps.nondating = netstats$main$fuzzynodematch_apps.dating
		)
		target.stats.main <- unname(target.stats.main)

		fit_main <- netest(
		  nw = nw_main,
		  formation = model_main,
		  target.stats = target.stats.main,
		  coef.diss = netstats$main$diss.byage,
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_main <- trim_netest(fit_main)

		main_df <- data.frame(treatment = "Venues and Apps",
		                      model = "Main",
		                      term = names(fit_main$coef.form),
		                      estimate = fit_main$coef.form)

		saveRDS(fit_main, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_both_main_", calibration_set_num, ".rds"))
		write.csv(main_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_both_main_", calibration_set_num, ".csv"))
	
	} else if (thispartnershiptype == 'casual'){

		print("Both - Casual (B2)")

		model_casl <- ~ edges +
		  # nodefactor("age.grp", levels= 1) +
		  nodematch("age.grp", diff = TRUE) +
		  concurrent +
		  nodefactor("race", levels=-4) +
		  nodematch("race") +
		  # nodematch("race", diff=TRUE, levels=1) +

		  nodefactor("deg.main", levels=-1) +
		  fuzzynodematch("venues.all", binary=TRUE) +
		  fuzzynodematch("apps.all", binary = TRUE)
		#fuzzynodematch("apps_nondating", binary=TRUE)


		target.stats.casl <- c(
		  edges =                           netstats$casl$edges,
		  #  nodefactor_age.grp =            netstats$casl$nodefactor_age.grp[1],
		  nodematch_age.grp =             netstats$casl$nodematch_age.grp,
		  concurrent =                      netstats$casl$concurrent,
		  nodefactor_race =               netstats$casl$nodefactor_race[1:3],
		  nodematch_race =                netstats$casl$nodematch_race,
		  # nodematch_race.1 =              netstats$casl$nodematch_race.1,

		  nodefactor_deg.main =           netstats$casl$nodefactor_deg.main[-1],
		  fuzzynodematch_venues.all =     netstats$casl$fuzzynodematch_venues.all,
		  fuzzynodematch_apps.all =       netstats$casl$fuzzynodematch_apps.all
		  # fuzzynodematch_apps.nondating = netstats$casl$fuzzynodematch_apps.dating
		)
		target.stats.casl <- unname(target.stats.casl)


		fit_casl <- netest(
		  nw = nw_casl,
		  formation = model_casl,
		  target.stats = target.stats.casl,
		  coef.diss = netstats$casl$diss.byage,
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_casl <- trim_netest(fit_casl)

		casl_df <- data.frame(treatment = "Venues and Apps",
		                      model = "Casual",
		                      term = names(fit_casl$coef.form),
		                      estimate = fit_casl$coef.form)

		saveRDS(fit_casl, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_both_casual_", calibration_set_num, ".rds"))
		write.csv(casl_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_both_casual_", calibration_set_num, ".csv"))		

	} else if (thispartnershiptype == 'onetime') {

		print("Both - Inst (B3)")

		model_inst <-  ~ edges +
		  # nodefactor("age.grp", levels=1) +
		  nodematch("age.grp", diff = TRUE) +
		  nodefactor("race", levels=-4) +
		  nodematch("race") +
		  # nodematch("race", diff=TRUE, levels=1) +

		  nodefactor("deg.tot", levels=-1) +
		  fuzzynodematch("venues.all", binary=TRUE) +
		  fuzzynodematch("apps.all", binary = TRUE)
		#fuzzynodematch("apps_nondating", binary=TRUE)

		target.stats.inst <- c(
		  edges =                           netstats$inst$edges,
		  # nodefactor_age.grp =            netstats$inst$nodefactor_age.grp[1],
		  nodematch_age.grp =             netstats$inst$nodematch_age.grp,
		  nodefactor_race =               netstats$inst$nodefactor_race[1:3],
		  nodematch_race =                netstats$inst$nodematch_race,
		  # nodematch_race.1 =              netstats$inst$nodematch_race.1,

		  nodefactor_deg.tot =           netstats$inst$nodefactor_deg.tot[-1],
		  fuzzynodematch_venues.all =       netstats$inst$fuzzynodematch_venues.all,
		  fuzzynodematch_apps.all = netstats$inst$fuzzynodematch_apps.all
		  # fuzzynodematch_apps.nondating = netstats$inst$fuzzynodematch_apps.dating
		)
		target.stats.inst <- unname(target.stats.inst)

		fit_inst <- netest(
		  nw = nw_inst,
		  formation = model_inst,
		  target.stats = target.stats.inst,
		  coef.diss = dissolution_coefs(~offset(edges), duration = 1),
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_inst <- trim_netest(fit_inst)

		inst_df <- data.frame(treatment = "Venues and Apps",
		                      model = "Onetime",
		                      term = names(fit_inst$coef.form),
		                      estimate = fit_inst$coef.form)

		saveRDS(fit_inst, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_both_onetime_", calibration_set_num, ".rds"))
		write.csv(inst_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_both_onetime_", calibration_set_num, ".csv"))		

	} else {

		print("ERROR: PARTNERSHIP TYPE NOT CORRECTLY SPECIFIED")

	}

} else if (thistreatmenttype == 'apps') {

	if (thispartnershiptype == 'main') {

		print("Apps - Main (C1)")

		model_main <- ~ edges +
		  # nodefactor("age.grp", levels= 1) +
		  nodematch("age.grp", diff = TRUE) +
		  concurrent +
		  nodefactor("race", levels = -4) +
		  nodematch("race") +
		  # nodematch("race", diff = TRUE, levels = 1) +

		  nodefactor("deg.casl", levels= -1) +
		  fuzzynodematch("apps.all", binary = TRUE)
		# fuzzynodematch("apps_nondating", binary=TRUE)


		target.stats.main <- c(
		  edges = netstats$main$edges,
		  # nodefactor_age.grp = netstats$main$nodefactor_age.grp[1],
		  nodematch_age.grp = netstats$main$nodematch_age.grp,
		  concurrent = netstats$main$concurrent,
		  nodefactor_race = netstats$main$nodefactor_race[1:3],
		  nodematch_race = netstats$main$nodematch_race,
		  # nodematch_race.1 = netstats$main$nodematch_race.1,
		  nodefactor_deg.casl = netstats$main$nodefactor_deg.casl[-1],
		  fuzzynodematch_apps.all = netstats$main$fuzzynodematch_apps.all
		  # fuzzynodematch_apps.nondating = netstats$main$fuzzynodematch_apps.dating
		)
		target.stats.main <- unname(target.stats.main)

		fit_main <- netest(
		  nw = nw_main,
		  formation = model_main,
		  target.stats = target.stats.main,
		  coef.diss = netstats$main$diss.byage,
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_main <- trim_netest(fit_main)

		main_df <- data.frame(treatment = "Apps Only",
		                      model = "Main",
		                      term = names(fit_main$coef.form),
		                      estimate = fit_main$coef.form)

		saveRDS(fit_main, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_apps_main_", calibration_set_num, ".rds"))
		write.csv(main_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_apps_main_", calibration_set_num, ".csv"))		

	} else if (thispartnershiptype == 'casual') {

		print("Apps - Casual (C2)")

		model_casl <- ~ edges +
		  # nodefactor("age.grp", levels= 1) +
		  nodematch("age.grp", diff = TRUE) +
		  concurrent +
		  nodefactor("race", levels=-4) +
		  nodematch("race") +
		  # nodematch("race", diff=TRUE, levels=1) +

		  nodefactor("deg.main", levels=-1) +
		  fuzzynodematch("apps.all", binary = TRUE)
		#fuzzynodematch("apps_nondating", binary=TRUE)


		target.stats.casl <- c(
		  edges =                           netstats$casl$edges,
		  # nodefactor_age.grp =            netstats$casl$nodefactor_age.grp[1],
		  nodematch_age.grp =             netstats$casl$nodematch_age.grp,
		  concurrent =                      netstats$casl$concurrent,
		  nodefactor_race =               netstats$casl$nodefactor_race[1:3],
		  nodematch_race =                netstats$casl$nodematch_race,
		  # nodematch_race.1 =              netstats$casl$nodematch_race.1,

		  nodefactor_deg.main =           netstats$casl$nodefactor_deg.main[-1],
		  fuzzynodematch_apps.all =       netstats$casl$fuzzynodematch_apps.all
		  # fuzzynodematch_apps.nondating = netstats$casl$fuzzynodematch_apps.dating
		)
		target.stats.casl <- unname(target.stats.casl)

		fit_casl <- netest(
		  nw = nw_casl,
		  formation = model_casl,
		  target.stats = target.stats.casl,
		  coef.diss = netstats$casl$diss.byage,
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_casl <- trim_netest(fit_casl)

		casl_df <- data.frame(treatment = "Apps Only",
		                      model = "Casual",
		                      term = names(fit_casl$coef.form),
		                      estimate = fit_casl$coef.form)

		saveRDS(fit_casl, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_apps_casual_", calibration_set_num, ".rds"))
		write.csv(casl_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_apps_casual_", calibration_set_num, ".csv"))		

	} else if (thispartnershiptype == 'onetime') {

		print("Apps - Onetime (C3)")

		model_inst <-  ~ edges +
		  # nodefactor("age.grp", levels=1) +
		  nodematch("age.grp", diff = TRUE) +
		  nodefactor("race", levels=-4) +
		  nodematch("race") +
		  # nodematch("race", diff=TRUE, levels=1) +

		  nodefactor("deg.tot", levels=-1) +
		  fuzzynodematch("apps.all", binary = TRUE)
		#fuzzynodematch("apps_nondating", binary=TRUE)

		target.stats.inst <- c(
		  edges =                           netstats$inst$edges,
		  # nodefactor_age.grp =            netstats$inst$nodefactor_age.grp[1],
		  nodematch_age.grp =             netstats$inst$nodematch_age.grp,
		  nodefactor_race =               netstats$inst$nodefactor_race[1:3],
		  nodematch_race =                netstats$inst$nodematch_race,
		  # nodematch_race.1 =              netstats$inst$nodematch_race.1,

		  nodefactor_deg.tot =           netstats$inst$nodefactor_deg.tot[-1],
		  fuzzynodematch_apps.all = netstats$inst$fuzzynodematch_apps.all
		  # fuzzynodematch_apps.nondating = netstats$inst$fuzzynodematch_apps.dating
		)
		target.stats.inst <- unname(target.stats.inst)

		fit_inst <- netest(
		  nw = nw_inst,
		  formation = model_inst,
		  target.stats = target.stats.inst,
		  coef.diss = dissolution_coefs(~offset(edges), duration = 1),
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_inst <- trim_netest(fit_inst)

		inst_df <- data.frame(treatment = "Apps Only",
		                      model = "Onetime",
		                      term = names(fit_inst$coef.form),
		                      estimate = fit_inst$coef.form)

		saveRDS(fit_inst, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_apps_onetime_", calibration_set_num, ".rds"))
		write.csv(inst_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_apps_onetime_", calibration_set_num, ".csv"))		

	} else {

		print("ERROR: PARTNERSHIP TYPE NOT CORRECTLY SPECIFIED")

	}

} else if (thistreatmenttype == 'venues') {

	if (thispartnershiptype == 'main') {

		print("Venues - Main (D1)")

		model_main <- ~ edges +
		  # nodefactor("age.grp", levels= 1) +
		  nodematch("age.grp", diff = TRUE) +
		  concurrent +
		  nodefactor("race", levels = -4) +
		  nodematch("race") +
		  # nodematch("race", diff = TRUE, levels = 1) +

		  nodefactor("deg.casl", levels= -1) +
		  fuzzynodematch("venues.all", binary=TRUE)
		# fuzzynodematch("apps_nondating", binary=TRUE)


		target.stats.main <- c(
		  edges = netstats$main$edges,
		  # nodefactor_age.grp = netstats$main$nodefactor_age.grp[1],
		  nodematch_age.grp = netstats$main$nodematch_age.grp,
		  concurrent = netstats$main$concurrent,
		  nodefactor_race = netstats$main$nodefactor_race[1:3],
		  nodematch_race = netstats$main$nodematch_race,
		  # nodematch_race.1 = netstats$main$nodematch_race.1,

		  nodefactor_deg.casl = netstats$main$nodefactor_deg.casl[-1],
		  fuzzynodematch_venues.all = netstats$main$fuzzynodematch_venues.all
		  # fuzzynodematch_apps.nondating = netstats$main$fuzzynodematch_apps.dating
		)
		target.stats.main <- unname(target.stats.main)

		fit_main <- netest(
		  nw = nw_main,
		  formation = model_main,
		  target.stats = target.stats.main,
		  coef.diss = netstats$main$diss.byage,
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_main <- trim_netest(fit_main)

		main_df <- data.frame(treatment = "Venues Only",
		                      model = "Main",
		                      term = names(fit_main$coef.form),
		                      estimate = fit_main$coef.form)

		saveRDS(fit_main, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_venues_main_", calibration_set_num, ".rds"))
		write.csv(main_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_venues_main_", calibration_set_num, ".csv"))		

	} else if (thispartnershiptype == 'casual') {

		print("Venues - Casual (D2)")

		model_casl <- ~ edges +
		  # nodefactor("age.grp", levels= 1) +
		  nodematch("age.grp", diff = TRUE) +
		  concurrent +
		  nodefactor("race", levels=-4) +
		  nodematch("race") +
		  # nodematch("race", diff=TRUE, levels=1) +

		  nodefactor("deg.main", levels=-1) +
		  fuzzynodematch("venues.all", binary=TRUE)
		#fuzzynodematch("apps_nondating", binary=TRUE)


		target.stats.casl <- c(
		  edges =                           netstats$casl$edges,
		  # nodefactor_age.grp =            netstats$casl$nodefactor_age.grp[1],
		  nodematch_age.grp =             netstats$casl$nodematch_age.grp,
		  concurrent =                      netstats$casl$concurrent,
		  nodefactor_race =               netstats$casl$nodefactor_race[1:3],
		  nodematch_race =                netstats$casl$nodematch_race,
		  # nodematch_race.1 =              netstats$casl$nodematch_race.1,
		  nodefactor_deg.main =           netstats$casl$nodefactor_deg.main[-1],
		  fuzzynodematch_venues.all =     netstats$casl$fuzzynodematch_venues.all
		  # fuzzynodematch_apps.nondating = netstats$casl$fuzzynodematch_apps.dating
		)
		target.stats.casl <- unname(target.stats.casl)

		fit_casl <- netest(
		  nw = nw_casl,
		  formation = model_casl,
		  target.stats = target.stats.casl,
		  coef.diss = netstats$casl$diss.byage,
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_casl <- trim_netest(fit_casl)

		casl_df <- data.frame(treatment = "Venues Only",
		                      model = "Casual",
		                      term = names(fit_casl$coef.form),
		                      estimate = fit_casl$coef.form)

		saveRDS(fit_casl, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_venues_casual_", calibration_set_num, ".rds"))
		write.csv(casl_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_venues_casual_", calibration_set_num, ".csv"))		

	} else if (thispartnershiptype == 'onetime') {

		print("Venues - Onetime (D3)")

		model_inst <-  ~ edges +
		  # nodefactor("age.grp", levels=1) +
		  nodematch("age.grp", diff = TRUE) +
		  nodefactor("race", levels=-4) +
		  nodematch("race") +
		  # nodematch("race", diff=TRUE, levels=1) +

		  nodefactor("deg.tot", levels=-1) +
		  fuzzynodematch("venues.all", binary=TRUE)
		#fuzzynodematch("apps_nondating", binary=TRUE)

		target.stats.inst <- c(
		  edges =                           netstats$inst$edges,
		  # nodefactor_age.grp =            netstats$inst$nodefactor_age.grp[1],
		  nodematch_age.grp =             netstats$inst$nodematch_age.grp,
		  nodefactor_race =               netstats$inst$nodefactor_race[1:3],
		  nodematch_race =                netstats$inst$nodematch_race,
		  # nodematch_race.1 =              netstats$inst$nodematch_race.1,

		  nodefactor_deg.tot =           netstats$inst$nodefactor_deg.tot[-1],
		  fuzzynodematch_venues.all =       netstats$inst$fuzzynodematch_venues.all
		  # fuzzynodematch_apps.nondating = netstats$inst$fuzzynodematch_apps.dating
		)
		target.stats.inst <- unname(target.stats.inst)

		fit_inst <- netest(
		  nw = nw_inst,
		  formation = model_inst,
		  target.stats = target.stats.inst,
		  coef.diss = dissolution_coefs(~offset(edges), duration = 1),
		  set.control.ergm =
		    control.ergm(
		      parallel = 4,
		      MCMC.interval = 10000,
		      MCMLE.effectiveSize=NULL,
		      MCMC.burnin = 1000,
		      MCMC.samplesize = 20000,
		      SAN.maxit = 20,
		      SAN.nsteps.times = 10
		    )
		)

		fit_inst <- trim_netest(fit_inst)

		inst_df <- data.frame(treatment = "Venues Only",
		                      model = "Onetime",
		                      term = names(fit_inst$coef.form),
		                      estimate = fit_inst$coef.form)

		saveRDS(fit_inst, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "fit_venues_onetime_", calibration_set_num, ".rds"))
		write.csv(inst_df, paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$expname, "/", "coef_df_venues_onetime_", calibration_set_num, ".csv"))		

	} else {

		print("ERROR: PARTNERSHIP TYPE NOT CORRECTLY SPECIFIED")

	}

} else {

	print("ERROR: TREATMENT TYPE NOT CORRECTLY SPECIFIED")


}


# C - control model (no apps or venues)
# CM - control model; main partnerships  
# CC - control model; casual partnerships  
# CO - control model; one-time partnerships  

# B - both model (both apps and venues)
# BM - both model; main partnerships  
# BC - both model; casual partnerships  
# BO - both model; one-time partnerships  

# A - apps model (apps only)
# AM - apps model; main partnerships  
# AC - apps model; casual partnerships  
# AO - apps model; one-time partnerships  

# V - venues model (venues only)
# VM - venues model; main partnerships  
# VC - venues model; casual partnerships  
# VO - venues model; one-time partnerships  




# }