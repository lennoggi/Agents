#!/bin/bash
#PBS -l select=1:mpiprocs=1:ncpus=56:ngpus=4:mem=0
#PBS -l walltime=01:00:00
#PBS -q agipGPU
#PBS -o vllm_qwen3-coder-next_cuda_pbs.out
#PBS -e vllm_qwen3-coder-next_cuda_pbs.err
#PBS -N vllm_qwen3-coder-next_cuda_pbs

PYTHON_MODULE="python/3.12.12"
CUDA_MODULE="cuda/13.0.2"
VENV="/path/to/user/scratch/vLLM_install/vllm-env"

ml $PYTHON_MODULE
ml $CUDA_MODULE
. $VENV/bin/activate

export NCPUS=$(grep '^#PBS -l select=' "${BASH_SOURCE[0]}" | grep -oP 'ncpus=\K[0-9]+')
export NGPUS=$(grep '^#PBS -l select=' "${BASH_SOURCE[0]}" | grep -oP 'ngpus=\K[0-9]+')

if [[ -z "$NCPUS" ]]
then
    echo "ERROR: could not determine NCPUS from #PBS line" >&2
    exit 1
fi

if [[ -z "$NGPUS" ]]
then
    echo "ERROR: could not determine NGPUS from #PBS line" >&2
    exit 1
fi

echo "Launching with"
echo "  NCPUS  = $NCPUS"
echo "  NGPUS  = $NGPUS"
echo ""

cd $PBS_O_WORKDIR
time pbsdsh -v -- env PYTHON_MODULE="$PYTHON_MODULE" CUDA_MODULE="$CUDA_MODULE" VENV="$VENV" NCPUS="$NCPUS" NGPUS="$NGPUS" PBS_NODEFILE="$PBS_NODEFILE" $PBS_O_WORKDIR/vllm_qwen3-coder-next_cuda_pbs_launch.sh
deactivate
