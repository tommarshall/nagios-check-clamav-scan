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

@test "exits UNKNOWN if an executable dependency is missing" {
  PATH='/bin'
  run $BASE_DIR/check_clamav --logfile clamav.log

  assert_failure 3
  assert_output "UNKNOWN: Missing dependency: cut"
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

@test "exits UNKNOWN logfile older than the default threshold" {
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
  touch -m -d "$(date -d '-49 hours')" clamav.log.clean

  run $BASE_DIR/check_clamav --logfile clamav.log.clean

  assert_failure 3
  assert_output "UNKNOWN: Logfile has expired, more than 48 hours old"
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

# --expiry
# ------------------------------------------------------------------------------
@test "--expiry overrides default" {
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
  touch -m -d "$(date -d '-2 hours')" clamav.log.clean

  run $BASE_DIR/check_clamav --logfile clamav.log.clean --expiry '1 hour'

  assert_failure 3
  assert_output "UNKNOWN: Logfile has expired, more than 1 hour old"
}

@test "-e is an alias for --expiry" {
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
  touch -m -d "$(date -d '-2 hours')" clamav.log.clean

  run $BASE_DIR/check_clamav --logfile clamav.log.clean -e '1 hour'

  assert_failure 3
  assert_output "UNKNOWN: Logfile has expired, more than 1 hour old"
}

@test "exits UNKNOWN if invalid date string" {
  cat > clamav.log.clean <<-EOF
----------- SCAN SUMMARY -----------
Infected files: 0
EOF

  run $BASE_DIR/check_clamav --logfile clamav.log.clean --expiry 'not-a-valid-date'

  assert_failure 3
  assert_output "UNKNOWN: Invalid expiry specified: not-a-valid-date"
}

# --critical
# ------------------------------------------------------------------------------
@test "--critical overrides default" {
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

  run $BASE_DIR/check_clamav --logfile clamav.log.infected --critical 2

  assert_failure 1
  assert_output "WARNING: 1 infected file(s) detected"
}

@test "-c is an alias for --critical" {
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

  run $BASE_DIR/check_clamav --logfile clamav.log.infected -c 2

  assert_failure 1
  assert_output "WARNING: 1 infected file(s) detected"
}

# --warning
# ------------------------------------------------------------------------------
@test "--warning overrides default" {
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

  run $BASE_DIR/check_clamav --logfile clamav.log.infected --critical 3 --warning 2

  assert_success
  assert_output "OK: 1 infected file(s) detected"
}

@test "-w is an alias for --warning" {
  skip
}

@test "-w is an alias for --warning" {
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

  run $BASE_DIR/check_clamav --logfile clamav.log.infected --critical 3 -w 2

  assert_success
  assert_output "OK: 1 infected file(s) detected"
}

@test "critical takes prescence over warning" {
cat > clamav.log.infected <<-EOF
----------- SCAN SUMMARY -----------
Known viruses: 6297594
Engine version: 0.99.2
Scanned directories: 1
Infected files: 2
Scanned files: 35
Data scanned: 0.11 MB
Data read: 0.05 MB (ratio 2.00:1)
Time: 13.705 sec (0 m 13 s)
EOF

  run $BASE_DIR/check_clamav --logfile clamav.log.infected --critical 2 --warning 1

  assert_failure 2
  assert_output "CRITICAL: 2 infected file(s) detected"
}

# --verbose
# ------------------------------------------------------------------------------
@test "--verbose includes the scan summary in the output" {
  cat > clamav.log <<-EOF
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

  run $BASE_DIR/check_clamav --logfile clamav.log --verbose

  assert_success
  assert_output <<-EOF
OK: 0 infected file(s) detected
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
}

@test "-v is an alias for --verbose" {
  cat > clamav.log <<-EOF
----------- SCAN SUMMARY -----------
Infected files: 0
EOF

  run $BASE_DIR/check_clamav --logfile clamav.log -v

  assert_success
  assert_output <<-EOF
OK: 0 infected file(s) detected
----------- SCAN SUMMARY -----------
Infected files: 0
EOF
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
  assert_line --partial "Usage: ./check_clamav -l <path> [options]"
}

@test "-h is an alias for --help" {
  run $BASE_DIR/check_clamav -h

  assert_success
  assert_line --partial "Usage: ./check_clamav -l <path> [options]"
}
