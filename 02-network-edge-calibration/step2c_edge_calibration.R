library(yaml)

args <- commandArgs(trailingOnly = TRUE)
yamlfname <- args[1]
yamldata <- yaml.load_file(yamlfname)

# set up calibration directory 
calibration_subdir <- paste(yamldata$repo.dir, yamldata$calibration.subdir, sep="") #nolint

# set up experiment directory
if (is.null(yamldata$expname)){
    experiment_subdir <- calibration_subdir
} else {
    experiment_subdir <- paste(calibration_subdir, yamldata$expname, "/", sep="") #nolint
}

# set up interim data directory
if (is.null(yamldata$interim.data.subdir)) {
  interim_subdir <- experiment_subdir
} else {
  interim_subdir <- paste(experiment_subdir, yamldata$interim.data.subdir, sep="") #nolint
}

print(interim_subdir)

# # set up output data directory
# out_subdir <- interim_subdir


# # # set up input data directories 
# # sim_input_data_dir <- paste0(yamldata$repo.dir, yamldata$netest.subdir) #nolint



# # set up the .yaml directories 
# if (is.null(yamldata$interim.data.subdir)) {
#   outdir <- paste(yamldata$repo.dir, yamldata$calibration.subdir, sep="") #nolint
# } else {
#   outdir <- paste(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$interim.data.subdir, sep="") #nolint
# }



# # get the number of calibration scenarios
# # drate_mat_fname <- paste0(experiment_dir, yamldata$calibration.matrix.fname, "_", experiment_name, ".csv") #nolint
# # drate_mat_full <- read.csv(drate_mat_fname) #nolint

# netstats_fname <- paste0(yamldata$repo.dir, yamldata$netstats.subdir, yamldata$netstats.fname) #nolint
# netstats_base <- readRDS(netstats_fname)

# calibration_matrix_fname <- paste0(yamldata$repo.dir, yamldata$calibration.subdir, yamldata$calibration.matrix.fname) #nolint
# calibration_matrix_full <- read.csv(calibration_matrix_fname)
# num_calibration_scenarios <- max(calibration_matrix_full$fit_no)


# # get the partnership types
# partnership_types <- yamldata$partnership.types

# # get the treatment tyeps 
# treatment_types <- yamldata$treatment.types

# cset2skip <- c()

# for (cset in 1:num_calibration_scenarios){
#     for(ttype in treatment_types){
#         for (ptype in partnership_types){
#             fit_file <- paste0(interim_subdir, "netest-", ptype, "-", ttype, "_", cset, ".rds") #nolint
#             if (!file.exists(file = fit_file)){
#                 print("Could not find the following ERGM fit file:")
#                 print(fit_file)
#                 cset2skip <- c(cset2skip, cset)
#             }
#         }
#     }
# }

# cset2skip <- unique(cset2skip)
# print(paste0("Will skip the following calibration sets: ", cset2skip))


# for (cset in 1:num_calibration_scenarios) {
#     if (cset %in% cset2skip) {
#         next
#     }

#     for (ttype in treatment_types) {
#         for (ptype in partnership_types) {
#             fit_file <- paste0(experiment_subdir, "netest-", ptype, "-", ttype, "_", cset, ".rds") #nolint
#             # check if file exists or not; if not, need to document them 
#             if (!file.exists(file = fit_file)){
#                 print("NO FILE EXISTS")
#             }
#             if (ptype == "main"){
#                 fit_main <- readRDS(fit_file)
#             } else if (ptype == "casual") {
#                 fit_casl <- readRDS(fit_file)
#             } else if (ptype == "onetime"){
#                 fit_inst <- readRDS(fit_file)
#             } else {
#                 print("ERROR: the defined partnership types do not correspond to the fit files") #nolint
#             }
#         }
#         out <- list(fit_main = fit_main, fit_casl = fit_casl, fit_inst = fit_inst) #nolint
#         saveRDS(out, paste0(out_subdir, "netest-", ttype, "_", cset, ".rds")) #nolint
#     }
# }

# cset2skip_fname <- paste0(out_subdir, yamldata$convergence.fail.fname, ".txt")
# write(cset2skip, file = cset2skip_fname, ncolumns = 1, sep = "\n")
