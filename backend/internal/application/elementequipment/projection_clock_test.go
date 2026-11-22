package elementequipment

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/domain/character"
	elem "gxb.local/backend/v2/internal/domain/elementequipment"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type clockQueryer struct{}

func (clockQueryer) QueryRow(context.Context, string, ...any) tx.Row { return clockRow{} }

type clockRow struct{}

func (clockRow) Scan(...any) error { return errors.New("clock fixture never queries") }

type clockOwner struct {
	root elem.Root
	hero elem.HeroRoot
}

func (o *clockOwner) ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (elem.Root, error) {
	return o.root, nil
}
func (o *clockOwner) ReadHeroTx(context.Context, tx.Queryer, identity.PlayerID, int64) (elem.HeroRoot, error) {
	return o.hero, nil
}
func (*clockOwner) LockHeroTx(context.Context, tx.Tx, identity.PlayerID, int64) (elem.HeroRoot, error) {
	return elem.HeroRoot{}, errors.New("clock fixture does not lock")
}
func (*clockOwner) SaveHeroTx(context.Context, tx.Tx, elem.HeroRoot, int64) error {
	return errors.New("clock fixture does not save")
}
func (*clockOwner) LockRootTx(context.Context, tx.Tx, identity.PlayerID) (elem.Root, error) {
	return elem.Root{}, errors.New("clock fixture does not lock")
}
func (*clockOwner) SaveRootTx(context.Context, tx.Tx, elem.Root, int64) error {
	return errors.New("clock fixture does not save")
}
func (*clockOwner) LockAdmissionTx(context.Context, tx.Tx, identity.PlayerID, string) (Admission, bool, error) {
	return Admission{}, false, errors.New("clock fixture does not admit")
}
func (*clockOwner) SaveAdmissionTx(context.Context, tx.Tx, Admission) error {
	return errors.New("clock fixture does not admit")
}

type clockHeroes struct {
	root character.HeroRoot
	hero character.Hero
}

func (h *clockHeroes) ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (character.HeroRoot, error) {
	return h.root, nil
}
func (h *clockHeroes) ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error) {
	return h.hero, nil
}
func (*clockHeroes) LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error) {
	return character.HeroRoot{}, errors.New("clock fixture does not lock")
}
func (*clockHeroes) LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error) {
	return character.Hero{}, errors.New("clock fixture does not lock")
}
func (*clockHeroes) ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error) {
	return nil, nil
}

type clockContent struct {
	apphero.EquipmentStateContent
}

func (clockContent) HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error) {
	return character.NormalHero, nil
}
func (clockContent) ElementCatalogTx(context.Context, tx.Queryer, string) (elem.Catalog, error) {
	return elem.Catalog{}, nil
}
func (clockContent) ElementInputsActive(context.Context) (string, bool, error) {
	return "", false, nil
}
func (clockContent) ElementInputsRevisionTx(context.Context, tx.Queryer, string) (bool, error) {
	return false, nil
}
func (clockContent) ResolveProgressionPolicyTx(context.Context, tx.Queryer, string) (player.ProgressionPolicy, error) {
	return player.ProgressionPolicy{}, errors.New("clock fixture has no progression policy")
}

// K2' (I9_11_CLOCK_ROLLBACK_V1 Amendment 1): a decision one hour before every
// stored row is a read, not a refusal, and the raw observation stays the pin.
func TestHeroElementInputsAcceptsBackwardObservation(t *testing.T) {
	created := time.Unix(1_700_000_000, 0).UTC()
	stored := created.Add(time.Hour)
	revision := strings.Repeat("a", 64)
	playerID := identity.PlayerID(7)
	hero := character.Hero{RawSkills: character.NewHeroRawSkillSeed(), PlayerID: playerID, PartnerID: 11, TableID: 1001, OriginTableID: 1001, Kind: character.NormalHero, Star: 1, Level: 1, Color: 1, CreationContentRevision: revision, StateVersion: 1, CreatedAt: created, UpdatedAt: stored}
	service := Service{
		Owner:   &clockOwner{root: elem.Root{Player: playerID, Version: 1, Revision: revision, Facts: elem.Seed(), CreatedAt: created, UpdatedAt: stored}, hero: elem.HeroRoot{Player: playerID, PartnerID: 11, Version: 1, Facts: elem.SeedHero(), CreatedAt: created, UpdatedAt: stored}},
		Heroes:  &clockHeroes{root: character.HeroRoot{PlayerID: playerID, StateVersion: 1, CreatedAt: created, UpdatedAt: stored}, hero: hero},
		Content: clockContent{},
	}
	inputs, err := service.HeroElementInputsTx(context.Background(), clockQueryer{}, InputScope{Player: playerID, ContentRevision: revision, ObservedAt: created}, 11)
	if err != nil {
		t.Fatalf("backward observation refused: %v", err)
	}
	if !inputs.ObservedAt.Equal(created) || !inputs.Root.UpdatedAt.Equal(stored) {
		t.Fatalf("read rewrote the observation: observed=%v root=%v", inputs.ObservedAt, inputs.Root.UpdatedAt)
	}
}
