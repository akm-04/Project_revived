//go:build postgres && river

package playerdisplay_test

import (
	"bytes"
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/characterpet"
	gen "gxb.local/backend/v2/internal/application/generation"
	profile "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"image"
	"image/png"
	"io"
	"mime/multipart"
	"net"
	"net/http"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

type profileBases struct {
	characterhero.BaseObservationReader
	Pet characterpet.BaseObservationReader
}

func (b profileBases) PetBaseObservationTx(c context.Context, q tx.Queryer, pid identity.PlayerID, id int64) (characterasset.PetBaseObservation, error) {
	return b.Pet.PetBaseObservationTx(c, q, pid, id)
}
func profileWire(p *pg.Pool) profile.ShowcaseWireService {
	r := tx.Runner{DB: p}
	content := contentstore.Store{}
	return profile.ShowcaseWireService{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Reads: r, Fresh: p, Roots: profile.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, Receipts: kernelstore.Store{}, Content: content, Slots: publicprofilestore.Store{}, References: characterstore.Store{}, Bases: profileBases{characterhero.BaseObservationReader{Store: characterstore.Store{}, Content: content}, characterpet.BaseObservationReader{Store: characterstore.Store{}}}, Records: profile.UnavailableShowcaseRecords{}}
}
func Test6BActualAPICompositionMediaPrivacyAndWireRecovery(t *testing.T) {
	binary := os.Getenv("GXB_I7B6B_API_BINARY")
	if binary == "" {
		t.Fatal("exact6Bbinaryrequired")
	}
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	token := displayToken(t, p, a)
	other := displayToken(t, p, b)
	original := op()
	out, e := profileWire(p).Execute(ctx, a, profile.Selection{}, original)
	if e != nil {
		t.Fatal(e)
	}
	originalBytes, _ := json.Marshal(out)
	listener, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	addr := listener.Addr().String()
	listener.Close()
	origin := "http://" + addr
	dsn := os.Getenv("GXB_I7B6A_DSN")
	assets := filepath.Join(t.TempDir(), "private-media")
	if _, e = blobstore.NewLocal(assets); e != nil {
		t.Fatal(e)
	}
	var cmd *osexec.Cmd
	stop := func() {
		if cmd != nil {
			cmd.Process.Signal(os.Interrupt)
			cmd.Wait()
			cmd = nil
		}
	}
	defer stop()
	start := func() {
		cmd = osexec.Command(binary)
		cmd.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+dsn, "GXB_HTTP_ADDR="+addr, "GXB_PUBLIC_ENGINE_URL="+origin+"/engine", "GXB_REALTIME_PUBLIC_HOST=127.0.0.1", "GXB_REALTIME_PUBLIC_PORT=19001", "GXB_CREDENTIAL_DIGEST_SECRET=i7b2b-fixture-digest-key-00001", "GXB_GAMEPLAY_BEARER_SECRET=i7b2b-fixture-bearer-key-00001", "GXB_REDEEM_DIGEST_SECRET=i7b5b-fixture-redeem-key-00001", "GXB_DERIVATION_KEY_ID=i7b2b-native", "GXB_PROFILE_MEDIA_ROOT="+assets, "GXB_PROFILE_MEDIA_PUBLIC_ORIGIN="+origin)
		log, e := os.CreateTemp(t.TempDir(), "api6b-log")
		if e != nil {
			t.Fatal(e)
		}
		defer log.Close()
		cmd.Stdout = log
		cmd.Stderr = log
		if e = cmd.Start(); e != nil {
			t.Fatal(e)
		}
		for end := time.Now().Add(10 * time.Second); time.Now().Before(end); {
			resp, e := http.Get(origin + "/profile-media/missing")
			if e == nil {
				resp.Body.Close()
				return
			}
			time.Sleep(30 * time.Millisecond)
		}
		stop()
		raw, _ := os.ReadFile(log.Name())
		t.Fatal("APIstartup", string(raw))
	}
	post := func(tok string, mid int, fields map[string]any) (int, map[string]any) {
		fields["mid"] = mid
		fields["token"] = tok
		fields["region"] = 1
		raw, _ := json.Marshal(fields)
		resp, e := http.Post(origin+"/engine", "application/x-www-form-urlencoded", bytes.NewBufferString(url.Values{"payload": {string(raw)}}.Encode()))
		if e != nil {
			t.Fatal(e)
		}
		defer resp.Body.Close()
		var v map[string]any
		if e = json.NewDecoder(resp.Body).Decode(&v); e != nil {
			t.Fatal(e)
		}
		return resp.StatusCode, v
	}
	start()
	code, v := post(token, 1829, map[string]any{"to_player_id": int64(b.PlayerID)})
	if code != 200 || v["player_info"].(map[string]any)["exp"] != float64(37) || len(v["show_case"].([]any)) != 6 {
		t.Fatal("MAIN", code, v)
	}
	code, v = post(token, 1840, map[string]any{})
	if code != 200 || len(v["all_show_types"].(map[string]any)) != 1 || v["all_show_types"].(map[string]any)["1011"] == nil {
		t.Fatal("qualifiedmetrics", code, v)
	}
	for _, sub := range []int{2, 3, 5, 6} {
		if code, v = post(token, 1829, map[string]any{"to_player_id": int64(b.PlayerID), "sub_type": sub}); code == 200 {
			t.Fatal("unavailable/private/local subtype succeeded", sub, v)
		}
	}
	code, v = post(token, 1829, map[string]any{"to_player_id": int64(b.PlayerID), "sub_type": 4})
	if code != 200 || len(v["comment_list"].([]any)) != 0 {
		t.Fatal("SPACE", code, v)
	}
	for _, fields := range []map[string]any{{"to_player_id": int64(b.PlayerID), "index": 0}, {"to_player_id": int64(b.PlayerID), "index": 1}} {
		if code, v = post(token, 1838, fields); code == 200 {
			t.Fatal("emptydetail fabricated", v)
		}
	}
	code, v = post(token, 1832, map[string]any{"hero_ids": []int{0, 0, 0, 0, 0, 0}})
	if code != 200 || len(v["show_case"].([]any)) != 6 {
		t.Fatal("emptywire", code, v)
	}
	if code, v = post(token, 1832, map[string]any{"hero_ids": []int{0, 0, 0, 0, 0, 0}, "to_player_id": int64(b.PlayerID)}); code == 200 {
		t.Fatal("forgedactor", v)
	}
	// Actual immutable media capability; new composition controls discovery only.
	var imageBytes bytes.Buffer
	if e = png.Encode(&imageBytes, image.NewNRGBA(image.Rect(0, 0, 2, 2))); e != nil {
		t.Fatal(e)
	}
	var body bytes.Buffer
	multi := multipart.NewWriter(&body)
	for k, v := range map[string]string{"mid": "1844", "token": other, "region": "1", "v_": "1", "form_name": "avatar", "file_path": "/client/cache.png", "file_name": "hint.jpg", "md5_code": "untrusted"} {
		if e = multi.WriteField(k, v); e != nil {
			t.Fatal(e)
		}
	}
	file, e := multi.CreateFormFile("avatar", "hint.jpg")
	if e != nil {
		t.Fatal(e)
	}
	file.Write(imageBytes.Bytes())
	multi.Close()
	resp, e := http.Post(origin+"/engine", multi.FormDataContentType(), &body)
	if e != nil {
		t.Fatal(e)
	}
	resp.Body.Close()
	if resp.StatusCode != 200 {
		t.Fatal("mediaupload", resp.StatusCode)
	}
	code, v = post(token, 1829, map[string]any{"to_player_id": int64(b.PlayerID)})
	media, ok := v["avatar_file_path"].(string)
	if code != 200 || !ok || v["avatar_md5_code"] == "untrusted" {
		t.Fatal("actualmedia", code, v)
	}
	exec(t, p, `INSERT INTO player_social_roots(player_id,created_at,updated_at)VALUES($1,clock_timestamp(),clock_timestamp()),($2,clock_timestamp(),clock_timestamp()) ON CONFLICT DO NOTHING`, int64(a.PlayerID), int64(b.PlayerID))
	exec(t, p, `INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,state_version,updated_at)VALUES($1,$2,1,true,clock_timestamp(),1,clock_timestamp())`, int64(a.PlayerID), int64(b.PlayerID))
	code, v = post(token, 1829, map[string]any{"to_player_id": int64(b.PlayerID)})
	if code != 200 || v["avatar_file_path"] != nil || v["player_info"].(map[string]any)["exp"] != float64(37) {
		t.Fatal("blockeddiscovery", code, v)
	}
	resp, e = http.Get(media)
	if e != nil {
		t.Fatal(e)
	}
	raw, _ := io.ReadAll(resp.Body)
	resp.Body.Close()
	if resp.StatusCode != 200 || !bytes.Equal(raw, imageBytes.Bytes()) {
		t.Fatal("issuedcapabilityrevoked")
	}
	stop()
	dump := filepath.Join(t.TempDir(), "6b.dump")
	tool := func(name string, args ...string) {
		raw, e := osexec.Command(name, args...).CombinedOutput()
		if e != nil {
			t.Fatal(name, e, string(raw))
		}
	}
	tool("pg_dump", "--format=custom", "--file", dump, dsn)
	parsed, e := url.Parse(dsn)
	if e != nil {
		t.Fatal(e)
	}
	newDB := "profile6b_restore_" + strings.ReplaceAll(uuid().String(), "-", "")
	tool("createdb", "--maintenance-db", dsn, newDB)
	parsed.Path = "/" + newDB
	dsn = parsed.String()
	tool("pg_restore", "--no-owner", "--dbname", dsn, dump)
	restored, e := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer restored.Close()
	replay, e := profileWire(restored).Execute(ctx, a, profile.Selection{}, original)
	actual, _ := json.Marshal(replay)
	if e != nil || !bytes.Equal(actual, originalBytes) {
		t.Fatal("restoredwireproof", e)
	}
	start()
	code, v = post(token, 1840, map[string]any{})
	if code != 200 || v["all_show_types"] == nil {
		t.Fatal("restoredAPI", code, v)
	}
	code, v = post(token, 1829, map[string]any{"to_player_id": int64(b.PlayerID)})
	if code != 200 || v["avatar_file_path"] != nil {
		t.Fatal("restoredprivacy", code, v)
	}
	resp, e = http.Get(media)
	if e != nil {
		t.Fatal(e)
	}
	raw, _ = io.ReadAll(resp.Body)
	resp.Body.Close()
	if resp.StatusCode != 200 || !bytes.Equal(raw, imageBytes.Bytes()) {
		t.Fatal("jointmediacapability lost")
	}
}
