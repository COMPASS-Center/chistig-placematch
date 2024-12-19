# Describe the steps to set up an edge calibration experiment 

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

