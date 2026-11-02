//go:build postgres

package missions_test

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func awakeningNative(t *testing.T) (*pg.Pool, i5.Service, identity.ActorContext, character.Hero, time.Time) {
	t.Helper()
	p := missionPool(t)
	ctx := context.Background()
	at := upcomingOctober27()
	actor := runtimeActor(t, p, at)
	s := runtimeService(p, &missionClock{at: at})
	content := contentstore.Store{Queryer: p}
	store := characterstore.Store{Queryer: p}
	heroOwner := characterhero.Service{AcquisitionStore: store, Acquisition: content, CollectionAdmission: characterhero.CatalogCollectionAdmission{Content: content}, FreshFacets: characterbirth.FreshHeroFacets(), Equipment: content, Awakening: struct {
		characterstore.Store
		characterstore.RawAwakeningStore
	}{Store: store}}
	petOwner := characterpet.Service{Store: store, Awakening: store, Equipment: content}
	s.Awakening = &i5.AwakeningRuntime{Store: i5store.Store{Queryer: p}, Content: content, Heroes: heroOwner, Pets: petOwner, Stacks: i5store.Store{Queryer: p}, Costs: i5.MaterialCostDebiter{Store: i5store.Store{Queryer: p}, Content: content}}
	rev, e := content.ActiveRevision(ctx, p)
	if e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = heroOwner.LockStoryRosterTx(ctx, tr, actor.PlayerID); e != nil {
		t.Fatal(e)
	}
	admission := runtimeOperation(t, at)
	admission.Policies, e = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	if e != nil {
		t.Fatal(e)
	}
	h, _, e := heroOwner.AwardStoryPartnerTx(ctx, tr, actor.PlayerID, 10001001, rev, admission)
	if e != nil {
		t.Fatal(e)
	}
	// Declared source-level fixture, not proof of earned EXP or promotion.
	if _, e = tr.Exec(ctx, `UPDATE player_heroes SET level=100,color=15 WHERE player_id=$1 AND partner_id=$2`, int64(actor.PlayerID), h.PartnerID); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return p, s, actor, h, at
}

func awakeStack(t *testing.T, p *pg.Pool, pid identity.PlayerID, item, n int64, at time.Time) {
	t.Helper()
	_, e := p.Raw().Exec(context.Background(), `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,$3,1,$4,$4) ON CONFLICT(player_id,item_id)DO UPDATE SET quantity=$3`, int64(pid), item, n, at)
	if e != nil {
		t.Fatal(e)
	}
}
func awakeQuantity(t *testing.T, p *pg.Pool, pid identity.PlayerID, item int64) int64 {
	t.Helper()
	var n int64
	e := p.QueryRow(context.Background(), `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(pid), item).Scan(&n)
	if e != nil {
		t.Fatal(e)
	}
	return n
}

func TestAwakeningNativeWishCancelReplayAndReopen(t *testing.T) {
	p, s, a, h, at := awakeningNative(t)
	ctx := context.Background()
	store := i5store.Store{Queryer: p}
	if _, e := s.ReadAwakening(ctx, a, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	if _, e := s.ChangeAwakening(ctx, a, "open", 1001001, 1, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	root, e := store.ReadAwakeningTx(ctx, p, a.PlayerID)
	if e != nil || root.Active[0].OwnerID != h.PartnerID {
		t.Fatal(root, e)
	}
	generation := root.Active[0].Generation
	awakeStack(t, p, a.PlayerID, 50005037, 2, at)
	awakeStack(t, p, a.PlayerID, 50001019, 3, at)
	awakeStack(t, p, a.PlayerID, 50009377, 7, at)
	op := runtimeOperation(t, at)
	body, e := s.ChangeAwakening(ctx, a, "wish", 0, 0, op)
	if e != nil || body["item_id"] != int64(50001019) || body["extra_drops_"] != nil {
		t.Fatal(body, e)
	}
	if _, e = s.ChangeAwakening(ctx, a, "wish", 0, 0, op); e != nil {
		t.Fatal(e)
	}
	if awakeQuantity(t, p, a.PlayerID, 50001019) != 4 || awakeQuantity(t, p, a.PlayerID, 50005037) != 1 {
		t.Fatal("Wish replay changed value")
	}
	if _, e = s.ChangeAwakening(ctx, a, "claim", 1001001, 1, runtimeOperation(t, at)); !errors.Is(e, objective.ErrAwakeningRefused) {
		t.Fatal("incomplete claim", e)
	}
	for range 2 {
		if _, e = s.ChangeAwakening(ctx, a, "cancel", 1001001, 1, runtimeOperation(t, at)); e != nil {
			t.Fatal(e)
		}
	}
	if awakeQuantity(t, p, a.PlayerID, 50001019) != 0 || awakeQuantity(t, p, a.PlayerID, 50009377) != 7 || awakeQuantity(t, p, a.PlayerID, 50005037) != 1 {
		t.Fatal("cancel deleted unrelated stacks or refunded")
	}
	if _, e = s.ChangeAwakening(ctx, a, "open", 1001001, 1, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	root, e = store.ReadAwakeningTx(ctx, p, a.PlayerID)
	if e != nil || root.Active[0].Generation <= generation {
		t.Fatal(root, e)
	}
}

func TestAwakeningNativeBloodRawFacetAndConcurrentOpen(t *testing.T) {
	p, s, a, h, at := awakeningNative(t)
	ctx := context.Background()
	// An awakened-template fixture isolates the new raw lifecycle; ordinary completion is qualified separately.
	if _, e := p.Raw().Exec(ctx, `UPDATE player_heroes SET table_id=11001001 WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), h.PartnerID); e != nil {
		t.Fatal(e)
	}
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for range 2 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := s.ChangeAwakening(ctx, a, "open", 2001001, 2, runtimeOperation(t, at))
			errs <- e
		}()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	raw, e := (characterstore.RawAwakeningStore{}).ReadRawAwakeningBirthTx(ctx, p, h.Ref())
	if e != nil || raw.RawStage != 1 || raw.Version != 2 || raw.ProducerReference == "" {
		t.Fatal(raw, e)
	}
	body, e := s.ChangeAwakening(ctx, a, "cancel", 2001001, 2, runtimeOperation(t, at))
	if e != nil {
		t.Fatal(e)
	}
	channel := body["twice_awake_stage_"].(map[string]any)
	if channel["table_id"] != int64(11001001) || channel["stage"] != int64(0) {
		t.Fatal(channel)
	}
	raw, e = (characterstore.RawAwakeningStore{}).ReadRawAwakeningBirthTx(ctx, p, h.Ref())
	if e != nil || raw.RawStage != 0 || raw.Version != 3 {
		t.Fatal(raw, e)
	}
}

