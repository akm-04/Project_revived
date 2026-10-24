-- +goose Up
-- Pass474: forward repair for R4B JSON-null CHECK bypass (SQL UNKNOWN passes CHECK).
-- Preserve 00009 and all immutable payload bytes. Validate existing rows; a corrupt
-- registry blocks the migration atomically and requires operator reconciliation,
-- never automatic payload rewriting or activation. No DOWN by project law.
ALTER TABLE gxb_content_revisions
  ADD CONSTRAINT gxb_content_revisions_manifest_identity_strict_chk CHECK ((
    jsonb_typeof(manifest->'revision_id') = 'string'
    AND manifest->>'revision_id' = revision_id
    AND jsonb_typeof(manifest->'schema_version') = 'number'
    AND manifest->>'schema_version' = schema_version::text
    AND jsonb_typeof(manifest->'compiler_version') = 'string'
    AND manifest->>'compiler_version' = compiler_version
    AND jsonb_typeof(manifest->'parser_version') = 'string'
    AND manifest->>'parser_version' = parser_version
  ) IS TRUE);
