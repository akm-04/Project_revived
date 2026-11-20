package mentor

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"math/rand"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// WireFacts is the source-shaped My Class reply input. Both MID 1856 and the
// login-embedded record build from the same real state.
type WireFacts struct {
	Now             time.Time
	Actor           identity.PlayerID
	Level           int64
	CountMentor     int64
	CountStudent    int64
	BrokeAt         *time.Time
	Relations       []domain.Relationship
	Applications    []Application
	Cards           map[identity.PlayerID]playerpresentation.Projected
	MentorMissions  []domain.MissionState
	StudentMissions []domain.MissionState
}

// Info implements MID 1856 GET_CLASS_INFO.
func (service Service) Info(ctx context.Context, actor identity.ActorContext, op operation.Context) (map[string]any, error) {
	if !service.validForRead() {
		return nil, ErrUnavailable
	}
	catalog, err := service.catalog()
	if err != nil {
		return nil, err
	}
	rules := rulesFromCatalog(catalog)
	var body map[string]any
	err = service.run(ctx, actor, op, false, func(ctx context.Context, t tx.Tx, at time.Time) error {
		facts, err := service.readClassFacts(ctx, t, actor.PlayerID, at, catalog, rules)
		if err != nil {
			return err
		}
		body = BuildClassInfo(facts)
		return nil
	})
	if err != nil {
		return nil, err
	}
	return body, nil
}

func (service Service) readClassFacts(ctx context.Context, q tx.Tx, actor identity.PlayerID, at time.Time, catalog Catalog, _ domain.Rules) (WireFacts, error) {
	level, err := playerLevel(ctx, service.Directory, q, actor)
	if err != nil {
		return WireFacts{}, fmt.Errorf("mentor level: %w", err)
	}
	state, _, err := service.Store.ReadStateTx(ctx, q, actor, logicalserver.PlayerRegion(actor))
	if err != nil {
		return WireFacts{}, fmt.Errorf("mentor state: %w", err)
	}
	relations, err := service.Store.ReadRelationshipsTx(ctx, q, actor, logicalserver.PlayerRegion(actor))
	if err != nil {
		return WireFacts{}, fmt.Errorf("mentor relations: %w", err)
	}
	applications, err := service.Store.ListApplicationsToTx(ctx, q, actor, logicalserver.PlayerRegion(actor), at)
	if err != nil {
		return WireFacts{}, fmt.Errorf("mentor applications: %w", err)
	}
	progress, err := service.Store.ReadMissionProgressTx(ctx, q, actor)
	if err != nil {
		return WireFacts{}, fmt.Errorf("mentor missions: %w", err)
	}
	ids := make([]identity.PlayerID, 0, len(relations)+len(applications))
	for _, relation := range relations {
		if relation.Mentor == actor {
			ids = append(ids, relation.Student)
		} else {
			ids = append(ids, relation.Mentor)
		}
	}
	for _, application := range applications {
		ids = append(ids, application.Applicant)
	}
	cards, err := service.readCardsQueryer(ctx, q, ids, at)
	if err != nil {
		return WireFacts{}, fmt.Errorf("mentor cards: %w", err)
	}
	mentorMissions, studentMissions, err := deriveMissions(catalog, actor, level, relations, progress, at)
	if err != nil {
		return WireFacts{}, err
	}
	countMentor, countStudent := state.CountMentor, state.CountStudent
	if !sameDay(state.ApplyDay, at) {
		countMentor, countStudent = 0, 0
	}
	return WireFacts{Now: at, Actor: actor, Level: level, CountMentor: countMentor, CountStudent: countStudent, BrokeAt: state.BrokeAt, Relations: relations, Applications: applications, Cards: cards, MentorMissions: mentorMissions, StudentMissions: studentMissions}, nil
}

func (service Service) readCardsQueryer(ctx context.Context, q tx.Tx, ids []identity.PlayerID, at time.Time) (map[identity.PlayerID]playerpresentation.Projected, error) {
	if len(ids) == 0 {
		return map[identity.PlayerID]playerpresentation.Projected{}, nil
	}
	if reader, ok := service.Cards.(playerpresentation.TxReaderAt); ok {
		batch, err := reader.ReadManyAtTx(ctx, q, ids, at)
		if err != nil {
			return nil, err
		}
		for _, player := range ids {
			if _, ok := batch.Players[player]; !ok {
				return nil, playerpresentation.ErrMissingPresentation
			}
		}
		return batch.Players, nil
	}
	return nil, ErrUnavailable
}

