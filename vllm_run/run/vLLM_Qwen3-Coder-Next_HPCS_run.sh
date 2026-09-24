#!/bin/bash

set -euo pipefail

rundir="/scrt1/D/cibo/cibo39/vLLM_Qwen3-Coder-Next_HPCS_run"
launchscript="vLLM_Qwen3-Coder-Next_HPCS_launch.sh"
submitscript="vLLM_Qwen3-Coder-Next_HPCS_sub.sh"
submit_cmd="qsub"

mkdir ${rundir}
cp ../LaunchScripts/${launchscript} ${rundir}
cp ../SubmitScripts/${submitscript} ${rundir}
cd ${rundir}
${submit_cmd} ${submitscript}

echo ""
echo "Job submitted successfully"
echo ""
