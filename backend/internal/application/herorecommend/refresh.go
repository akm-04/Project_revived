package herorecommend

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"math"
	"sort"
	"strconv"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func Profile() tx.Profile {
	return tx.Profile{Name: "I9_10_HERO_RECOMMEND", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 40 * time.Second}
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 4, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 100 * time.Millisecond}
}

// WeekStart is the canonical Monday 05:00 GMT+8 game week
// (I9_MODE_FRAMEWORK_V1 F7). The snapshot is built by the first read or
// reconcile tick after the boundary.
func WeekStart(at time.Time) time.Time {
	return modes.DayBegins(modes.WeekStart(at))
}

// LegacyWeekStart is the pre-R3 Monday 04:00 UTC generation boundary. A stored
// snapshot of that generation that still covers at is served as this week's.
func LegacyWeekStart(at time.Time) time.Time {
	u := at.UTC()
	days := (int(u.Weekday()) + 6) % 7
	start := time.Date(u.Year(), u.Month(), u.Day(), 4, 0, 0, 0, time.UTC).AddDate(0, 0, -days)
	if u.Before(start) {
		start = start.AddDate(0, 0, -7)
	}
	return start
}

// pinContent binds the active revision to the operation so the public stat
// engine accepts the coherent read scope.
func pinContent(op operation.Context, revision string) (operation.Context, error) {
	if bound, ok := op.Policies.Get("content"); ok && bound == revision {
		return op, nil
	}
	set, err := policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})...)
	op.Policies = set
	return op, err
}

func (s Service) Snapshot(ctx context.Context, a identity.ActorContext, o operation.Context) (d.Snapshot, error) {
	if !s.complete() || !a.PlayerID.Valid() || !a.LogicalServerID.Valid() || o.ID.IsZero() || o.StartedAt.IsZero() {
		return d.Snapshot{}, d.ErrUnavailable
	}
	return s.ensureSnapshot(ctx, o, a.LogicalServerID)
}

func (s Service) ensureSnapshot(ctx context.Context, o operation.Context, server identity.LogicalServerID) (d.Snapshot, error) {
	var out d.Snapshot
	_, _, err := s.Timed.Run(ctx, o, Profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(ctx context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		generation := WeekStart(at).Unix()
		latest, ok, err := s.Store.LatestSnapshotTx(ctx, sc.Tx, server)
		// A derived snapshot that does not round-trip is rebuilt, never served as an outage.
		if errors.Is(err, d.ErrUnavailable) {
			ok, err = false, nil
		}
		if err != nil {
			return err
		}
		if ok && latest.Generation == generation {
			out = latest
			return nil
		}
		if ok && latest.Generation == LegacyWeekStart(at).Unix() {
			out = latest
			return nil
		}
		revision, err := s.Content.ActiveRevision(ctx, sc.Tx)
		if err != nil {
			return err
		}
		built, err := s.build(ctx, sc, server, generation, revision, at)
		if err != nil {
			return err
		}
		if err = s.Store.InsertSnapshotTx(ctx, sc.Tx, built); err != nil {
			return err
		}
		out = built
		return nil
	})
	if err != nil {
		return d.Snapshot{}, err
	}
	return out, nil
}

type categorySource struct {
	category int64
	data     d.Source
}

type ownerState struct {
	card      d.PlayerCard
	byPartner map[int64]map[string]any
	byTable   map[int64]map[string]any
	byOrigin  map[int64]map[string]any
	pets      map[int64]map[string]any
}

type resolvedFormation struct {
	player   d.PlayerCard
	heroes   []map[string]any
	pet      map[string]any
	tableIDs []int64
	weight   int64
	paradise int64
	chapter  int64
}

