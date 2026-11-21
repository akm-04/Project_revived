//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"compress/zlib"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
	"mime/multipart"
	"net"
	"net/http"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"testing"
	"time"
)

// The stock client sends furniture_record as its three panel tables (a Lua
// table keyed 1..3, so a JSON array) and its message board sends total_num.
func TestI912StockDormSaveAndCommentShapes(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	p := pool(t)
	a, _, catalog := dormFixture(t, p)
	bearer := displayToken(t, p, a)
	listener, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	addr := listener.Addr().String()
	listener.Close()
	origin := "http://" + addr
	targetDSN := os.Getenv("GXB_I7B6A_DSN")
	assets := filepath.Join(t.TempDir(), "private-media")
	if _, e := blobstore.NewLocal(assets); e != nil {
		t.Fatal(e)
	}
	cmd := osexec.Command(binary)
	cmd.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+targetDSN, "GXB_HTTP_ADDR="+addr, "GXB_PUBLIC_ENGINE_URL="+origin+"/engine", "GXB_REALTIME_PUBLIC_HOST=127.0.0.1", "GXB_REALTIME_PUBLIC_PORT=19003", "GXB_CREDENTIAL_DIGEST_SECRET=i7b2b-fixture-digest-key-00001", "GXB_GAMEPLAY_BEARER_SECRET=i7b2b-fixture-bearer-key-00001", "GXB_REDEEM_DIGEST_SECRET=i7b5b-fixture-redeem-key-00001", "GXB_DERIVATION_KEY_ID=i7b2b-native", "GXB_PROFILE_MEDIA_ROOT="+assets, "GXB_PROFILE_MEDIA_PUBLIC_ORIGIN="+origin)
	log, e := os.CreateTemp(t.TempDir(), "api-log")
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(func() { log.Close() })
	cmd.Stdout = log
	cmd.Stderr = log
	if e = cmd.Start(); e != nil {
		t.Fatal(e)
	}
	t.Cleanup(func() {
		cmd.Process.Kill()
		cmd.Wait()
	})
	for end := time.Now().Add(10 * time.Second); time.Now().Before(end); {
		resp, e := http.Get(origin + "/profile-media/missing")
		if e == nil {
			resp.Body.Close()
			break
		}
		time.Sleep(30 * time.Millisecond)
	}
	post := func(mid int, fields map[string]any) (int, map[string]any) {
		fields["mid"] = mid
		fields["token"] = bearer
		fields["region"] = 1
		raw, _ := json.Marshal(fields)
		var requestBody bytes.Buffer
		contentType := "application/x-www-form-urlencoded"
		if mid == 2515 {
			var compressed bytes.Buffer
			zw := zlib.NewWriter(&compressed)
			zw.Write(raw)
			zw.Close()
			mw := multipart.NewWriter(&requestBody)
			part, e := mw.CreateFormField("payload")
			if e != nil {
				t.Fatal(e)
			}
			part.Write(compressed.Bytes())
			mw.Close()
			contentType = mw.FormDataContentType()
		} else {
			requestBody.WriteString(url.Values{"payload": {string(raw)}}.Encode())
		}
		resp, e := http.Post(origin+"/engine", contentType, &requestBody)
		if e != nil {
			t.Fatal(e)
		}
		defer resp.Body.Close()
		var out map[string]any
		if e = json.NewDecoder(resp.Body).Decode(&out); e != nil {
			t.Fatal(e)
		}
		return resp.StatusCode, out
	}

	code, out := post(2515, map[string]any{
		"house_id":         int64(1),
		"furniture_record": []any{map[string]any{}, map[string]any{}, map[string]any{}},
	})
	if code != 200 {
		t.Fatalf("stock save shape rejected: %d %v", code, out)
	}
	code, out = post(2524, map[string]any{"host_id": int64(a.PlayerID), "house_id": int64(1), "start": int64(0), "offset": int64(20), "total_num": int64(0)})
	if code != 200 {
		t.Fatalf("stock comment shape rejected: %d %v", code, out)
	}
	replyconformance.Check(t, 2524, out)
	code, out = post(2513, map[string]any{"key_item": dormKey(catalog, 2, true), "floor": int64(1), "pos": int64(1)})
	if code != 200 {
		t.Fatalf("open: %d %v", code, out)
	}
	house := int64(out["house_info"].(map[string]any)["house_id"].(float64))
	code, out = post(2514, map[string]any{"house_id": house, "host_id": int64(a.PlayerID)})
	if code != 200 {
		t.Fatalf("detail: %d %v", code, out)
	}
	record, ok := out["house_detail"].(map[string]any)["record"].([]any)
	if !ok || len(record) != stockPanelCount {
		t.Fatalf("record is not the stock panel array: %T %v", out["house_detail"].(map[string]any)["record"], out["house_detail"].(map[string]any)["record"])
	}
	code, out = post(2515, map[string]any{"house_id": house, "furniture_record": record})
	if code != 200 {
		t.Fatalf("stock record round trip rejected: %d %v", code, out)
	}
}

const stockPanelCount = 3
