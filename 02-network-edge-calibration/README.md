# Step 2: Calibration of Edges in ERGMs Underlying Experimental Treatments

In most simulation experiments using `EpiModelHIV`, experimental treatments are operationalized through "scenarios" that vary according to parameter values that determine simulated agents' behaviors related to HIV epidemiology (e.g. condom use, PrEP uptake and adherence, rates of HIV testing, ART uptake and adherence). While these parameters vary, the underlying network models (ERGMs) that determine sexual partnership formation and dissolution remain constant across experimental treatments. In this regard, our study makes a noteworthy departure from past `EpiModel` experiments. Our study is interested in how disparities in HIV incidence change when sexual partnerships are allowed to form on the basis of co-location in physical venues vs. when they are not. Our "scenarios," so to speak, are the inverse of what has been done in the past: parameters governing agents' epidemiological behaviors are kept constant, but our treatments use different sets of ERGMs to change the rules governing sexual partnership formation. This is why we created four different sets of ERGM fits (stored as `netest` objects) in Step 1 (`01-networks-estimation`).

While experimental treatments in our study use different sets of ERGMs to shape their respective sexual networks, these networks should have the same number of edges regardless of treatment. In theory, this similarity across treatments should be baked into our ERGMs, since we keep the target stats used to specify the number of edges in our network (`edges`) constant across treatments. In practice, however, our ERGM fits as they appear at the end of Step 1 produce treatments whose networks have different numbers of edges than those produced by our control simulation. We suspect this is a consequence of how we used data pertaining to venue colocation to fit ERGMs in our previous study (link to place-and-pop repo), which may differ from how these data need to be adapted for the purposes of `EpiModel`.

Were we to simply proceed with the ERGMs produced in Step 1, it would be difficult to defend the idea of experimental control between our treatments. Accordingly, this step of the preparation process adjusts the target stats we initially used to create ERGM fits underlying our experimental treatments. At the end of this step, the ERGMs underlying our treatments should be calibrated so that they produce networks with the same number of edges (and other properties) as those underlying our control model.

### 1. On a Local Machine, Create Edge Calibration Scenarios and Push to GitHub

For each experimental treatment in our study, we need to calibrate some combination of three values for each of our ERGM fits (main partnerships, casual partnerships, one-time partnerships):

- Target stat indicating the number of edges (partnerships) in the network whose nodes should have had some colocation at physical venues at the time of formation
- Target stat indicating the number of edges in the network whose nodes should have had some colocation on dating apps at the time of formation
- Departure rate (`d.rate`) parameter adjusting for agents exiting network - In practice, this parameter allows ERGMs to adjust for the rate at which people exit the network so that the number of edges in the network remains stable over time

The `step1_edge_calibration.R` script allows users to specify a set of values for each of these target stats/`d.rate` parameters that they wish to test. To get started, users will have to manually edit the values stored in objects between lines 47-72 of this script and then save their updates. Once this is done, running this script will create a new file, `edge_target_calibration_vals.csv`, containing all possible combinations of the target stats/`d.rate` parameters you want to explore. `edge_target_calibration_vals.csv` will then be fed into later steps of the edge calibration process. The shell files in this directory will do this for us, however, so *DO NOT* run this script on your own.

Once we've updated `step1_edge_calibration.R`, we will need to push our changes to our GitHub repository.

### 2. Log in to Quest via Command Line and Pull to Step 2 Directory

Once we have pushe the updated `step1_edge_calibration.R` to GitHub, we will want to ensure this updated script appears in our HPC environment (Northwestern's *Quest* in this instance). Using the command line within RStudio (this makes it easier to locate files within this project's GitHub repository), Northwestern personnel with proper access to Quest can log in via the following command:

`$ ssh -X <netID>@quest.northwestern.edu`

(Note: You’ll be asked for your password here)

Once logged in, you will need to move to the directory associated with your Quest project allocation,
your GitHub repository, and the edge calibration step:

`$ cd /projects/<allocation_number>/chistig-placematch/02-network-edge-calibration/`

Now pull the latest commit from your GitHub repository:

`$ git pull`

### 3. Run Initial Shell Files

A quick look at the `02-network-edge-calibration` subdirectory reveals that the edge calibration process consists of many different scripts. However, we have designed this process itself to be easy for most users to perform. To execute most of the edge calibration process, users need only run the three shell files contained in this subdirectory. 

Before executing these shell files, one should take care to manually inspect the contents of `02-network-edge-calibration/interim` and `02-network-edge-calibration/output`. These subdirectories should be empty of all contents prior to executing our sequence of shell files. Assuming these subdirectories are in fact empty, we can proceed.

First, we'll run `edge_calibration_procedure_ONE.sh`, which creates the `edge_target_calibration_vals.csv` file and creates ERGM specifications for each combination of target stats/`d.rate` parameters contained in the CSV:

`chmod +x edge_calibration_procedure_ONE.sh` 

`./edge_calibration_procedure_ONE.sh 02-edge-calibration.yaml`

Once `edge_calibration_procedure_ONE.sh` has completed, we then run `edge_calibration_procedure_TWO.sh`, which checks to see which ERGM specifications created in the previous step produce models that converge:

`chmod +x edge_calibration_procedure_TWO.sh` 

