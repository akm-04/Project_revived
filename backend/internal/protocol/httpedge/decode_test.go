package httpedge

import (
	"bytes"
	"compress/zlib"
	"context"
	"encoding/json"
	"fmt"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func luaURLEncode(s string) string {
	s = strings.ReplaceAll(s, "\n", "\r\n")
	const hex = "0123456789ABCDEF"
	var b strings.Builder
	for i := 0; i < len(s); i++ {
		c := s[i]
		keep := (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '.' || c == '-'
		if keep {
			b.WriteByte(c)
		} else if c == ' ' {
			b.WriteByte('+')
		} else {
			b.WriteByte('%')
			b.WriteByte(hex[c>>4])
			b.WriteByte(hex[c&15])
		}
	}
	return b.String()
}

func ordinaryRequest(t *testing.T, rawJSON string) *http.Request {
	t.Helper()
	body := "payload=" + luaURLEncode(rawJSON)
	r := httptest.NewRequest(http.MethodPost, "http://gxb.invalid/", strings.NewReader(body))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	return r
}

func TestOrdinaryExactlyOneDecodeLayer(t *testing.T) {
	raw := `{"mid":50,"token":"tok_en","region":1,"literal":"%25 + _"}`
	d, e := Decode(ordinaryRequest(t, raw), limits.Default())
	if e != nil {
		t.Fatal(e)
	}
	if d.MID != 50 {
		t.Fatal(d.MID)
	}
	if d.Params["literal"] != "%25 + _" {
		t.Fatalf("literal=%q", d.Params["literal"])
	}
	if d.Params["token"] != "tok_en" {
		t.Fatalf("underscore decode=%q", d.Params["token"])
	}
}

func TestOrdinaryRejectsWrongFamilyAndDuplicatePayload(t *testing.T) {
	_, e := Decode(ordinaryRequest(t, `{"mid":279}`), limits.Default())
	if e == nil || e.HTTPStatus != 400 {
		t.Fatalf("err=%v", e)
	}
	body := "payload=%7B%22mid%22%3A50%7D&payload=%7B%22mid%22%3A50%7D"
	r := httptest.NewRequest(http.MethodPost, "http://x/", strings.NewReader(body))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	_, e = Decode(r, limits.Default())
	if e == nil || e.HTTPStatus != 400 {
		t.Fatalf("err=%v", e)
	}
}

func zlibRequest(t *testing.T, mid uint16, extra int) *http.Request {
	t.Helper()
	payload := fmt.Sprintf(`{"mid":%d,"blob":"%s"}`, mid, strings.Repeat("x", extra))
	var comp bytes.Buffer
	zw := zlib.NewWriter(&comp)
	_, _ = zw.Write([]byte(payload))
	_ = zw.Close()
	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	p, err := mw.CreateFormField("payload")
	if err != nil {
		t.Fatal(err)
	}
	_, _ = p.Write(comp.Bytes())
	_ = mw.Close()
	r := httptest.NewRequest(http.MethodPost, "http://x/", bytes.NewReader(body.Bytes()))
	r.Header.Set("Content-Type", mw.FormDataContentType())
	return r
}

func TestAllSevenZlibMIDsAndWrongFamily(t *testing.T) {
	for _, mid := range []uint16{279, 2484, 535, 774, 1412, 1570, 2515} {
		d, e := Decode(zlibRequest(t, mid, 10), limits.Default())
		if e != nil {
			t.Fatalf("mid=%d err=%v", mid, e)
		}
		if d.MID != mid || d.Encoding != wire.EncodingZlibMultipart {
			t.Fatalf("%#v", d)
		}
	}
	_, e := Decode(zlibRequest(t, 50, 10), limits.Default())
	if e == nil || e.HTTPStatus != 400 {
		t.Fatalf("err=%v", e)
	}
}

func uploadRequest(t *testing.T, conflict bool) *http.Request {
	t.Helper()
	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	fw, err := mw.CreateFormFile("avatar", "face.png")
	if err != nil {
		t.Fatal(err)
	}
	_, _ = fw.Write([]byte("PNGDATA"))
	fields := [][2]string{{"form_name", "avatar"}, {"file_path", "/tmp/face.png"}, {"file_name", "face.png"}, {"mid", "1844"}, {"token", "tok"}, {"region", "1"}, {"v_", "123"}, {"app_v", "1.0"}, {"platform", "3"}, {"mid", "1844"}, {"token", "tok"}, {"region", "1"}, {"v_", "123"}}
	if conflict {
		fields = append(fields, [2]string{"token", "evil"})
	}
	for _, kv := range fields {
		_ = mw.WriteField(kv[0], kv[1])
	}
	_ = mw.Close()
	r := httptest.NewRequest(http.MethodPost, "http://x/", bytes.NewReader(body.Bytes()))
	r.Header.Set("Content-Type", mw.FormDataContentType())
	return r
}

func TestMID1844AgreeingDuplicatesAndConflict(t *testing.T) {
	d, e := Decode(uploadRequest(t, false), limits.Default())
	if e != nil {
		t.Fatal(e)
	}
	if d.MID != 1844 || d.Upload == nil || d.Upload.Size != 7 {
		t.Fatalf("%#v", d)
	}
	path := d.Upload.TempPath
	if _, err := os.Stat(path); err != nil {
		t.Fatal(err)
	}
	d.Cleanup()
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatalf("temp not removed: %v", err)
	}
	_, e = Decode(uploadRequest(t, true), limits.Default())
	if e == nil || e.HTTPStatus != 400 {
		t.Fatalf("err=%v", e)
	}
}

func TestCapsAndInflateRatio(t *testing.T) {
	cfg := limits.Default()
	cfg.OrdinaryBodyBytes = 8
	_, e := Decode(ordinaryRequest(t, `{"mid":50}`), cfg)
	if e == nil || e.HTTPStatus != 413 {
		t.Fatalf("err=%v", e)
	}
	cfg = limits.Default()
	cfg.MaxInflateRatio = 1
	_, e = Decode(zlibRequest(t, 279, 1000), cfg)
	if e == nil || e.HTTPStatus != 413 {
		t.Fatalf("err=%v", e)
	}
}

func TestHandlerUnknownUnimplementedImplementedAndSaturation(t *testing.T) {
	ad, _ := NewAdmission(1)
	h := Handler{Limits: limits.Default(), Admission: ad, Operations: operation.Factory{Clock: clock.Fixed{T: time.Unix(100, 0)}, Random: bytes.NewReader(make([]byte, 1024))}, Router: NewRouter()}
	call := func(raw string) *httptest.ResponseRecorder {
		w := httptest.NewRecorder()
		h.ServeHTTP(w, ordinaryRequest(t, raw))
		return w
	}
	w := call(`{"mid":65001}`)
	if w.Code != 404 {
		t.Fatalf("unknown=%d %s", w.Code, w.Body.String())
	}
	w = call(`{"mid":50}`)
	if w.Code != 501 {
		t.Fatalf("unimplemented=%d %s", w.Code, w.Body.String())
	}
	if err := h.Router.Register(50, DispatcherFunc(func(ctx context.Context, req DispatchRequest) Response {
		return Response{HTTPStatus: 200, Body: map[string]any{"ok": true, "mid": req.Envelope.MID, "token": req.Envelope.Claims.Token}}
	})); err != nil {
		t.Fatal(err)
	}
	w = call(`{"mid":50,"token":"abc","region":1}`)
	if w.Code != 200 {
		t.Fatalf("implemented=%d %s", w.Code, w.Body.String())
	}
	var obj map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &obj)
	if obj["ok"] != true {
		t.Fatalf("%v", obj)
	}
	if !ad.TryAcquire() {
		t.Fatal("acquire")
	}
	w = call(`{"mid":50}`)
	ad.Release()
	if w.Code != 503 {
		t.Fatalf("saturated=%d", w.Code)
	}
}

