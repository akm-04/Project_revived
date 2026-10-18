package characterhero

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

func TestCollectionAdmissionLegacyReplayRequiresOriginalContentAndValidOperation(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 1, StateVersion: 1, CreatedAt: now, UpdatedAt: now}}
	tmpl := character.HeroAcquisitionTemplate{TableID: 10001001, OriginTableID: 10001001, Kind: character.NormalHero, InitialStar: 1, FragmentItemID: 40001001}
	c := acqContent{summon: map[int64]character.HeroNormalSummonPolicy{tmpl.TableID: {Template: tmpl, FragmentCount: 10, Mana: 1000}}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	svc := acquisitionService(as, c, &capAuth{max: 100}, &costDebiter{}, &levelReader{level: 100}, rr)
	o := testOp(t, "88888888-8888-4888-8888-888888888888")
	actor := testActor(t)
	want, e := svc.SummonNormal(context.Background(), actor, tmpl.TableID, tmpl.FragmentItemID, 10, o)
	if e != nil {
		t.Fatal(e)
	}
	svc.Capacity = nil
	svc.CollectionAdmission = CatalogCollectionAdmission{} // No current catalog is needed for positive original proof.
	got, e := svc.SummonNormal(context.Background(), actor, tmpl.TableID, tmpl.FragmentItemID, 10, o)
	if e != nil || got.PartnerID != want.PartnerID {
		t.Fatal("legacy proof rejected", e)
	}
	id := heroReceiptID(actor, "stone-summon", o)
	prior := rr.m[id]
	var ar acquisitionReceipt
	if e = json.Unmarshal(prior.ResultPayload, &ar); e != nil {
		t.Fatal(e)
	}
	ar.CreationContentRevision = strings.Repeat("f", 64)
	prior.ResultPayload, _ = json.Marshal(ar)
	rr.m[id] = prior
	if _, e = svc.SummonNormal(context.Background(), actor, tmpl.TableID, tmpl.FragmentItemID, 10, o); !errors.Is(e, ErrHeroAcquisitionInvalid) {
		t.Fatal("corrupt legacy content accepted", e)
	}
	o.StartedAt = time.Time{}
	if _, e = svc.SummonNormal(context.Background(), actor, tmpl.TableID, tmpl.FragmentItemID, 10, o); !errors.Is(e, ErrHeroAcquisitionInvalid) {
		t.Fatal("invalid operation accepted", e)
	}
}
