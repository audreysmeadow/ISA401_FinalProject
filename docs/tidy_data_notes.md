# Tidy Data Notes

Raw files are kept close to the acquired source format for auditability.
The clean, final, and dashboard-ready files are organized as tidy analysis tables:

- state-level files use one row per U.S. state and one variable per column;
- the AFDC station location file uses one row per physical charging station;
- the final dashboard state file merges the state-level sources into one row per state;
- station locations stay separate because their row grain is station-level, not state-level.

Validation output:
- `validation/tidy_data_validation.csv`
