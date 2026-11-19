package librarylocal

import (
	"context"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"slices"
	"strconv"
	"time"
)

// InputScope belongs to the caller's snapshot. None of these ports opens a
// transaction, samples time, resolves current content, or synthesizes facts.
type InputScope struct {
	Player          identity.PlayerID
	ContentRevision string
	ObservedAt      time.Time
}

func (s InputScope) valid() bool {
	return s.Player.Valid() && lib.ValidRevision(s.ContentRevision) && !s.ObservedAt.IsZero()
}

type HeroInputs struct {
	Hero                                  character.Hero
	Facts                                 lib.HeroFacts
	PopulationVersion, LibraryRootVersion int64
	ContentRevision                       string
	ObservedAt                            time.Time
	FavorBonusBP                          int64
}
type CollectionInputs struct {
	Player                                identity.PlayerID
	PopulationVersion, LibraryRootVersion int64
	ContentRevision                       string
	ObservedAt                            time.Time
	Contributions                         map[int64]int64
	MarriedCount                          int64
}
type RosterProjectionPort interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

func (s Service) HeroLibraryInputsTx(ctx context.Context, q tx.Queryer, scope InputScope, partner int64) (HeroInputs, error) {
	var out HeroInputs
	if q == nil || !scope.valid() || partner <= 0 {
		return out, lib.ErrUnqualified
	}
	catalog, e := s.Content.LibraryCatalogTx(ctx, q, scope.ContentRevision)
	if e != nil {
		return out, e
	}
	root, e := s.Heroes.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	lr, e := s.Library.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, q, scope.Player, partner)
	if e != nil {
		return out, e
	}
	rule, ok := catalog.Templates[h.TableID]
	if !ok {
		return out, lib.ErrUnqualified
	}
	facts, e := s.Library.ReadHeroTx(ctx, q, h.Ref())
	if e != nil {
		return out, e
	}
	if catalog.Feeding.ValidateApplied(facts.Applied) != nil {
		return out, lib.ErrUnqualified
	}
	bonus, e := facts.FavorBonusBP()
	if e != nil {
		return out, e
	}
	if !rule.DialogEnabled && (facts.Favor != 0 || facts.Married || facts.Pending != nil) {
		return out, lib.ErrInvalidFacts
	}
	return HeroInputs{h, facts, root.StateVersion, lr.StateVersion, scope.ContentRevision, scope.ObservedAt, bonus}, nil
}
func (s Service) PlayerCollectionInputsTx(ctx context.Context, q tx.Queryer, scope InputScope) (CollectionInputs, error) {
	out := CollectionInputs{Player: scope.Player, ContentRevision: scope.ContentRevision, ObservedAt: scope.ObservedAt, Contributions: map[int64]int64{}}
	if q == nil || !scope.valid() {
		return out, lib.ErrUnqualified
	}
	catalog, e := s.Content.LibraryCatalogTx(ctx, q, scope.ContentRevision)
	if e != nil {
		return out, e
	}
	hr, e := s.Heroes.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	lr, e := s.Library.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	out.PopulationVersion = hr.StateVersion
	out.LibraryRootVersion = lr.StateVersion
	heroes, e := s.Heroes.ListHeroesTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	add := func(c lib.Contribution) error {
		if c.Hundredths < 0 || out.Contributions[c.AttrID] > math.MaxInt64-c.Hundredths {
			return lib.ErrInvalidFacts
		}
		out.Contributions[c.AttrID] += c.Hundredths
		return nil
	}
	factsRows, e := s.Library.ListHeroesTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	byPartner := make(map[int64]lib.HeroFacts, len(factsRows))
	for _, f := range factsRows {
		byPartner[f.Ref.PartnerID] = f
	}
	for _, h := range heroes {
		rule, ok := catalog.Templates[h.TableID]
		if !ok {
			return out, lib.ErrUnqualified
		}
		f, ok := byPartner[h.PartnerID]
		if !ok {
			return out, lib.ErrUnqualified
		}
		if f.Married {
			out.MarriedCount++
		}
		normal, ok := catalog.NormalCollections[rule.CollectionSourceID]
		if !ok {
			if f.QualityStage != 0 || f.StarStage != 0 {
				return out, lib.ErrInvalidFacts
			}
			continue
		}
		c, e := f.NormalContribution(normal)
		if e != nil {
			return out, e
		}
		if e = add(c); e != nil {
			return out, e
		}
	}
	for i, claimed := range lr.SpecialClaims {
		if claimed {
			if e = add(catalog.SpecialCollections[i].Contribution); e != nil {
				return out, e
			}
		}
	}
	return out, nil
}
func (s Service) MarriedHeroCountTx(ctx context.Context, q tx.Queryer, scope InputScope) (CollectionInputs, error) {
	return s.PlayerCollectionInputsTx(ctx, q, scope)
}