func (s Service) build(ctx context.Context, sc gen.TimedScope, server identity.LogicalServerID, generation int64, revision string, at time.Time) (d.Snapshot, error) {
	gathered := make([]categorySource, 0, 6)
	for _, entry := range s.sources() {
		if entry.source == nil {
			continue
		}
		data, err := entry.source.HeroRecommendSourceTx(ctx, sc.Tx, server, at, d.MaxSourceScan)
		if err != nil {
			return d.Snapshot{}, err
		}
		gathered = append(gathered, categorySource{category: entry.category, data: data})
	}
	candidates := candidateOwners(gathered)
	owners := map[int64]ownerState{}
	for _, playerID := range candidates {
		state, ok, err := s.loadOwner(ctx, sc.Tx, identity.PlayerID(playerID), at)
		if err != nil {
			return d.Snapshot{}, err
		}
		if ok {
			owners[playerID] = state
		}
	}

	scores := map[int64]map[int64]int64{}
	for _, source := range gathered {
		if scores[source.category] == nil {
			scores[source.category] = map[int64]int64{}
		}
		for _, row := range source.data.Popularity {
			state, ok := owners[row.PlayerID]
			if !ok {
				continue
			}
			hero := state.byPartner[row.PartnerID]
			if row.TableID > 0 {
				hero = state.byTable[row.TableID]
				if hero == nil {
					hero = state.byOrigin[row.TableID]
				}
			}
			tableID := recommendationTableID(hero)
			if tableID <= 0 || row.Score <= 0 {
				continue
			}
			scores[source.category][tableID] += row.Score
		}
	}

	formations := map[int64][]resolvedFormation{}
	for _, source := range gathered {
		resolved := []resolvedFormation{}
		for _, row := range source.data.Formations {
			state, ok := owners[row.PlayerID]
			if !ok {
				continue
			}
			formation, ok := resolveFormation(state, row)
			if !ok {
				continue
			}
			resolved = append(resolved, formation)
		}
		sort.SliceStable(resolved, func(i, j int) bool {
			if resolved[i].weight != resolved[j].weight {
				return resolved[i].weight > resolved[j].weight
			}
			return resolved[i].player.PlayerID < resolved[j].player.PlayerID
		})
		if len(resolved) > d.MaxSourceFormations {
			resolved = resolved[:d.MaxSourceFormations]
		}
		formations[source.category] = resolved
	}

	overview, totals := buildOverview(scores)
	operationContext, err := pinContent(sc.Operation.Operation(), revision)
	if err != nil {
		return d.Snapshot{}, err
	}
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: operationContext, Attempt: sc.Attempt, Options: sc.Options}, revision, at)
	if err != nil {
		return d.Snapshot{}, err
	}
	details, err := s.buildDetails(ctx, scope, owners, formations, totals)
	if err != nil {
		return d.Snapshot{}, err
	}
	// timestamptz keeps microseconds; the payload copy must match it or the stored row never validates.
	snapshot := d.Snapshot{Schema: d.Schema, Server: int64(server), Generation: generation, Revision: revision, ObservedAt: at.UTC().Truncate(time.Microsecond), Overview: overview, Details: details}
	raw, err := json.Marshal(snapshot)
	if err != nil {
		return d.Snapshot{}, err
	}
	sum := sha256.Sum256(raw)
	snapshot.Digest = hex.EncodeToString(sum[:])
	return snapshot, nil
}

func candidateOwners(gathered []categorySource) []int64 {
	seen := map[int64]bool{}
	out := []int64{}
	add := func(playerID int64) {
		if playerID <= 0 || seen[playerID] || len(out) >= d.MaxCandidateOwners {
			return
		}
		seen[playerID] = true
		out = append(out, playerID)
	}
	for _, source := range gathered {
		for _, row := range source.data.Formations {
			add(row.PlayerID)
		}
	}
	for _, source := range gathered {
		for _, row := range source.data.Popularity {
			add(row.PlayerID)
		}
	}
	return out
}

// rosterRows loads the stock MID1 hero rows and restores the origin identity
// the wire omits, so recommendation groups awakened forms under their base hero.
func (s Service) rosterRows(ctx context.Context, q tx.Queryer, playerID identity.PlayerID, at time.Time) (map[string]any, error) {
	detail := map[string]any{}
	if err := s.Heroes.OverlayMID1(ctx, q, identity.ActorContext{PlayerID: playerID}, false, at, detail); err != nil {
		return nil, err
	}
	heroes, _ := detail["49"].(map[string]any)
	rows, _ := heroes["heros"].(map[string]any)
	origins, err := s.Heroes.HeroOriginTableIDsTx(ctx, q, playerID)
	if err != nil {
		return nil, err
	}
	for _, value := range rows {
		row, ok := value.(map[string]any)
		if !ok {
			continue
		}
		if origin := origins[rowNumber(row, "partner_id")]; origin > 0 {
			row["origin_table_id"] = origin
		}
	}
	return rows, nil
}

