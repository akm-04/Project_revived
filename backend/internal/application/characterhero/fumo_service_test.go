package characterhero

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fumoOpContent struct {
	targets   map[int64]character.HeroFumoTarget
	materials map[int64]character.HeroFumoMaterial
}

func (fumoOpContent) HeroFumoRevision(context.Context, string) (bool, error) { return true, nil }
func (c fumoOpContent) HeroFumoTargetTx(_ context.Context, _ tx.Queryer, _ string, id character.EquipmentTemplateID) (character.HeroFumoTarget, error) {
	v, ok := c.targets[int64(id)]
	if !ok {
		return character.HeroFumoTarget{}, errors.New("missing Fumo target")
	}
	return v, nil
}
func (c fumoOpContent) HeroFumoMaterialTx(_ context.Context, _ tx.Queryer, _ string, id character.EquipmentTemplateID) (character.HeroFumoMaterial, error) {
	v, ok := c.materials[int64(id)]
	if !ok {
		return character.HeroFumoMaterial{}, errors.New("missing Fumo material")
	}
	return v, nil
}

func oneStageFumoTarget(id, cap, mana int64) character.HeroFumoTarget {
	return character.HeroFumoTarget{ItemID: character.EquipmentTemplateID(id), ThresholdIncrements: []int64{cap}, TotalCap: cap, ManaPerFumo: mana, StageDeltaByAttr: []map[int64]string{{1: "6"}}}
}
func specialFumoTarget() character.HeroFumoTarget {
	return character.HeroFumoTarget{ItemID: 20001185, ThresholdIncrements: []int64{90, 150, 240, 450, 750}, TotalCap: 1680, ManaPerFumo: 300, StageDeltaByAttr: []map[int64]string{{1: "10"}, {1: "10"}, {1: "10"}, {1: "10"}, {1: "10"}}}
}

func fumoFixture(t *testing.T, h character.Hero, mana int64, stacks map[int64]int64, targetID int64, ordinary bool) (Service, *progStore, *equipmentI5Store) {
	t.Helper()
	now := h.UpdatedAt
	pid := identityForFumoTest()
	i5 := &equipmentI5Store{
		pid:         pid,
		mana:        economy.ScalarBalance{PlayerID: pid, ResourceKey: "mana", Amount: mana, StateVersion: 1, UpdatedAt: now},
		progression: player.Progression{PlayerID: pid, Level: 100, Exp: 0, StateVersion: 1, UpdatedAt: now},
		stacks:      map[int64]economy.StackState{},
	}
	for id, qty := range stacks {
		i5.stacks[id] = economy.StackState{PlayerID: pid, ItemID: id, Quantity: qty, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	}
	svc, ps, _, _ := equipmentServiceFixture(t, h, i5)
	positions := map[[3]int64]character.HeroEquipmentPosition{}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		positions[[3]int64{h.TableID, h.Color, slot}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: h.Color, Slot: slot}
	}
	positions[[3]int64{h.TableID, h.Color, 5}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: h.Color, Slot: 5, ItemID: character.EquipmentTemplateID(targetID), OrdinaryEligible: ordinary}
	positions[[3]int64{h.TableID, h.Color, 1}] = character.HeroEquipmentPosition{HeroTableID: h.TableID, Color: h.Color, Slot: 1, ItemID: 20001185, OrdinaryEligible: false}
	svc.Equipment = equipmentOpContent{positions: positions, primitives: map[int64]character.EquipmentPrimitive{}, edges: map[int64][]character.EquipmentRecipeEdge{}}
	svc.Fumo = fumoOpContent{
		targets: map[int64]character.HeroFumoTarget{20001016: oneStageFumoTarget(20001016, 20, 120), 20001185: specialFumoTarget()},
		materials: map[int64]character.HeroFumoMaterial{
			20001014: {ItemID: 20001014, ItemType: 1, Moneng: 6},
			20001038: {ItemID: 20001038, ItemType: 1, Moneng: 10},
			20001047: {ItemID: 20001047, ItemType: 1, Moneng: 20},
			20001086: {ItemID: 20001086, ItemType: 1, Moneng: 60},
			60001011: {ItemID: 60001011, ItemType: 5, Moneng: 5},
		},
	}
	return svc, ps, i5
}

func identityForFumoTest() identity.PlayerID { return identity.PlayerID(7) }

