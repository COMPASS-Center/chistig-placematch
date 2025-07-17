# Step 2: Calibration of Edges in ERGMs Underlying Experimental Treatments

In most simulation experiments using `EpiModelHIV`, experimental treatments are operationalized through "scenarios" that vary according to parameter values that determine simulated agents' behaviors related to HIV epidemiology (e.g. condom use, PrEP uptake and adherence, rates of HIV testing, ART uptake and adherence). While these parameters vary, the underlying network models (ERGMs) that determine sexual partnership formation and dissolution remain constant across experimental treatments. In this regard, our study makes a noteworthy departure from past `EpiModel` experiments. Our study is interested in how disparities in HIV incidence change when sexual partnerships are allowed to form on the basis of co-location in physical venues vs. when they are not. Our "scenarios," so to speak, are the inverse of what has been done in the past: parameters governing agents' epidemiological behaviors are kept constant, but our treatments use different sets of ERGMs to change the rules governing sexual partnership formation. This is why we created four different sets of ERGM fits (stored as `netest` objects) in Step 1 (`01-networks-estimation`).

While experimental treatments in our study use different sets of ERGMs to shape their respective sexual networks, these networks should have the same number of edges regardless of treatment. In theory, this similarity across treatments should be baked into our ERGMs, since we keep the target stats used to specify the number of edges in our network (`edges`) constant across treatments. In practice, however, our ERGM fits as they appear at the end of Step 1 produce treatments whose networks have different numbers of edges than those produced by our control simulation. We suspect this is a consequence of how we used data pertaining to venue colocation to fit ERGMs in our previous study (link to place-and-pop repo), which may differ from how these data need to be adapted for the purposes of `EpiModel`.

Were we to simply proceed with the ERGMs produced in Step 1, it would be difficult to defend the idea of experimental control between our treatments. Accordingly, this step of the preparation process adjusts the target stats we initially used to create ERGM fits underlying our experimental treatments. At the end of this step, the ERGMs underlying our treatments should be calibrated so that they produce networks with the same number of edges (and other properties) as those underlying our control model.

### 1. Create Edge Calibration Scenarios

For each experimental treatment in our study, we need to calibrate some combination of three values for each of our ERGM fits (main partnerships, casual partnerships, one-time partnerships):

- Target stat indicating the number of edges (partnerships) in the network whose nodes should have had some colocation at physical venues at the time of formation
- Target stat indicating the number of edges in the network whose nodes should have had some colocation on dating apps at the time of formation
- Departure rate (`d.rate`) parameter adjusting for agents exiting network - In practice, this parameter allows ERGMs to adjust for the rate at which people exit the network so that the number of edges in the network remains stable over time

The `step1_edge_calibration.R` script allows users to specify a set of values for each of these target stats/`d.rate` parameters that they wish to test. To get started, users will have to manually edit the values stored in objects between lines 47-72 of this script and then save their updates. Once this is done, running this script will create a `csv` file containing all possible combinations of the target stats/`d.rate` parameters you want to explore, which will then be fed into later steps of the edge calibration process. The shell files in this directory will do this for you, however, so *DO NOT* run this script on your own.

### 2. Copy Changes to HPC Directory (If Needed)

If you completed the previous step on your local machine, you will need to push your changes to your GitHub repository and pull them to where this workflow is located on your HPC allocation.

### 3. Run Shell Files on HPC

@Sara or @Josh I need you to run me through what the shell file workflow in this directory looks like. Do users only need to run one of these files and it will ensure the remaining shell files run? Or is it more involved than that? I can write out this step by myself once I know.

### 4. Evaluate Edge Calibration Results

I don't *think* this script I use to visualize and diagnose edge calibration results is currently here. I think the best way forward is to confirm that all of Step 2 runs okay after recent changes, and then I'll take the data created at the end of what we currently have and ensure my visualization script works with it. 







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