// BuildClassInfo renders the stock freshClassInfo shape.
func BuildClassInfo(facts WireFacts) map[string]any {
	relations := [2]any{map[string]any{}, map[string]any{}}
	intimacies := [2]int64{0, 0}
	accept := [2]int64{0, 0}
	dailyAdd := [2]int64{0, 0}
	for _, relation := range facts.Relations {
		slot := int64(1)
		other := relation.Mentor
		if relation.Mentor == facts.Actor {
			slot = 2
			other = relation.Student
		}
		projection, ok := facts.Cards[other]
		if !ok {
			continue
		}
		relations[slot-1] = cardWire(projection, facts.Now)
		intimacies[slot-1] = relation.Intimacy
		accept[slot-1] = relation.AcceptedAt.Unix()
		if relation.LastIntimacyDay == gameDate(facts.Now) {
			dailyAdd[slot-1] = 1
		}
	}
	broke := [2]int64{0, 0}
	if facts.BrokeAt != nil {
		broke = [2]int64{facts.BrokeAt.Unix(), facts.BrokeAt.Unix()}
	}
	applyList := make([]any, 0, len(facts.Applications))
	for _, application := range facts.Applications {
		projection, ok := facts.Cards[application.Applicant]
		if !ok {
			continue
		}
		row := cardWire(projection, facts.Now)
		row["relation_type"] = int64(application.RecipientSlot)
		row["msg"] = application.Message
		row["player_info"] = cardWire(projection, facts.Now)
		row["is_online"] = onlineFlag(projection, facts.Now)
		applyList = append(applyList, row)
	}
	return map[string]any{
		"base_info": map[string]any{
			"accept_time":        []any{accept[0], accept[1]},
			"broke_time":         []any{broke[0], broke[1]},
			"daily_apply_times":  []any{facts.CountMentor, facts.CountStudent},
			"daily_intimacy_add": []any{dailyAdd[0], dailyAdd[1]},
			"intimacies":         []any{intimacies[0], intimacies[1]},
			"relations":          []any{relations[0], relations[1]},
		},
		"apply_list":   applyList,
		"mission_list": []any{missionListWire(facts.MentorMissions), missionListWire(facts.StudentMissions)},
	}
}

func missionListWire(rows []domain.MissionState) []any {
	out := make([]any, 0, len(rows))
	for _, row := range rows {
		isComplete := int64(0)
		if row.Complete {
			isComplete = 1
		}
		isAwarded := int64(0)
		if row.Awarded {
			isAwarded = 1
		}
		out = append(out, map[string]any{"table_id": row.Mission.ID, "is_complete": isComplete, "is_awarded": isAwarded, "progress": row.Progress})
	}
	return out
}

func cardWire(projection playerpresentation.Projected, at time.Time) map[string]any {
	last := lastSeenUnix(projection, at)
	return map[string]any{
		"player_id":       int64(projection.Minimal.PlayerID),
		"player_name":     projection.Minimal.Name,
		"avatar_id":       projection.Minimal.AvatarID,
		"avatar_frame_id": projection.Minimal.AvatarFrameID,
		"lev":             projection.Minimal.Level,
		"conquer_lev":     projection.Minimal.ConquerLevel,
		"conquer_loop_id": projection.Minimal.ConquerLoopID,
		"is_online":       onlineFlag(projection, at),
		"last_time":       last,
	}
}

func onlineFlag(projection playerpresentation.Projected, _ time.Time) int64 {
	if projection.Presence.IsOnline {
		return 1
	}
	return 0
}

func lastSeenUnix(projection playerpresentation.Projected, _ time.Time) int64 {
	if projection.Presence.LatestConnectedAt != nil {
		return projection.Presence.LatestConnectedAt.Unix()
	}
	if projection.Presence.LastSeenAt != nil {
		return projection.Presence.LastSeenAt.Unix()
	}
	return 0
}

