#!/usr/bin/env bats

load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'
load 'test_helper'

# Validation
# ------------------------------------------------------------------------------
@test "exits UNKNOWN if unrecognised option provided" {
  run $BASE_DIR/check_clamav --logfile /tmp/foo --not-an-arg

  assert_failure 3
  assert_line "UNKNOWN: Unrecognised argument: --not-an-arg"
  assert_line --partial "Usage:"
}

@test "exits UNKNOWN if --logfile/-l not provided" {
  run $BASE_DIR/check_clamav

  assert_failure 3
  assert_output "UNKNOWN: --logfile/-l not set"
}

@test "exits UNKNOWN if --logfile/-l is not readable" {
  touch clamav.log.unreadable
  chmod a-r clamav.log.unreadable

  run $BASE_DIR/check_clamav --logfile clamav.log.unreadable

  assert_failure 3
  assert_output "UNKNOWN: Unable to read logfile: clamav.log.unreadable"
}

@test "exits UNKNOWN if scan summary not found within logfile" {
  touch clamav.log.empty

  run $BASE_DIR/check_clamav --logfile clamav.log.empty

  assert_failure 3
  assert_output "UNKNOWN: Unable to locate scan summary within logfile"
}

@test "exits UNKNOWN if infected files total not found within scan summary" {
  cat > clamav.log.partial-summary <<-EOF
----------- SCAN SUMMARY -----------
Known viruses: 6297594
Engine version: 0.99.2
Scanned directories: 1
Scanned files: 35
Data scanned: 0.11 MB
Data read: 0.05 MB (ratio 2.00:1)
Time: 13.705 sec (0 m 13 s)
EOF

  run $BASE_DIR/check_clamav --logfile clamav.log.partial-summary

  assert_failure 3
  assert_output "UNKNOWN: Unable to locate infected files count within scan summary"
}

# Defaults
#------------------------------------------------------------------------------
@test "exits OK if no infected files are found" {
  cat > clamav.log.clean <<-EOF
----------- SCAN SUMMARY -----------
Known viruses: 6297594
Engine version: 0.99.2
Scanned directories: 1
Infected files: 0
Scanned files: 35
Data scanned: 0.11 MB
Data read: 0.05 MB (ratio 2.00:1)
Time: 13.705 sec (0 m 13 s)
EOF

  run $BASE_DIR/check_clamav --logfile clamav.log.clean

  assert_success
  assert_output "OK: 0 infected file(s) detected"
}

@test "exits CRITICAL if an infected file is found" {
  cat > clamav.log.infected <<-EOF
----------- SCAN SUMMARY -----------
Known viruses: 6297594
Engine version: 0.99.2
Scanned directories: 1
Infected files: 1
Scanned files: 35
Data scanned: 0.11 MB
Data read: 0.05 MB (ratio 2.00:1)
Time: 13.705 sec (0 m 13 s)
EOF

  run $BASE_DIR/check_clamav --logfile clamav.log.infected

  assert_failure 2
  assert_output "CRITICAL: 1 infected file(s) detected"
}

# --logfile
# ------------------------------------------------------------------------------
@test "-l is an alias for --logfile" {
  cat > clamav.log.clean <<-EOF
----------- SCAN SUMMARY -----------
Infected files: 0
EOF

  run $BASE_DIR/check_clamav --logfile clamav.log.clean

  assert_success
  assert_output "OK: 0 infected file(s) detected"
}

# --version
# ------------------------------------------------------------------------------
@test "--version prints the version" {
  run $BASE_DIR/check_clamav --version

  assert_success
  [[ "$output" == "check_clamav "?.?.? ]]
}

@test "-V is an alias for --version" {
  run $BASE_DIR/check_clamav -V

  assert_success
  [[ "$output" == "check_clamav "?.?.? ]]
}

# --help
# ------------------------------------------------------------------------------
@test "--help prints the usage" {
  run $BASE_DIR/check_clamav --help

  assert_success
  assert_line --partial "Usage: ./check_clamav -l <path>"
}

@test "-h is an alias for --help" {
  run $BASE_DIR/check_clamav -h

  assert_success
  assert_line --partial "Usage: ./check_clamav -l <path>"
}