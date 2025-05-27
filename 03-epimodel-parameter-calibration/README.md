# Step 3: Calibration of Epidemiological Parameters

This step of the preparation process calibrates values of epidemiological parameters related to rates of HIV testing as well as antiretroviral therapy (ART) uptake, retention, and re-uptake. It also calibrates levels of HIV acquisition occurring from sources outside the focal population (i.e. sexual partners who are not MSM-TW aged 16-30). Additionally, it calibrates values for parameters designed to emulate unexplained causes of racial disparities in HIV prevalence. These values are all stored in the `params.csv` file located within `./data/input/`, which is called upon when setting up `EpiModelHIV` simulations (you can see this in line 83 of the `step3_utils.R` script located in this subdirectory).

This `README` is meant to guide users through the setup and execution of code related to this step of the preparation process. It is adapted from documentation written by the core EpiModel team, which explains the calibration process in detail and describes how specific epidemiological phenomena are represented by parameters: <https://epimodel.github.io/swfcalib/articles/swfcalib.html>

Note that the instructions listed below are tailored for use with Northwestern University's *Quest* high-performance computing cluster, which uses the *slurm* cluster management and job scheduling system. The code and workflow contained in this part of the repository may not be fully compatible with your high-performance computing environment. In order to replicate progress made in this step, you may need to adapt our workflow to ensure compatibility with your own HPC resources.

### 1. On a Local Machine, Edit Project Repository as Needed and Push to GitHub

