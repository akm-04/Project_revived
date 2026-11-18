-- +goose Up
-- owner: character/hero-core
-- Bug #99: the stock client persists its backpack filter through MID 88. The
-- player preference shares the CharacterHero root row with the hero-list sort
-- (player_hero_roots.sort_type, MID 89) but stays a separate fact.
ALTER TABLE player_hero_roots
  ADD COLUMN backpack_sort_type integer NOT NULL DEFAULT 0
  CHECK (backpack_sort_type BETWEEN 0 AND 8191);
