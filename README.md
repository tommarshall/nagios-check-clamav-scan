# Nagios check_clamav

Nagios plugin for monitoring [ClamAV] virus scans.

Exits `CRITICAL` if any infected files are reported within the `clamscan` log, otherwise `OK`.

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
Usage: ./check_clamav -l <path>
```

### Examples

```sh
# exit CRITICAL if 1 or more infected files are found, otherwise OK
./check_clamav -l /tmp/clamav.log
```

### Options

```
-l, --logfile <path>        Path to clamscan logfile
-V, --version               output version
-h, --help                  output help information
```

## Dependencies

* Bash

[ClamAV]: https://www.clamav.net/
[check_clamav]: https://cdn.rawgit.com/tommarshall/nagios-check-clamav/v0.1.0/check_clamav
