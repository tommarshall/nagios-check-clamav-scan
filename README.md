# Nagios check_clamav

[![Build Status](https://travis-ci.org/tommarshall/nagios-check-clamav.svg?branch=master)](https://travis-ci.org/tommarshall/nagios-check-clamav)

Nagios plugin for monitoring [ClamAV] virus scans.

## Installation

Install [ClamAV].

Define a cron task for ClamAV to perform a scan, capturing the output in a logfile, e.g.

```sh
0 0 * * * root clamscan -r -i /var/www/uploads > /tmp/clamav.log
```

Download the [check_clamav] script and make it executable.

Define a new `command` in the Nagios config, e.g.

```nagios
define command {
    command_name    check_clamav
    command_line    $USER1$/check_clamav -l /tmp/clamav.log
}
```

## Usage

```
Usage: ./check_clamav -l <path> [options]
```

### Examples

```sh
# exit OK if 0 infected files detected, CRITICAL if 1 or more detected
./check_clamav -l /tmp/clamav.log

# exit UNKNOWN if logfile is more than 1 hour old
./check_clamav -l /tmp/clamav.log -e '1 hour'

# exit OK if 0 infected files detected, WARNING if upto 10 detected, CRITICAL if 10 or more detected
./check_clamav -l /tmp/clamav.log -c 10

# exit OK if upto 4 infected files detected, WARNING if upto 5 detected, CRITICAL if 10 or more detected
./check_clamav -l /tmp/clamav.log -c 10 -w 5
```

### Options

```
-l, --logfile <path>        path to clamscan logfile
-e, --expiry <duration>     expiry threshold for logfile
-w, --warning <number>      number of infected files treat as WARNING
-c, --critical <number>     number of infected files to treat as CRITICAL
-V, --version               output version
-h, --help                  output help information
```

* `-e`/`--expiry` should be a human readable duration, e.g. '1 hour', or '7 days'.
* `-c`/`--critical` takes priority over `-w`/`--warning`.

## Dependencies

* Bash
* `cut`, `grep`, `rev`, `sed`

[ClamAV]: https://www.clamav.net/
[check_clamav]: https://cdn.rawgit.com/tommarshall/nagios-check-clamav/v0.1.0/check_clamav
