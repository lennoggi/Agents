#!/bin/bash
#PBS -l select=1:ncpus=56:ngpus=4:mem=0
#PBS -l walltime=01:00:00
#PBS -q agipGPU
#PBS -o vLLM_Qwen3-Coder-Next_HPCS.out
#PBS -e vLLM_Qwen3-Coder-Next_HPCS.err
#PBS -N vLLM_Qwen3-Coder-Next_HPCS

# ----------
# Parameters
# ----------
PYTHON_MODULE="python/3.12.12"
CUDA_MODULE="cuda/13.0.2"
VENV="/scrt1/D/cibo/cibo39/vLLM_install/vllm-env"
NODEFILE="$PBS_O_WORKDIR/NodeList.txt"

# -----------------------
# Prepare the environment
# -----------------------
ml $PYTHON_MODULE
ml $CUDA_MODULE
. $VENV/bin/activate


# ----------------
# Setup and launch
# ----------------
cd $PBS_O_WORKDIR
cat $PBS_NODEFILE > $NODEFILE

NCPUS=$(grep '^#PBS -l select=' "${BASH_SOURCE[0]}" | grep -oP 'ncpus=\K[0-9]+')
NGPUS=$(grep '^#PBS -l select=' "${BASH_SOURCE[0]}" | grep -oP 'ngpus=\K[0-9]+')

if [[ -z "$NCPUS" ]]; then
    echo "Error: could not determine NCPUS from #PBS line" >&2
    exit 1
fi

if [[ -z "$NGPUS" ]]; then
    echo "Error: could not determine NGPUS from #PBS line" >&2
    exit 1
fi

echo "Launching with"
echo "  NCPUS  = $NCPUS"
echo "  NGPUS  = $NGPUS"
echo ""

time pbsdsh -v $PBS_O_WORKDIR/vLLM_Qwen3-Coder-Next_HPCS_launch.sh $PYTHON_MODULE $CUDA_MODULE $VENV $NODEFILE $NCPUS $NGPUS
deactivate
