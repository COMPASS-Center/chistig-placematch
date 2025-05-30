# Specify location of `assessments.rds` file (edit as needed)
assessments_path <- "~/Downloads/assessments.rds"
# Specify location of `calib_object.rds` file (edit as needed)
calib_object_path <- "~/Downloads/calib_object.rds"

# Create HMTL report of automated calibration progress
swfcalib::render_assessment(assessments_path, output_dir = "~/Desktop")

# Read in `calib_object.rds`
calib_object <- readRDS("~/Downloads/calib_object.rds")

# Examine and confirm initial parameter values
calib_object$config$default_proposal

# Identify last wave of parameter calibration attempted by automated workflow
calib_object$state$wave

# Did this wave successfully finish?
calib_object$state$done

# How many iterations were performed for this wave?
calib_object$state$iteration

# Examine and confirm calibrated parameter values going into most recent wave of calibration
# (This is what you'll want to manually copy into your `params.csv` file)
calib_object$state$default_proposal
