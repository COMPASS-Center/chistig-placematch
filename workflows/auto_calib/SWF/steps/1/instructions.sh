module purge all
module load R/4.3.0
module load git
Rscript "workflows/auto_calib/SWF/steps/1/script.R"