// OverlayRosterTx is called by the existing Character projection; it never
// claims key49 independently. Applied fields exclude the paid candidate.
func (s Service) OverlayRosterTx(ctx context.Context, q tx.Queryer, actor identity.ActorContext, revision string, at time.Time, body map[string]any) error {
	active, e := s.Content.LibraryInputsRevisionTx(ctx, q, revision)
	if e != nil {
		return e
	}
	if !active {
		return nil
	}
	rows, ok := body["heros"].(map[string]any)
	if !ok {
		return lib.ErrUnqualified
	}
	root, e := s.Library.ReadRootTx(ctx, q, actor.PlayerID)
	if e != nil {
		return e
	}
	for key, raw := range rows {
		partner, e := strconv.ParseInt(key, 10, 64)
		if e != nil {
			return e
		}
		row, ok := raw.(map[string]any)
		if !ok {
			return lib.ErrUnqualified
		}
		f, e := s.HeroLibraryInputsTx(ctx, q, InputScope{actor.PlayerID, revision, at}, partner)
		if e != nil {
			return e
		}
		row["favor_degree"] = f.Facts.Favor
		row["is_married"] = bit(f.Facts.Married)
		row["feed_attrs"] = f.Facts.Applied
		row["collect_quality_stage"] = f.Facts.QualityStage
		row["collect_star_stage"] = f.Facts.StarStage
		row["is_board"] = int64(0)
		row["board_card"] = int64(1)
		row["board_model_id"] = int64(0)
		if root.BoardPartner == partner {
			row["is_board"] = int64(1)
			row["board_card"] = root.BoardCard
			row["board_model_id"] = root.BoardModelID
		}
	}
	return nil
}
func bit(v bool) int64 {
	if v {
		return 1
	}
	return 0
}
func (s Service) Read(ctx context.Context, a identity.ActorContext, op operation.Context, mid uint16, targetIdentifier int64) (map[string]any, error) {
	var body map[string]any
	if !s.complete() {
		return nil, ErrUnavailable
	}
	_, result, e := s.Timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc gen.TimedScope) error {
		if e := s.Fence.FenceActorTx(ctx, sc.Tx, a, sc.Operation.DecisionAt()); e != nil {
			return e
		}
		revision, active, e := s.Content.HeroCoreActiveTx(ctx, sc.Tx)
		if e != nil {
			return e
		}
		if !active {
			return ErrUnavailable
		}
		if mid == 841 {
			if e := s.ensurePartnerMissionsTx(ctx, sc.Tx, a.PlayerID, targetIdentifier, revision, sc.Operation.DecisionAt()); e != nil {
				return e
			}
		}
		return s.ReadBodyTx(ctx, sc.Tx, a, revision, sc.Operation.DecisionAt(), mid, targetIdentifier, &body)
	})
	if e != nil {
		return nil, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return body, nil
}
func (s Service) ReadBodyTx(ctx context.Context, q tx.Queryer, a identity.ActorContext, revision string, at time.Time, mid uint16, targetIdentifier int64, out *map[string]any) error {
	scope := InputScope{a.PlayerID, revision, at}
	if q == nil || out == nil || !scope.valid() {
		return lib.ErrUnqualified
	}
	if mid == 49 {
		if s.Roster == nil {
			return ErrUnavailable
		}
		detail := map[string]any{}
		if e := s.Roster.OverlayMID1(ctx, q, a, false, at, detail); e != nil {
			return e
		}
		body, ok := detail["49"].(map[string]any)
		if !ok {
			return ErrUnavailable
		}
		*out = body
		return nil
	}
	if mid == 853 {
		f, e := s.HeroLibraryInputsTx(ctx, q, scope, targetIdentifier)
		if e != nil {
			return e
		}
		*out = map[string]any{}
		if f.Facts.Pending != nil {
			(*out)["feed_add"] = f.Facts.Pending.Delta
		}
		return nil
	}
	if mid == 2784 {
		lr, e := s.Library.ReadRootTx(ctx, q, a.PlayerID)
		if e != nil {
			return e
		}
		if _, e = s.Content.LibraryCatalogTx(ctx, q, revision); e != nil {
			return e
		}
		bits := make([]int64, lib.SpecialClaimCount)
		for i, v := range lr.SpecialClaims {
			bits[i] = bit(v)
		}
		*out = map[string]any{"is_award": bits}
		return nil
	}
	if mid == 841 {
		return s.readPartnerMissions(ctx, q, a.PlayerID, targetIdentifier, out)
	}
	if mid == 838 || mid == 842 {
		return s.readPartnerDialogsOrActs(ctx, q, a, scope, targetIdentifier, mid, out)
	}
	if mid != 836 {
		return errors.New("library: unsupported read")
	}
	catalog, e := s.Content.LibraryCatalogTx(ctx, q, revision)
	if e != nil {
		return e
	}
	heroes, e := s.Heroes.ListHeroesTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}
	dialogs, e := s.Library.ListDialogsTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}
	missions, e := s.Library.ListMissionsTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}
	awards, e := s.Library.ListActAwardsTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}
	talkClaims, e := s.Library.ListTalkClaimsTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}
	cgClaims, e := s.Library.ListCGClaimsTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}
	backgrounds, e := s.Library.ListBackgroundsTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}
	heroLogs, e := s.Library.ListHeroLogsTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}
	root, e := s.Library.ReadRootTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}

	dialogsByPartner := map[int64][]lib.DialogFact{}
	for _, d := range dialogs {
		dialogsByPartner[d.PartnerID] = append(dialogsByPartner[d.PartnerID], d)
	}
	missionsByPartner := map[int64][]any{}
	for _, m := range missions {
		missionsByPartner[m.PartnerID] = append(missionsByPartner[m.PartnerID], map[string]any{
			"mission_id": m.MissionID, "process": m.Process, "mission_state": m.MissionState,
		})
	}
	infos := map[string]any{}
	for _, h := range heroes {
		f, e := s.HeroLibraryInputsTx(ctx, q, scope, h.PartnerID)
		if e != nil {
			return e
		}
		rule, ok := catalog.Templates[h.TableID]
		if !ok {
			return lib.ErrUnqualified
		}
		partnerMissions := missionsByPartner[h.PartnerID]
		if partnerMissions == nil {
			partnerMissions = []any{}
		}
		infos[strconv.FormatInt(h.PartnerID, 10)] = map[string]any{
			"favor_degree":     f.Facts.Favor,
			"is_married":       bit(f.Facts.Married),
			"partner_dialogs":  projectPartnerDialogs(catalog, rule.DialogEnabled, f.Facts.Favor, f.Facts.Married, h.PartnerID, dialogsByPartner[h.PartnerID]),
			"partner_missions": partnerMissions,
			"partner_acts":     projectPartnerActs(catalog, h.PartnerID, f.Facts.Favor, awards),
			"partner_logs":     partnerLogMap(heroLogs, h.PartnerID, f.Facts.Favor, f.Facts.CreatedAt, at),
		}
	}

	talkInfos := make(map[string]any, len(catalog.Talks))
	for id := range catalog.Talks {
		talkInfos[strconv.FormatInt(id, 10)] = int64(0)
	}
	for _, claim := range talkClaims {
		if _, ok := catalog.Talks[claim.TalkID]; ok {
			talkInfos[strconv.FormatInt(claim.TalkID, 10)] = int64(1)
		}
	}
	cgInfos := make([]int64, 0, len(cgClaims))
	for _, claim := range cgClaims {
		if _, ok := catalog.CGs[claim.CGID]; ok {
			cgInfos = append(cgInfos, claim.CGID)
		}
	}
	hasBuy := make([]int64, 0, len(backgrounds))
	for _, owned := range backgrounds {
		if _, ok := catalog.Backgrounds[owned.BgID]; ok {
			hasBuy = append(hasBuy, owned.BgID)
		}
	}

	*out = map[string]any{
		"library_infos":      infos,
		"library_talk_infos": talkInfos,
		"library_cg_infos":   cgInfos,
		"library_bg_infos": map[string]any{
			"bg_main": root.BgMain, "bg_room": root.BgRoom, "has_buy": hasBuy, "server_time": at.Unix(),
		},
	}
	return nil
}