func TestFeedFumoOverfeedConsumesAllCreditsRemainingAndReplays(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 10, 0, now)
	h.Equipment[4] = 1
	h.Fumo[4] = 15
	svc, ps, i5 := fumoFixture(t, h, 10000, map[int64]int64{20001038: 1, 20001047: 1}, 20001016, true)
	op := testOp(t, "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
	got, err := svc.FeedFumo(context.Background(), testActor(t), 11, 5, []int64{20001038, 20001047}, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.Fumo != 20 || got.Levels[4] != 1 || ps.saves != 1 || i5.mana.Amount != 9400 {
		t.Fatalf("got=%+v saves=%d mana=%d", got, ps.saves, i5.mana.Amount)
	}
	if _, ok := i5.stacks[20001038]; ok {
		t.Fatal("first overfeed material not consumed")
	}
	if _, ok := i5.stacks[20001047]; ok {
		t.Fatal("second overfeed material not consumed")
	}
	writes := i5.writes
	got2, err := svc.FeedFumo(context.Background(), testActor(t), 11, 5, []int64{20001038, 20001047}, op)
	if err != nil {
		t.Fatal(err)
	}
	if !got2.Replayed || got2.Fumo != 20 || ps.saves != 1 || i5.writes != writes {
		t.Fatalf("replay=%+v saves=%d writes=%d/%d", got2, ps.saves, i5.writes, writes)
	}
}

func TestFeedFumoDuplicateOccurrenceRequiresDuplicateQuantity(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 10, 0, now)
	h.Equipment[4] = 1
	svc, ps, i5 := fumoFixture(t, h, 10000, map[int64]int64{20001014: 1}, 20001016, true)
	_, err := svc.FeedFumo(context.Background(), testActor(t), 11, 5, []int64{20001014, 20001014}, testOp(t, "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"))
	if err == nil {
		t.Fatal("expected insufficient duplicate quantity")
	}
	if ps.saves != 0 || i5.writes != 0 || i5.mana.Amount != 10000 {
		t.Fatalf("rejection mutated state saves=%d writes=%d mana=%d", ps.saves, i5.writes, i5.mana.Amount)
	}
}

func TestFeedFumoSpecialMappingIsValidTarget(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 10, 0, now)
	h.Equipment[0] = 1
	svc, ps, i5 := fumoFixture(t, h, 10000, map[int64]int64{20001038: 1}, 20001016, true)
	got, err := svc.FeedFumo(context.Background(), testActor(t), 11, 1, []int64{20001038}, testOp(t, "cccccccc-cccc-4ccc-8ccc-cccccccccccc"))
	if err != nil {
		t.Fatal(err)
	}
	if got.Fumo != 10 || got.Levels[0] != 0 || ps.saves != 1 || i5.mana.Amount != 7000 {
		t.Fatalf("got=%+v saves=%d mana=%d", got, ps.saves, i5.mana.Amount)
	}
}

type ca43aMID58VectorDoc struct {
	Schema  string             `json:"schema"`
	Vectors []ca43aMID58Vector `json:"vectors"`
}

type ca43aMID58Vector struct {
	Name  string `json:"name"`
	Kind  string `json:"kind"`
	Input struct {
		CurrentRawFumo int64            `json:"current_raw_fumo"`
		Family         string           `json:"family"`
		Inventory      map[string]int64 `json:"inventory"`
		Mana           int64            `json:"mana"`
		Materials      []int64          `json:"materials"`
		Slot           int64            `json:"slot"`
		SlotCollected  bool             `json:"slot_collected"`
		TargetItemID   int64            `json:"target_item_id"`
	} `json:"input"`
	Expected struct {
		CreditedFumo      int64            `json:"credited_fumo"`
		FumoLevProjection []int64          `json:"fumo_lev_projection"`
		MaterialDebits    map[string]int64 `json:"material_debit_counts"`
		NewRawFumo        int64            `json:"new_raw_fumo"`
		PostcommitMana    int64            `json:"postcommit_economy_mana"`
		HeroMutation      bool             `json:"hero_mutation"`
		MaterialDebit     bool             `json:"material_debit"`
	} `json:"expected"`
}