type awakeningFailStore struct{ i5store.Store }

func (awakeningFailStore) SaveAwakeningTx(context.Context, tx.Tx, identity.PlayerID, objective.AwakeRoot, int64) error {
	return errors.New("injected awakening root failure")
}
func TestAwakeningNativeRollbackAndLostCommit(t *testing.T) {
	p, s, a, _, at := awakeningNative(t)
	ctx := context.Background()
	store := i5store.Store{Queryer: p}
	broken := s
	runtime := *s.Awakening
	runtime.Store = awakeningFailStore{store}
	broken.Awakening = &runtime
	if _, e := broken.ChangeAwakening(ctx, a, "open", 1001001, 1, runtimeOperation(t, at)); e == nil {
		t.Fatal("injected failure ignored")
	}
	root, e := store.ReadAwakeningTx(ctx, p, a.PlayerID)
	if e != nil || root.Active[0].Mission != 0 {
		t.Fatal(root, e)
	}
	s.Runner.DB = &signLostDB{Beginner: p}
	op := runtimeOperation(t, at)
	if _, e = s.ChangeAwakening(ctx, a, "open", 1001001, 1, op); e != nil {
		t.Fatal(e)
	}
	if _, e = s.ChangeAwakening(ctx, a, "open", 1001001, 1, op); e != nil {
		t.Fatal(e)
	}
	root, e = store.ReadAwakeningTx(ctx, p, a.PlayerID)
	if e != nil || root.NextGeneration != 2 || root.Active[0].Generation != 1 {
		t.Fatal(root, e)
	}
}

