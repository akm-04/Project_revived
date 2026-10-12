//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

func TestDisplayCanonicalCharacterEligibilityAndDestructionRace(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	s := service(p, p)
	catalog, e := (contentstore.Store{}).ReadPlayerDisplayCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	var normal, super, awaken player.Cosmetic
	var awakentable int64
	kinds := map[int64]player.DisplayHeroTemplate{}
	for _, h := range catalog.HeroTemplates {
		kinds[h.TableID] = h
	}
	for _, v := range catalog.Cosmetics {
		if v.Family != "avatar" {
			continue
		}
		h := kinds[v.PartnerID]
		if v.Type == 2 && h.Kind == "NORMAL" && h.BeforeAwaken == 0 && normal.ID == 0 {
			normal = v
		}
		if v.Type == 2 && h.Kind == "SUPER" && super.ID == 0 {
			super = v
		}
		if v.Type == 3 && h.Kind == "NORMAL" && h.BeforeAwaken > 0 && h.BeforeAwaken != normal.PartnerID && awaken.ID == 0 {
			awaken = v
			awakentable = h.TableID
		}
	}
	if normal.ID == 0 || super.ID == 0 || awaken.ID == 0 {
		t.Fatal("source facets missing")
	}
	exec(t, p, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,4,0,1,clock_timestamp(),clock_timestamp())`, int64(a.PlayerID))
	add := func(partner, table, origin, color, star int64) {
		exec(t, p, `INSERT INTO player_heroes(player_id,partner_id,table_id,origin_table_id,color,star,level,exp,creation_content_revision,state_version,created_at,updated_at)VALUES($1,$2,$3,$4,$5,$6,1,0,$7,1,clock_timestamp(),clock_timestamp())`, int64(a.PlayerID), partner, table, origin, color, star, rev)
	}
	add(1, normal.PartnerID, normal.PartnerID, 6, 1)
	add(2, super.PartnerID, super.PartnerID, 1, 1)
	add(3, awakentable, kinds[awakentable].BeforeAwaken, 7, 1)
	cmd := func(v player.Cosmetic, category int64) app.Command {
		return app.Command{Kind: "avatar", ID: v.ID, Icon: v.Icon, Category: category}
	}
	if _, e = s.Execute(ctx, a, cmd(normal, 2), op()); !errors.Is(e, app.ErrRequest) {
		t.Fatal("below purple", e)
	}
	exec(t, p, `UPDATE player_heroes SET color=7,state_version=state_version+1 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	if _, e = s.Execute(ctx, a, cmd(normal, 2), op()); e != nil {
		t.Fatal("purple canonical", e)
	}
	if _, e = s.Execute(ctx, a, cmd(super, 3), op()); !errors.Is(e, app.ErrRequest) {
		t.Fatal("super below star2", e)
	}
	exec(t, p, `UPDATE player_heroes SET star=2,state_version=state_version+1 WHERE player_id=$1 AND partner_id=2`, int64(a.PlayerID))
	if _, e = s.Execute(ctx, a, cmd(super, 3), op()); e != nil {
		t.Fatal("super star2", e)
	}
	exec(t, p, `UPDATE player_heroes SET color=7,state_version=state_version+1 WHERE player_id=$1 AND partner_id=2`, int64(a.PlayerID))
	if _, e = s.Execute(ctx, a, cmd(super, 2), op()); e != nil {
		t.Fatal("source purple Super also in category2", e)
	}
	if _, e = s.Execute(ctx, a, cmd(awaken, 4), op()); e != nil {
		t.Fatal("awaken sourcefirstid", e)
	}
	// Canonical skin entitlements, including source collection, never catalog-as-owned.
	for _, id := range catalog.Collection {
		v, _ := catalog.Find("avatar", id)
		exec(t, p, `INSERT INTO player_hero_skin_entitlements(player_id,partner_id,model_id)VALUES($1,1,$2)`, int64(a.PlayerID), v.PartnerID)
	}
	collection, _ := catalog.Find("avatar", 110006002)
	if _, e = s.Execute(ctx, a, cmd(collection, 5), op()); e != nil {
		t.Fatal("collection skin facets", e)
	}
	// A destruction owning the same Character root commits while assignment waits.
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	cs := characterstore.Store{}
	if _, e = cs.LockRootTx(ctx, tr, a.PlayerID); e != nil {
		t.Fatal(e)
	}
	started := make(chan struct{})
	done := make(chan error, 1)
	go func() { close(started); _, e := s.Execute(ctx, a, cmd(normal, 2), op()); done <- e }()
	<-started
	if _, e = tr.Exec(ctx, `DELETE FROM player_heroes WHERE player_id=$1`, int64(a.PlayerID)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if e = <-done; !errors.Is(e, app.ErrRequest) {
		t.Fatal("destruction race eligibility", e)
	}
	obs, e := s.ObserveTx(ctx, p, a.PlayerID, rev, time.Now().UTC())
	base, _ := catalog.Find("avatar", catalog.DefaultAvatar)
	if e != nil || obs.AvatarID != base.Icon || state(t, p, a).Selection.AvatarTableID != collection.ID {
		t.Fatal("fallback retains descriptor", obs, e)
	}
}

type fixedTime struct{ at time.Time }

func (x fixedTime) Now(context.Context) (time.Time, error) { return x.at, nil }
func TestDisplayChargedReplayInsufficientAndBackwardTime(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	s := service(p, p)
	if _, e := s.Execute(ctx, a, app.Command{Kind: "rename", Name: "Initial"}, op()); e != nil {
		t.Fatal(e)
	}
	charged := op()
	q := app.Command{Kind: "rename", Name: "Charged"}
	r, e := s.Execute(ctx, a, q, charged)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = s.Execute(ctx, a, app.Command{Kind: "rename", Name: "Latest"}, op()); e != nil {
		t.Fatal(e)
	}
	replay, e := s.Execute(ctx, a, q, charged)
	if e != nil || replay.ProfileVersion != r.ProfileVersion || state(t, p, a).Basis.Profile.DisplayName != "Latest" {
		t.Fatal("charged old replay", replay, e)
	}
	exec(t, p, `UPDATE player_currency_balances SET amount=1 WHERE player_id=$1`, int64(a.PlayerID))
	before := state(t, p, a)
	if _, e = s.Execute(ctx, a, app.Command{Kind: "rename", Name: "NoFunds"}, op()); e == nil {
		t.Fatal("insufficient accepted")
	}
	if state(t, p, a).Basis.Profile.StateVersion != before.Basis.Profile.StateVersion {
		t.Fatal("insufficient mutated")
	}
	// Distinct actor avoids intentionally pending failed-value admission above.
	b := actor(t, p)
	if _, e = s.Execute(ctx, b, app.Command{Kind: "rename", Name: "First"}, op()); e != nil {
		t.Fatal(e)
	}
	s.Time = fixedTime{at: time.Now().Add(-48 * time.Hour)}
	if _, e = s.Execute(ctx, b, app.Command{Kind: "rename", Name: "Backward"}, op()); e == nil {
		t.Fatal("backward profile clock accepted")
	}
	s = service(p, p)
	exec(t, p, `UPDATE player_currency_balances SET updated_at=clock_timestamp()+interval '1 day' WHERE player_id=$1`, int64(b.PlayerID))
	if _, e = s.Execute(ctx, b, app.Command{Kind: "rename", Name: "FutureScalar"}, op()); e == nil {
		t.Fatal("scalar clock regression")
	}
}

// Explicit external fixture tests payload/seam behavior only, not producer activation.
func TestDisplayTitleUniquePayloadAndQualifiedOrigins(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	s := service(p, p)
	origin := app.Origin{PlayerID: a.PlayerID, Key: "title-family-payload", Owner: "qualified-test-only", Family: "title", CatalogID: 100001, UniqueID: 21001, Revision: rev, StateVersion: 1, EndTime: 0}
	s.External = originProvider{o: origin}
	q := app.Command{Kind: "title", ID: origin.CatalogID, UniqueID: origin.UniqueID}
	r, e := s.Execute(ctx, a, q, op())
	if e != nil {
		t.Fatal(e)
	}
	info := r.Wire["title_info"].(map[string]any)
	if info["unique_id"] != origin.UniqueID || info["end_time"] != int64(0) {
		t.Fatal(info)
	}
	obs, e := s.ObserveTx(ctx, p, a.PlayerID, rev, time.Now().UTC())
	if e != nil || obs.TitleUniqueID != origin.UniqueID {
		t.Fatal(obs, e)
	}
	list, e := s.Read(ctx, a, "titles", op())
	if e != nil || len(list["title_list"].([]map[string]any)) != 1 {
		t.Fatal(list, e)
	}
	origin.PlayerID = identity.PlayerID(int64(a.PlayerID) + 99)
	s.External = originProvider{o: origin}
	if _, e = s.Read(ctx, a, "titles", op()); !errors.Is(e, app.ErrConflict) {
		t.Fatal("foreign qualified fact", e)
	}
}