// Finding implements MID 1858 GET_CLASS_FINDING_LIST.
func (service Service) Finding(ctx context.Context, actor identity.ActorContext, relationType int64, filter string, op operation.Context) (map[string]any, error) {
	if !service.validForRead() || relationType != 1 && relationType != 2 {
		return nil, ErrInvalid
	}
	catalog, err := service.catalog()
	if err != nil {
		return nil, err
	}
	rules := rulesFromCatalog(catalog)
	var list []any
	err = service.run(ctx, actor, op, false, func(ctx context.Context, t tx.Tx, at time.Time) error {
		actorLevel, err := playerLevel(ctx, service.Directory, t, actor.PlayerID)
		if err != nil {
			return err
		}
		candidates, err := service.findCandidates(ctx, t, actor, relationType, filter, at)
		if err != nil {
			return err
		}
		ids := make([]identity.PlayerID, 0, len(candidates))
		for _, candidate := range candidates {
			ids = append(ids, candidate.PlayerID)
		}
		states := map[identity.PlayerID]CandidateState{}
		if len(ids) > 0 {
			states, err = service.Store.CandidateStatesTx(ctx, t, actor.LogicalServerID, ids)
			if err != nil {
				return err
			}
		}
		pending, err := service.Store.PendingTargetsTx(ctx, t, actor.PlayerID, actor.LogicalServerID, at)
		if err != nil {
			return err
		}
		pendingSet := map[identity.PlayerID]bool{}
		for _, target := range pending {
			pendingSet[target] = true
		}
		eligible := make([]playerdirectory.Profile, 0, len(candidates))
		for _, candidate := range candidates {
			if !eligibleCandidate(candidate, states[candidate.PlayerID], relationType, actorLevel, rules, at) {
				continue
			}
			eligible = append(eligible, candidate)
		}
		cards, err := service.readCards(ctx, t, eligibleIDs(eligible))
		if err != nil {
			return err
		}
		sort.SliceStable(eligible, func(i, j int) bool {
			return activity(cards[eligible[i].PlayerID]) > activity(cards[eligible[j].PlayerID])
		})
		recent := eligible
		if len(recent) > FindingRecentPool {
			recent = recent[:FindingRecentPool]
		}
		shuffleProfiles(recent, op.ID.String())
		if len(recent) > FindingResultLimit {
			recent = recent[:FindingResultLimit]
		}
		list = make([]any, 0, len(recent))
		for _, candidate := range recent {
			projection, ok := cards[candidate.PlayerID]
			if !ok {
				return playerpresentation.ErrMissingPresentation
			}
			row := cardWire(projection, at)
			row["is_send_apply"] = pendingSet[candidate.PlayerID]
			list = append(list, row)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return map[string]any{"player_list": list}, nil
}

func (service Service) findCandidates(ctx context.Context, t tx.Tx, actor identity.ActorContext, relationType int64, filter string, at time.Time) ([]playerdirectory.Profile, error) {
	filter = trimFilter(filter)
	if filter != "" {
		if numericPlayerID(filter) {
			profile, found, err := service.Directory.ProfileTx(ctx, t, identity.PlayerID(parsePlayerID(filter)))
			if err != nil {
				return nil, err
			}
			if !found {
				return nil, nil
			}
			return appendSameServer(nil, []playerdirectory.Profile{profile}, actor), nil
		}
		matches, err := service.Directory.ProfilesByExactNameTx(ctx, t, filter, FindingResultLimit)
		if err != nil {
			return nil, err
		}
		return appendSameServer(nil, matches, actor), nil
	}
	lower, upper, found, err := service.Directory.PlayerIDBoundsTx(ctx, t)
	if err != nil {
		return nil, err
	}
	bandLow := identity.PlayerID(int64(actor.LogicalServerID) * 100000)
	bandHigh := bandLow + 99999
	if !found {
		lower, upper = bandLow, bandHigh
	}
	start := actor.PlayerID
	if start < bandLow || start > bandHigh {
		start = bandLow - 1
	}
	rows, err := service.Directory.ProfilesAfterTx(ctx, t, start, FindingScanLimit)
	if err != nil {
		return nil, err
	}
	out := appendSameServer(nil, rows, actor)
	if len(out) < FindingScanLimit && start > bandLow {
		rows, err = service.Directory.ProfilesAfterTx(ctx, t, bandLow-1, FindingScanLimit)
		if err != nil {
			return nil, err
		}
		out = appendSameServer(out, rows, actor)
	}
	_ = lower
	_ = upper
	return out, nil
}

// The find list is server-scoped and never offers the actor (contract C3).
func appendSameServer(out []playerdirectory.Profile, rows []playerdirectory.Profile, actor identity.ActorContext) []playerdirectory.Profile {
	for _, row := range rows {
		if row.PlayerID == actor.PlayerID || logicalserver.PlayerRegion(row.PlayerID) != actor.LogicalServerID {
			continue
		}
		out = append(out, row)
	}
	return out
}

func (service Service) readCards(ctx context.Context, t tx.Tx, ids []identity.PlayerID) (map[identity.PlayerID]playerpresentation.Projected, error) {
	if len(ids) == 0 {
		return map[identity.PlayerID]playerpresentation.Projected{}, nil
	}
	batch, err := service.Cards.ReadManyTx(ctx, t, ids)
	if err != nil {
		return nil, err
	}
	for _, player := range ids {
		if _, ok := batch.Players[player]; !ok {
			return nil, playerpresentation.ErrMissingPresentation
		}
	}
	return batch.Players, nil
}

func eligibleCandidate(candidate playerdirectory.Profile, state CandidateState, relationType, actorLevel int64, rules domain.Rules, at time.Time) bool {
	if candidate.Validate() != nil || candidate.Level < 1 {
		return false
	}
	if domain.BreakCooldownActive(rules, state.BrokeAt, at) {
		return false
	}
	if relationType == 1 {
		if candidate.Level < rules.MentorMinimumLevel || state.HasStudent {
			return false
		}
		return candidate.Level-actorLevel >= rules.LevelGap
	}
	if candidate.Level <= rules.StudentMinimumLevel || candidate.Level >= rules.StudentLevelLimit || state.HasMentor {
		return false
	}
	return actorLevel-candidate.Level >= rules.LevelGap
}

func eligibleIDs(profiles []playerdirectory.Profile) []identity.PlayerID {
	out := make([]identity.PlayerID, len(profiles))
	for index, profile := range profiles {
		out[index] = profile.PlayerID
	}
	return out
}

func activity(projection playerpresentation.Projected) int64 {
	if projection.Presence.IsOnline {
		return 1 << 62
	}
	if projection.Presence.LatestConnectedAt != nil {
		return projection.Presence.LatestConnectedAt.Unix()
	}
	if projection.Presence.LastSeenAt != nil {
		return projection.Presence.LastSeenAt.Unix()
	}
	return 0
}

// shuffleProfiles is deterministic per operation: the find list is response
// composition, not durable state.
func shuffleProfiles(profiles []playerdirectory.Profile, seed string) {
	sum := sha256.Sum256([]byte(seed))
	source := rand.New(rand.NewSource(int64(binary.BigEndian.Uint64(sum[:8]))))
	source.Shuffle(len(profiles), func(i, j int) { profiles[i], profiles[j] = profiles[j], profiles[i] })
}

func trimFilter(filter string) string {
	start, end := 0, len(filter)
	for start < end && (filter[start] == ' ' || filter[start] == '\t') {
		start++
	}
	for end > start && (filter[end-1] == ' ' || filter[end-1] == '\t') {
		end--
	}
	return filter[start:end]
}

func numericPlayerID(value string) bool {
	if value == "" {
		return false
	}
	for _, character := range value {
		if character < '0' || character > '9' {
			return false
		}
	}
	return true
}

func parsePlayerID(value string) int64 {
	var out int64
	for _, character := range value {
		out = out*10 + int64(character-'0')
		if out > 1<<62 {
			return 0
		}
	}
	return out
}

// GiftBaseInfoTx projects the freshBaseInfo record SocialSystem.lua reads from
// a gift reply when first and second hold an active class relation. ok is false
// for any other pair. The caller reads it inside the transaction that raised
// the pair's bond, so the projection carries the raised intimacy. It performs
// no write.
func (service Service) GiftBaseInfoTx(ctx context.Context, t tx.Tx, first, second identity.PlayerID, at time.Time) (map[string]any, bool, error) {
	if t == nil || !first.Valid() || !second.Valid() || first == second || at.IsZero() || service.Store == nil || service.Directory == nil || service.Cards == nil || service.Content == nil {
		return nil, false, ErrUnavailable
	}
	catalog, err := service.catalog()
	if err != nil {
		return nil, false, err
	}
	facts, err := service.readClassFacts(ctx, t, first, at, catalog, rulesFromCatalog(catalog))
	if err != nil {
		return nil, false, err
	}
	linked := false
	for _, relation := range facts.Relations {
		if relation.Mentor == second || relation.Student == second {
			linked = true
			break
		}
	}
	if !linked {
		return nil, false, nil
	}
	base, ok := BuildClassInfo(facts)["base_info"].(map[string]any)
	if !ok {
		return nil, false, ErrUnavailable
	}
	return base, true, nil
}

// ProjectClassInfo builds the login-embedded 1856 record from real state using
// the caller's transaction. It owns no gameplay authority and performs no write.
func (service Service) ProjectClassInfo(ctx context.Context, t tx.Tx, actor identity.PlayerID, at time.Time) (map[string]any, error) {
	if t == nil || !actor.Valid() || at.IsZero() || service.Store == nil || service.Directory == nil || service.Cards == nil || service.Content == nil {
		return nil, ErrUnavailable
	}
	catalog, err := service.catalog()
	if err != nil {
		return nil, err
	}
	facts, err := service.readClassFacts(ctx, t, actor, at, catalog, rulesFromCatalog(catalog))
	if err != nil {
		return nil, err
	}
	return BuildClassInfo(facts), nil
}
