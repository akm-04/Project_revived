// Package achievement owns earned tier facts. It consumes canonical Library
// transitions; generic objectives, points and award claims are not trophies.
package achievement

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

type Event struct {
	Source           lib.MarriageEvent
	Population       int64
	Key, Fingerprint string
}

func (e Event) Validate() error {
	s := e.Source
	if !s.Player.Valid() || s.PartnerID < 1 || s.OldVersion < 1 || s.NewVersion != s.OldVersion+1 || s.OperationID.IsZero() || !d.RevisionValid(s.ContentRevision) || s.DecisionAt.Unix() <= 0 || e.Population < 1 || e.Population > 9007199254740991 {
		return d.ErrConflict
	}
	v, err := NewEvent(s, e.Population)
	if err != nil || v.Key != e.Key || v.Fingerprint != e.Fingerprint {
		return d.ErrConflict
	}
	return nil
}
func NewEvent(s lib.MarriageEvent, n int64) (Event, error) {
	f := objective.Fact{PlayerID: s.Player, SourceDomain: "Library", SourceBusinessKey: s.OperationID.String(), Kind: "MARRIED_HERO_POPULATION"}
	key, e := f.Key()
	if e != nil {
		return Event{}, e
	}
	raw, e := json.Marshal(struct {
		Source     lib.MarriageEvent
		Population int64
		Policy     string
	}{s, n, d.Policy})
	if e != nil {
		return Event{}, e
	}
	hash := sha256.Sum256(raw)
	return Event{Source: s, Population: n, Key: key, Fingerprint: hex.EncodeToString(hash[:])}, nil
}

type Store interface {
	ReadRootTx(context.Context, tx.Queryer, identity.PlayerID, bool) (d.Root, bool, error)
	SaveRootTx(context.Context, tx.Tx, d.Root, int64) error
	PutEventTx(context.Context, tx.Tx, Event) error
	ReadStreakTx(context.Context, tx.Queryer, identity.PlayerID, int64, bool) (d.Streak, bool, error)
	SaveStreakTx(context.Context, tx.Tx, d.Streak, int64) error
	ActiveStreakPlayersTx(context.Context, tx.Queryer, identity.LogicalServerID, int64, int64) ([]identity.PlayerID, error)
	InitFreshTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) error
	ReadStreaksTx(context.Context, tx.Queryer, identity.PlayerID) ([]d.Streak, error)
	ReadClaimsTx(context.Context, tx.Queryer, identity.PlayerID) (map[int64]bool, error)
	PutClaimTx(context.Context, tx.Tx, identity.PlayerID, int64, string, ids.UUID, int64, time.Time) error
	PutNoticesTx(context.Context, tx.Tx, []Notice) error
	PendingNoticesTx(context.Context, tx.Queryer, identity.PlayerID) ([]Notice, error)
	MarkNoticesDeliveredTx(context.Context, tx.Tx, identity.PlayerID, time.Time) error
	TrophyRankTx(context.Context, tx.Queryer, identity.PlayerID, d.Catalog) (int64, error)
	TrophyTopTx(context.Context, tx.Queryer, identity.LogicalServerID, d.Catalog, int) ([]TrophyStanding, error)
}
type Content interface {
	AchievementCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}
type Population interface {
	MarriedHeroCountTx(context.Context, tx.Queryer, lib.InputScope) (lib.CollectionInputs, error)
	HeroLibraryInputsTx(context.Context, tx.Queryer, lib.InputScope, int64) (lib.HeroInputs, error)
}
type Service struct {
	Store      Store
	Content    Content
	Population Population
	Runtime    *Runtime
}
type prepared struct {
	owner   Service
	event   Event
	root    d.Root
	catalog d.Catalog
	tracked bool
}

