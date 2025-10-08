# Step 4: chiSTIG Model Simulation

With our network-based experimental treatments and epidemiological parameters calibrated, we are now ready to perform simulation experiments. The instructions listed below are designed to walk us through how to conduct an EpiModel-based experiment using Northwestern University's *Quest* high-performance computing cluster. As such, you may need to adapt some of the steps listed below to work with your own HPC resources.

### 1. Confirm Accuracy of Simulation Arguments and Filepaths

Our simulation experiment workflow is designed so that users can change settings and specify paths to requisite files via a single YAML file. Prior to running any simulations, be sure to open `04-model-simulation.yaml` and ensure that all specified paths, filenames, and arguments are to your liking. The default settings in this file are meant to replicate the original chiSTIG project's settings. 

Directory paths and filenames are set so that simulations will use the `epistats`, `netstats`, and `netest` objects created in Steps 1-2, as well as the calibrated epidemiological parameter values created in step 3 (lines 1-23 in the YAML file). You may need to change these settings if you want to read in pre-generated versions of these objects created using a different process than what is contained in this repository.

To customize the EpiModel experiment itself, you will need to modify the remaining sections of the `yaml` file. We describe the settings you will most likely need to change below:

 `experiment.name` (line 26) assigns experiment a "name" that can be used to identify files created during a specific set of simulations. We recommend you update `experiment.name` before running a new batch of simulations so as not to wrongly combine data from experiments with different settings.

`number.runs.per.treatment` (line 27) specifies how many EpiModel simulations should be run for each treatment group in an experiment. Following recommendations from other EpiModel users, we have set the default number to 120 simulations per treatment group.

`treatment.types` (lines 31-35) specifies which treatments one wants to include in a simulation experiment. Our workflow supports the inclusion of treatments wherein simulated agents form sexual partnerships via co-location in physical venues, in online apps, or in both. Users may not want to include all of these treatment groups in an experiment, particularly as the inclusion of each treatment increases experiment runtimes and computing resource costs. To remove a treatment from the experiment, one can simply comment out the name of the treatment in question. One sees that our default settings have the `apps` and `venuesapps` treatments commented out.

Lines 43-47 contain settings relevant to the *slurm* cluster management and job scheduling system used on Northwestern's HPC cluster. Users may need to change or replace these settings to match the particulars of their own HPC resources.

Similarly, lines 49-51 specify filepaths needed for our EpiModel simulations, which are performed in R, to interface with our tools for simulation venue/app co-location, which are executed in Python. As users' Python/conda environment and its location will likely differ from those of our team's project, you will likely need to update these as well.

### 2. Ensure Consistency Between YAML file and Experiment Setup Shell File

If, during the preceding step, you edited the `sbatch.outfile.fname` setting in `04-model-simulation.yaml` (line 14), you will need to edit the `04_model_simulation_setup.sh` file to ensure consistency between the two. Within `04_model_simulation_setup.sh`, replace "`04_sbatch.sh`" with whatever value you set for `sbatch.outfile.fname` in the YAML file.

### 3. (If Needed) Push/Pull to HPC

If `04-model-simulation.yaml` and/or `04_model_simulation_setup.sh` were edited on a local machine, we will need to push all saved changes to our GitHub repository. Once all changes have been pushed, we will then need to pull pull these changes to the instance of the repository stored on our HPC.

### 4. Execute Simulation Experiment on HPC

From the command line, log into your HPC cluster. Northwestern personnel with proper access to Quest can log in via the following command:

`$ ssh -X <netID>@quest.northwestern.edu`

Enter your password:

(Password entry)

Once logged in, move to the directory associated with your Quest project allocation:

`$ cd /projects/<allocation_number>/chistig-placematch`

Now run the two following lines:

```
chmod +x 04_model_simulation_setup.sh
./04_model_simulation_setup.sh 04-model-simulation.yaml
```
This starts the simulation experiment on the HPC, which will take several hours or a couple days to complete depending on your `number.runs.per.treatment` and the power of your HPC resources. If you are on an HPC cluster using slurm and have an email address set for `sbatch.email` (line 43 in `04-model-simulation.yaml`), you should receive email notifications when your experiment has started, when it finishes, and when it abruptly crashes or times out.

### 5. Examine Experiment Results
