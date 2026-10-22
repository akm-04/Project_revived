-- +goose Up
-- owner: conquer
-- I8-5D (PASS748 topology): Conquer START/RESULT bind a Combat
-- CLIENT_SUMMARY_ATTESTED attempt, so the mode-local JSON attempt retires. An
-- open I7C-5E attempt is closed by its removal; its chance stays spent and its
-- late RESULT drains (D21g private policy). A rolled-back product reads the
-- state without the field as no open attempt.
UPDATE conquer_school_players SET state = state - 'attempt' WHERE state ? 'attempt';
