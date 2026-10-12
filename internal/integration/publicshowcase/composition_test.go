//go:build postgres

package publicshowcase_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/guildinvitebundle"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/profilefeedbackstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	feedback "gxb.local/backend/v2/internal/application/profilefeedback"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
)

// Explicit transport/component test double: genuine owned base observations,
// fixture payload marker, NO HeroSkill/final-stat/history producer qualification.
type componentRecords struct {
	Marker string
	Fail   bool
	Wrong  bool
}

func (b componentRecords) RecordTx(c context.Context, sc characterasset.CoherentReadScope, pid identity.PlayerID, id int64) (map[string]any, error) {
	if b.Fail {
		return nil, app.ErrShowcaseUnavailable
	}
	if sc.Validate() != nil {
		return nil, app.ErrShowcaseUnavailable
	}
	refs := baseReaders()
	var table int64
	key := "partner_id"
	value := id
	if id > 0 {
		h, e := refs.HeroBaseObservationTx(c, sc.Queryer(), pid, id)
		if e != nil {
			return nil, e
		}
		table = h.TableID
	} else {
		p, e := refs.PetBaseObservationTx(c, sc.Queryer(), pid, -id)
		if e != nil {
			return nil, e
		}
		table = p.TableID
		key = "pet_id"
		value = -id
	}
	if b.Wrong {
		value++
	}
	return map[string]any{key: value, "table_id": table, "component_fixture_marker": b.Marker}, nil
}
func wire(p *pg.Pool, db tx.Beginner, b app.ShowcaseRecordBuilder) app.ShowcaseWireService {
	old := showcase(p, db)
	return app.ShowcaseWireService{Timed: old.Timed, Reads: old.Reads, Fresh: old.Fresh, Roots: old.Roots, Players: old.Players, Fence: old.Fence, Receipts: old.Receipts, Content: old.Content, Slots: old.Slots, References: old.References, Bases: old.Bases, Records: b}
}
func composer(t *testing.T, p *pg.Pool) app.ReadService {
	b := reader()
	content := contentstore.Store{}
	r := tx.Runner{DB: p}
	rev, e := content.ActiveRevision(ctx, p)
	if e != nil {
		t.Fatal(e)
	}
	inv, e := guildinvitebundle.Prepare(ctx, p, r, rev)
	if e != nil {
		t.Fatal(e)
	}
	fb := feedback.Service{Roots: feedback.RootService{Store: profilefeedbackstore.Store{}}, Content: content, Recipients: i4store.PlayerRootLocker{}, Authors: i5store.Store{}}
	display := playerdisplay.Service{Store: i5store.Store{}, Content: content, Characters: characterstore.DisplayReader{Store: characterstore.Store{}, Content: content}}
	return app.ReadService{Runner: r, Fresh: p, Time: pg.AuthoritativeTime{Queryer: p}, Content: content, Basic: b.Basic, Display: display, Guilds: guildcore.PublicViewReader{Store: guildstore.Store{}, Invites: inv.Source}, Feedback: fb.Roots, Comments: feedback.CommentService{Base: fb, Store: profilefeedbackstore.Store{}}, Media: publicprofilestore.Store{}, Metrics: app.CanonicalCreationMetricProvider{Players: i5store.Store{}}, Slots: b.Slots, Characters: b.Characters, Records: app.UnavailableShowcaseRecords{}}
}
func profileActor(t *testing.T, p *pg.Pool) identity.ActorContext {
	a := actor(t, p)
	sqlExec(t, p, `UPDATE player_profiles SET avatar_id=110001001 WHERE player_id=$1`, int64(a.PlayerID))
	sqlExec(t, p, `UPDATE player_progression SET exp=37 WHERE player_id=$1`, int64(a.PlayerID))
	sqlExec(t, p, `INSERT INTO player_social_roots(player_id,created_at,updated_at)VALUES($1,clock_timestamp(),clock_timestamp())`, int64(a.PlayerID))
	return a
}
func Test6BWireAtomicRecordsReplayUnknownAndConcurrency(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := profileActor(t, p)
	assets(t, p, a, rev)
	q := app.Selection{1, 0, -1, 0, 0, 2}
	for _, builder := range []app.ShowcaseRecordBuilder{nil, app.UnavailableShowcaseRecords{}, componentRecords{Wrong: true}} {
		if _, e := wire(p, p, builder).Execute(ctx, a, q, op()); e == nil {
			t.Fatal("unqualified/mismatchedrecords accepted")
		}
		if _, present := root(t, p, a.PlayerID); present {
			t.Fatal("providerfailure wrote root")
		}
		if selection(t, p, a.PlayerID) != (app.Selection{}) {
			t.Fatal("providerfailure wrote slots")
		}
	}
	first := op()
	s := wire(p, p, componentRecords{Marker: "original"})
	out, e := s.Execute(ctx, a, q, first)
	if e != nil {
		t.Fatal(e)
	}
	if len(out.Records[1]) != 0 || out.Records[0]["component_fixture_marker"] != "original" {
		t.Fatal(out)
	}
	original, _ := json.Marshal(out)
	if _, e = wire(p, p, componentRecords{Marker: "later"}).Execute(ctx, a, app.Selection{2, 0, -1}, op()); e != nil {
		t.Fatal(e)
	}
	s.Records = app.UnavailableShowcaseRecords{}
	replay, e := s.Execute(ctx, a, q, first)
	got, _ := json.Marshal(replay)
	if e != nil || string(got) != string(original) {
		t.Fatal("replayreprojected", e, string(got))
	}
	lost := op()
	out, e = wire(p, faultDB{p, true}, componentRecords{Marker: "lostACK"}).Execute(ctx, a, app.Selection{1}, lost)
	if e != nil || out.Records[0]["component_fixture_marker"] != "lostACK" {
		t.Fatal("unknowncommitproof", out, e)
	}
	if _, e = wire(p, faultDB{p, false}, componentRecords{Marker: "rollbackACK"}).Execute(ctx, a, app.Selection{2}, op()); e == nil {
		t.Fatal("unknownabsencereexecuted", e)
	}
	if selection(t, p, a.PlayerID) != (app.Selection{1}) {
		t.Fatal("unknownrollbackmutated")
	}
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for _, v := range []app.Selection{{1}, {2}} {
		wg.Add(1)
		go func(v app.Selection) {
			defer wg.Done()
			_, e := wire(p, p, componentRecords{Marker: "race"}).Execute(ctx, a, v, op())
			errs <- e
		}(v)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
}
func Test6BCoherentCompositionPrivacyMetricsAndCurrentDetail(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b := profileActor(t, p), profileActor(t, p)
	s := composer(t, p)
	read := func(who identity.ActorContext, target identity.PlayerID, sub int16) (map[string]any, error) {
		return s.Read(ctx, who, app.ReadRequest{MID: 1829, Target: target, Subtype: sub}, op())
	}
	out, e := read(a, b.PlayerID, 0)
	if e != nil {
		t.Fatal(e)
	}
	info := out["player_info"].(map[string]any)
	if info["exp"] != int64(37) || info["guild_id"] != int64(0) {
		t.Fatal(out)
	}
	if _, present := root(t, p, b.PlayerID); present {
		t.Fatal("readmaterializedroot")
	}
	if out["show_case"].([6]map[string]any)[5] == nil {
		t.Fatal("missinghole")
	}
	choices, e := s.Read(ctx, a, app.ReadRequest{MID: 1840}, op())
	if e != nil {
		t.Fatal(e)
	}
	all := choices["all_show_types"].(map[string]int64)
	if len(all) != 1 || all["1011"] <= 0 {
		t.Fatal(choices)
	}
	// Future persisted choice cannot become a guessed zero.
	assign(t, p, b, app.Command{Kind: app.ShowCommand, Show: []int64{1011}}, op())
	out, e = read(a, b.PlayerID, 1)
	if e != nil || len(out["show_types"].(map[string]int64)) != 1 {
		t.Fatal(out, e)
	}
	sqlExec(t, p, `UPDATE player_public_profile_roots SET show_type_ids=ARRAY[1001]::bigint[] WHERE player_id=$1`, int64(b.PlayerID))
	if _, e = read(a, b.PlayerID, 1); e == nil {
		t.Fatal("unqualifiedselectedmetric")
	}
	sqlExec(t, p, `UPDATE player_public_profile_roots SET show_type_ids=ARRAY[1011]::bigint[] WHERE player_id=$1`, int64(b.PlayerID))
	if _, e = read(a, b.PlayerID, 2); !errors.Is(e, app.ErrProfileProvider) {
		t.Fatal("fakehistory", e)
	}
	if _, e = read(a, b.PlayerID, 6); e == nil {
		t.Fatal("otherSYSTEM")
	}
	if _, e = read(a, b.PlayerID, 5); e == nil {
		t.Fatal("HELPowner")
	}
	out, e = read(a, b.PlayerID, 4)
	if e != nil || out["comment_num"] != int64(0) {
		t.Fatal("SPACE genuineempty", out, e)
	}
	assign(t, p, b, app.Command{Kind: app.HideCommand, Hide: []int16{2, 4}}, op())
	if _, e = read(a, b.PlayerID, 4); e == nil {
		t.Fatal("hiddenSPACE")
	}
	if _, e = read(b, b.PlayerID, 4); e != nil {
		t.Fatal("ownhiddenSPACE", e)
	}
	assets(t, p, b, rev)
	set(t, p, b, app.Selection{1}, op())
	if _, e = read(a, b.PlayerID, 1); !errors.Is(e, app.ErrShowcaseUnavailable) {
		t.Fatal("minimumrichactivation", e)
	}
	s.Records = componentRecords{Marker: "componentonly"}
	detail, e := s.Read(ctx, a, app.ReadRequest{MID: 1838, Target: b.PlayerID, Index: 1}, op())
	if e != nil || fmt.Sprint(detail["partner_id"]) != "1" {
		t.Fatal(detail, e)
	}
	set(t, p, b, app.Selection{2}, op())
	detail, e = s.Read(ctx, a, app.ReadRequest{MID: 1838, Target: b.PlayerID, Index: 1}, op())
	if e != nil || fmt.Sprint(detail["partner_id"]) != "2" {
		t.Fatal("staleindex", detail, e)
	}
	for _, pair := range [][2]identity.PlayerID{{a.PlayerID, b.PlayerID}, {b.PlayerID, a.PlayerID}} {
		sqlExec(t, p, `INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,state_version,updated_at)VALUES($1,$2,1,true,clock_timestamp(),1,clock_timestamp()) ON CONFLICT(blocker_player_id,blocked_player_id) DO UPDATE SET active=true,removed_at=NULL,updated_at=clock_timestamp()`, int64(pair[0]), int64(pair[1]))
		out, e = read(a, b.PlayerID, 1)
		if e != nil || out["player_info"].(map[string]any)["exp"] != int64(37) {
			t.Fatal("blockedbasicEXP", out, e)
		}
		for _, k := range []string{"show_case", "show_types", "avatar_file_path", "praise_num", "intro"} {
			if _, yes := out[k]; yes {
				t.Fatal("blockleak", k)
			}
		}
		if out["is_in_blacklist"] != (pair[0] == a.PlayerID) {
			t.Fatal("directioncollapsed")
		}
		if _, e = s.Read(ctx, a, app.ReadRequest{MID: 1838, Target: b.PlayerID, Index: 1}, op()); e == nil {
			t.Fatal("blockdetail")
		}
		sqlExec(t, p, `UPDATE social_blocks SET active=false,removed_at=clock_timestamp(),updated_at=clock_timestamp() WHERE blocker_player_id=$1 AND blocked_player_id=$2`, int64(pair[0]), int64(pair[1]))
	}
	// Invalid isolation is rejected rather than inferred from bare Queryer.
	if _, e = s.ReadTx(ctx, tx.Scope{Tx: nil}, a, app.ReadRequest{MID: 1829, Target: b.PlayerID}, rev, at); e == nil {
		t.Fatal("unwitnessed")
	}
}
