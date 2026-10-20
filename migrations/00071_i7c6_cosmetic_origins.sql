-- +goose Up
-- owner: library-local-progression
-- C6_SELECTED_COSMETIC_ORIGINS_V1: marriage titles are kept once earned. The mark never
-- decreases; legacy roots start from their current married count.
ALTER TABLE player_library_roots ADD COLUMN married_high_water bigint NOT NULL DEFAULT 0 CHECK (married_high_water >= 0);
UPDATE player_library_roots r SET married_high_water = (SELECT count(*) FROM player_library_heroes h WHERE h.player_id = r.player_id AND h.is_married);
