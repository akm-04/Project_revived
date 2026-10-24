package librarylocal

import (
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"testing"
	"time"
)

func actor(t *testing.T) HeroFacts {
	t.Helper()
	f, e := NewHeroFacts(character.HeroRef{PlayerID: identity.PlayerID(7), PartnerID: 3}, time.Unix(100, 0).UTC())
	if e != nil {
		t.Fatal(e)
	}
	return f
}
func TestRelationshipProducerAndSaveSeparation(t *testing.T) {
	f := actor(t)
	rule := TemplateRule{TableID: 10001001, RelationshipSourceID: 10001001, DialogEnabled: true, GiftLikeType: 1, GiftDislikeType: 2}
	now := time.Unix(101, 0).UTC()
	ring := GiftRule{ItemID: 50001112, Ring: true}
	if _, _, e := f.ApplyGift(rule, ring, now); e != ErrMarriageGate {
		t.Fatalf("ring without favor: %v", e)
	}
	f.Favor = 1999
	next, changed, e := f.ApplyGift(rule, GiftRule{ItemID: 50001113, Category: 1, BaseFavor: 100}, now)
	if e != nil || !changed || next.Favor != 2000 || f.Favor != 1999 {
		t.Fatalf("gift clamp/pure effect: %+v %v", next, e)
	}
	f = next
	f, changed, e = f.ApplyGift(rule, ring, now)
	if e != nil || !changed || !f.Married {
		t.Fatal(f, e)
	}
	if _, changed, e = f.ApplyGift(rule, ring, now); e != nil || changed {
		t.Fatal("repeat ring must converge without debit", e)
	}
	id, _ := ids.ParseUUID("12345678-1234-4234-8234-123456789012")
	c := Candidate{OperationID: id, Revision: f.StateVersion + 1, PolicyVersion: FeedPolicyV1, ContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", Base: f.Applied, Proposed: FeedAttrs{60, 5, 5, 2, 2, 2}, Delta: FeedAttrs{60, 5, 5, 2, 2, 2}, CreatedAt: now}
	preview, e := f.WithPreview(c, now)
	if e != nil || preview.Applied != f.Applied || preview.Pending == nil || f.Pending != nil {
		t.Fatal("paid preview leaked into applied", e)
	}
	saved, changed, e := preview.SaveCurrent(now)
	if e != nil || !changed || saved.Applied != c.Proposed || saved.Pending != nil {
		t.Fatal(saved, e)
	}
	if _, changed, e = saved.SaveCurrent(now); e != nil || changed {
		t.Fatal("double save must converge", e)
	}
	// A replacement candidate can have negative effects; SAVE applies its exact proposal.
	c.Base = saved.Applied
	c.Proposed = FeedAttrs{15, 2, 2, 1, 1, 1}
	for i := range c.Delta {
		c.Delta[i] = c.Proposed[i] - c.Base[i]
	}
	c.Revision = saved.StateVersion + 1
	redo, e := saved.WithPreview(c, now)
	if e != nil {
		t.Fatal(e)
	}
	saved, _, e = redo.SaveCurrent(now)
	if e != nil || saved.Applied != c.Proposed {
		t.Fatal("negative redo/apply", e)
	}
}
func TestCollectionMonotonicPerInstanceAndExactFraction(t *testing.T) {
	f := actor(t)
	r := NormalCollectionRule{SourceID: 10001001, AttrID: 4, QualityThresholds: []int64{1, 2, 4, 7, 12, 15}, QualityHundredths: []int64{12000, 15000, 18000, 21000, 24000, 30000}, StarThresholds: []int64{4, 5}, StarHundredths: []int64{4000, 10000}}
	now := time.Unix(101, 0).UTC()
	f, changed, e := f.ClaimNormal(r, 12, 5, now)
	if e != nil || !changed || f.QualityStage != 5 || f.StarStage != 2 {
		t.Fatal(f, e)
	}
	if _, changed, e = f.ClaimNormal(r, 1, 1, now); e != nil || changed {
		t.Fatal("claim stage rollback", e)
	}
	amount, e := f.NormalContribution(r)
	if e != nil || amount.Hundredths != 34000 {
		t.Fatal("stages select cumulative amount, not sum each prior stage", amount, e)
	}
	player, e := NewPlayerFacts(f.Ref.PlayerID, now)
	if e != nil {
		t.Fatal(e)
	}
	sp := SpecialCollectionRule{ID: 2, Type: 1, RequiredSourceIDs: []int64{10001040, 11001}, Contribution: Contribution{AttrID: 35, Hundredths: 10}}
	if _, _, e = player.ClaimSpecial(sp, map[int64]bool{10001040: true}, now); e != ErrUnqualified {
		t.Fatal("incomplete ownership set accepted", e)
	}
	player, changed, e = player.ClaimSpecial(sp, map[int64]bool{10001040: true, 11001: true}, now)
	if e != nil || !changed || !player.SpecialClaims[1] {
		t.Fatal(player, e)
	}
	if _, changed, e = player.ClaimSpecial(sp, nil, now); e != nil || changed {
		t.Fatal("already claimed must converge", e)
	}
	sp.Type = 2
	if _, _, e = player.ClaimSpecial(sp, nil, now); e != ErrUnqualified {
		t.Fatal("dormant reward shape accepted", e)
	}
}
func TestFavorBonusBoundaryStages(t *testing.T) {
	f := actor(t)
	f.Favor = 100
	if v, _ := f.FavorBonusBP(); v != 0 {
		t.Fatal(v)
	}
	f.Favor = 101
	if v, _ := f.FavorBonusBP(); v != 50 {
		t.Fatal(v)
	}
	f.Favor = 301
	if v, _ := f.FavorBonusBP(); v != 100 {
		t.Fatal(v)
	}
	f.Favor = 801
	if v, _ := f.FavorBonusBP(); v != 300 {
		t.Fatal(v)
	}
	f.Favor = 2000
	f.Married = true
	if v, _ := f.FavorBonusBP(); v != 500 {
		t.Fatal(v)
	}
}
