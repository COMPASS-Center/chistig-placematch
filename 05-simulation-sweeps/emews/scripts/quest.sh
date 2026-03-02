module load mamba/23.1.0
source /hpc/software/mamba/23.1.0/etc/profile.d/conda.sh
set +u
conda activate /projects/p32153/condaenvs/conda-swift
set -u


which python
which python3
python --version
echo $PYTHONPATH
echo $CONDA_DEFAULT_ENV