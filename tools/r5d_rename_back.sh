#!/usr/bin/env bash
# R5D rollback (R5D_DESIGN_QUALIFICATION "Rollback"): rename the three retired
# mode-attempt tables back to their old names so the previous binary starts.
# Run inside a maintenance window. The settlement tables are untouched.
# usage: r5d_rename_back.sh <postgres-dsn>
set -euo pipefail
DSN=${1:?usage: r5d_rename_back.sh <postgres-dsn>}
psql "$DSN" -X -q -v ON_ERROR_STOP=1 --single-transaction <<'SQL'
ALTER TABLE worldboss_attempts_retired_r5d RENAME TO worldboss_attempts;
ALTER TABLE illusion_attempts_retired_r5d RENAME TO illusion_attempts;
ALTER TABLE adventure_single_attempts_retired_r5d RENAME TO adventure_single_attempts;
SQL
