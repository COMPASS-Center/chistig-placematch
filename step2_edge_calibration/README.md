# Describe the specific calibration test here

To run an edge calibration, do the following:

## Setup the calibration experiment

1. Make sure you are in the appropriate subdirectory. It should be the experiment name of your calibration test. For example, let us use the experiment name example of `test18sep`. You should be in the following directory: `/projects/p32153/ChiSTIG_model/calibration/test18sep/`. If not, run the following from the terminal in Quest:
```sh
cd /projects/p32153/ChiSTIG_model/calibration/test18sep/
```


2. Edit the `step1_edge_calibration.R` script to setup the calibration sets you would like to explore. 


3. Make a copy of `testXX.yaml` in the experiment name of your calibration test. If you are in the quest terminal, an example of how to do this would look like the following: 
```sh
cp testXX.yaml test18sep.yaml
``` 

where `test18sep` is the experiment name of your calibration test.

NOTE: Your calibration test subdirectory MUST be named the same as your experiment name. (e.g., `test18sep.yaml` must be inside the `ChiSTIG_model/calibration/test18sep/` subdirectory) 


4.  Edit the `testXX.yaml` to reflect the arguments you would like for the calibration test. You should not need to edit much here EXCEPT the `expname: testXX` argument in the first line. Again, this variable MUST be named the same as your experiment (and subdirectory) name. For for this example, it would look like the following:
```yaml
expname: 'test18sep'
```

## Setup and run the ERGM fits for each calibration set, treatment type, and partnership type

4. Setup the Python and R environment to carry out our initial ERGM fits on Quest. To do so, run the following from the Quest terminal:
```sh
module purge all
conda activate /projects/p32153/condaenvs/conda-chistig
```


5. Make the `edge_calibration_procedure_ONE.sh` executable. To do so, run the following from the Quest terminal:
```sh
chmod +x edge_calibration_procedure_ONE.sh
```


6. Setup and run the ERGM fits for each of the calibration sets. To do so, run the `edge_calibration_procedure_ONE.sh` script from the terminal while passing in the corresponding `.yaml` file. For our example here, this would look like the following:
```sh
./edge_calibration_procedure_ONE.sh test18sep.yaml
```


7. Wait for the ERGM fits to run completely (can take up to 48 hours, but should be less)...


## Setup and run the simulations for each treatment type and calibration set

8. If you are starting a new Quest session, then re-setup the Python and R environment to carry out the simulations on Quest. To do so, run the following from the Quest terminal:
```sh
module purge all
conda activate /projects/p32153/condaenvs/conda-chistig
```


9. Make the `edge_calibration_procedure_TWO.sh` executable. To do so, run the following from the Quest terminal:
```sh
chmod +x edge_calibration_procedure_TWO.sh
```


10. Setup and run the simulations for the ERGM fits for each calibration set. To do so, run the `edge_calibration_procedure_TWO.sh` script from the terminal while passing in the corresponding `.yaml` file. For our example here, this would look like the following:
```sh
./edge_calibration_procedure_TWO.sh test18sep.yaml
```


11. Wait for the simulations to run completely (can take up to 48 hours, but should be less)...


## Obtain simulation results

12. Results from the simulations will be in the `/projects/p32153/ChiSTIG_model/output/` subdirectory. 

NOTE: Ignore the `agent_log_XX.txt` files.

NOTE: For any ERGM fits of that did not converge in step 6., there should not be an associated `.rds` output for those corresponding calibration sets. To see the calibration sets that did not converge across all ERGM fits, see the `calibration_sets_that_did_not_converge_testXX.txt` file in the experiment subdirectory. For this example, that would be the following: `/projects/p32153/ChiSTIG_model/calibration/test26sep/calibration_sets_that_did_not_converge_test18sep.txt`.








