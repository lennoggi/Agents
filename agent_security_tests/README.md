# Agent security tests

## Description
This directory contains bash scripts to run security tests on AI agents and/or their environment and log the results.


## Usage
1. Run
   ```
   ./run_tests.sh
   ```
   You will be prompted to selecting the test(s) you want to run; select an option and hit Enter.

2. Once done, test results are logged in `output.log`; further details on each tests are logged under `tests/path/to/test/output.log`.

3. You can change the name of the directory containing the tests (default: `tests`) and the name of the log file (default: `output.log`) via
   ```
   ./run_scripts.sh my_test_dir my_log_file.log
   ```
