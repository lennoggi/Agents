#!/bin/bash
#SBATCH -N 10
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task 56
#SBATCH --gpus-per-node 8
#SBATCH -t 02:00:00
#SBATCH -p agipGPU
#SBATCH -o vllm_qwen3.8-2.4t_rocm.out
#SBATCH -e vllm_qwen3.8-2.4t_rocm.err
#SBATCH -J vllm_qwen3.8-2.4t_rocm

if [[ -z "$SLURM_CPUS_PER_TASK" ]]
then
    echo "ERROR: SLURM_CPUS_PER_TASK unset" >&2
    exit 1
fi

if [[ -z "$SLURM_GPUS_PER_NODE" ]]
then
    echo "ERROR: SLURM_GPUS_PER_NODE unset" >&2
    exit 1
fi

if [[ -z "$SLURM_SUBMIT_DIR" ]]
then
    echo "ERROR: SLURM_SUBMIT_DIR unset" >&2
    exit 1
fi

echo "Launching with"
echo "  SLURM_CPUS_PER_TASK = $SLURM_CPUS_PER_TASK"
echo "  SLURM_GPUS_PER_NODE = $SLURM_GPUS_PER_NODE"
echo ""

time srun $SLURM_SUBMIT_DIR/vllm_qwen3.8-2.4t_rocm_slurm_singularity_launch.sh