func TestHandlerSourceProvenScalarJSONResponse(t *testing.T) {
	ad, _ := NewAdmission(1)
	router := NewRouter()
	if err := router.Register(2864, DispatcherFunc(func(context.Context, DispatchRequest) Response {
		return Response{HTTPStatus: 200, JSON: "B"}
	})); err != nil {
		t.Fatal(err)
	}
	h := Handler{Limits: limits.Default(), Admission: ad, Operations: operation.Factory{Clock: clock.Fixed{T: time.Unix(100, 0)}, Random: bytes.NewReader(make([]byte, 1024))}, Router: router}
	w := httptest.NewRecorder()
	h.ServeHTTP(w, ordinaryRequest(t, `{"mid":2864,"unique_key":"mtspy"}`))
	if w.Code != 200 || strings.TrimSpace(w.Body.String()) != `"B"` {
		t.Fatalf("status=%d body=%q", w.Code, w.Body.String())
	}
}

func FuzzOrdinaryDecoder(f *testing.F) {
	f.Add("payload=%7B%22mid%22%3A50%7D")
	cfg := limits.Default()
	f.Fuzz(func(t *testing.T, s string) {
		if len(s) > 4096 {
			s = s[:4096]
		}
		r := httptest.NewRequest(http.MethodPost, "http://x/", strings.NewReader(s))
		r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		_, _ = Decode(r, cfg)
	})
}

func TestHandlerResponseEncodingFailureDoesNotRedispatch(t *testing.T) {
	ad, _ := NewAdmission(1)
	router := NewRouter()
	calls := 0
	if err := router.Register(50, DispatcherFunc(func(context.Context, DispatchRequest) Response {
		calls++
		return Response{HTTPStatus: http.StatusOK, JSON: func() {}}
	})); err != nil {
		t.Fatal(err)
	}
	h := Handler{
		Limits: limits.Default(), Admission: ad,
		Operations: operation.Factory{Clock: clock.Fixed{T: time.Unix(100, 0)}, Random: bytes.NewReader(make([]byte, 1024))},
		Router:     router,
	}
	w := httptest.NewRecorder()
	h.ServeHTTP(w, ordinaryRequest(t, `{"mid":50}`))
	if calls != 1 {
		t.Fatalf("dispatcher calls=%d, want 1", calls)
	}
	if w.Code != http.StatusInternalServerError {
		t.Fatalf("status=%d body=%q", w.Code, w.Body.String())
	}
	var body map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	if body["error"] != "response_encoding" {
		t.Fatalf("body=%v", body)
	}
}

func TestI7A2LowNumberRealtimePushesAreNotOrdinaryHTTP(t *testing.T) {
	for _, mid := range []uint16{514, 516} {
		_, edgeErr := Decode(ordinaryRequest(t, fmt.Sprintf(`{"mid":%d}`, mid)), limits.Default())
		if edgeErr == nil || edgeErr.HTTPStatus != http.StatusBadRequest {
			t.Fatalf("mid=%d unexpectedly accepted as ordinary HTTP: %v", mid, edgeErr)
		}
	}
}
