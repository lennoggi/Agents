#!/bin/bash
#PBS -l select=20:mpiprocs=1:ncpus=56:ngpus=8:mem=0
#PBS -l walltime=02:00:00
#PBS -q agipGPU
#PBS -o vllm_qwen3.8-2.4t.out
#PBS -e vllm_qwen3.8-2.4t.err
#PBS -N vllm_qwen3.8-2.4t

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
time pbsdsh -v -- env NCPUS="$NCPUS" NGPUS="$NGPUS" PBS_NODEFILE="$PBS_NODEFILE" $PBS_O_WORKDIR/vllm_qwen3.8-2.4t_rocm_pbs_singularity_launch.sh