func (s Service) readPartnerMissions(ctx context.Context, q tx.Queryer, player identity.PlayerID, partnerID int64, out *map[string]any) error {
	heroes, e := s.Heroes.ListHeroesTx(ctx, q, player)
	if e != nil {
		return e
	}
	owned := false
	for _, hero := range heroes {
		if hero.PartnerID == partnerID {
			owned = true
			break
		}
	}
	if !owned {
		return lib.ErrUnqualified
	}
	missions, e := s.Library.ListMissionsTx(ctx, q, player)
	if e != nil {
		return e
	}
	rows := make([]any, 0, len(missions))
	for _, mission := range missions {
		if mission.PartnerID != partnerID {
			continue
		}
		rows = append(rows, map[string]any{"mission_id": mission.MissionID, "process": mission.Process, "mission_state": mission.MissionState})
	}
	*out = map[string]any{"mission_list": rows}
	return nil
}

func (s Service) readPartnerDialogsOrActs(ctx context.Context, q tx.Queryer, a identity.ActorContext, scope InputScope, partnerID int64, mid uint16, out *map[string]any) error {
	catalog, e := s.Content.LibraryCatalogTx(ctx, q, scope.ContentRevision)
	if e != nil {
		return e
	}
	heroes, e := s.Heroes.ListHeroesTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}
	var tableID int64
	found := false
	for _, h := range heroes {
		if h.PartnerID == partnerID {
			tableID, found = h.TableID, true
			break
		}
	}
	if !found {
		return lib.ErrUnqualified
	}
	rule, ok := catalog.Templates[tableID]
	if !ok {
		return lib.ErrUnqualified
	}
	inputs, e := s.HeroLibraryInputsTx(ctx, q, scope, partnerID)
	if e != nil {
		return e
	}
	if mid == 842 {
		awards, e := s.Library.ListActAwardsTx(ctx, q, a.PlayerID)
		if e != nil {
			return e
		}
		*out = map[string]any{"partner_acts": projectPartnerActs(catalog, partnerID, inputs.Facts.Favor, awards)}
		return nil
	}
	stored, e := s.Library.ListDialogsTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}
	*out = map[string]any{"partner_dialogs": projectPartnerDialogs(catalog, rule.DialogEnabled, inputs.Facts.Favor, inputs.Facts.Married, partnerID, stored)}
	return nil
}

