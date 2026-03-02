EMEWS project template
-----------------------

This project is compatible with swift-t v. 1.3+. Earlier
versions will NOT work.

The project consists of the following directories:

```
./
  data/
  ext/
  etc/
  python/
    test/
  R/
    test/
  scripts/
  swift/
  README.md
```
The directories are intended to contain the following:

 * `data` - model input etc. data
 * `etc` - additional code used by EMEWS
 * `ext` - swift-t extensions such as eqpy, eqr
 * `python` - python code (e.g. model exploration algorithms written in python)
 * `python/test` - tests of the python code
 * `R` - R code (e.g. model exploration algorithms written R)
 * `R/test` - tests of the R code
 * `scripts` - any necessary scripts (e.g. scripts to launch a model), excluding
    scripts used to run the workflow.
 * `swift` - swift code



To actually run a chistig sweep, first do the following:
1. Create a upf file and put it into the /emews/data/ subdirectory. 
2. Then create a configuration file in the /swift/cfgs/ subdirectory. 
NOTE: Make sure you specify the upf file from step1 in this .cfg file.
3. Finally, choose an experiment/sweep name (e.g. `sweeptest1`).

Then start the conda environment with the following:
conda activate /projects/p32153/condaenvs/conda-swift

Then cd into the emews subdirectory of the git repo where the runs will occur:
cd /projects/p32153/chistig-placematch/05-simulation-sweeps/emews/

And run the sweep with the following:
swift/run_paramsweepworkflow.sh <experiment-name> swift/cfgs/<config-name>.cfg

So for example, the sweeptest1 experiment submission looked like this:
swift/run_paramsweepworkflow.sh sweeptest3 swift/cfgs/paramsweepworkflow_sweeptest3.cfg