func (s Service) loadOwner(ctx context.Context, q tx.Queryer, playerID identity.PlayerID, at time.Time) (ownerState, bool, error) {
	profile, found, err := s.Directory.ProfileTx(ctx, q, playerID)
	if err != nil {
		return ownerState{}, false, err
	}
	if !found || profile.Validate() != nil {
		return ownerState{}, false, nil
	}
	card := d.PlayerCard{PlayerID: int64(playerID), Name: profile.Name, Level: profile.Level, ConquerLevel: profile.ConquerLevel, ConquerLoopID: profile.ConquerLoopID,
		AvatarID: profile.AvatarID, AvatarFrameID: profile.AvatarFrameID, Region: int64(logicalserver.PlayerRegion(playerID))}
	if membership, ok, err := s.Guilds.ReadMembershipTx(ctx, q, playerID); err != nil {
		return ownerState{}, false, err
	} else if ok {
		card.GuildID = int64(membership.GuildID)
		if guildRow, known, err := s.Guilds.ReadGuildTx(ctx, q, membership.GuildID); err != nil {
			return ownerState{}, false, err
		} else if known {
			card.GuildName = guildRow.Name
		}
	}
	rows, err := s.rosterRows(ctx, q, playerID, at)
	if err != nil {
		return ownerState{}, false, err
	}
	state := ownerState{card: card, byPartner: map[int64]map[string]any{}, byTable: map[int64]map[string]any{}, byOrigin: map[int64]map[string]any{}, pets: map[int64]map[string]any{}}
	for _, value := range rows {
		row, ok := value.(map[string]any)
		if !ok {
			continue
		}
		partnerID := rowNumber(row, "partner_id")
		tableID := rowNumber(row, "table_id")
		originTableID := recommendationTableID(row)
		if partnerID > 0 {
			state.byPartner[partnerID] = row
		}
		if tableID > 0 {
			state.byTable[tableID] = row
		}
		if originTableID > 0 {
			state.byOrigin[originTableID] = row
		}
	}
	petDetail := map[string]any{}
	if err = s.Pets.OverlayMID1(ctx, q, identity.ActorContext{PlayerID: playerID}, false, at, petDetail); err != nil {
		return ownerState{}, false, err
	}
	pets, _ := petDetail["780"].(map[string]any)
	for _, value := range sliceAny(pets["pets"]) {
		row, ok := value.(map[string]any)
		if !ok {
			continue
		}
		if petID := rowNumber(row, "pet_id"); petID > 0 {
			state.pets[petID] = row
		}
	}
	return state, true, nil
}

func resolveFormation(state ownerState, row d.Formation) (resolvedFormation, bool) {
	out := resolvedFormation{player: state.card, weight: row.Weight, paradise: row.ParadiseID, chapter: row.ChapterID}
	for _, tableID := range row.TableIDs {
		hero, owned := state.byTable[tableID]
		if !owned {
			hero, owned = state.byOrigin[tableID]
		}
		if !owned {
			continue
		}
		out.tableIDs = append(out.tableIDs, recommendationTableID(hero))
		out.heroes = append(out.heroes, hero)
	}
	if len(out.heroes) == 0 {
		for _, partnerID := range row.PartnerIDs {
			hero, owned := state.byPartner[partnerID]
			if !owned {
				continue
			}
			out.tableIDs = append(out.tableIDs, recommendationTableID(hero))
			out.heroes = append(out.heroes, hero)
		}
	}
	out.pet = state.pets[row.PetID]
	return out, len(out.heroes) > 0
}

func buildOverview(scores map[int64]map[int64]int64) (d.Overview, map[int64]int64) {
	overview := d.Overview{SubRankList: map[string][]int64{}, TotalRankList: []map[string]any{}}
	totals := map[int64]int64{}
	for _, category := range []int64{d.TopFloor, d.OneOnOne, d.Arena, d.Fantasy, d.GuildEvent, d.Champion} {
		ranked := rankScores(scores[category], d.MaxCategoryHeroes)
		key := strconv.FormatInt(category, 10)
		overview.SubRankList[key] = ranked
		for tableID, score := range scores[category] {
			totals[tableID] += score
		}
	}
	for _, tableID := range rankScores(totals, d.MaxTotalHeroes) {
		overview.TotalRankList = append(overview.TotalRankList, map[string]any{"table_id": tableID, "recommend_score": totals[tableID]})
	}
	return overview, totals
}

