//go:build postgres

package profilefeedback_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres/profilefeedbackstore"
	app "gxb.local/backend/v2/internal/application/profilefeedback"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"strconv"
	"testing"
	"time"
)

type commitHoldDB struct {
	tx.Beginner
	ready, release chan struct{}
	file           string
}
type commitHoldTx struct {
	tx.Tx
	db *commitHoldDB
}

func (d *commitHoldDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	v, e := d.Beginner.Begin(c, o)
	return &commitHoldTx{v, d}, e
}
func (t *commitHoldTx) Commit(c context.Context) error {
	if t.db.file != "" {
		if e := os.WriteFile(t.db.file, []byte("semantic-before-commit"), 0600); e != nil {
			return e
		}
	}
	if t.db.ready != nil {
		close(t.db.ready)
	}
	select {
	case <-t.db.release:
	case <-c.Done():
		return c.Err()
	}
	return t.Tx.Commit(c)
}
func TestCommentInflightLaneWaitsForOriginal(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	db := &commitHoldDB{Beginner: p, ready: make(chan struct{}), release: make(chan struct{})}
	s := app.CommentService{Base: service(p, db), Store: profilefeedbackstore.Store{}}
	fresh := app.CommentService{Base: service(p, p), Store: profilefeedbackstore.Store{}}
	q := app.CommentCommand{Kind: "post", Target: b.PlayerID, Content: "inflight"}
	done := make(chan error, 1)
	go func() { _, e := s.ExecuteComment(ctx, a, q, op()); done <- e }()
	select {
	case <-db.ready:
	case <-time.After(10 * time.Second):
		t.Fatal("no semantic commit barrier")
	}
	other := make(chan error, 1)
	go func() { _, e := fresh.ExecuteComment(ctx, a, q, op()); other <- e }()
	select {
	case e := <-other:
		close(db.release)
		t.Fatal("fresh request advanced while pending", e)
	case <-time.After(100 * time.Millisecond):
	}
	close(db.release)
	if e := <-done; e != nil {
		t.Fatal(e)
	}
	if e := <-other; e != nil {
		t.Fatal(e)
	}
	page, e := fresh.ListComments(ctx, b, b.PlayerID, app.PageRequest{Offset: 20}, op())
	if e != nil || page.Count != 2 {
		t.Fatal("resolved new occurrence", page, e)
	}
}
func TestCommentKilledTransactionHelper(t *testing.T) {
	file := os.Getenv("GXB_I7B4B_KILL_CHILD")
	if file == "" {
		t.Skip("killhelper")
	}
	p := pool(t)
	var payload struct {
		Actor     actorTransport
		Target    identity.PlayerID
		Operation operation.Context
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	if e = json.Unmarshal(raw, &payload); e != nil {
		t.Fatal(e)
	}
	db := &commitHoldDB{Beginner: p, file: file + ".ready", release: make(chan struct{})}
	s := app.CommentService{Base: service(p, db), Store: profilefeedbackstore.Store{}}
	_, e = s.ExecuteComment(ctx, decodeActor(t, payload.Actor), app.CommentCommand{Kind: "post", Target: payload.Target, Content: "killedtx"}, payload.Operation)
	if e != nil {
		t.Fatal(e)
	}
}
func TestCommentKilledProcessRollbackRecovery(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	old := op()
	raw, e := json.Marshal(struct {
		Actor     actorTransport
		Target    identity.PlayerID
		Operation operation.Context
	}{encodeActor(a), b.PlayerID, old})
	if e != nil {
		t.Fatal(e)
	}
	file := t.TempDir() + "/kill.json"
	if e = os.WriteFile(file, raw, 0600); e != nil {
		t.Fatal(e)
	}
	cmd := exec.Command(os.Args[0], "-test.run=^TestCommentKilledTransactionHelper$", "-test.v")
	cmd.Env = append(os.Environ(), "GXB_I7B4B_KILL_CHILD="+file)
	var output bytes.Buffer
	cmd.Stdout = &output
	cmd.Stderr = &output
	if e = cmd.Start(); e != nil {
		t.Fatal(e)
	}
	defer func() { _ = cmd.Process.Kill() }()
	ready := false
	for deadline := time.Now().Add(10 * time.Second); time.Now().Before(deadline); {
		if _, e = os.Stat(file + ".ready"); e == nil {
			ready = true
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	if !ready {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
		t.Fatalf("kill barrier %s", output.String())
	}
	_ = cmd.Process.Kill()
	if e = cmd.Wait(); e == nil {
		t.Fatal("child was not killed")
	}
	s := app.CommentService{Base: service(p, p), Store: profilefeedbackstore.Store{}}
	q := app.CommentCommand{Kind: "post", Target: b.PlayerID, Content: "killedtx"}
	if _, e = s.ExecuteComment(ctx, a, q, op()); e == nil {
		t.Fatal("advanced unresolved killedtx")
	}
	if _, e = s.ExecuteComment(ctx, a, q, old); e == nil {
		t.Fatal("retired killed identity restarted")
	}
	r := post(t, s, a, b.PlayerID, q.Content, op())
	if r.Current.Count != 1 {
		t.Fatal("killed rolled back gameplay", r)
	}
}
func TestCommentCorruptProofAndMissingAuthor(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	s := app.CommentService{Base: service(p, p), Store: profilefeedbackstore.Store{}}
	o := op()
	r := post(t, s, a, b.PlayerID, "proof", o)
	replay := s
	replay.Base.Timed.Binder.Time = fixedTime{r.Terminal.DecisionAt.Add(time.Second)}
	seen := post(t, replay, a, b.PlayerID, "proof", o)
	if !seen.Current.ObservedAt.After(r.Terminal.DecisionAt) || seen.Terminal != r.Terminal {
		t.Fatal("private vs current witness", seen)
	}
	sqlExec(t, p, `UPDATE gxb_operation_receipts SET result_payload=jsonb_set(result_payload,'{RootVersion}','0') WHERE domain='profile-feedback' AND operation='comment-post' AND semantic_key=$1`, o.ID.String())
	if _, e := s.ExecuteComment(ctx, a, app.CommentCommand{Kind: "post", Target: b.PlayerID, Content: "proof"}, o); e == nil {
		t.Fatal("corrupt proof accepted")
	}
	sqlExec(t, p, `DELETE FROM player_profiles WHERE player_id=$1`, int64(a.PlayerID))
	if _, e := s.ListComments(ctx, b, b.PlayerID, app.PageRequest{Offset: 20}, op()); e == nil {
		t.Fatal("missing author fabricated/dropped")
	}
	if _, e := s.ExecuteComment(ctx, b, app.CommentCommand{Kind: "delete", CommentID: r.Terminal.ID}, op()); e != nil {
		t.Fatal("owner empty-success delete requires missing author", e)
	}
	f, ok, e := s.Store.FindCommentTx(ctx, p, r.Terminal.ID, b.PlayerID)
	if e != nil || !ok || f.DeletedAt == nil {
		t.Fatal("tombstone", f, e)
	}
}
func TestCommentActualAPIProcess(t *testing.T) {
	binary := os.Getenv("GXB_I7B4B_API_BINARY")
	if binary == "" {
		t.Skip("final exact API binary required")
	}
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	_, bearer := token(t, p, a)
	_, ownerBearer := token(t, p, b)
	l, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	addr := l.Addr().String()
	l.Close()
	cmd := exec.Command(binary)
	cmd.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+nativeDSN(t), "GXB_HTTP_ADDR="+addr, "GXB_PUBLIC_ENGINE_URL=http://"+addr+"/engine", "GXB_REALTIME_PUBLIC_HOST=127.0.0.1", "GXB_REALTIME_PUBLIC_PORT=19001", "GXB_CREDENTIAL_DIGEST_SECRET=i7b2b-fixture-digest-key-00001", "GXB_GAMEPLAY_BEARER_SECRET=i7b2b-fixture-bearer-key-00001", "GXB_REDEEM_DIGEST_SECRET=i7b4b-fixture-redeem-key-00001", "GXB_DERIVATION_KEY_ID=i7b2b-native")
	var output bytes.Buffer
	cmd.Stdout = &output
	cmd.Stderr = &output
	if e = cmd.Start(); e != nil {
		t.Fatal(e)
	}
	defer func() { _ = cmd.Process.Signal(os.Interrupt); _ = cmd.Wait() }()
	send := func(raw string) (int, map[string]any, error) {
		resp, e := http.Post("http://"+addr+"/engine", "application/x-www-form-urlencoded", bytes.NewBufferString(url.Values{"payload": {raw}}.Encode()))
		if e != nil {
			return 0, nil, e
		}
		defer resp.Body.Close()
		var body map[string]any
		e = json.NewDecoder(resp.Body).Decode(&body)
		return resp.StatusCode, body, e
	}
	raw := fmt.Sprintf(`{"mid":1835,"token":%q,"region":1,"to_player_id":%d,"content":"wire"}`, bearer, b.PlayerID)
	var status int
	var body map[string]any
	for deadline := time.Now().Add(12 * time.Second); time.Now().Before(deadline); {
		status, body, e = send(raw)
		if e == nil {
			break
		}
		time.Sleep(25 * time.Millisecond)
	}
	if e != nil || status != 200 || body["comment_num"] != float64(1) {
		t.Fatalf("actual API %d %v %v %s", status, body, e, output.String())
	}
	best := body["best_comments"].([]any)
	row := best[0].(map[string]any)
	id := int64(row["comment_id"].(float64))
	if row["player_id"] != float64(b.PlayerID) || row["player_info"].(map[string]any)["player_id"] != float64(a.PlayerID) {
		t.Fatal("source owner/author", row)
	}
	status, body, e = send(fmt.Sprintf(`{"mid":1836,"token":%q,"region":1,"to_player_id":%d,"comment_id":%d}`, bearer, b.PlayerID, id))
	if e != nil || status != 200 || body["comment_info"].(map[string]any)["is_has_praise"] != float64(1) {
		t.Fatal("reactwire", status, body, e)
	}
	status, body, e = send(fmt.Sprintf(`{"mid":1839,"token":%q,"region":1,"to_player_id":%d,"start":0,"offset":20,"comment_num":999}`, bearer, b.PlayerID))
	if e != nil || status != 200 || body["comment_num"] != float64(1) || len(body["comment_list"].([]any)) != 0 {
		t.Fatal("listwire", status, body, e)
	}
	status, body, e = send(fmt.Sprintf(`{"mid":1841,"token":%q,"region":1,"comment_id":%d}`, ownerBearer, id))
	if e != nil || status != 200 || len(body) != 0 {
		t.Fatal("deletewire", status, body, e)
	}
	for _, bad := range []string{fmt.Sprintf(`{"mid":1841,"token":%q,"region":1,"comment_id":%d}`, ownerBearer, id), fmt.Sprintf(`{"mid":1835,"token":%q,"region":1,"to_player_id":%d,"content":"a","content":"b"}`, bearer, b.PlayerID), fmt.Sprintf(`{"mid":1839,"token":%q,"region":1,"to_player_id":%d,"start":0,"offset":2e1}`, bearer, b.PlayerID), fmt.Sprintf(`{"mid":1836,"token":%q,"region":2,"to_player_id":%d,"comment_id":%d}`, bearer, b.PlayerID, id)} {
		status, body, e = send(bad)
		if e != nil || status == 200 || body["comment_info"] != nil || body["comment_list"] != nil {
			t.Fatal("raw/freshfailure", status, body, e)
		}
	}
}
func TestCommentRestoreSeed(t *testing.T) {
	if os.Getenv("GXB_I7B4B_FINAL") != "1" {
		t.Skip("final restore seed")
	}
	p := pool(t)
	rev := installed(t, p)
	a, b := actor(t, p), actor(t, p)
	s := app.CommentService{Base: service(p, p), Store: profilefeedbackstore.Store{}}
	first := post(t, s, a, b.PlayerID, "restore-live", op())
	deleted := post(t, s, a, b.PlayerID, "restore-deleted", op())
	if _, e := s.ExecuteComment(ctx, b, app.CommentCommand{Kind: "delete", CommentID: deleted.Terminal.ID}, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := s.ExecuteComment(ctx, a, app.CommentCommand{Kind: "react", Target: b.PlayerID, CommentID: first.Terminal.ID}, op()); e != nil {
		t.Fatal(e)
	}
	pcy, e := s.Base.Content.ReadPublicProfilePolicy(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = s.AdmitPost(ctx, a, app.CommentCommand{Kind: "post", Target: b.PlayerID, Content: "restore-pending"}, op(), pcy); e != nil {
		t.Fatal(e)
	}
}
func TestCommentRestoredReload(t *testing.T) {
	if os.Getenv("GXB_I7B4B_RESTORED") != "1" {
		t.Skip("restore/restart gate")
	}
	p := pool(t)
	var id string
	state := "PENDING"
	e := p.QueryRow(ctx, `SELECT operation_id::text,state FROM player_profile_comment_operations WHERE admission_payload->'Command'->>'content'='restore-pending' ORDER BY (admission_payload->>'DecisionAt')::timestamptz DESC LIMIT 1`).Scan(&id, &state)
	if e != nil {
		t.Fatal(e)
	}
	store := profilefeedbackstore.Store{}
	j, ok, e := store.ReadAdmissionTx(ctx, p, id, false)
	if e != nil || !ok || j.State != state {
		t.Fatal("restored operation", e)
	}
	var tr actorTransport
	e = p.QueryRow(ctx, `SELECT a.account_id::text,g.session_id::text,g.context_id::text,a.account_uid,g.player_id,g.logical_server_id FROM gameplay_contexts g JOIN accounts a ON a.account_id=g.account_id WHERE g.context_id=$1::uuid`, j.Context).Scan(&tr.Account, &tr.Session, &tr.Context, &tr.UID, &tr.PlayerID, &tr.Server)
	if e != nil {
		t.Fatal(e)
	}
	actor := decodeActor(t, tr)
	s := app.CommentService{Base: service(p, p), Store: store}
	var liveOp string
	if e = p.QueryRow(ctx, `SELECT operation_id::text FROM player_profile_comment_operations WHERE actor_player_id=$1 AND admission_payload->'Command'->>'content'='restore-live' AND state='COMMITTED' ORDER BY operation_id LIMIT 1`, int64(actor.PlayerID)).Scan(&liveOp); e != nil {
		t.Fatal(e)
	}
	live, has, e := store.ReadAdmissionTx(ctx, p, liveOp, false)
	if e != nil || !has {
		t.Fatal(e)
	}
	known, e := s.ExecuteComment(ctx, actor, live.Command, live.Operation)
	if e != nil || known.Terminal.Content != "restore-live" {
		t.Fatal("retained exactpost receipt/policy", known, e)
	}
	var deadID int64
	if e = p.QueryRow(ctx, `SELECT comment_id FROM player_profile_comments WHERE target_player_id=$1 AND content='restore-deleted' AND deleted_at IS NOT NULL LIMIT 1`, int64(j.Target)).Scan(&deadID); e != nil {
		t.Fatal(e)
	}
	dead, has, e := store.FindCommentTx(ctx, p, deadID, actor.PlayerID)
	if e != nil || !has || dead.DeletedVersion == nil {
		t.Fatal("restoredtombstone", dead, e)
	}
	var high int64
	if e = p.QueryRow(ctx, `SELECT last_value FROM player_profile_comments_comment_id_seq`).Scan(&high); e != nil {
		t.Fatal(e)
	}
	if state == "PENDING" {
		if _, e = s.ExecuteComment(ctx, actor, j.Command, op()); e == nil {
			t.Fatal("restore pending advanced")
		}
		if _, e = s.ExecuteComment(ctx, actor, j.Command, j.Operation); e == nil {
			t.Fatal("restoredcancelledID")
		}
	}
	r := post(t, s, actor, j.Target, "restore-new"+strconv.FormatInt(high, 10), op())
	if r.Terminal.ID <= high {
		t.Fatal("restore allocator reuse", high, r.Terminal.ID)
	}
	page, e := s.ListComments(ctx, actor, j.Target, app.PageRequest{Offset: 20}, op())
	if e != nil || page.Count < 2 || page.RootVersion < r.Terminal.RootVersion {
		t.Fatal("restoredtypedview", e)
	}
}
