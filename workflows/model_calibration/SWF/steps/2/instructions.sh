module purge all
module load R/4.3.0
module load git
Rscript "workflows/model_calibration/SWF/steps/2/script.R"
