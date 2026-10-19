#!/bin/bash

set -euo pipefail

rundir="/path/to/user/scratch/vllm_qwen3.8-2.4t_rocm_pbs_singularity_run"
launchscript="vllm_qwen3.8-2.4t_rocm_pbs_singularity_launch.sh"
submitscript="vllm_qwen3.8-2.4t_rocm_pbs_singularity_sub.sh"
submit_cmd="qsub"

mkdir ${rundir}
cp ../launch/${launchscript} ${rundir}
cp ../submit/${submitscript} ${rundir}
cd ${rundir}
${submit_cmd} ${submitscript}

echo ""
echo "Job submitted successfully"
echo ""
