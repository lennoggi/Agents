#!/bin/bash

set -euo pipefail

rundir="/path/to/user/scratch/vLLM_Qwen3-Coder-Next_CUDA_run"
launchscript="vLLM_Qwen3-Coder-Next_CUDA_launch.sh"
submitscript="vLLM_Qwen3-Coder-Next_CUDA_sub.sh"
submit_cmd="qsub"

mkdir ${rundir}
cp ../LaunchScripts/${launchscript} ${rundir}
cp ../SubmitScripts/${submitscript} ${rundir}
cd ${rundir}
${submit_cmd} ${submitscript}

echo ""
echo "Job submitted successfully"
echo ""