As mentioned above, [a full explanation of the parameter calibration process and a tutorial on how to set it up on an HPC can be found here](https://epimodel.github.io/swfcalib/articles/swfcalib.html). In our repository, `workflow_06-automated-calibration.R` contains the code found in this tutorial and is what should be edited to create new calibration attempts. Using RStudio on a local machine, we modify this script to specify which parameters we want to calibrate, the range of values that should be explored for each parameter, and the order of calibration "waves" in which parameter values should be explored. After saving these modifications to `workflow_06-automated-calibration.R`, we push our updated script to our GitHub repository.

### 2. Log in to Quest via Command Line and head to project directory

Once we have pushed the updated `workflow_06-automated-calibration.R` to GitHub, we will want to ensure this updated script appears in our HPC environment (again, Northwestern's *Quest* in this instance). Using the command line within RStudio (this makes it easier to locate files within this project's GitHub repository), Northwestern personnel with proper access to Quest can log in via the following command:

`$ ssh -X <webID>@quest.northwestern.edu`

(Note: You’ll be asked for your password here)

Once logged in, you will need to move to the directory associated with your Quest project allocation:

`$ cd /projects/<allocation_number>`

### 3. Clone (or pull latest version of) this Repository to HPC

If you are cloning the GitHub repository for the first time, use the following command:

`$ git clone https://github.com/COMPASS-Center/chistig-placematch.git`

If you have previously cloned the GitHub repository to your project allocation, simply pull the latest commit of the repository:

`$ cd ./chiSTIG_HPC`

`$ git pull`

### 4. On Your Local Machine, Generate the Workflow Shell Files You Wish to Run on Quest

Returning to your local machine's instance of the GitHub repository, restart R and run the `workflow_06-automated-calibration.R` we modified in Step 1. Running this script creates a directory of shell (`.sh`) files that will be used to run the automated calibration process on the HPC. This directory will be located in the `workflows` folder found in the main project directory (`chistig-placematch`). The directory containing the shell files will be given the name specified in the `create_workflow` function in `workflow_06-automated-calibration.R` (the default name in our repository is `auto_calib`).

**NOTE:** `workflow_06-automated-calibration.R` will only create the directory of shell files if this directory does not already exist within the `workflows` folder. If you have previously run `workflow_06-automated-calibration.R`, you will need to delete `chistig-placematch/workflows/auto_calib` (or whatever your directory is named) and its contents before running `workflow_06-automated-calibration.R` again.

### 6. From the Command Line, Copy the Newly-Created Subdirectory of `workflows` to its Corresponding Place on the HPC

Returning to the command line in RStudio, copy the directory of shell files to `chistig-placematch/workflows` on your HPC allocation:

`$ scp -r ./workflows/auto_calib quest.northwestern.edu:/projects/<allocation_number>/chistig-placematch/workflows/`

Note: You'll be asked for your password once more

### 7. Ensure Files Related to Calibration Process are Uploaded to (or Deleted from) HPC as Necessary

Much like the edge calibration process contained in `chistig-placematch/02-network-edge-calibration`, the automated parameter calibration process entails performing a large number of `EpiModelHIV` simulations using different parameter values and comparing their results. Accordingly, our calibration simulations also require `epistats`, `netstats`, and `netest` objects that we created in previous steps of our project workflow.

Generally speaking, the core EpiModel team recommends keeping `epistats`, `netstats`, and `netest` objects off project GitHub repositories and manually copying them between the project directories on your local machine and your HPC. This is recommended to avoid accidentally generating results based on earlier versions of these files that you may not mean to use in the calibration process. However, because we intend this project repository to be used for replication purposes, we include the versions of these files we used in our parameter calibration within `chistig-placematch/03-epimodel-parameter-calibration/data/intermediate`.

Upon completion, the automated calibration workflow stores a variety of output files located in `chistig-placematch/03-epimodel-parameter-calibration/data/calib`, as well as log files in `chistig-placematch/workflows/auto_calib/log`. If these files currently exist on your HPC, you should delete them before beginning the automated calibration process.

### 8. Begin Automated Calibration Process on the HPC via the Command Line

Using the command line, log into your HPC cluster:

`$ ssh -X <webID>@quest.northwestern.edu`

Enter your password:

(Password entry)

Move to the directory associated with this GitHub repository on your HPC's project allocation:

`$ cd /projects/<allocation_number>/chistig-placematch`

Activate the conda environment associated with this project:

`conda activate /projects/<allocation_number>/condaenvs/conda-chistig`

Once the conda environment is activated, begin the automated calibration workflow by running the following shell file:

`$ ./workflows/auto_calib/start_workflow.sh`

### 9. Await Completion or Crash of Calibration Process

The automated calibration process will take some time. If you specified an email address in the `mail_user` argument of `swf_configs_quest`, found in `chistig-placematch/03-epimodel-parameter-calibration/step3_utils.R`, notices of slurm job failures will be sent to that email address.

Should you receive a notification of job failure, we recommend consulting the log files stored in `placematch/workflows/auto_calib/log` to troubleshoot any potential issues.

Our experience is that the automated calibration process will successfully finish calibrating parameters related to HIV testing, ART initiation, cessation, and re-initiation, and rates of HIV infection originating from outside the core network. However, the automated calibration process will struggle to complete calibration of the `trans.scale` parameters emulating unexplained causes of racial disparities in HIV prevalence. We believe this is due to the complexity of calibrating these four interrelated parameters (most `EpiModelHIV` projects only examine three racial/ethnic groups, resulting in lower complexity), especially when given a population of the size examined in our study (`EpiModelHIV` simulations of MSM typically simulate larger populations reflecting a larger age distribution). We expect anyone replicating our study to receive emails notifying them of job failure once the automated calibration process spends an excess amount of time attempting to calibrate `trans.scale` values.

Because of the difficulties described above, we recommend that final calibration of `trans.scale` parameters be done manually on a local machine, with final values being determined at the researcher's discretion (more information on this below).

### 10. Analyze Results of Automated Calibration Workflow

As mentioned in Step 7, the automated calibration process generates several output files stored in `chistig-placematch/03-epimodel-parameter-calibration/data/calib`. Unless you have to troubleshoot a very specific issue, you will only need the `assessments.rds` and `calib_object.rds` files to move forward. We recommend that you manually download these files from your HPC cluster to your local machine to examine them.

To examine `assessments.rds`, all you need to do is pass this file through the `swfcalib::render_assessment` function in R:

``` R
swfcalib::render_assessment("~/Downloads/assessments.rds", output_dir = "~/Desktop")
```

This creates an HTML file, `assessment.html`, located at whatever path you specify as the `output_dir` argument. Opening this HTML file in a browser provides you with a series of visualizations summarizing the progress made within each wave and job of the overall automated calibration workflow. Of these visualizations, we find that the ones labeled **Target Errors** are most informative. If calibration of a parameter was successful, these plots should show error values that gradually center around 0.00 over the course of calibration.

Provided the results summarized in `assessment.html` are satisfactory, the `calib_object.rds` file contains any and all calibrated parameter values. Here is a brief runthrough of how you would inspect this file:

``` r
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
calib_object$state$default_proposal
```

With `calib_object` in front of you, you will want to copy all calibrated parameter values found in `calib_object$state$default_proposal` to your `params.csv` file. With your calibrated epidemiological parameters in tow, you can now move on to finalizing calibration of the `trans.scale` parameters.

### 11. Manual Calibration of `trans.scale` Parameters
