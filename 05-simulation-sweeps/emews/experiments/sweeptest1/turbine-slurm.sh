#!/bin/bash -l
# We changed the M4 comment to d-n-l, not hash
# We may need 'bash -l' for the module system

# Copyright 2013 University of Chicago and Argonne National Laboratory
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

# TURBINE-SLURM.SH

# Created: 2026-02-24 17:03:41


#SBATCH --output=/gpfs/projects/p32153/chistig-placematch/05-simulation-sweeps/emews/experiments/sweeptest1/output.txt
#SBATCH --error=/gpfs/projects/p32153/chistig-placematch/05-simulation-sweeps/emews/experiments/sweeptest1/output.txt

#SBATCH --partition=normal


#SBATCH --account=p32153


#SBATCH --job-name=sweeptest1_job

#SBATCH --time=10:00:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH -D /gpfs/projects/p32153/chistig-placematch/05-simulation-sweeps/emews/experiments/sweeptest1

# M4 conditional to optionally perform user email notifications


# This block should be here, after other arguments to #SBATCH,
# so that the user can overwrite automatically set values
# such as --nodes (which is set in run-init.zsh using PROCS / PPN)
# Note this works because sbatch ignores all but the last of duplicate arguments
# TURBINE_SBATCH_ARGS could include --exclusive, --constraint=..., etc.


# BEGIN TURBINE_DIRECTIVE

# END TURBINE_DIRECTIVE

source ${TURBINE_HOME}/scripts/helpers.sh

START=$( nanos )
echo # Separate from startup junk
echo "TURBINE-SLURM.SH"

export TURBINE_HOME=$( cd "$(dirname "$0")/../../.." ; /bin/pwd )

VERBOSE=
if (( ${VERBOSE} ))
then
 set -x
fi

TURBINE_PILOT=${TURBINE_PILOT:-}
if (( ! ${#TURBINE_PILOT} ))
then
  TURBINE_HOME=/projects/p32153/software/swift-t/turbine
  source ${TURBINE_HOME}/scripts/turbine-config.sh
fi

COMMAND="/projects/p32153/condaenvs/conda-swift/bin/tclsh8.6 /gpfs/projects/p32153/chistig-placematch/05-simulation-sweeps/emews/experiments/sweeptest1/swift-t-paramsweepworkflow.8BC.tic sweeptest1 swift/cfgs/paramsweepworkflow.cfg -f=/gpfs/projects/p32153/chistig-placematch/05-simulation-sweeps/emews/experiments/sweeptest1/upf.txt"

# SLURM exports all environment variables to the job by default
# Evaluate any user turbine -e K=V settings here
ENV_PAIRS=( TURBINE_MPI_THREAD='1' TURBINE_OUTPUT='/gpfs/projects/p32153/chistig-placematch/05-simulation-sweeps/emews/experiments/sweeptest1' EMEWS_PROJECT_ROOT='/gpfs/projects/p32153/chistig-placematch/05-simulation-sweeps/emews' PROJECT='p32153' QUEUE='normal' WALLTIME='10:00:00' TURBINE_OUTPUT='/gpfs/projects/p32153/chistig-placematch/05-simulation-sweeps/emews/experiments/sweeptest1' TURBINE_JOBNAME='sweeptest1_job' TCLLIBPATH='/projects/p32153/software/swift-t/turbine/lib' ADLB_SERVERS='1' TURBINE_WORKERS='7' TURBINE_LOG='0' TURBINE_DEBUG='0' ADLB_DEBUG='0' ADLB_TRACE='0' PATH='/projects/p32153/software/swift-t/stc/bin:/projects/p32153/software/swift-t/turbine/bin:/projects/p32153/condaenvs/conda-swift/bin:/hpc/software/mamba/23.1.0/condabin:/gpfs/software/2025/pseudo-system-utils:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/lpp/mmfs/bin:/hpc/usertools:/home/spr4854/.local/bin:/home/spr4854/bin' PYTHONPATH='/projects/p32153/software/swift-t/turbine/py'  )
for P in "${ENV_PAIRS[@]}"
do
    export "$P"
done

# Use this on Midway:
# module load openmpi gcc/4.9
# Use mpiexec on Midway

# Use this on Bebop:
# module unload intel-mpi
# module unload intel-mkl
# module load gcc/7.1.0
# module load mvapich2
# module list
# TURBINE_LAUNCHER=srun

# Use this on Stampede2
#  TURBINE_LAUNCHER=ibrun

# Use this on Cori:
# TURBINE_LAUNCHER=srun
# module swap PrgEnv-intel PrgEnv-gnu
# module load gcc

TURBINE_LAUNCHER="/projects/p32153/condaenvs/conda-swift/bin/mpiexec"
TURBINE_INTERPOSER=""

# BEGIN TURBINE_PRELAUNCH

# END TURBINE_PRELAUNCH

if [[ ${TURBINE_LAUNCHER} == 0 ]]
then
  TURBINE_LAUNCHER=srun
fi

# module load cpe/23.05
# export LD_LIBRARY_PATH+=:/opt/cray/pe/mpich/8.1.26/ofi/gnu/9.1/lib

# Delay needed on Frontier:
# export PMI_MMAP_SYNC_WAIT_TIME=1800

SLURM_OPENMPI=

if (

  turbine_log_start | tee -a turbine.log
  turbine_report_env > turbine-env.txt

  if (( ${SLURM_OPENMPI:-0} == 0 ))
  then
    LAUNCH_OPTIONS=(
      --nodes=2
      --ntasks=8
      --ntasks-per-node=4
      
    )
  else
    # Case for OpenMPI launcher:
    LAUNCH_OPTIONS=(
      -n 8
      --map-by node:PE=PPN
    )
  fi

  # Report modules to output.txt for debugging:
  module list

  echo
  set -x
  # Launch it!
  ${TURBINE_LAUNCHER} ${LAUNCH_OPTIONS[@]} ${TURBINE_INTERPOSER} \
                      ${COMMAND}
)
then
  CODE=0
else
  CODE=$?
  echo
  echo "TURBINE-SLURM: MPI launcher returned an error code!"
  echo
fi

echo
STOP=$( nanos )
DURATION=$( duration )

turbine_log_stop | tee -a turbine.log

# Return exit code from launcher
exit $CODE

# Local Variables:
# mode: m4;
# End:
