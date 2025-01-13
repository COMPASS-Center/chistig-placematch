library(yaml)

args <- commandArgs(trailingOnly = TRUE)
yamlfname <- args[1]
yamldata <- yaml.load_file(yamlfname)


# set up the .yaml directories 
experiment_name <- yamldata$expname
experiment_dir <- paste0(yamldata$repo.dir, yamldata$calibration.subdir, experiment_name, "/")
sim_input_data_dir <- paste0(yamldata$repo.dir, yamldata$netest.subdir)

# get the number of calibration scenarios
drate_mat_fname <- paste0(experiment_dir, yamldata$calibration.matrix.fname, "_", experiment_name, ".csv")
drate_mat_full <- read.csv(drate_mat_fname)
num_calibration_scenarios <- max(drate_mat_full$fit_no) 

# get the partnership types
partnership_types <- yamldata$partnership.types

# get the treatment tyeps 
treatment_types <- yamldata$treatment.types


cset2skip <- c()

for (cset in 1:num_calibration_scenarios){

	for(ttype in treatment_types){

		for (ptype in partnership_types){

			fit_file <- paste0(experiment_dir, "fit_", ttype, "_", ptype, "_", cset, ".rds")
			if (!file.exists(file = fit_file)){
				cset2skip <- c(cset2skip, cset)
			}

		}
	}
}

cset2skip <- unique(cset2skip)
print(paste0("Will skip the following calibration sets: ", cset2skip))


for (cset in 1:num_calibration_scenarios) {

	if (cset %in% cset2skip) {
		next
	}

	for (ttype in treatment_types) {

		for (ptype in partnership_types) {

			fit_file <- paste0(experiment_dir, "fit_", ttype, "_", ptype, "_", cset, ".rds")

			# check if file exists or not; if not, need to document them 
			if (!file.exists(file = fit_file)){
				print("NO FILE EXISTS")
			}

			if (ptype == "main"){

				fit_main <- readRDS(fit_file)

			} else if (ptype == "casual") {

				fit_casl <- readRDS(fit_file)

			} else if (ptype == "onetime"){

				fit_inst <- readRDS(fit_file)

			} else {

				print("ERROR: the defined partnership types do not correspond to the fit files")

			}

		}

		out <- list(fit_main = fit_main, fit_casl = fit_casl, fit_inst = fit_inst)

		saveRDS(out, paste0(sim_input_data_dir, ttype, "_netest_", experiment_name,  "_", cset, ".rds"))

	}

}

cset2skip_fname <- paste0(experiment_dir, yamldata$convergence.fail.fname, "_", experiment_name, ".txt")
write(cset2skip, file = cset2skip_fname, ncolumns = 1, sep = "\n")