func (s Service) PrepareMarriageTx(c context.Context, t tx.Tx, e lib.MarriageEvent) (lib.PreparedMarriageFact, error) {
	if t == nil || s.Store == nil || s.Content == nil || s.Population == nil {
		return nil, d.ErrUnavailable
	}
	probe, err := NewEvent(e, 1)
	if err != nil || probe.Validate() != nil {
		return nil, d.ErrConflict
	}
	catalog, err := s.Content.AchievementCatalogTx(c, t, e.ContentRevision)
	if err != nil {
		return nil, err
	}
	// Rank620, acquired before Library's first I5 debit. Missing legacy history is
	// explicit unknown; source operation remains valid without invented backfill.
	r, ok, err := s.Store.ReadRootTx(c, t, e.Player, true)
	if err != nil {
		return nil, err
	}
	if ok && (r.Validate() != nil || r.UpdatedAt.After(e.DecisionAt)) {
		return nil, d.ErrConflict
	}
	if !ok {
		return nil, nil
	}
	if ok {
		if _, err = s.Content.AchievementCatalogTx(c, t, r.ContentRevision); err != nil {
			return nil, err
		}
	}
	scope := lib.InputScope{Player: e.Player, ContentRevision: e.ContentRevision, ObservedAt: e.DecisionAt}
	h, err := s.Population.HeroLibraryInputsTx(c, t, scope, e.PartnerID)
	if err != nil {
		return nil, err
	}
	if h.Facts.Married || h.Facts.Favor != 2000 || h.Facts.StateVersion != e.OldVersion {
		return nil, d.ErrConflict
	}
	count, err := s.Population.MarriedHeroCountTx(c, t, scope)
	if err != nil {
		return nil, err
	}
	if count.MarriedCount >= 9007199254740991 {
		return nil, d.ErrConflict
	}
	event, err := NewEvent(e, count.MarriedCount+1)
	if err != nil {
		return nil, err
	}
	return prepared{owner: s, event: event, root: r, catalog: catalog, tracked: ok}, nil
}
func (p prepared) ApplyMarriageTx(c context.Context, t tx.Tx) error {
	if t == nil {
		return d.ErrUnavailable
	}
	s := p.event.Source
	scope := lib.InputScope{Player: s.Player, ContentRevision: s.ContentRevision, ObservedAt: s.DecisionAt}
	h, e := p.owner.Population.HeroLibraryInputsTx(c, t, scope, s.PartnerID)
	if e != nil {
		return e
	}
	if !h.Facts.Married || h.Facts.StateVersion != s.NewVersion {
		return d.ErrConflict
	}
	count, e := p.owner.Population.MarriedHeroCountTx(c, t, scope)
	if e != nil {
		return e
	}
	if count.MarriedCount != p.event.Population {
		return d.ErrConflict
	}
	if !p.tracked {
		return nil
	}
	next, changed, e := p.root.ObservePopulation(p.catalog, count.MarriedCount, s.DecisionAt)
	if e != nil {
		return e
	}
	if e = p.owner.Store.PutEventTx(c, t, p.event); e != nil {
		return e
	}
	if !changed {
		return nil
	}
	if e = p.owner.Store.SaveRootTx(c, t, next, p.root.StateVersion); e != nil {
		return e
	}
	return p.owner.Store.PutNoticesTx(c, t, newTiers(s.Player, d.SelectedID, p.root.CompleteTimes, next.CompleteTimes))
}

type Request struct {
	Player          identity.PlayerID
	AchievementID   int64
	CompleteCatalog bool
}
type TierFact struct {
	Tier         int
	Earned       bool
	CompleteTime int64
}
type Observation struct {
	Player                                    identity.PlayerID
	AchievementID                             int64
	ContentRevision, OriginRevision, PolicyID string
	ObservedAt                                time.Time
	StateVersion, Progress                    int64
	Tiers                                     [3]TierFact
	CompleteCatalog                           bool
	UnavailableAchievementIDs                 []int64
}

func (s Service) ReadTierFactsTx(c context.Context, sc ca.CoherentReadScope, q Request) (Observation, error) {
	var out Observation
	pin, ok := sc.Operation.Policies.Get("content")
	if sc.Validate() != nil || !ok || pin != sc.ContentRevision || !q.Player.Valid() || q.AchievementID != d.SelectedID || q.CompleteCatalog || s.Store == nil || s.Content == nil {
		return out, d.ErrUnavailable
	}
	catalog, e := s.Content.AchievementCatalogTx(c, sc.Queryer(), sc.ContentRevision)
	if e != nil {
		return out, e
	}
	r, found, e := s.Store.ReadRootTx(c, sc.Queryer(), q.Player, false)
	if e != nil {
		return out, e
	}
	if !found {
		return out, d.ErrUnavailable
	}
	if r.PlayerID != q.Player || r.Validate() != nil || r.UpdatedAt.After(sc.ObservedAt) {
		return out, d.ErrConflict
	}
	if _, e = s.Content.AchievementCatalogTx(c, sc.Queryer(), r.ContentRevision); e != nil {
		return out, e
	}
	out = Observation{Player: q.Player, AchievementID: d.SelectedID, ContentRevision: sc.ContentRevision, OriginRevision: r.ContentRevision, PolicyID: r.PolicyID, ObservedAt: sc.ObservedAt, StateVersion: r.StateVersion, Progress: r.Progress}
	for i, at := range r.CompleteTimes {
		out.Tiers[i] = TierFact{Tier: i + 1, Earned: at != nil}
		if at != nil {
			out.Tiers[i].CompleteTime = at.Unix()
		}
	}
	for _, row := range catalog.Rows {
		if row.ID != d.SelectedID {
			out.UnavailableAchievementIDs = append(out.UnavailableAchievementIDs, row.ID)
		}
	}
	return out, nil
}

