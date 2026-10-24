//go:build postgres

package playerdisplay_test

import (
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/elementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	courseapp "gxb.local/backend/v2/internal/application/course"
	app "gxb.local/backend/v2/internal/application/dormhouse"
	elementapp "gxb.local/backend/v2/internal/application/elementequipment"
	"gxb.local/backend/v2/internal/application/i5"
	insapp "gxb.local/backend/v2/internal/application/inscription"
	spiritapp "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

func TestI7C2HFreshBootstrapAndActualAcquisitionRequiredFacets(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	if _, e := courseService(p, p).CourseInputsTx(ctx, p, courseapp.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}); e == nil {
		t.Fatal("missing required owner fabricated inputs")
	}
	cs := contentstore.Store{Queryer: p}
	hs := characterstore.Store{Queryer: p}
	owner := dormstore.Store{}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	bootop := op()
	bootop.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	b := logicalserver.BootstrapContext{PlayerID: a.PlayerID, Operation: bootop}
	for _, port := range []appboot.CharacterBootstrapPersistenceContributor{characterstore.BootstrapContributor{}, librarystore.BootstrapContributor{}, dormstore.BootstrapContributor{Revision: rev}, bookstore.BootstrapContributor{Revision: rev}, coursestore.BootstrapContributor{Revision: rev}, inscriptionstore.BootstrapContributor{Revision: rev}, i5store.InscriptionCertificateBootstrap{}, elementstore.BootstrapContributor{Revision: rev}, spiritstore.BootstrapContributor{Revision: rev}} {
		if e = port.PersistCharacterBootstrap(ctx, tr, b); e != nil {
			t.Fatal(e)
		}
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	inv := i5store.Store{Queryer: p, StackUsage: app.FurnitureUsage{Owner: owner, Content: cs}}
	svc := hero.Service{FreshFacets: hero.FreshFacetChain{librarystore.Store{}, owner, coursestore.Store{}, inscriptionstore.Store{}, elementstore.Store{}, spiritstore.Store{}}, Runner: tx.Runner{DB: p}, Store: hs, Fencer: inv, Content: cs, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, AcquisitionStore: hs, Acquisition: cs, Progression: cs, MaterialCosts: i5.MaterialCostDebiter{Store: inv, Content: cs}, PlayerLevel: i5.CrossOwner{Store: inv}, Capacity: skillTestCapacity{}}
	policy, e := cs.HeroNormalSummonTx(ctx, p, rev, 10001001)
	if e != nil {
		t.Fatal(e)
	}
	skillBook(t, p, a, policy.Template.FragmentItemID)
	exec(t, p, `UPDATE player_item_stacks SET quantity=$2 WHERE player_id=$1 AND item_id=$3`, int64(a.PlayerID), policy.FragmentCount, policy.Template.FragmentItemID)
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'mana',100000000,1,clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	original := op()
	h, e := svc.SummonNormal(ctx, a, 10001001, policy.Template.FragmentItemID, policy.FragmentCount, original)
	if e != nil {
		t.Fatal(e)
	}
	f, e := owner.ReadHeroTx(ctx, p, h.Ref())
	if e != nil || f.HouseID != 0 || f.Equipment != ([5]int64{}) {
		t.Fatal("new facet", f, e)
	}
	if _, e = (librarystore.Store{}).ReadHeroTx(ctx, p, h.Ref()); e != nil {
		t.Fatal("Library dropped", e)
	}
	if _, e = svc.SummonNormal(ctx, a, 10001001, policy.Template.FragmentItemID, policy.FragmentCount, original); e != nil {
		t.Fatal("acquisition replay", e)
	}
	root, e := owner.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.NextHouseID != 2 {
		t.Fatal(root, e)
	}
	bookRoot, e := (bookstore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || bookRoot.Facts.Buildings[4].Level != 1 {
		t.Fatal("required Book bootstrap", bookRoot, e)
	}
	inputs, e := courseService(p, p).HeroCourseInputsTx(ctx, p, courseapp.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, h.PartnerID)
	if e != nil || len(inputs.Applied.Courses) != 0 || inputs.FacetVersion != 1 {
		t.Fatal("fresh genuine Course absence", inputs, e)
	}
	iv, e := inscriptionService(p, p).HeroInscriptionInputsTx(ctx, p, insapp.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, h.PartnerID)
	if e != nil || len(iv.Applied.Wire()) != 0 || iv.FacetVersion != 1 {
		t.Fatal("actual fresh Inscription facet", iv, e)
	}
	ev, e := elementService(p, p).HeroElementInputsTx(ctx, p, elementapp.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, h.PartnerID)
	if e != nil || ev.Facet.Version != 1 || ev.Facet.Facts.Slots != ([4]int64{}) || len(ev.Facet.Facts.Backup) != 0 {
		t.Fatal("actual fresh Element absence", ev, e)
	}
	sv, e := spiritService(p, p).HeroSpiritInputsTx(ctx, p, spiritapp.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now()}, h.PartnerID)
	if e != nil || sv.Facet.Version != 1 || sv.Facet.Facts.Slots != ([6]int64{}) || sv.Items[0] == nil {
		t.Fatal("new actual Spirit facet", sv, e)
	}

	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	detail := map[string]any{}
	if e = (coursestore.BootstrapProjection{Service: courseService(p, p), Content: cs}).OverlayMID1(ctx, tr, a, false, time.Now().UTC(), detail); e != nil {
		t.Fatal(e)
	}
	if detail["2137"] == nil {
		t.Fatal("MID1 owningclaim")
	}
	tr.Rollback(ctx)
}
