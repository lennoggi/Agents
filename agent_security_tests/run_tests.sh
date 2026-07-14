# =======================================================================
# Driver script running AI agent security tests and logging their results 
# =======================================================================

set -euo pipefail


# ----------------
# Helper variables
# ----------------
PASS="\e[1;32mPASS:\e[0m"
FAIL="\e[1;31mFAIL:\e[0m"
UNEXPECTED_FAILURE="\e[1;33mUNEXPECTED FAILURE:\e[0m"
INVALID_EXIT_STATUS="\e[1;35mINVALID_EXIT_STATUS:\e[0m"


# ----------------------------------
# Helper routine to run single tests
# ----------------------------------
run_test() {
    path="$1"
    log_file="$2"
    append_to_output_log=$3

    # The expected test script's name is the leaf directory's name + ".sh".
    # The following command extracts the substring to the right of the
    # rightmost "/" character (leaf directory's name).
    test_script="${path}/${path##*/}.sh"

    ((append_to_output_log)) && tee_cmd="tee -a" || tee_cmd="tee"

    if [ -f "$test_script" ]
    then
        echo -n "$test_script" | tr '[:print:]' '-'
        echo -e "\n$test_script"
        echo -n "$test_script" | tr '[:print:]' '-'
        echo ""

        local_log_file="${path}/output.log"

        # Prevent "set -e" from killing the script in case "$test_script"
        # returns non-zero
        set +e
        "$test_script" 2>&1 | tee "$local_log_file"
        exit_status="${PIPESTATUS[0]}"  # Captures the exit status of "$test_script"
        set -e

        case "$exit_status" in
            0)
                echo -e ""$PASS" "$path"" ## | "$tee_cmd" "$log_file"
                ;;
            1)
                echo -e ""$FAIL" "$path", check log "$local_log_file"" | "$tee_cmd" "$log_file"
                ;;
            2)
                echo -e ""$UNEXPECTED_FAILURE" "$path", check log "$local_log_file"" | "$tee_cmd" "$log_file"
                ;;
            *)
                echo -e ""$INVALID_EXIT_STATUS" "$exit_status" "$path""  | $tee_cmd $log_file
                ;;
        esac
    else
        echo -e ""$UNEXPECTED_FAILURE" test script "$(realpath $test_script)" not found, quitting" | $tee_cmd $log_file
        add_log_lines $log_file
        exit 2
    fi
}



# ----------------------------------
# Helper routine to output test logs
# ----------------------------------
add_log_lines() {
    log_file="$1"

    echo -e "\n=========
TEST LOGS
=========
Test script:   "$(realpath "${BASH_SOURCE[0]}")"
User:          "$(whoami)"
Machine:       "$(hostname -s)"
Date and time: "$(date '+%Y-%m-%d %H:%M:%S')"
Log file:      "$(realpath "$log_file")"" | tee -a "$log_file"
}





# *****
# Begin
# *****

# ---------------------------------------------------------------------------
# Parse the (optional) command-line argument (directory containing the tests)
# NOTE: the tests directory defaults to $PWD/tests if not specified
# ---------------------------------------------------------------------------
[[ $# -lt 3 ]] || { echo "Usage: "$0" [OPTIONAL: TEST_DIR] [OPTIONAL: log file name]" >&2; exit 1; }

TEST_DIR="${1:-tests}"
LOG_FILE="${2:-output.log}"

echo "Current directory: $(pwd)"

if ! [ -d "$TEST_DIR" ]
then
    echo -e ""$UNEXPECTED_FAILURE" test directory $(realpath "$TEST_DIR") does not exist, quitting" | tee "$LOG_FILE"
    add_log_lines "$LOG_FILE"
    exit 2
fi

echo "Test directory:    $(realpath "$TEST_DIR")"
echo "Log file:          $(realpath "$LOG_FILE")"


# ---------------------------------------------------------------------------
# Scan $TEST_DIR for test subdirectories and add them as options the user can
# dynamically select
# ---------------------------------------------------------------------------
options=()

while IFS= read -r -d '' dir; do
    # Just list leaf subdirectories
    has_subdir=$(find "$dir" -mindepth 1 -maxdepth 1 -type d -print -quit)
    
    if [ -z "$has_subdir" ]; then
        options+=("$dir")
    fi
done < <(find "$TEST_DIR" -mindepth 1 -type d -print0 2>/dev/null)

options+=("Run all tests")
options+=("Quit")


# ------------------------
# List the available tests
# ------------------------
echo -e "\n----------------"
echo "Available tests:"
echo "----------------"
COLUMNS=1  # Force listing the paths on separate lines
PS3=$'\nWhich test do you want to run? '
select option in "${options[@]}"
do
    # Validate that the user picked a valid option from the menu
    if [ -n "$option" ]; then
        # ***** Run all tests *****
        if [ "$option" = "Run all tests" ]
        then
            echo "Running all tests"

            # Exclude the last two options ("Run all tests" and "Quit" are not
            # test directories)
            for ((i=0; i < ${#options[@]}-2; ++i))
            do
                (( i == 0 )) && append_to_output_log=0 || append_to_output_log=1
                run_test "${options[i]}" "$LOG_FILE" $append_to_output_log
            done

            add_log_lines "$LOG_FILE"


        # ***** Quit *****
        elif [ "$option" = "Quit" ]
        then
            echo "Quitting tests following user decision" | tee "$LOG_FILE"
            add_log_lines "$LOG_FILE"
            exit 2


        # ***** Run a specific test only *****
        else
            append_to_output_log=0
            run_test "$option" "$LOG_FILE" $append_to_output_log
            add_log_lines "$LOG_FILE"
        fi
        break
    else
        echo "Invalid choice. Please pick a number between 1 and ${#options[@]}."
    fi
done
