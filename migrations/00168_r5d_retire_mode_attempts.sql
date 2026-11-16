-- +goose Up
-- owner: worldboss
-- owner: illusion
-- owner: adventure
-- R5D data migration (design "Data migration"): every settled mode-local attempt
-- becomes one settlement row on its terminal Combat attempt, with settled_at
-- equal to that attempt's terminal_at. Open rows whose Combat attempt is open
-- need nothing: Combat already holds them. Stale rows are counted, never
-- migrated. An attempt id that is not a uuid fails the migration. The three old
-- tables are renamed, never dropped; a later migration drops them once a
-- release has read the shared record.

-- +goose StatementBegin
DO $$
DECLARE
 moved bigint;
 settled bigint := 0;
 open_kept bigint := 0;
 stale_placeholder bigint := 0;
 stale_open_terminal bigint := 0;
 stale_resolved_missing bigint := 0;
 target record;
BEGIN
 FOR target IN
  SELECT attempt_table, settlement_table
  FROM (VALUES
   ('worldboss_attempts', 'worldboss_attempt_settlements'),
   ('illusion_attempts', 'illusion_attempt_settlements'),
   ('adventure_single_attempts', 'adventure_attempt_settlements')
  ) AS r5d_tables(attempt_table, settlement_table)
 LOOP
  EXECUTE format(
   'INSERT INTO %I(attempt_id,player_id,damage,settled_at)
    SELECT mode_row.attempt_id::uuid,mode_row.player_id,mode_row.damage,attempt.terminal_at
    FROM %I mode_row
    JOIN combat_attempts attempt ON attempt.attempt_id=CASE WHEN pg_input_is_valid(mode_row.attempt_id,''uuid'') THEN mode_row.attempt_id::uuid END
    WHERE mode_row.resolved AND attempt.state=''TERMINAL''',
   target.settlement_table, target.attempt_table);
  GET DIAGNOSTICS moved = ROW_COUNT;
  settled := settled + moved;

  EXECUTE format(
   'SELECT count(*) FROM %I mode_row WHERE NOT mode_row.resolved AND pg_input_is_valid(mode_row.attempt_id,''uuid'')
      AND EXISTS(SELECT 1 FROM combat_attempts attempt WHERE attempt.attempt_id=mode_row.attempt_id::uuid AND attempt.state<>''TERMINAL'')',
   target.attempt_table) INTO moved;
  open_kept := open_kept + moved;

  EXECUTE format(
   'SELECT count(*) FROM %I mode_row WHERE NOT mode_row.resolved AND pg_input_is_valid(mode_row.attempt_id,''uuid'')
      AND NOT EXISTS(SELECT 1 FROM combat_attempts attempt WHERE attempt.attempt_id=mode_row.attempt_id::uuid)',
   target.attempt_table) INTO moved;
  stale_placeholder := stale_placeholder + moved;

  EXECUTE format(
   'SELECT count(*) FROM %I mode_row WHERE NOT mode_row.resolved AND pg_input_is_valid(mode_row.attempt_id,''uuid'')
      AND EXISTS(SELECT 1 FROM combat_attempts attempt WHERE attempt.attempt_id=mode_row.attempt_id::uuid AND attempt.state=''TERMINAL'')',
   target.attempt_table) INTO moved;
  stale_open_terminal := stale_open_terminal + moved;

  EXECUTE format(
   'SELECT count(*) FROM %I mode_row WHERE mode_row.resolved AND pg_input_is_valid(mode_row.attempt_id,''uuid'')
      AND NOT EXISTS(SELECT 1 FROM combat_attempts attempt WHERE attempt.attempt_id=mode_row.attempt_id::uuid)',
   target.attempt_table) INTO moved;
  stale_resolved_missing := stale_resolved_missing + moved;
 END LOOP;
 RAISE NOTICE 'R5D 00168 settled=%', settled;
 RAISE NOTICE 'R5D 00168 open_kept=%', open_kept;
 RAISE NOTICE 'R5D 00168 stale_placeholder=%', stale_placeholder;
 RAISE NOTICE 'R5D 00168 stale_open_terminal=%', stale_open_terminal;
 RAISE NOTICE 'R5D 00168 stale_resolved_missing=%', stale_resolved_missing;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$
DECLARE
 bad_table text;
 bad_id text;
BEGIN
 SELECT 'worldboss_attempts', attempt_id INTO bad_table, bad_id
 FROM worldboss_attempts WHERE NOT pg_input_is_valid(attempt_id, 'uuid') LIMIT 1;
 IF bad_id IS NULL THEN
  SELECT 'illusion_attempts', attempt_id INTO bad_table, bad_id
  FROM illusion_attempts WHERE NOT pg_input_is_valid(attempt_id, 'uuid') LIMIT 1;
 END IF;
 IF bad_id IS NULL THEN
  SELECT 'adventure_single_attempts', attempt_id INTO bad_table, bad_id
  FROM adventure_single_attempts WHERE NOT pg_input_is_valid(attempt_id, 'uuid') LIMIT 1;
 END IF;
 IF bad_id IS NOT NULL THEN
  RAISE EXCEPTION 'R5D 00168: %.attempt_id % is not a uuid', bad_table, bad_id;
 END IF;
END $$;
-- +goose StatementEnd

ALTER TABLE worldboss_attempts RENAME TO worldboss_attempts_retired_r5d;
ALTER TABLE illusion_attempts RENAME TO illusion_attempts_retired_r5d;
ALTER TABLE adventure_single_attempts RENAME TO adventure_single_attempts_retired_r5d;
