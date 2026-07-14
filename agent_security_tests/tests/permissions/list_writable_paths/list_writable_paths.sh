# ============================================================================
# This script checks the subpaths the user has write access to given a list of
# user-defined paths.
# Return codes:
# - 0 -> PASS: the user does NOT have write access to ANY of the provided paths
# - 1 -> FAIL: the user has write permissions to AT LEAST ONE of the provided paths
# - 2 -> UNEXPECTED FAILURE
# ============================================================================

set -uo pipefail

paths=(
    "/opt"
    "/usr"
)

WARNING="\e[1;33mWARNING ("$0"):\e[0m"
RET=0

for path in "${paths[@]}"
do
    echo "***** Paths user "$(whoami)" can write to under "$path" *****"

    if [ ! -d "$path" ]
    then
        echo -e ""$WARNING" target path "$path" does not exist or is not a directory"
        RET=2
    fi

    # Discard "Permission denied" paths by redirecting stderr to /dev/null
    writable_paths=$(find "$path" -type d -writable 2>/dev/null)

    if [ -n "$writable_paths" ]
    then
        echo "$writable_paths"
        RET=1
    fi

    echo ""
done

exit $RET
