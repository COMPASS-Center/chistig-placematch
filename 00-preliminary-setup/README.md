The preliminary works to set up everything needed before we begin the Chistig modeling specific to the venues colocating. It includes the following steps:

1. `radar_prelim.R` - sets up and anonymizes the data from the RADAR dataset needed throughout the simulations (from acts_setup.R)
2. `epistats.R ` - Sets up the base `epistats` object for the rest of EpiModel 
3. `artnet_prelim.R` - sets up the data from the ARTnet dataset so that the ARTnet and ARTnetData packages are no longer needed throughout the rest of the simulations
4. `netstats.R` - Sets up the base `netstats` object for the rest of EpiModel 

The `prelim.yaml` file sets up the necessary arguments needed for the preliminary steps.


To run the above, do the following:

First, either run the `radar_prelim.R` script locally, or ensure the correct output file is stored within the 
`00-preliminary-setup` directory. 

Then, sign in to Quest, and setup the environment for our `R` and `python` instances:
```sh
module purge all 
conda activate /projects/p32153/condaenvs/conda-chistig
```

From here, you can run the rest of the preliminary scripts in the following order:
```sh
Rscript epistats.R prelim.yaml
Rscript artnet_prelim.R prelim.yaml
Rscript netstats.R prelim.yaml
```

At the end of this, you should have the base `netstats.rds` object that will be used throughout the rest of the simulations. 