func TestCA43AMID58ExecutableAdversarialVectors(t *testing.T) {
	raw, err := os.ReadFile("testdata/ca4_3a_mid58_adversarial_vectors.json")
	if err != nil {
		t.Fatal(err)
	}
	var doc ca43aMID58VectorDoc
	if err := json.Unmarshal(raw, &doc); err != nil {
		t.Fatal(err)
	}
	if doc.Schema != "CA4_3A_MID58_ADVERSARIAL_VECTORS_V1" || len(doc.Vectors) != 17 {
		t.Fatalf("fixture schema=%q vectors=%d", doc.Schema, len(doc.Vectors))
	}
	for vectorIndex, v := range doc.Vectors {
		if vectorIndex >= 15 { // receipt replay and cross-request ambiguity have dedicated contract tests.
			continue
		}
		v := v
		t.Run(v.Name, func(t *testing.T) {
			now := time.Unix(1, 0).UTC()
			h := heroAt(11, 1001, 1001, 3, 10, 0, now)
			if v.Input.Slot < 1 || v.Input.Slot > character.HeroEquipmentSlotCount {
				t.Fatalf("invalid sealed vector slot %d", v.Input.Slot)
			}
			h.Equipment[v.Input.Slot-1] = 0
			if v.Input.SlotCollected {
				h.Equipment[v.Input.Slot-1] = 1
			}
			h.Fumo[v.Input.Slot-1] = v.Input.CurrentRawFumo
			stacks := make(map[int64]int64, len(v.Input.Inventory))
			for k, qty := range v.Input.Inventory {
				id, err := strconv.ParseInt(k, 10, 64)
				if err != nil {
					t.Fatalf("fixture inventory id %q: %v", k, err)
				}
				stacks[id] = qty
			}
			svc, ps, i5 := fumoFixture(t, h, v.Input.Mana, stacks, v.Input.TargetItemID, true)
			if v.Input.Family == "SUPER_HERO" {
				svc.Progression = progContent{template: map[int64]character.HeroTemplateProgression{
					h.TableID: {Kind: character.SuperHero, OriginTableID: h.OriginTableID, InitialStar: h.Star},
				}}
			}
			opID := fmt.Sprintf("%08x-0000-4000-8000-%012x", vectorIndex+1, vectorIndex+1)
			got, err := svc.FeedFumo(context.Background(), testActor(t), h.PartnerID, v.Input.Slot, v.Input.Materials, testOp(t, opID))
			if v.Kind == "REJECT" {
				if err == nil {
					t.Fatalf("sealed reject vector unexpectedly succeeded: %+v", got)
				}
				if ps.saves != 0 || i5.writes != 0 || i5.mana.Amount != v.Input.Mana {
					t.Fatalf("rejection mutated state saves=%d writes=%d mana=%d want=%d", ps.saves, i5.writes, i5.mana.Amount, v.Input.Mana)
				}
				if ps.heroes[h.PartnerID].Fumo[v.Input.Slot-1] != v.Input.CurrentRawFumo {
					t.Fatalf("rejection changed raw Fumo: %d -> %d", v.Input.CurrentRawFumo, ps.heroes[h.PartnerID].Fumo[v.Input.Slot-1])
				}
				return
			}
			if v.Kind != "SUCCESS" {
				t.Fatalf("unexpected executable vector kind %q", v.Kind)
			}
			if err != nil {
				t.Fatal(err)
			}
			if got.Fumo != v.Expected.NewRawFumo || ps.saves != 1 || i5.mana.Amount != v.Expected.PostcommitMana {
				t.Fatalf("got=%+v saves=%d mana=%d wantFumo=%d wantMana=%d", got, ps.saves, i5.mana.Amount, v.Expected.NewRawFumo, v.Expected.PostcommitMana)
			}
			if len(v.Expected.FumoLevProjection) != character.HeroEquipmentSlotCount {
				t.Fatalf("fixture levels len=%d", len(v.Expected.FumoLevProjection))
			}
			for i, want := range v.Expected.FumoLevProjection {
				if got.Levels[i] != want {
					t.Fatalf("level[%d]=%d want=%d full=%v", i, got.Levels[i], want, got.Levels)
				}
			}
			for k, debit := range v.Expected.MaterialDebits {
				id, err := strconv.ParseInt(k, 10, 64)
				if err != nil {
					t.Fatal(err)
				}
				initial := v.Input.Inventory[k]
				remaining := initial - debit
				stack, ok := i5.stacks[id]
				if remaining == 0 {
					if ok {
						t.Fatalf("item %d should be fully consumed, stack=%+v", id, stack)
					}
				} else if !ok || stack.Quantity != remaining {
					t.Fatalf("item %d remaining=%v want=%d", id, stack, remaining)
				}
			}
		})
	}
}

func TestCA43ASealedMID58VectorFixtureIdentity(t *testing.T) {
	raw, err := os.ReadFile("testdata/ca4_3a_mid58_adversarial_vectors.json")
	if err != nil {
		t.Fatal(err)
	}
	sum := sha256.Sum256(raw)
	if got := hex.EncodeToString(sum[:]); got != "063c8b17d72f423b62533d00b4e18453d0b159d1fa1927fc4ef40313ce34b3e7" {
		t.Fatalf("vector fixture drift %s", got)
	}
	var doc struct {
		Schema  string            `json:"schema"`
		Vectors []json.RawMessage `json:"vectors"`
	}
	if err := json.Unmarshal(raw, &doc); err != nil {
		t.Fatal(err)
	}
	if doc.Schema != "CA4_3A_MID58_ADVERSARIAL_VECTORS_V1" || len(doc.Vectors) != 17 {
		t.Fatalf("schema=%q vectors=%d", doc.Schema, len(doc.Vectors))
	}
}
