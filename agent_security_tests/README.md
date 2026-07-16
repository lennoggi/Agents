# Agent security tests

## Description
This directory contains bash scripts to run security tests on AI agents and/or their environment and log the results.


## Usage
1. Run
   ```
   ./run_tests.sh
   ```
   You will be prompted to selecting the test(s) you want to run; select an option and hit Enter.

2. Once done, test results are logged in `output.log`; further details on each test's output are logged under `tests/path/to/test/output.log`.

3. You can change the name of the directory containing the tests (default: `tests`) and the name of the log file (default: `output.log`) via
   ```
   ./run_scripts.sh my_test_dir my_log_file.log
   ```


## How to implement a new test
1. Navigate to the desired test directory, e.g.,
   ```
   cd tests/permissions/list_writable_paths
   ```

2. Create a test script *with the same name as the leaf directory* with `.sh` extension, e.g.,
   ```
   touch list_writable_paths.sh
   ```
   **WARNING:** the driver script `run_tests.sh` won't find your test script unless you comply with the above naming convention

3. Implement the test making sure your script can only ever exit with one of these three codes:
   - `exit 0`: test passed
   - `exit 1`: test failed
   - `exit 2`: unexpected failure (e.g., bad input parameters, ...)
   See `tests/permissions/list_writable_paths/list_writable_paths.sh` for an example.
