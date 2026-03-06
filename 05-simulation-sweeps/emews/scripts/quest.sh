module load mamba/23.1.0
source /hpc/software/mamba/23.1.0/etc/profile.d/conda.sh
set +u
conda activate /projects/p32153/condaenvs/conda-swift
set -u

export PYTHONPATH=$EMEWS_PROJECT_ROOT/python:/projects/p32153/software/swift-t/turbine/py:${PYTHONPATH:-}

which python
which python3
python --version
echo $PYTHONPATH
echo $CONDA_DEFAULT_ENV
