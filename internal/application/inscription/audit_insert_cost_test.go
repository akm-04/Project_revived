package inscription

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	ins "gxb.local/backend/v2/internal/domain/inscription"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestAuditA068EmptySlotInsertDoesNotChargeRemoval(t *testing.T) {
	data, err := builtin.GeneratedFile("inscription_input_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog ins.Catalog
	if err = json.Unmarshal(data, &catalog); err != nil {
		t.Fatal(err)
	}
	if err = catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	for _, existing := range []int64{0, 160100101} {
		plans := &auditInsertPlans{}
		service := Service{Owner: auditInsertOwner{existing: existing}, Heroes: auditInsertHeroes{}, Content: auditInsertContent{catalog: catalog}, Eligibility: auditInsertEligibility{}, Values: auditInsertValues{}, ValuePlans: plans}
		_, err = service.apply(context.Background(), nil, identity.ActorContext{PlayerID: 100001}, Admission{DecisionAt: time.Unix(100, 0).UTC(), ContentRevision: "test", Command: Command{Family: Insert, PartnerID: 1, ItemID: 160100102, ReplaceID: existing}})
		if !errors.Is(err, auditInsertPrepared) {
			t.Fatalf("existing=%d: preparation not reached: %v", existing, err)
		}
		want := int64(0)
		if existing != 0 {
			want = catalog.RemoveCost()
		}
		var charged int64
		for _, scalar := range plans.request.Cost.Scalars {
			if scalar.ResourceKey != "crystal" {
				t.Fatalf("unexpected scalar %s", scalar.ResourceKey)
			}
			charged += scalar.Amount
		}
		if charged != want {
			t.Errorf("existing=%d: crystal cost=%d want=%d", existing, charged, want)
		}
		if len(plans.request.Cost.Stacks) != 1 || plans.request.Cost.Stacks[0].ItemID != 160100102 || plans.request.Cost.Stacks[0].Amount != 1 {
			t.Fatalf("new medal cost lost: %+v", plans.request.Cost.Stacks)
		}
	}
}

type auditInsertOwner struct {
	OwnerPort
	existing int64
}

func (auditInsertOwner) ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (ins.Root, error) {
	return ins.Root{Facts: ins.Seed()}, nil
}
func (owner auditInsertOwner) ReadHeroTx(context.Context, tx.Queryer, identity.PlayerID, int64) (ins.HeroRoot, error) {
	return ins.HeroRoot{Facts: ins.HeroFacts{Slots: [3]int64{owner.existing}}}, nil
}

type auditInsertHeroes struct{ HeroPort }

func (auditInsertHeroes) ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (character.HeroRoot, error) {
	return character.HeroRoot{StateVersion: 1}, nil
}
func (auditInsertHeroes) ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error) {
	return character.Hero{StateVersion: 1, Level: 100}, nil
}

type auditInsertContent struct {
	ContentPort
	catalog ins.Catalog
}

func (content auditInsertContent) InscriptionCatalogTx(context.Context, tx.Queryer, string) (ins.Catalog, error) {
	return content.catalog, nil
}
func (auditInsertContent) HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error) {
	return character.NormalHero, nil
}

type auditInsertEligibility struct{}

func (auditInsertEligibility) InscriptionEligibilityTx(_ context.Context, _ tx.Queryer, player identity.PlayerID, partner int64, revision string, at time.Time) (Eligibility, error) {
	return Eligibility{Player: player, PartnerID: partner, PopulationVersion: 1, HeroVersion: 1, Level: 100, RawStage: 3, Kind: character.NormalHero, ContentRevision: revision, ProviderRevision: "test", ObservedAt: at, Qualified: true}, nil
}

type auditInsertValues struct{ ValuePort }

func (auditInsertValues) ListStacksTx(context.Context, tx.Queryer, identity.PlayerID) ([]economy.StackState, error) {
	return nil, nil
}

var auditInsertPrepared = errors.New("audit: captured prepared value request")

type auditInsertPlans struct {
	i5.TxInscriptionValue
	request i5.InscriptionValueRequest
}

func (plans *auditInsertPlans) PrepareInscriptionValueTx(_ context.Context, _ tx.Tx, _ identity.ActorContext, request i5.InscriptionValueRequest, _ operation.Context) (*i5.PreparedInscriptionValue, error) {
	plans.request = request
	return nil, auditInsertPrepared
}