func TestAwakeningNativeHeroEquipmentAdvancesOnlyBoundOccurrence(t *testing.T) {
	p, s, a, h, at := awakeningNative(t)
	ctx := context.Background()
	content := contentstore.Store{Queryer: p}
	rev, e := content.ActiveRevision(ctx, p)
	if e != nil {
		t.Fatal(e)
	}
	hero := s.Awakening.Heroes.(characterhero.Service)
	store := characterstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	hero.Runner = s.Runner
	hero.Store = store
	hero.Fencer = values
	hero.Content = content
	hero.ProgressionStore = store
	hero.Progression = content
	hero.Economy = i5.HeroProgressionDebiter{Store: values, Content: content}
	hero.Backpack = values
	hero.Receipts = s.Receipts
	hero.ReceiptRead = s.ReceiptRead
	hero.Equipment = content
	hero.MaterialCosts = s.Awakening.Costs
	hero.AwakeningEquipment = &s
	if _, e = s.ChangeAwakening(ctx, a, "open", 1001001, 1, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	var slot int64
	for n := int64(1); n <= 6; n++ {
		pos, e := content.HeroEquipmentPositionTx(ctx, p, rev, h.TableID, 15, n)
		if e != nil {
			t.Fatal(e)
		}
		if pos.ItemID == 20001185 {
			slot = n
		}
	}
	if slot == 0 {
		t.Fatal("source special position missing")
	}
	awakeStack(t, p, a.PlayerID, 20001185, 2, at)
	op := runtimeOperation(t, at)
	got, e := hero.EquipItem(ctx, a, h.PartnerID, slot, op)
	if e != nil || got.MissionChanges["awake_mission_"] == nil {
		t.Fatal(got, e)
	}
	if _, e = hero.EquipItem(ctx, a, h.PartnerID, slot, op); e != nil {
		t.Fatal(e)
	}
	if awakeQuantity(t, p, a.PlayerID, 20001185) != 1 {
		t.Fatal("equipment replay debited twice")
	}
	root, e := values.ReadAwakeningTx(ctx, p, a.PlayerID)
	if e != nil || !root.Active[0].Complete {
		t.Fatal(root, e)
	}
	if _, e = s.ChangeAwakening(ctx, a, "claim", 1001001, 1, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	root, e = values.ReadAwakeningTx(ctx, p, a.PlayerID)
	if e != nil || root.Active[0].Mission != 1001003 || root.Active[0].Complete {
		t.Fatal(root, e)
	}
	if _, e = s.ChangeAwakening(ctx, a, "claim", 1001001, 1, runtimeOperation(t, at)); e != nil {
		t.Fatal("semantic stage1 replay", e)
	}
	if _, e = s.ChangeAwakening(ctx, a, "claim", 1001003, 1, runtimeOperation(t, at)); !errors.Is(e, objective.ErrAwakeningRefused) {
		t.Fatal("unearned battle completion", e)
	}
	if _, e = s.ChangeAwakening(ctx, a, "cancel", 1001003, 1, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	if _, e = s.ChangeAwakening(ctx, a, "open", 1001001, 1, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	reopened, e := values.ReadAwakeningTx(ctx, p, a.PlayerID)
	if e != nil || !reopened.Active[0].Complete {
		t.Fatal("canonical collected gear stranded reopen", reopened, e)
	}
	if awakeQuantity(t, p, a.PlayerID, 20001185) != 1 {
		t.Fatal("reopen debited collected gear")
	}

}

func TestAwakeningNativeBloodGearRawAndInscriptionConsumer(t *testing.T) {
	p, s, a, h, at := awakeningNative(t)
	ctx := context.Background()
	content := contentstore.Store{Queryer: p}
	store := characterstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	rev, e := content.ActiveRevision(ctx, p)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = p.Raw().Exec(ctx, `UPDATE player_heroes SET table_id=11001001,equip_1=1,equip_2=1,equip_3=1,equip_4=1,equip_5=1,equip_6=1 WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), h.PartnerID); e != nil {
		t.Fatal(e)
	}
	hero := s.Awakening.Heroes.(characterhero.Service)
	hero.Runner = s.Runner
	hero.Store = store
	hero.Fencer = values
	hero.Content = content
	hero.ProgressionStore = store
	hero.Progression = content
	hero.Economy = i5.HeroProgressionDebiter{Store: values, Content: content}
	hero.Backpack = values
	hero.Receipts = s.Receipts
	hero.ReceiptRead = s.ReceiptRead
	hero.Equipment = content
	hero.MaterialCosts = s.Awakening.Costs
	hero.AwakeningEquipment = &s
	resolver := &characterhero.AwakeningPositionResolver{Raw: characterstore.RawAwakeningStore{}, Content: content}
	hero.AwakeningPositions = resolver
	if _, e = s.ChangeAwakening(ctx, a, "open", 2001001, 2, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	var slot int64
	for n := int64(1); n <= 6; n++ {
		pos, e := content.HeroEquipmentPositionTx(ctx, p, rev, 11001001, 15, n)
		if e != nil {
			t.Fatal(e)
		}
		if pos.ItemID == 20001185 {
			slot = n
		}
	}
	if slot == 0 {
		t.Fatal("Blood base special position missing")
	}
	awakeStack(t, p, a.PlayerID, 21001001, 2, at)
	if _, e = hero.EquipItem(ctx, a, h.PartnerID, slot, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	if _, e = s.ChangeAwakening(ctx, a, "claim", 2001001, 2, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	raw, e := (characterstore.RawAwakeningStore{}).ReadRawAwakeningBirthTx(ctx, p, h.Ref())
	if e != nil || raw.RawStage != 2 {
		t.Fatal(raw, e)
	}
	gear, e := (characterhero.EquipmentStateReader{Store: store, Content: content, Awakening: resolver}).RawEquipmentStateTx(ctx, p, a.PlayerID, h.PartnerID, rev)
	if e != nil || gear.Slots[slot-1].TemplateID != 21001001 {
		t.Fatal(gear, e)
	}
	got, e := hero.EquipItem(ctx, a, h.PartnerID, slot, runtimeOperation(t, at))
	if e != nil || !got.AlreadyEquipped || awakeQuantity(t, p, a.PlayerID, 21001001) != 1 {
		t.Fatal(got, e)
	}
	// Declared mission-completion fixture tests terminal owner/consumer composition only; it does not qualify 867.
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	root, e := values.LockAwakeningTx(ctx, tr, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	old := root.Version
	active := root.Active[1]
	if e = root.Complete(2, active.Mission, active.Generation, 1); e != nil {
		t.Fatal(e)
	}
	root.Version++
	if e = values.SaveAwakeningTx(ctx, tr, a.PlayerID, root, old); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if _, e = s.ChangeAwakening(ctx, a, "claim", 2001002, 2, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	raw, e = (characterstore.RawAwakeningStore{}).ReadRawAwakeningBirthTx(ctx, p, h.Ref())
	if e != nil || raw.RawStage != 3 {
		t.Fatal(raw, e)
	}
	eligible, e := (characterstore.InscriptionHeroPort{Store: store, Content: content}).InscriptionEligibilityTx(ctx, p, a.PlayerID, h.PartnerID, rev, at)
	if e != nil || !eligible.Qualified || eligible.RawStage != 3 {
		t.Fatal(eligible, e)
	}
}

type awakeningZeroDraw struct{}

func (awakeningZeroDraw) Uniform(uint64) uint64 { return 0 }
func TestAwakeningNativeCampaignDropGenerationAndSourceQualification(t *testing.T) {
	p, s, a, h, at := awakeningNative(t)
	ctx := context.Background()
	if _, e := s.ChangeAwakening(ctx, a, "open", 1001001, 1, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	frozen, e := s.FreezeAwakeningCampaignTx(ctx, p, a.PlayerID, 1200021, 2, []int64{h.PartnerID}, 0, true)
	if e != nil || len(frozen.Drops) != 1 {
		t.Fatal(frozen, e)
	}
	frozen = frozen.Draw(awakeningZeroDraw{})
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	drops, _, e := s.SettleAwakeningCampaignTx(ctx, tr, a.PlayerID, frozen, 0, 0, true)
	if e != nil || len(drops) != 1 || drops[0].ItemID != 60001043 {
		t.Fatal(drops, e)
	}
	tr.Rollback(ctx)
	forged := frozen
	forged.Drops = append([]objective.AwakeFrozenDrop{}, frozen.Drops...)
	forged.Drops[0].ItemID = 50009377
	tr, e = p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	_, _, e = s.SettleAwakeningCampaignTx(ctx, tr, a.PlayerID, forged, 0, 0, true)
	tr.Rollback(ctx)
	if !errors.Is(e, objective.ErrAwakeningRefused) {
		t.Fatal("unqualified source item accepted", e)
	}
	if _, e = s.ChangeAwakening(ctx, a, "cancel", 1001001, 1, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	if _, e = s.ChangeAwakening(ctx, a, "open", 1001001, 1, runtimeOperation(t, at)); e != nil {
		t.Fatal(e)
	}
	tr, e = p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	drops, _, e = s.SettleAwakeningCampaignTx(ctx, tr, a.PlayerID, frozen, 0, 0, true)
	if e != nil || len(drops) != 0 {
		t.Fatal("old draw attached to reopened occurrence", drops, e)
	}
	if _, _, e = s.SettleAwakeningCampaignTx(ctx, tr, a.PlayerID, frozen, 1001003, 0, true); !errors.Is(e, objective.ErrAwakeningRefused) {
		t.Fatal("unfrozen goal accepted", e)
	}
}
