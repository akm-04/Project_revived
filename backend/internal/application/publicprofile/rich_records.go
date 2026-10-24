package publicprofile

import (
	"context"
	"fmt"
	"maps"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	conquer "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Roster is the stock roster composer (MID1 key 49 Heroes, 780 Pets) that
// Combat also freezes from; profile records reuse it instead of a second mapping.
type Roster interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

type ConquerFacts interface {
	FactsTx(context.Context, characterasset.CoherentReadScope, identity.PlayerID) (conquer.Observation, error)
}

// RosterRecords builds rich showcase records as Combat builds owned actor
// params: the owner's roster row, the known raw twice-awake stage and the
// positive Conquer keys. An unknown awakening or Conquer basis is omitted.
type RosterRecords struct {
	Heroes    Roster
	Pets      Roster
	Awakening publicstats.Awakening
	Conquer   ConquerFacts
}

// shortcut: the roster is recomposed per showcase slot (up to six per 1829 read); memoize per scope if profile latency matters.
func (r RosterRecords) RecordTx(c context.Context, sc characterasset.CoherentReadScope, pid identity.PlayerID, id int64) (map[string]any, error) {
	if r.Heroes == nil || r.Pets == nil || r.Awakening == nil || r.Conquer == nil {
		return nil, ErrShowcaseUnavailable
	}
	if id < 0 {
		return r.petTx(c, sc, pid, -id)
	}
	rows, err := heroRows(c, r.Heroes, sc.Queryer(), pid, sc.ObservedAt)
	if err != nil {
		return nil, err
	}
	row, ok := rows[strconv.FormatInt(id, 10)].(map[string]any)
	if !ok {
		return nil, ErrShowcaseUnavailable
	}
	out := maps.Clone(row)
	ref := character.HeroRef{PlayerID: pid, PartnerID: id}
	awakening, err := r.Awakening.RawAwakeningTx(c, sc, ref)
	if err != nil {
		return nil, err
	}
	if awakening.Known && awakening.Ref == ref {
		out["twice_awake_stage"] = awakening.RawStage
	}
	observation, err := r.Conquer.FactsTx(c, sc, pid)
	if err != nil {
		return nil, err
	}
	if !observation.Facts.Known() {
		return out, nil
	}
	// NormalHero.toParams emits conquer keys only when positive.
	progress := observation.Facts.Payload.Progress
	if progress.Level > 0 {
		out["conquer_lev"] = progress.Level
	}
	if progress.Loop > 0 {
		out["conquer_loop_id"] = progress.Loop
	}
	return out, nil
}

func (r RosterRecords) petTx(c context.Context, sc characterasset.CoherentReadScope, pid identity.PlayerID, petID int64) (map[string]any, error) {
	detail := map[string]any{}
	if err := r.Pets.OverlayMID1(c, sc.Queryer(), identity.ActorContext{PlayerID: pid}, false, sc.ObservedAt, detail); err != nil {
		return nil, err
	}
	body, _ := detail["780"].(map[string]any)
	rows, _ := body["pets"].([]any)
	for _, raw := range rows {
		row, ok := raw.(map[string]any)
		if ok && fmt.Sprint(row["pet_id"]) == strconv.FormatInt(petID, 10) {
			return maps.Clone(row), nil
		}
	}
	return nil, ErrShowcaseUnavailable
}

func heroRows(c context.Context, roster Roster, q tx.Queryer, pid identity.PlayerID, at time.Time) (map[string]any, error) {
	detail := map[string]any{}
	if err := roster.OverlayMID1(c, q, identity.ActorContext{PlayerID: pid}, false, at, detail); err != nil {
		return nil, err
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	if rows == nil {
		return nil, ErrShowcaseUnavailable
	}
	return rows, nil
}

type ModeHistorySource interface {
	PublicHistoryTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (cd.History, error)
}

// ModeHistory answers 1829 HISTORY (subtype 2) from the Top Floor (ARENA),
// 1 on 1 (SUPER_ARENA) and Arena (REGION_ARENA) owners. BATTLE_RECORD
// (subtype 3) has no source caller and stays unavailable.
type ModeHistory struct {
	TopFloor ModeHistorySource
	OneOnOne ModeHistorySource
	Arena    ModeHistorySource
	Heroes   Roster
}

func (h ModeHistory) ReadPublicHistoryTx(c context.Context, sc tx.Scope, pid identity.PlayerID, sub int16, rev string, at time.Time) (HistoryObservation, error) {
	if sub != 2 || h.TopFloor == nil || h.OneOnOne == nil || h.Arena == nil || h.Heroes == nil {
		return HistoryObservation{}, ErrProfileProvider
	}
	topFloor, err := h.TopFloor.PublicHistoryTx(c, sc.Tx, pid, at)
	if err != nil {
		return HistoryObservation{}, err
	}
	oneOnOne, err := h.OneOnOne.PublicHistoryTx(c, sc.Tx, pid, at)
	if err != nil {
		return HistoryObservation{}, err
	}
	arena, err := h.Arena.PublicHistoryTx(c, sc.Tx, pid, at)
	if err != nil {
		return HistoryObservation{}, err
	}
	owned, err := heroRows(c, h.Heroes, sc.Tx, pid, at)
	if err != nil {
		return HistoryObservation{}, err
	}
	fields := map[string]any{
		"arena_performance":       rankedPerformance(topFloor, owned),
		"super_arena_performance": rankedPerformance(oneOnOne, owned),
		// Lord Points label (TIPS_8) reads king_coin: the season Lord points.
		"region_arena_performance": map[string]any{
			"arena_info":   map[string]any{"king_coin": arena.Points, "total_fight": arena.Fights, "win_times": arena.Wins},
			"partner_info": partnerRows(arena.Partners, nil),
		},
	}
	version := 1 + topFloor.Version + oneOnOne.Version + arena.Version
	return HistoryObservation{PlayerID: pid, Subtype: sub, ContentRevision: rev, ObservedAt: at, SourceVersion: version, Fields: fields}, nil
}

func rankedPerformance(h cd.History, owned map[string]any) map[string]any {
	info := map[string]any{"total_fight": h.Fights, "win_fight": h.Wins}
	if h.Rank > 0 {
		info["rank"] = h.Rank
	}
	return map[string]any{"arena_info": info, "partners_info": partnerRows(h.Partners, owned)}
}

// partnerRows renders usage for Hero:populate. With a roster, rows are keyed
// by partner and a partner no longer owned is dropped; without one (Arena,
// keyed by girl) the row carries table_id for formatRegionArenaHeros.
func partnerRows(partners []cd.PartnerTotals, owned map[string]any) []any {
	out := []any{}
	for _, p := range partners {
		row := map[string]any{"table_id": p.TableID}
		if owned != nil {
			hero, ok := owned[strconv.FormatInt(p.PartnerID, 10)].(map[string]any)
			if !ok {
				continue
			}
			row = maps.Clone(hero)
		}
		damage, _ := strconv.ParseFloat(p.Harms, 64)
		row["total_fight"], row["win_fight"], row["total_kill"], row["total_damage"] = p.Fights, p.Wins, p.Kills, int64(damage)
		out = append(out, row)
	}
	return out
}
