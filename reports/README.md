# Reporting on GitHub Actions usage

This folder contains MySQL queries around the usage of GitHub Actions.

:information_source: Please don't run these against your production database.  Use the backup taken from [backup-utils](https://github.com/github/backup-utils) loaded into another server, just in case.

## Usage summary report

This query returns a table of the compute time provided (hours), average time each job spends in queue (seconds), and a count of jobs run, all broken down by month.