func rankScores(scores map[int64]int64, limit int) []int64 {
	out := make([]int64, 0, len(scores))
	for tableID, score := range scores {
		if tableID > 0 && score > 0 {
			out = append(out, tableID)
		}
	}
	sort.Slice(out, func(i, j int) bool {
		if scores[out[i]] != scores[out[j]] {
			return scores[out[i]] > scores[out[j]]
		}
		return out[i] < out[j]
	})
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

func (s Service) buildDetails(ctx context.Context, scope ca.CoherentReadScope, owners map[int64]ownerState, formations map[int64][]resolvedFormation, totals map[int64]int64) (map[string]d.Detail, error) {
	details := map[string]d.Detail{}
	for _, tableID := range rankScores(totals, d.MaxTotalHeroes) {
		rows := []d.ForceRow{}
		for playerID, state := range owners {
			hero, owned := state.byOrigin[tableID]
			if !owned {
				continue
			}
			force, err := s.heroForce(ctx, scope, identity.PlayerID(playerID), rowNumber(hero, "partner_id"))
			if err != nil {
				return nil, err
			}
			rows = append(rows, d.ForceRow{Player: state.card, Force: force})
		}
		if len(rows) == 0 {
			continue
		}
		sort.Slice(rows, func(i, j int) bool {
			if rows[i].Force != rows[j].Force {
				return rows[i].Force > rows[j].Force
			}
			return rows[i].Player.PlayerID < rows[j].Player.PlayerID
		})
		if len(rows) > d.MaxForceRows {
			rows = rows[:d.MaxForceRows]
		}
		top := rows[0]
		topState := owners[top.Player.PlayerID]
		topHero := copyRow(topState.byOrigin[tableID])
		topHero["force"] = top.Force
		details[strconv.FormatInt(tableID, 10)] = d.Detail{
			Score:      totals[tableID],
			TopPlayer:  top.Player,
			TopHero:    topHero,
			Formations: recommendFormations(tableID, formations),
			ForceRows:  rows,
		}
	}
	return details, nil
}

func recommendFormations(tableID int64, formations map[int64][]resolvedFormation) map[string]any {
	out := map[string]any{}
	for category, rows := range formations {
		matches := []map[string]any{}
		for _, row := range rows {
			if !containsTable(row.tableIDs, tableID) {
				continue
			}
			entry := map[string]any{"formation_rank": int64(len(matches) + 1), "formation": row.heroes, "player_info": row.player}
			if row.pet != nil {
				entry["pet_info"] = row.pet
			}
			if row.paradise > 0 {
				entry["paradise_id"] = row.paradise
			}
			if row.chapter > 0 {
				entry["chapter_id"] = row.chapter
			}
			matches = append(matches, entry)
			if len(matches) == d.MaxDetailFormations {
				break
			}
		}
		if len(matches) == 0 {
			continue
		}
		key := strconv.FormatInt(category, 10)
		if category == d.Fantasy || category == d.GuildEvent {
			out[key] = matches
			continue
		}
		out[key] = matches[0]
	}
	return out
}

func (s Service) heroForce(ctx context.Context, scope ca.CoherentReadScope, owner identity.PlayerID, partnerID int64) (int64, error) {
	if partnerID <= 0 {
		return 0, nil
	}
	result, err := s.HeroPower.HeroTx(ctx, scope, character.HeroRef{PlayerID: owner, PartnerID: partnerID}, publicstats.View{Kind: publicstats.Self, Viewer: owner})
	if err != nil {
		return 0, err
	}
	force := math.Round(result.Stats.Force)
	if math.IsNaN(force) || math.IsInf(force, 0) || force < 0 || force > 100000000000 {
		return 0, d.ErrUnavailable
	}
	return int64(force), nil
}

func rowNumber(row map[string]any, key string) int64 {
	if row == nil {
		return 0
	}
	return number(row[key])
}

func rowTableID(row map[string]any) int64 { return rowNumber(row, "table_id") }

func recommendationTableID(row map[string]any) int64 {
	originTableID := rowNumber(row, "origin_table_id")
	if originTableID > 0 {
		return originTableID
	}
	return rowTableID(row)
}

func number(value any) int64 {
	switch typed := value.(type) {
	case int:
		return int64(typed)
	case int32:
		return int64(typed)
	case int64:
		return typed
	case float64:
		return int64(typed)
	case json.Number:
		parsed, err := typed.Int64()
		if err == nil {
			return parsed
		}
	}
	return 0
}

func sliceAny(value any) []any {
	out, _ := value.([]any)
	return out
}

func copyRow(row map[string]any) map[string]any {
	out := make(map[string]any, len(row))
	for key, value := range row {
		out[key] = value
	}
	return out
}

func containsTable(values []int64, target int64) bool {
	for _, value := range values {
		if value == target {
			return true
		}
	}
	return false
}
