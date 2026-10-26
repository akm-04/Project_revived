//go:build postgres

package playerdisplay_test

import (
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestI9_4DPetGearClaimAndForwardModePort(t *testing.T) {
	p := pool(t)
	defer p.Close()
	actor, rev, _ := combatOwner(t, p, rankingServer(t, p))
	pet := statPet(t, p, actor, rev)
	owner, _ := i94AwakeningOwners(p)
	pets := genuinePetService(p)
	pets.Awakening = characterstore.Store{Queryer: p}
	pets.AwakeningEquipment = &owner
	owner.Awakening.Pets = pets
	// Declared progression/show fixture; eggs and pet identity came through the actual summon owner.
	exec(t, p, `UPDATE player_pets SET level=90,color=15,is_show=true WHERE player_id=$1 AND pet_id=$2`, int64(actor.PlayerID), pet.PetID)
	if _, err := owner.ChangeAwakening(ctx, actor, "open", 10001001, 3, op()); err != nil {
		t.Fatal(err)
	}
	content := contentstore.Store{Queryer: p}
	var slot int64
	for n := int64(1); n <= character.PetEquipmentSlotCount; n++ {
		pos, err := content.PetEquipmentPositionTx(ctx, p, rev, pet.TableID, 15, n)
		if err != nil {
			t.Fatal(err)
		}
		if int64(pos.ItemID) == 80001073 {
			slot = n
		}
	}
	if slot == 0 {
		t.Fatal("source pet awakening slot missing")
	}
	fixture := op()
	if _, err := owner.SettleGrant(ctx, actor, grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "i94-fixture", Operation: "pet-gear", BusinessKey: fixture.ID.String(), Occurrence: fixture.ID.String(), PolicyVersion: "i94-fixture-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 80001073, Amount: 1}}}, fixture); err != nil {
		t.Fatal(err)
	}
	equip := op()
	got, err := pets.EquipItem(ctx, actor, pet.PetID, slot, equip)
	if err != nil || got.MissionChanges["pet_awake_mission_"] == nil {
		t.Fatal(got, err)
	}
	if _, err = pets.EquipItem(ctx, actor, pet.PetID, slot, equip); err != nil {
		t.Fatal(err)
	}
	if _, err = owner.ChangeAwakening(ctx, actor, "claim", 10001001, 3, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = owner.ChangeAwakening(ctx, actor, "claim", 10001002, 3, op()); !errors.Is(err, objective.ErrAwakeningRefused) {
		t.Fatal("unearned final", err)
	}
	// The typed port is qualified with a declared terminal fixture; real I9-5 mode origin remains OPEN.
	frozen, err := owner.FreezeAwakeningPetTx(ctx, p, actor.PlayerID, 41002, []int64{pet.PetID})
	if err != nil || frozen == nil {
		t.Fatal(frozen, err)
	}
	if unrelated, err := owner.FreezeAwakeningPetTx(ctx, p, actor.PlayerID, 41001, []int64{pet.PetID}); err != nil || unrelated != nil {
		t.Fatal("unrelated route", err)
	}
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if err = (i5store.Store{Queryer: p}).FenceActorTx(ctx, tr, actor, op().StartedAt); err != nil {
		t.Fatal(err)
	}
	if _, err = owner.CompleteAwakeningPetTx(ctx, tr, actor.PlayerID, *frozen, 10001002, false); !errors.Is(err, objective.ErrAwakeningRefused) {
		t.Fatal("losing terminal", err)
	}
	if _, err = owner.CompleteAwakeningPetTx(ctx, tr, actor.PlayerID, *frozen, 10001002, true); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	claim := op()
	if _, err = owner.ChangeAwakening(ctx, actor, "claim", 10001002, 3, claim); err != nil {
		t.Fatal(err)
	}
	if _, err = owner.ChangeAwakening(ctx, actor, "claim", 10001002, 3, claim); err != nil {
		t.Fatal(err)
	}
	rows, err := (characterstore.Store{Queryer: p}).ListPets(ctx, actor.PlayerID)
	if err != nil || len(rows) != 1 || rows[0].PetID != pet.PetID || rows[0].TableID != 110010001 {
		t.Fatal(rows, err)
	}
	if _, err = owner.ReadAwakening(ctx, actor, op()); err != nil {
		t.Fatal("reload", err)
	}
}
