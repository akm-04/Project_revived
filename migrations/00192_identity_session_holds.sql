-- +goose Up
-- owner: identity/logicalserver/bootstrap (operator_session_holds)
CREATE TABLE operator_session_holds (
  hold_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  scope_kind text NOT NULL CHECK (scope_kind IN ('global','server','player')),
  scope_key bigint NOT NULL CHECK (
    (scope_kind = 'global' AND scope_key = 0)
    OR (scope_kind IN ('server','player') AND scope_key > 0)
  ),
  held_until timestamptz NOT NULL,
  reason text NOT NULL,
  command_key text NOT NULL,
  created_at timestamptz NOT NULL
);
CREATE INDEX operator_session_holds_until ON operator_session_holds(held_until);
