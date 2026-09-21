package characterasset

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ca8Tag int64

func (t ca8Tag) RowsAffected() int64 { return int64(t) }

type ca8Row struct{}

func (ca8Row) Scan(...any) error { return errors.New("unexpected scan") }

type ca8Tx struct{}

func (ca8Tx) QueryRow(context.Context, string, ...any) tx.Row { return ca8Row{} }
func (ca8Tx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return ca8Tag(0), errors.New("unexpected exec")
}
func (ca8Tx) Commit(context.Context) error   { return nil }
func (ca8Tx) Rollback(context.Context) error { return nil }

func ca8Scope(isolation tx.Isolation) tx.Scope {
	return tx.Scope{
		Tx: ca8Tx{}, Attempt: 1, Options: tx.Options{Isolation: isolation, ReadOnly: true},
		Operation: operation.Context{ID: ids.UUID{1}, StartedAt: time.Unix(10, 0).UTC()},
	}
}

func TestCoherentReadScopeRequiresWitnessedIsolationAndPinnedInputs(t *testing.T) {
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	at := time.Unix(20, 0).UTC()
	for _, iso := range []tx.Isolation{tx.RepeatableRead, tx.Serializable} {
		s, err := NewCoherentReadScope(ca8Scope(iso), rev, at)
		if err != nil {
			t.Fatalf("iso %s: %v", iso, err)
		}
		if s.Queryer() == nil || s.Isolation != iso || s.ContentRevision != rev || !s.ObservedAt.Equal(at) {
			t.Fatalf("scope=%+v", s)
		}
	}
	if _, err := NewCoherentReadScope(ca8Scope(tx.ReadCommitted), rev, at); !errors.Is(err, ErrInsufficientReadIsolation) {
		t.Fatalf("read committed err=%v", err)
	}
	if _, err := NewCoherentReadScope(ca8Scope(tx.RepeatableRead), "bad", at); !errors.Is(err, ErrInvalidCoherentReadScope) {
		t.Fatalf("bad revision err=%v", err)
	}
	if _, err := NewCoherentReadScope(ca8Scope(tx.RepeatableRead), rev, time.Time{}); !errors.Is(err, ErrInvalidCoherentReadScope) {
		t.Fatalf("zero time err=%v", err)
	}
	offset := time.FixedZone("caller", 6*60*60)
	callerAt := time.Unix(20, 0).In(offset)
	normalized, err := NewCoherentReadScope(ca8Scope(tx.RepeatableRead), rev, callerAt)
	if err != nil {
		t.Fatalf("equivalent caller instant rejected: %v", err)
	}
	if normalized.ObservedAt.Location() != time.UTC || !normalized.ObservedAt.Equal(callerAt) {
		t.Fatalf("observation instant not normalized without drift: %v", normalized.ObservedAt)
	}
}

func TestCA8OriginAndProviderDispositionsRemainDistinct(t *testing.T) {
	origins := []ActorOrigin{ActorOriginOwned, ActorOriginBorrowed, ActorOriginTrial, ActorOriginNPCTemplate}
	seen := map[ActorOrigin]bool{}
	for _, o := range origins {
		if o.Validate() != nil || seen[o] {
			t.Fatalf("origin=%q", o)
		}
		seen[o] = true
	}
	if ActorOrigin("TEMP").Validate() == nil {
		t.Fatal("invented origin accepted")
	}
	if !ProviderQualifiedActive.Available() || ProviderExplicitlyInactiveOrAbsent.Available() {
		t.Fatal("availability collapsed")
	}
	if !ProviderUnavailableUnqualified.Unavailable() || ProviderUnavailableUnqualified.BlocksConsumer() {
		t.Fatal("optional unavailable collapsed into required blocker")
	}
	if !ProviderRequiredButUnavailable.Unavailable() || !ProviderRequiredButUnavailable.BlocksConsumer() {
		t.Fatal("required unavailable not blocking")
	}
}

func TestBaseObservationValidationPreservesOwnerBoundary(t *testing.T) {
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	h := HeroBaseObservation{Ref: character.HeroRef{PlayerID: 1, PartnerID: 2}, TableID: 10, OriginTableID: 10, Kind: character.NormalHero, Star: 1, Level: 1, Color: 1, CreationContentRevision: rev, StateVersion: 3}
	if err := h.Validate(); err != nil {
		t.Fatal(err)
	}
	p := PetBaseObservation{Ref: character.PetRef{PlayerID: 1, PetID: 4}, TableID: 20, OriginTableID: 20, Star: 1, Level: 1, Color: 1, Skills: character.DefaultPetSkillLevels(), Birthday: 100, IsShow: false, CreationContentRevision: rev, StateVersion: 5}
	if err := p.Validate(); err != nil {
		t.Fatal(err)
	}
	p.Skills[0] = 0
	if p.Validate() == nil {
		t.Fatal("invalid Pet skill state accepted")
	}
}
