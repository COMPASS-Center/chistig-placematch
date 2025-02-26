The preliminary works to set up everything needed before we begin the Chistig modeling specific to the venues colocating. It includes the following steps:

1. `radar_prelim.R` - sets up and anonymizes the data from the RADAR dataset needed throughout the simulations (from acts_setup.R)
2. `epistats.R ` - Sets up the base `epistats` object for the rest of EpiModel 
3. `artnet_prelim.R` - sets up the data from the ARTnet dataset so that the ARTnet and ARTnetData packages are no longer needed throughout the rest of the simulations
4. `netstats.R` - Sets up the base `netstats` object for the rest of EpiModel 

The `prelim.yaml` file sets up the necessary arguments needed for the preliminary steps.


To run the above, do the following:

1.

```sh
Rscript radar_prelim.R prelim.yaml
```

2. 

```sh
Rscript epistats.R prelim.yaml
```

3.

```sh
Rscript artnet_prelim.R prelim.yaml
```

4. 

```sh
Rscript netstats.R prelim.yaml
```

