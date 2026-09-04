# Pass346 I7 Offline Migration Rehearsal

I7 prepares and proves a PostgreSQL candidate. It does **not** switch runtime authority, open traffic, retire the legacy global `RLock`, or enable multiple HTTP workers. Those remain I8/I9 gates.

## Prerequisites

- Stop HTTP/realtime/background writers and let in-flight requests drain.
- Identify the operator-owned `GXB_MULTIUSER_ROOT` (`data/server_state` is intentionally absent from release archives).
- Use PostgreSQL 16 with data checksums and an empty database whose name ends in `_test` for rehearsal.
- Set `GXB_DATABASE_URL` to that disposable database. Never put its password on a command line; the supplied backup wrapper uses `PGPASSWORD` internally.

## Inventory and immutable snapshot

Run advisory discovery while the old service is live:

```bash
python tools/pass346_i7_migrate.py inventory \
  --source-root /srv/gxb/data/server_state \
  --report /restricted/preflight-redacted.json
```

After quiescing all writers, copy and seal the source. The destination must not already exist and cannot be inside the live root:

```bash
python tools/pass346_i7_migrate.py snapshot \
  --source-root /srv/gxb/data/server_state \
  --destination /restricted/gxb-snapshot-YYYYMMDD \
  --manifest /restricted/gxb-snapshot-YYYYMMDD.manifest.json \
  --report /restricted/gxb-snapshot-YYYYMMDD.redacted.json
```

The manifest is mode `0600` because paths can contain legacy session IDs. Keep the entire snapshot restricted; it contains password verifiers and retired bearer material. Import never reads the live root.

## Import and validate

Use the exact content root printed by the snapshot command:

```bash
python tools/pass346_i7_migrate.py migrate \
  --snapshot-root /restricted/gxb-snapshot-YYYYMMDD \
  --expected-content-root SHA256_FROM_SNAPSHOT \
  --manifest /restricted/gxb-snapshot-YYYYMMDD.manifest.json \
  --report /restricted/i7-migration-redacted.json
```

The importer refuses a non-empty target and any database not ending in `_test`. Identity/index/region/semantic contradictions stop the run. The only automatic adjustments are forward-only allocator lifts and deterministic invalid/colliding mail-ID remaps, all recorded in the report. Legacy sessions and raw bearers are counted then discarded; users must reauthenticate after the eventual I8 cutover.

## Logical backup and independent restore

```bash
python tools/pass346_i7_backup.py dump /restricted/gxb-i7.dump
# Create a second empty *_test database and point GXB_DATABASE_URL at it.
python tools/pass346_i7_backup.py restore /restricted/gxb-i7.dump
python tools/pass346_i7_migrate.py validate \
  --snapshot-root /restricted/gxb-snapshot-YYYYMMDD \
  --expected-content-root SHA256_FROM_SNAPSHOT \
  --manifest /restricted/gxb-snapshot-YYYYMMDD.manifest.json \
  --report /restricted/i7-restored-redacted.json
```

The restore wrapper never uses `--clean`: the operator creates an unambiguously disposable empty database. Preserve the dump SHA-256 and validation report.

## Physical backup/PITR drill

Configure pgBackRest with its repository outside `PGDATA`, continuous `archive_mode=on`, and an `archive_command` using `archive-push`. Run `stanza-create`, `check`, a full backup, and a timed recovery into a separate empty `PGDATA`. Confirm the restored marker set stops at the requested target, PostgreSQL promotes onto a new timeline, and the candidate remains readable. Retention/RPO/RTO are operator policy; I7 does not invent fixed values.

## Failure boundary

- Before I8 `TRAFFIC_OPEN`, discard a failed candidate and repeat from the same immutable snapshot.
- Once I8 opens write traffic, JSON is archival evidence only. Recovery uses PostgreSQL backup/PITR or forward repair—never stale JSON.
- I7 has no function or CLI option that writes `TRAFFIC_OPEN`.
