//go:build postgres

package profilefeedback_test

import (
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/profilefeedbackstore"
	app "gxb.local/backend/v2/internal/application/profilefeedback"
	pp "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/operation"
	"os"
	"os/exec"
	"strings"
	"sync"
	"testing"
	"time"
)

func post(t *testing.T, s app.CommentService, a identity.ActorContext, target identity.PlayerID, text string, o operation.Context) app.CommentResult {
	t.Helper()
	r, e := s.ExecuteComment(ctx, a, app.CommentCommand{Kind: "post", Target: target, Content: text}, o)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func TestCommentLifecyclePaging(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b, c := actor(t, p), actor(t, p), actor(t, p)
	s := app.CommentService{Base: service(p, p), Store: profilefeedbackstore.Store{}}
	empty, e := s.ListComments(ctx, b, b.PlayerID, app.PageRequest{Offset: 20}, op())
	if e != nil || empty.Count != 0 || empty.RootVersion != 0 || empty.Rows == nil || empty.Best == nil {
		t.Fatal("empty", empty, e)
	}
	if _, ok := root(t, p, b.PlayerID); ok {
		t.Fatal("readmaterialized")
	}
	known := op()
	first := post(t, s, a, b.PlayerID, "hello", known)
	same := post(t, s, a, b.PlayerID, "hello", known)
	fresh := post(t, s, a, b.PlayerID, "hello", op())
	if first.Terminal.ID != same.Terminal.ID || first.Terminal != same.Terminal || fresh.Terminal.ID <= first.Terminal.ID || fresh.Current.Count != 2 {
		t.Fatal("occurrences", first, same, fresh)
	}
	for i := 0; i < 24; i++ {
		post(t, s, a, b.PlayerID, fmt.Sprint("comment", i), op())
	}
	page, e := s.ListComments(ctx, c, b.PlayerID, app.PageRequest{Start: 0, Offset: 20}, op())
	if e != nil || page.Count != 26 || len(page.Best) != 2 || len(page.Rows) != 20 {
		t.Fatal("page", page, e)
	}
	for _, r := range append(page.Best, page.Rows...) {
		if r.Owner != b.PlayerID || r.Author.PlayerID != int64(a.PlayerID) || r.HasPraised != 0 {
			t.Fatal("owner-author", r)
		}
	}
	tail, e := s.ListComments(ctx, c, b.PlayerID, app.PageRequest{Start: 20, Offset: 20}, op())
	if e != nil || len(tail.Rows) != 4 {
		t.Fatal("ordinarytail", tail, e)
	}
	rq := app.CommentCommand{Kind: "react", Target: b.PlayerID, CommentID: first.Terminal.ID}
	r, e := s.ExecuteComment(ctx, c, rq, op())
	if e != nil || r.Affected == nil || r.Affected.HasPraised != 1 || r.Affected.PraiseCount != 1 || r.Current.Best[0].ID != first.Terminal.ID {
		t.Fatal("react", r, e)
	}
	v := r.Current.RootVersion
	r, e = s.ExecuteComment(ctx, c, rq, op())
	if e != nil || r.Terminal.Inserted || r.Current.RootVersion != v || r.Affected.PraiseCount != 1 {
		t.Fatal("repeatreact", r, e)
	}
	if _, e = s.ExecuteComment(ctx, a, app.CommentCommand{Kind: "delete", CommentID: first.Terminal.ID}, op()); e == nil {
		t.Fatal("author deleted other's card")
	}
	delop := op()
	dq := app.CommentCommand{Kind: "delete", CommentID: first.Terminal.ID}
	removed, e := s.ExecuteComment(ctx, b, dq, delop)
	if e != nil || removed.Current.Count != 25 {
		t.Fatal("delete", removed, e)
	}
	if _, e = s.ExecuteComment(ctx, b, dq, op()); e == nil {
		t.Fatal("fresh deleted success decrements twice")
	}
	replay, e := s.ExecuteComment(ctx, b, dq, delop)
	if e != nil || replay.Terminal != removed.Terminal {
		t.Fatal("privateknown delete", e)
	}
	fact, ok, e := (profilefeedbackstore.Store{}).FindCommentTx(ctx, p, first.Terminal.ID, c.PlayerID)
	if e != nil || !ok || fact.DeletedAt == nil || fact.PraiseCount != 1 {
		t.Fatal("retained", fact, e)
	}
	if _, e = s.ExecuteComment(ctx, c, rq, op()); e == nil {
		t.Fatal("deleted reacted")
	}
	changed := known
	changed.EntropySeed[0]++
	if _, e = s.ExecuteComment(ctx, a, app.CommentCommand{Kind: "post", Target: b.PlayerID, Content: "hello"}, changed); !errors.Is(e, app.ErrConflict) {
		t.Fatal("entropy", e)
	}
	if _, e = s.ExecuteComment(ctx, a, app.CommentCommand{Kind: "post", Target: b.PlayerID, Content: "different"}, known); !errors.Is(e, app.ErrConflict) {
		t.Fatal("fp", e)
	}
}
func TestCommentScalarAndPrivacy(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b, c := actor(t, p), actor(t, p), actor(t, p)
	s := app.CommentService{Base: service(p, p), Store: profilefeedbackstore.Store{}}
	if _, e := d.ModerateComment(strings.Repeat("界", 30), nil); e != nil {
		t.Fatal(e)
	}
	for _, text := range []string{"", strings.Repeat("界", 31), "a\x00b", string([]byte{0xff})} {
		if _, e := d.ModerateComment(text, nil); e == nil {
			t.Fatal("badscalar admitted")
		}
	}
	text, e := d.ModerateComment("a b c", []string{"abc"})
	if e != nil || text != "*****" {
		t.Fatal("reuse moderation", text, e)
	}
	if _, e = s.ExecuteComment(ctx, a, app.CommentCommand{Kind: "post", Target: a.PlayerID, Content: "self"}, op()); e == nil {
		t.Fatal("self")
	}
	pref := pp.CommandService{Timed: s.Base.Timed, Reads: s.Base.Reads, Fresh: p, Roots: s.Base.Basic.Roots, Players: s.Base.Basic.Players, Fence: s.Base.Basic.Fence, Receipts: s.Base.Receipts, Content: s.Base.Content, Metrics: pp.CanonicalCreationMetricProvider{Players: i5store.Store{}}}
	if _, e = pref.Execute(ctx, b, pp.Command{Kind: pp.HideCommand, Hide: []int16{4}}, op()); e != nil {
		t.Fatal(e)
	}
	if _, e = s.ExecuteComment(ctx, a, app.CommentCommand{Kind: "post", Target: b.PlayerID, Content: "hidden"}, op()); e == nil {
		t.Fatal("hide bypass")
	}
	if _, e = s.ListComments(ctx, a, b.PlayerID, app.PageRequest{Offset: 20}, op()); e == nil {
		t.Fatal("hiddenread")
	}
	if _, e = s.ListComments(ctx, b, b.PlayerID, app.PageRequest{Offset: 20}, op()); e != nil {
		t.Fatal("ownhidden", e)
	}
	if _, e = pref.Execute(ctx, b, pp.Command{Kind: pp.HideCommand, Hide: []int16{}}, op()); e != nil {
		t.Fatal(e)
	}
	first := post(t, s, a, b.PlayerID, "normal", op())
	if _, e = s.ExecuteComment(ctx, c, app.CommentCommand{Kind: "react", Target: a.PlayerID, CommentID: first.Terminal.ID}, op()); e == nil {
		t.Fatal("forgedtarget")
	}
	// Reuse the accepted native Social fixtures and exact owner schema.
	socialRoot(t, p, a)
	socialRoot(t, p, b)
	for _, pair := range [][2]identity.PlayerID{{a.PlayerID, b.PlayerID}, {b.PlayerID, a.PlayerID}} {
		sqlExec(t, p, `INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,state_version,updated_at)VALUES($1,$2,1,true,clock_timestamp(),1,clock_timestamp())`, int64(pair[0]), int64(pair[1]))
		if _, e = s.ListComments(ctx, a, b.PlayerID, app.PageRequest{Offset: 20}, op()); e == nil {
			t.Fatal("blockread", pair)
		}
		sqlExec(t, p, `DELETE FROM social_blocks WHERE blocker_player_id=$1 AND blocked_player_id=$2`, int64(pair[0]), int64(pair[1]))
	}
	_ = rev
}
func TestCommentPendingTerminalFenceAndUnknown(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b := actor(t, p), actor(t, p)
	s := app.CommentService{Base: service(p, p), Store: profilefeedbackstore.Store{}}
	policy, e := s.Base.Content.ReadPublicProfilePolicy(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	q := app.CommentCommand{Kind: "post", Target: b.PlayerID, Content: "pending"}
	old := op()
	j, e := s.AdmitPost(ctx, a, q, old, policy)
	if e != nil || j.State != "PENDING" {
		t.Fatal("admission", j, e)
	}
	if _, e = s.ExecuteComment(ctx, a, q, op()); e == nil {
		t.Fatal("unresolved allowed new occurrence")
	}
	j, ok, e := s.Store.ReadAdmissionTx(ctx, p, old.ID.String(), false)
	if e != nil || !ok || j.State != "ABORTED" {
		t.Fatal("terminalfence", j, e)
	}
	if _, e = s.ExecuteComment(ctx, a, q, old); e == nil {
		t.Fatal("delayedcancelled body settled")
	}
	post(t, s, a, b.PlayerID, "pending", op())
	// Only the semantic transaction loses ACK; admission remains genuine.
	ack := s
	ack.Base.Timed.Runner.DB = faultDB{Beginner: p, commit: true}
	o := op()
	r, e := ack.ExecuteComment(ctx, a, q, o)
	if e != nil || r.Current.Count != 2 {
		t.Fatal("knownACK", r, e)
	}
	again, e := s.ExecuteComment(ctx, a, q, o)
	if e != nil || again.Terminal != r.Terminal || again.Current.Count != 2 {
		t.Fatal("ACKreplay", again, e)
	}
	miss := s
	miss.Base.Timed.Runner.DB = faultDB{Beginner: p, commit: false}
	unknown := op()
	if _, e = miss.ExecuteComment(ctx, a, q, unknown); e == nil {
		t.Fatal("unknownmisssuccess")
	}
	if _, e = s.ExecuteComment(ctx, a, q, unknown); e == nil {
		t.Fatal("knownunknown blindresubmit")
	}
	j, ok, e = s.Store.ReadAdmissionTx(ctx, p, unknown.ID.String(), false)
	if e != nil || !ok || j.State != "ABORTED" {
		t.Fatal("unknownterminal", e)
	}
	next := post(t, s, a, b.PlayerID, "pending", op())
	if next.Current.Count != 3 {
		t.Fatal("negative fence duplication", next)
	}
}
func TestCommentConcurrencySharedPraiseRoot(t *testing.T) {
	p := pool(t)
	installed(t, p)
	b := actor(t, p)
	s := app.CommentService{Base: service(p, p), Store: profilefeedbackstore.Store{}}
	actors := make([]identity.ActorContext, 8)
	for i := range actors {
		actors[i] = actor(t, p)
	}
	var wg sync.WaitGroup
	errs := make(chan error, 16)
	for _, a := range actors {
		wg.Add(2)
		go func(a identity.ActorContext) {
			defer wg.Done()
			_, e := s.ExecuteComment(ctx, a, app.CommentCommand{Kind: "post", Target: b.PlayerID, Content: "race"}, op())
			errs <- e
		}(a)
		go func(a identity.ActorContext) {
			defer wg.Done()
			_, e := s.Base.Execute(ctx, a, app.Command{Target: b.PlayerID}, op())
			errs <- e
		}(a)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal("race", e)
		}
	}
	page, e := s.ListComments(ctx, b, b.PlayerID, app.PageRequest{Offset: 20}, op())
	if e != nil || page.Count != 8 || page.RootVersion != 16 {
		t.Fatal("sharedroot", page, e)
	}
	praisePage, e := s.Base.List(ctx, b, app.PageRequest{Offset: 20}, op())
	if e != nil || praisePage.Current.Count != 8 || praisePage.Current.RootVersion != 16 {
		t.Fatal("praisepreserved", e)
	}
}
func TestCommentProcessPendingHelper(t *testing.T) {
	file := os.Getenv("GXB_I7B4B_PENDING_CHILD")
	if file == "" {
		t.Skip("processhelper")
	}
	p := pool(t)
	var payload struct {
		Actor     actorTransport
		Target    identity.PlayerID
		Operation operation.Context
		Revision  string
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	if e = json.Unmarshal(raw, &payload); e != nil {
		t.Fatal(e)
	}
	s := app.CommentService{Base: service(p, p), Store: profilefeedbackstore.Store{}}
	policy, e := s.Base.Content.ReadPublicProfilePolicy(ctx, p, payload.Revision)
	if e != nil {
		t.Fatal(e)
	}
	_, e = s.AdmitPost(ctx, decodeActor(t, payload.Actor), app.CommentCommand{Kind: "post", Target: payload.Target, Content: "processpending"}, payload.Operation, policy)
	if e != nil {
		t.Fatal(e)
	}
}
func TestCommentIndependentProcessPendingRecovery(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b := actor(t, p), actor(t, p)
	old := op()
	payload := struct {
		Actor     actorTransport
		Target    identity.PlayerID
		Operation operation.Context
		Revision  string
	}{encodeActor(a), b.PlayerID, old, rev}
	raw, e := json.Marshal(payload)
	if e != nil {
		t.Fatal(e)
	}
	file := t.TempDir() + "/pending.json"
	if e = os.WriteFile(file, raw, 0600); e != nil {
		t.Fatal(e)
	}
	cmd := exec.Command(os.Args[0], "-test.run=^TestCommentProcessPendingHelper$", "-test.v")
	cmd.Env = append(os.Environ(), "GXB_I7B4B_PENDING_CHILD="+file)
	out, e := cmd.CombinedOutput()
	if e != nil {
		t.Fatalf("child %s %v", out, e)
	}
	s := app.CommentService{Base: service(p, p), Store: profilefeedbackstore.Store{}}
	q := app.CommentCommand{Kind: "post", Target: b.PlayerID, Content: "processpending"}
	if _, e = s.ExecuteComment(ctx, a, q, op()); e == nil {
		t.Fatal("reconnect admitted unresolved")
	}
	if _, e = s.ExecuteComment(ctx, a, q, old); e == nil {
		t.Fatal("cancelledprioridentity")
	}
	r := post(t, s, a, b.PlayerID, q.Content, op())
	if r.Current.Count != 1 {
		t.Fatal("processrecovery", r)
	}
}
func TestCommentDefiniteAbortStableTime(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	once := &abortOnceDB{Beginner: p}
	s := app.CommentService{Base: service(p, once), Store: profilefeedbackstore.Store{}}
	ct := &countingTime{inner: s.Base.Timed.Binder.Time}
	s.Base.Timed.Binder.Time = ct
	r := post(t, s, a, b.PlayerID, "retry", op())
	if !r.Terminal.DecisionAt.Equal(r.Terminal.CreatedAt) || ct.calls.Load() != 1 || r.Current.Count != 1 {
		t.Fatal("stable", r, ct.calls.Load())
	}
	if r.Terminal.DecisionAt.After(time.Now().Add(time.Second)) {
		t.Fatal("time")
	}
}