// projectPartnerDialogs is the one sorted view 836, 838 and the saved 840 reply
// share: statically open catalog dialogs plus retained known rows, with the
// stored read/award/select bits preserved. It writes nothing.
// partnerLogMap is the single Girls Log projection shared by 836 and the
// library.partner_log.v1 notice. The explicit acquisition row wins; a facet
// without one is dated from its creation time (PRIVATE_POLICY).
func partnerLogMap(heroLogs []lib.HeroLogFact, partnerID, favor int64, created, at time.Time) map[string]any {
	acquiredAt := created
	out := map[string]any{}
	for _, row := range heroLogs {
		if row.PartnerID != partnerID {
			continue
		}
		out[strconv.FormatInt(row.LogID, 10)] = map[string]any{"time": row.OccurredAt.Unix()}
		if row.LogID == lib.LogAcquired {
			acquiredAt = row.OccurredAt
		}
	}
	if _, present := out[strconv.FormatInt(lib.LogAcquired, 10)]; !present {
		out[strconv.FormatInt(lib.LogAcquired, 10)] = map[string]any{"time": acquiredAt.Unix()}
	}
	for _, logID := range lib.FavorLogIDsCrossed(0, favor) {
		key := strconv.FormatInt(logID, 10)
		if _, present := out[key]; !present {
			out[key] = map[string]any{"time": acquiredAt.Unix()}
		}
	}
	for _, milestone := range lib.HoldTimeLogsReached(acquiredAt, at) {
		out[strconv.FormatInt(milestone.LogID, 10)] = map[string]any{"time": milestone.OccurredAt.Unix()}
	}
	return out
}