`./edge_calibration_procedure_TWO.sh 02-edge-calibration.yaml`

### 4. Check ERGM Convergence and Revisit Past Steps as Needed

Once `edge_calibration_procedure_ONE.sh` has completed, we will want to check if any or all ERGM specifications produced models that converged. The quickest way of doing this is to inspect the contents of `02-network-edge-calibration/interim/edge_calibration_sets_that_did_not_converge.txt`. This text file will list which ERGM specifications did not converge via numbers corresponding to rows in `edge_target_calibration_vals.csv`. 

All numbers 1-[number of rows in the CSV file] can appear in the text file if their corresponding ERGM specifications do not converge. If one or more numbers do not appear in the text file, we have converged ERGMs which we can use as to continue through the remaining steps of the edge calibration process.

If all numbers appear in the text file, this indicates that none of the target stat/`d.rate` parameter combinations specified in `edge_target_calibration_vals.csv` produced ERGM fits that converged. When this is the case, we can try rerunning `edge_calibration_procedure_ONE.sh` and `edge_calibration_procedure_TWO.sh` to see if some ERGM specifications converge upon another attempt. Be sure to empty the contents of `02-network-edge-calibration/interim` between attempts. If all numbers continue to appear in the text file after repeated attempts, we may need to restart the entire edge calibration process adjust the range of target statistics and `d.rate` values used (i.e. return to Step #1 in this documentation).

### 5. Run Final Shell Files

Provided we have at least one ERGM specification that converged, we can run the remaining shell file, which runs test simulations for each set of converged ERGM and aggregates the data produced by these simulations:

`chmod +x edge_calibration_procedure_THREE.sh` 

`./edge_calibration_procedure_THREE.sh 02-edge-calibration.yaml`

### 6. Download Edge Calibration Data

Once `edge_calibration_procedure_THREE.sh` has completed, we will want to inspect the results of the edge calibration process. The best way to do this is to copy the contents of the `interim` subdirectory to its counterpart on your local machine, whether by pushing/pulling from GitHub or via manual download.

### 7. Evaluate Edge Calibration Results

Once you have copied the contents of the `interim` subdirectory to your local machine, open `step4_edge_calibration.R`, which allows you to evalute the results of the edge calibration process. Running this script script generates a series of visualizations that help us determine which ERGM specification (i.e. set of target statistics and `d.rate` parameter values) produces networks that best resemble those produced by our control model. Personal judgment allows us to determine if our best ERGM specification is sufficient or if we will need to repeat the edge calibration process. With that said, `step4_edge_calibration.R` ends with code designed to identify the best ERGM specification and copy the `netest` files associated with that specification to the `output` subdirectory.



Katie on how the mean degree values in the edge calibration section were calculated: "Sure - basically all that's happening is that we're reweighting our target stats based on the empirical data to represent the age/race/ethnicity breakdown of the synthetic population, because each of the overall targets needs to be internally consistent with the stratified targets (e.g. mean degree by race needs to total mean degree overall by the props in each race category). So all of the egos in the empirical data get a weight based on their age (16-20 vs 21-29) and race-ehtnicity in 4 cats, and then we calculate the weighted mean degree, proportion concurrent etc etc."







** OLD TEXT FROM CHISTIG_model REPO, PROBABLY CAN BE PHASED OUT?**
To setup a new calibration experiment, do the following:

1. Make sure you are in the general calibration subdirectory. If you are signed in to Quest, then you can ensure you are in the correct subdirectory by running the following from the command line:
```sh
cd /projects/p32153/ChiSTIG_model/calibration/
```

2. Make sure the `dur_coefs.R` and `target_values_v4_1_uniform_age_dist.csv` files are correct. Both of these files are in the calibration subdirectory. That is, they are located in the following:
```
/projects/p32153/ChiSTIG_model/calibration/target_values_v4_1_uniform_age_dist.csv
/projects/p32153/ChiSTIG_model/calibration/dur_coefs.R
```

3. Determine the name of your new calibration experiment. The format I have been using is `testXX` where `XX` is the date of the experiment when it is setup. For example, let our experiment name be `test18sep`.


4. Copy the generic calibration experiment subdirectory (i.e. `testXX`) to be the base for the new experiment. For our example, this would look like the following from the Quest command line:
```sh
cp -r testXX test18sep
```

NOTE: To copy a directory, you must use the `-r` argument. 


5. Move into the new experiment subdirectory, and follow the instructions written inside the subdirectory's README. For example, to move into the new experiment's subdirectory, do the following:
```sh
cd test18sep
```

The README file in this subdirectory will guide you on the rest of the steps. For our example experiment, the README file should be located in the following location:
```
/projects/p32153/ChiSTIG_model/calibration/test18sep/README.md
```




REPOSITORY NOTES:
- step2b is extremely messy 
    - includes reading in dur_coefs.rds and epistats.rds from the prelim directory, which we should not have to do this as we should be able to read in the netstats.rds object from the preliminary step and just edit that directly for each calibration scenario
    - comments and unused lines have not been cleaned up
- also, took out the "experiment" defining for different types of edge calibration experiments... this could be added in in the future
- need to write out what to do if there are specific models that do not converge (e.g. VENUES ONLY for ONE-TIME partnerships)
    - how to run more of the ERGM fits to try and get convergence 
    
