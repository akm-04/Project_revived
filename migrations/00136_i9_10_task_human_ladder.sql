-- +goose Up
-- owner: TopFloor
-- PRIVATE_POLICY D512: the special Top Floor ladder is humans-only, so a fresh
-- weekly period starts empty instead of seeding the 10,325 source robot rows.
ALTER TABLE top_floor_task_periods DROP CONSTRAINT top_floor_task_periods_size_check;
ALTER TABLE top_floor_task_periods ADD CONSTRAINT top_floor_task_periods_size_check CHECK(size>=0);
