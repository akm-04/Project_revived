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
	if scope.ObservedAt.Before(root.UpdatedAt) || scope.ObservedAt.Before(lr.UpdatedAt) || scope.ObservedAt.Before(h.UpdatedAt) || scope.ObservedAt.Before(facts.UpdatedAt) || catalog.Feeding.ValidateApplied(facts.Applied) != nil {
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
	if scope.ObservedAt.Before(hr.UpdatedAt) || scope.ObservedAt.Before(lr.UpdatedAt) {
		return out, lib.ErrUnqualified
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
	for _, h := range heroes {
		rule, ok := catalog.Templates[h.TableID]
		if !ok {
			return out, lib.ErrUnqualified
		}
		f, e := s.Library.ReadHeroTx(ctx, q, h.Ref())
		if e != nil {
			return out, e
		}
		if scope.ObservedAt.Before(h.UpdatedAt) || scope.ObservedAt.Before(f.UpdatedAt) {
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
	}
	return nil
}
func bit(v bool) int64 {
	if v {
		return 1
	}
	return 0
}
func (s Service) Read(ctx context.Context, a identity.ActorContext, op operation.Context, mid uint16, partner int64) (map[string]any, error) {
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
		return s.ReadBodyTx(ctx, sc.Tx, a, revision, sc.Operation.DecisionAt(), mid, partner, &body)
	})
	if e != nil {
		return nil, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return body, nil
}
func (s Service) ReadBodyTx(ctx context.Context, q tx.Queryer, a identity.ActorContext, revision string, at time.Time, mid uint16, partner int64, out *map[string]any) error {
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
		f, e := s.HeroLibraryInputsTx(ctx, q, scope, partner)
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
	if mid != 836 {
		return errors.New("library: unsupported read")
	}
	heroes, e := s.Heroes.ListHeroesTx(ctx, q, a.PlayerID)
	if e != nil {
		return e
	}
	infos := map[string]any{}
	for _, h := range heroes {
		f, e := s.HeroLibraryInputsTx(ctx, q, scope, h.PartnerID)
		if e != nil {
			return e
		}
		infos[strconv.FormatInt(h.PartnerID, 10)] = map[string]any{"favor_degree": f.Facts.Favor, "is_married": bit(f.Facts.Married)}
	}
	*out = map[string]any{"library_infos": infos, "library_talk_infos": map[string]any{}}
	return nil
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
