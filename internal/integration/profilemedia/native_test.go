//go:build postgres && linux

package profilemedia_test

import (
	"bytes"
	"context"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	port "gxb.local/backend/v2/internal/application/profileasset"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
	"image"
	"image/color"
	"image/png"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"sync"
	"testing"
	"time"
)

func pngBytes(t *testing.T, n uint8) []byte {
	t.Helper()
	im := image.NewRGBA(image.Rect(0, 0, 150, 150))
	for i := range im.Pix {
		im.Pix[i] = n
	}
	im.Set(0, 0, color.RGBA{n, 8, 9, 255})
	var b bytes.Buffer
	if e := png.Encode(&b, im); e != nil {
		t.Fatal(e)
	}
	return b.Bytes()
}
func blobs(t *testing.T) *blobstore.Local {
	t.Helper()
	root := os.Getenv("GXB_I7B5B_ASSET_ROOT")
	if root == "" {
		t.Fatal("required owned shared media root missing")
	}
	b, e := blobstore.NewLocal(root)
	if e != nil {
		t.Fatal(e)
	}
	return b
}
func mediaService(p *pg.Pool, db tx.Beginner, b *blobstore.Local) app.MediaService {
	u, _ := app.NewMediaURL("http://127.0.0.1:18080")
	return app.MediaService{Commands: service(p, db), Media: publicprofilestore.Store{}, Blobs: b, URLs: u}
}
func maintenance(s app.MediaService) app.MediaMaintenance {
	return app.MediaMaintenance{Service: s, Receipts: kernelstore.Store{}}
}
func publish(t *testing.T, s app.MediaService, a identity.ActorContext, raw []byte, o operation.Context) (app.MediaResult, error) {
	t.Helper()
	p, e := s.Blobs.Prepare(ctx, bytes.NewReader(raw), asset.Reservation{Operation: o.ID, Actor: a.PlayerID, Server: a.LogicalServerID})
	if e != nil {
		return app.MediaResult{}, e
	}
	d, e := p.Descriptor()
	if e != nil {
		t.Fatal(e)
	}
	r, e, cleanup := s.Publish(ctx, a, d, p, o)
	if cleanup != nil {
		t.Fatal("cleanup", cleanup)
	}
	return r, e
}
func upload(t *testing.T, s app.MediaService, a identity.ActorContext, raw []byte, o operation.Context) app.MediaResult {
	t.Helper()
	r, e := publish(t, s, a, raw, o)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func current(t *testing.T, p *pg.Pool, a identity.ActorContext) app.MediaHistory {
	t.Helper()
	h, ok, e := (publicprofilestore.Store{}).ReadCurrentMediaTx(ctx, p, a.PlayerID)
	if e != nil || !ok {
		t.Fatal("current", e)
	}
	return h
}
func countPins(t *testing.T, b *blobstore.Local) int {
	t.Helper()
	n := 0
	if e := b.WithMaintenance(ctx, func(m port.Maintenance) error { return m.Inventory(nil, func(asset.Pin) error { n++; return nil }) }); e != nil {
		t.Fatal(e)
	}
	return n
}
func TestMediaAssignmentReplayAndNoop(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	b := blobs(t)
	s := mediaService(p, p, b)
	pinsBefore := countPins(t, b)
	o := op()
	one := upload(t, s, a, pngBytes(t, 20), o)
	if one.History.RootVersion != 1 || one.History.Reference.Asset.MD5 == "" || countPins(t, b) != pinsBefore {
		t.Fatal("initialversion/protection")
	}
	same := upload(t, s, a, pngBytes(t, 20), op())
	if same.History.RootVersion != 1 || same.History.Reference != one.History.Reference || current(t, p, a).Operation != o.ID {
		t.Fatal("identicalbytes changedcanonicalstate")
	}
	two := upload(t, s, a, pngBytes(t, 21), op())
	if two.History.RootVersion != 2 || two.History.Reference.URL == one.History.Reference.URL {
		t.Fatal("replacement/version")
	}
	replay, e, cleanup := s.Publish(ctx, a, one.History.Reference.Asset, nil, o)
	if e != nil || cleanup != nil || replay != one || current(t, p, a).Operation != two.History.Operation {
		t.Fatal("oldknownop resetcurrent", e)
	}
	wrong := one.History.Reference.Asset
	wrong.MD5 = "00000000000000000000000000000000"
	if _, e, _ := s.Publish(ctx, a, wrong, nil, o); e == nil {
		t.Fatal("fingerprintconflictaccepted")
	}
	if e = maintenance(s).Validate(ctx); e != nil {
		t.Fatal("jointreachability", e)
	}
	sqlExec(t, p, `UPDATE account_sessions SET revoked_at=clock_timestamp(),revocation_reason='5b' WHERE session_id=$1`, a.SessionID.UUID().String())
	if _, e, _ := s.Publish(ctx, a, one.History.Reference.Asset, nil, o); e == nil {
		t.Fatal("revokedknownop bypass")
	}
}

type faultDB struct {
	tx.Beginner
	commit bool
}
type faultTx struct {
	tx.Tx
	commit bool
}

func (d faultDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return faultTx{t, d.commit}, nil
}
func (t faultTx) Commit(c context.Context) error {
	if t.commit {
		if e := t.Tx.Commit(c); e != nil {
			return e
		}
	} else {
		_ = t.Tx.Rollback(c)
	}
	return errors.New("injected ACK loss")
}
func TestMediaUnknownCommitPinsAndGC(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	b := blobs(t)
	s := mediaService(p, p, b)
	// The shared root may hold pins from an earlier run; drain its garbage so the counts below are this test's own.
	drained, e := maintenance(s).Collect(ctx)
	if e != nil {
		t.Fatal(e)
	}
	pinsBefore := countPins(t, b)
	original := upload(t, mediaService(p, faultDB{p, true}, b), a, pngBytes(t, 31), op())
	if original.History.RootVersion != 1 {
		t.Fatal("positiveACKloss")
	}
	unknown := op()
	if r, e := publish(t, mediaService(p, faultDB{p, false}, b), a, pngBytes(t, 32), unknown); e == nil || r.Schema != "" {
		t.Fatal("unknownsuccess leaked")
	}
	if countPins(t, b) != pinsBefore+1 {
		t.Fatal("unknownpin lost")
	}
	abortedOp := op()
	pr, e := b.Prepare(ctx, bytes.NewReader(pngBytes(t, 33)), asset.Reservation{Operation: abortedOp.ID, Actor: a.PlayerID, Server: a.LogicalServerID})
	if e != nil {
		t.Fatal(e)
	}
	if e = pr.Close(asset.DefiniteAbort); e != nil {
		t.Fatal(e)
	}
	result, e := maintenance(s).Collect(ctx)
	if e != nil || result.Deleted != 1 || result.UnknownPins != drained.UnknownPins+1 || countPins(t, b) != pinsBefore+1 {
		t.Fatal("GCreachability", result, e)
	}
	if current(t, p, a).Operation != original.History.Operation {
		t.Fatal("unknownreboundcurrent")
	}
}

type fixedTime struct{ at time.Time }

func (f fixedTime) Now(context.Context) (time.Time, error) { return f.at, nil }
func TestMediaStableTimeAndConcurrentAssignments(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	b := blobs(t)
	s := mediaService(p, p, b)
	first := upload(t, s, a, pngBytes(t, 40), op())
	stale := s
	stale.Commands.Timed.Binder.Time = fixedTime{first.History.DecisionAt.Add(-time.Second)}
	if _, e := publish(t, stale, a, pngBytes(t, 41), op()); e == nil {
		t.Fatal("staleDecisionAtclamped")
	}
	if current(t, p, a).Operation != first.History.Operation {
		t.Fatal("stalechangedcurrent")
	}
	var wg sync.WaitGroup
	results := make(chan app.MediaResult, 6)
	errs := make(chan error, 6)
	for i := 0; i < 6; i++ {
		raw := pngBytes(t, uint8(50+i))
		wg.Add(1)
		go func(raw []byte) {
			defer wg.Done()
			r, e := publish(t, s, a, raw, op())
			if e != nil {
				errs <- e
			} else {
				results <- r
			}
		}(raw)
	}
	wg.Wait()
	close(results)
	close(errs)
	committed := 0
	var highest int64
	for r := range results {
		committed++
		if r.History.RootVersion > highest {
			highest = r.History.RootVersion
		}
	}
	for e := range errs {
		if !errors.Is(e, app.ErrInvalidState) && tx.SQLState(e) != "40001" {
			t.Fatal("unexpectedraceerror", e)
		}
	}
	if committed == 0 || current(t, p, a).RootVersion != highest || highest != int64(1+committed) {
		t.Fatal("canonicalversions", committed, highest)
	}
	if e := maintenance(s).Validate(ctx); e != nil {
		t.Fatal(e)
	}
}
func multipartRequest(t *testing.T, endpoint, token string, raw []byte, extras map[string]string) (*http.Response, error) {
	t.Helper()
	var b bytes.Buffer
	w := multipart.NewWriter(&b)
	fields := map[string]string{"mid": "1844", "token": token, "region": "1", "v_": "1", "form_name": "avatar", "file_path": "/untrusted/cache.png", "file_name": "not-authority.jpg", "md5_code": "untrusted"}
	for k, v := range extras {
		fields[k] = v
	}
	for k, v := range fields {
		if e := w.WriteField(k, v); e != nil {
			t.Fatal(e)
		}
	}
	f, e := w.CreateFormFile(fields["form_name"], "untrusted.jpg")
	if e != nil {
		t.Fatal(e)
	}
	if _, e = f.Write(raw); e != nil {
		t.Fatal(e)
	}
	w.Close()
	return http.Post(endpoint, w.FormDataContentType(), &b)
}
func TestMediaHTTPMultipartGETAndFailures(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	b := blobs(t)
	s := mediaService(p, p, b)
	authority, bearer := token(t, p, a)
	router := httpedge.NewRouter()
	if e := router.Register(1844, stockruntime.ProfileMediaDispatcher{Authority: authority, Service: s}); e != nil {
		t.Fatal(e)
	}
	adm, _ := httpedge.NewAdmission(32)
	mux := http.NewServeMux()
	mux.Handle("/engine", httpedge.Handler{Limits: limits.Default(), Admission: adm, Operations: operation.Factory{Clock: clock.System{}}, Router: router})
	mux.Handle("/profile-media/", stockruntime.ProfileMediaGET{Service: s})
	server := httptest.NewUnstartedServer(mux)
	s.URLs, _ = app.NewMediaURL("http://" + server.Listener.Addr().String())
	router = httpedge.NewRouter()
	_ = router.Register(1844, stockruntime.ProfileMediaDispatcher{Authority: authority, Service: s})
	mux = http.NewServeMux()
	mux.Handle("/engine", httpedge.Handler{Limits: limits.Default(), Admission: adm, Operations: operation.Factory{Clock: clock.System{}}, Router: router})
	mux.Handle("/profile-media/", stockruntime.ProfileMediaGET{Service: s})
	server.Config.Handler = mux
	server.Start()
	defer server.Close()
	raw := pngBytes(t, 62)
	resp, e := multipartRequest(t, server.URL+"/engine", bearer, raw, nil)
	if e != nil {
		t.Fatal(e)
	}
	var body map[string]any
	if e = json.NewDecoder(resp.Body).Decode(&body); e != nil {
		t.Fatal(e)
	}
	resp.Body.Close()
	if resp.StatusCode != 200 {
		t.Fatal("uploadwire", resp.StatusCode, body)
	}
	digest := md5.Sum(raw)
	if body["avatar_md5_code"] != hex.EncodeToString(digest[:]) {
		t.Fatal("MD5notactualbytes")
	}
	path, ok := body["avatar_file_path"].(string)
	if !ok {
		t.Fatal("missingURL")
	}
	resp, e = http.Get(path)
	if e != nil {
		t.Fatal(e)
	}
	got, e := io.ReadAll(resp.Body)
	resp.Body.Close()
	if e != nil || resp.StatusCode != 200 || !bytes.Equal(raw, got) || resp.Header.Get("Content-Type") != "image/png" {
		t.Fatal("GETbyteidentity", e)
	}
	for _, q := range []struct {
		raw   []byte
		extra map[string]string
		tok   string
	}{{[]byte("bad png"), nil, bearer}, {raw, map[string]string{"region": "2"}, bearer}, {raw, map[string]string{"to_player_id": "123"}, bearer}, {raw, nil, "bad"}} {
		resp, e = multipartRequest(t, server.URL+"/engine", q.tok, q.raw, q.extra)
		if e != nil {
			t.Fatal(e)
		}
		resp.Body.Close()
		if resp.StatusCode == 200 {
			t.Fatal("invalidsuccess")
		}
	}
	h := current(t, p, a)
	if h.RootVersion != 1 {
		t.Fatal("failure mutatedref")
	}
	// GET refuses uncommitted/forged capabilities and missing bytes, rather than
	// silently synthesizing a default. Detailed missing/corrupt restore is separate.
	resp, e = http.Get(server.URL + "/profile-media/" + uuid().String() + "/" + h.Reference.Asset.SHA256 + ".png")
	if e != nil {
		t.Fatal(e)
	}
	resp.Body.Close()
	if resp.StatusCode != 404 {
		t.Fatal("uncommittedcapability")
	}
}

type failReceipt struct{ receipt.Store }

func (f failReceipt) PutTx(context.Context, tx.Tx, receipt.Receipt) (receipt.PutResult, error) {
	return receipt.PutResult{}, errors.New("injected receipt write failure")
}
func TestMediaReferenceReceiptAtomicAbort(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	b := blobs(t)
	s := mediaService(p, p, b)
	first := upload(t, s, a, pngBytes(t, 101), op())
	broken := s
	broken.Commands.Receipts = failReceipt{s.Commands.Receipts}
	o := op()
	if r, e := publish(t, broken, a, pngBytes(t, 102), o); e == nil || r.Schema != "" {
		t.Fatal("receiptfailure successleak")
	}
	if current(t, p, a) != first.History {
		t.Fatal("partiallycommittedreference")
	}
	if _, ok, e := s.Media.ReadMediaHistoryTx(ctx, p, o.ID); e != nil || ok {
		t.Fatal("abortedhistoryretained", e)
	}
	r, e := maintenance(s).Collect(ctx)
	if e != nil || r.Deleted < 1 {
		t.Fatal("definiteabort safeorphan", r, e)
	}
}