// ObserveTopFloorDayTx is the typed Top Floor producer (rank 620) for one
// immutable daily snapshot: top holds the server's players ranked 1..3 that day.
// Players without an Achievement root stay explicitly untracked.
func (s Service) ObserveTopFloorDayTx(c context.Context, t tx.Tx, server identity.LogicalServerID, day int64, revision string, top []identity.PlayerID, at time.Time) error {
	return s.observePeriodTx(c, t, d.TopFloorStreakID, server, day, revision, top, at)
}

// ObserveOneOnOneWeekTx is the typed 1 on 1 producer (rank 620) for one
// immutable Sunday 22:00 snapshot: top holds the server's players ranked 1..3.
func (s Service) ObserveOneOnOneWeekTx(c context.Context, t tx.Tx, server identity.LogicalServerID, day int64, revision string, top []identity.PlayerID, at time.Time) error {
	return s.observePeriodTx(c, t, d.WeeklyStreakID, server, day, revision, top, at)
}

// ObserveOneOnOneWinStreakTx records a player's running 1 on 1 attack win streak.
func (s Service) ObserveOneOnOneWinStreakTx(c context.Context, t tx.Tx, player identity.PlayerID, revision string, count int64, at time.Time) error {
	return s.observeCountTx(c, t, d.WinStreakID, player, revision, count, at)
}

// ObserveArenaWinStreakTx records a player's running ranked Arena attack win streak.
func (s Service) ObserveArenaWinStreakTx(c context.Context, t tx.Tx, player identity.PlayerID, revision string, count int64, at time.Time) error {
	return s.observeCountTx(c, t, d.ArenaStreakID, player, revision, count, at)
}

func (s Service) observeCountTx(c context.Context, t tx.Tx, id int64, player identity.PlayerID, revision string, count int64, at time.Time) error {
	if t == nil || s.Store == nil || s.Content == nil || !player.Valid() {
		return d.ErrUnavailable
	}
	catalog, err := s.Content.AchievementCatalogTx(c, t, revision)
	if err != nil {
		return err
	}
	return s.observePlayerTx(c, t, id, player, revision, at, func(current d.Streak) (d.Streak, bool, error) {
		return current.ObserveCount(catalog, count, at)
	})
}

func (s Service) observePeriodTx(c context.Context, t tx.Tx, id int64, server identity.LogicalServerID, day int64, revision string, top []identity.PlayerID, at time.Time) error {
	if t == nil || s.Store == nil || s.Content == nil || !server.Valid() || len(top) > int(d.StreakTopRank) {
		return d.ErrUnavailable
	}
	catalog, err := s.Content.AchievementCatalogTx(c, t, revision)
	if err != nil {
		return err
	}
	running, err := s.Store.ActiveStreakPlayersTx(c, t, server, id, day)
	if err != nil {
		return err
	}
	inTop := map[identity.PlayerID]bool{}
	for _, p := range top {
		inTop[p] = true
	}
	players := append([]identity.PlayerID(nil), top...)
	for _, p := range running {
		if !inTop[p] {
			players = append(players, p)
		}
	}
	sort.Slice(players, func(i, j int) bool { return players[i] < players[j] })
	for _, p := range players {
		if int64(p)/100000 != int64(server) {
			return d.ErrConflict
		}
		err = s.observePlayerTx(c, t, id, p, revision, at, func(current d.Streak) (d.Streak, bool, error) {
			return current.ObserveDay(catalog, day, inTop[p], at)
		})
		if err != nil {
			return err
		}
	}
	return nil
}

func (s Service) observePlayerTx(c context.Context, t tx.Tx, id int64, p identity.PlayerID, revision string, at time.Time, observe func(d.Streak) (d.Streak, bool, error)) error {
	if _, tracked, err := s.Store.ReadRootTx(c, t, p, true); err != nil || !tracked {
		return err
	}
	current, found, err := s.Store.ReadStreakTx(c, t, p, id, true)
	if err != nil {
		return err
	}
	if !found {
		if current, err = d.NewStreak(p, id, revision, at); err != nil {
			return err
		}
	}
	next, changed, err := observe(current)
	if err != nil || !changed {
		return err
	}
	old := current.StateVersion
	if !found {
		next.StateVersion, old = 1, 0
	}
	if err = s.Store.SaveStreakTx(c, t, next, old); err != nil {
		return err
	}
	return s.Store.PutNoticesTx(c, t, newTiers(p, id, current.CompleteTimes, next.CompleteTimes))
}

// ObserveLeagueDaysTx consumes the League owner's cumulative count of unique
// active-day top5 snapshots. It never counts a read or an unqualified row.
func (s Service) ObserveLeagueDaysTx(c context.Context, t tx.Tx, p identity.PlayerID, revision string, count int64, at time.Time) error {
	return s.observeCountTx(c, t, d.LeagueDaysID, p, revision, count, at)
}
