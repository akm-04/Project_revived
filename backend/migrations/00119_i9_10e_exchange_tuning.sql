-- +goose Up
CREATE TABLE social_exchange_tuning (
 singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 updated_at timestamptz NOT NULL
);