func projectPartnerDialogs(catalog lib.Catalog, enabled bool, favor int64, married bool, partnerID int64, stored []lib.DialogFact) []DialogRow {
	if !enabled {
		return []DialogRow{}
	}
	byID := map[int64]lib.DialogFact{}
	for _, row := range stored {
		if row.PartnerID == partnerID {
			byID[row.DialogID] = row
		}
	}
	ids := map[int64]bool{}
	for _, id := range catalog.OpenDialogIDs(favor, married) {
		ids[id] = true
	}
	for id := range byID {
		if _, known := catalog.DialogConfigs[id]; known {
			ids[id] = true
		}
	}
	ordered := make([]int64, 0, len(ids))
	for id := range ids {
		ordered = append(ordered, id)
	}
	slices.Sort(ordered)
	dialogs := make([]DialogRow, 0, len(ordered))
	for _, id := range ordered {
		row, ok := byID[id]
		if !ok {
			row = lib.DialogFact{PartnerID: partnerID, DialogID: id}
		}
		dialogs = append(dialogs, DialogRow{DialogID: row.DialogID, IsRead: bit(row.IsRead), IsAwarded: bit(row.IsAwarded), SelectID: row.SelectID})
	}
	return dialogs
}

// projectPartnerActs returns the unlocked prefix the client indexes. The stock
// touch window hides a button whose slot is nil (HeroTouchGameWindow.lua:164-181),
// and library_amour stages unlock acts in order, so a shorter array gates them.
func projectPartnerActs(catalog lib.Catalog, partnerID, favor int64, awards []lib.ActAwardFact) []ActSlot {
	awarded := map[int64]bool{}
	for _, award := range awards {
		if award.PartnerID == partnerID {
			awarded[award.ActID] = true
		}
	}
	slots := make([]ActSlot, 0, lib.ActCount)
	for id := int64(1); id <= lib.ActCount; id++ {
		if !catalog.ActUnlocked(id, favor) {
			break
		}
		slots = append(slots, ActSlot{IsAwarded: bit(awarded[id])})
	}
	return slots
}

// TitleProgressTx is the marriage title progress (C6_SELECTED_COSMETIC_ORIGINS_V1):
// a title once earned is kept, so the stored high-water mark counts even after
// the current married count falls.
func (s Service) TitleProgressTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, revision string, at time.Time) (int64, int64, error) {
	inputs, e := s.MarriedHeroCountTx(ctx, q, InputScope{Player: player, ContentRevision: revision, ObservedAt: at})
	if e != nil {
		return 0, 0, e
	}
	root, e := s.Library.ReadRootTx(ctx, q, player)
	if e != nil {
		return 0, 0, e
	}
	return max(root.MarriedHighWater, inputs.MarriedCount), inputs.LibraryRootVersion, nil
}
