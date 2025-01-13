# Tasks for chiSTIG on Quest HPC

What follows below is a simplifed set of steps for running EpiModel jobs on the HPC. But note that more thorough documentation of this process can be found here: https://github.com/EpiModel/EpiModeling/wiki

## 1. Make Edits to Project Repository as Needed and Push to GitHub

## 2. Log in to Quest via Command Line and head to project directory

`$ ssh -X <webID>@quest.northwestern.edu`

(Note: You’ll be asked for your password here)

`$ cd /projects/p32153`

## 3. Clone (or pull latest version of) this Repository to HPC

`$ git clone https://github.com/Tom-Wolff/chiSTIG_HPC.git`

Otherwise

`$ cd ./chiSTIG_HPC`

`$ git pull`

## 4. Ensure R environment and packages are all up to date

Load R version 4.3.0

`$ module load R/4.3.0`

Enter R

`$ R`

Restore R environment from lockfile (added to project directory via GitHub

`> renv::restore()`

Quit R (Choose “n” for saving workspace)

`> q()`

Log out of Quest

`$ exit`				             

## 5. On Your Local machine, Run the Workflow Script for the Part of the Process you Wish to Run on Quest

In this example we’ll run `./R/workflow_02-model_calibration.R`

Running this script creates a folder of `.sh` files that we’ll run later on the HPC. 

If this folder already exists in your local project repository, you’ll want to delete it before running the script.

## 6. From the command line, copy the newly-created subdirectory of `workflows` created by this script to its corresponding place on the HPC directory

`$ scp -r ./workflows/model_calibration quest.northwestern.edu:/projects/p32153/chiSTIG_HPC/workflows/`

Note: You'll be asked for your password once more

## 7. epistats, netstats, and netest objects are recommended to be uploaded manually to the HPC via Globus

You’ll want to place these filed in the folder where they’re called on by scripts: `/projects/p32153/chiSTIG_HPC/data/intermediate/estimates`

## 8. Log back onto Quest and submit the job through the command line

`$ ssh -X <webID>@quest.northwestern.edu`

(Password entry)

`$ cd /projects/p32153/chiSTIG_HPC`

`$ ./workflows/model_calibration/start_workflow.sh`

## 9. Await job completion or crash
