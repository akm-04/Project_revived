package clientlog

import (
	"bytes"
	"compress/flate"
	"compress/gzip"
	"compress/zlib"
	"strings"
	"testing"
	"time"
)

// stockRows is the shape json.encode(xyd.db.errorLog:getAll()) produces (src_64 storage/ErrorLog.lua).
const stockRows = `[{"rowid":3,"time":1761200000,"app_v":"1.5.82","version":"1.0.9","isCrash":0,"dump":"","log":"[string \"app/windows/A.lua\"]:12: attempt to index nil\nstack traceback:\n\t[C]: in function 'error'"},` +
	`{"rowid":4,"time":1761200001,"app_v":"1.5.82","version":"1.0.9","isCrash":1,"dump":"crash.dmp","log":"native crash"},` +
	`{"rowid":5,"time":1761200002,"app_v":"1.5.82","version":"1.0.9","isCrash":0,"dump":"","log":"asset 404","scene":"lobby"}]`

func compress(t *testing.T, kind string, payload []byte) []byte {
	t.Helper()
	var buffer bytes.Buffer
	var writer interface {
		Write([]byte) (int, error)
		Close() error
	}
	switch kind {
	case "zlib":
		writer = zlib.NewWriter(&buffer)
	case "gzip":
		writer = gzip.NewWriter(&buffer)
	default:
		raw, err := flate.NewWriter(&buffer, flate.DefaultCompression)
		if err != nil {
			t.Fatal(err)
		}
		writer = raw
	}
	if _, err := writer.Write(payload); err != nil {
		t.Fatal(err)
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	return buffer.Bytes()
}

func TestInflateAcceptsStockAndV1Encodings(t *testing.T) {
	for _, kind := range []string{"zlib", "gzip", "raw"} {
		out, err := Inflate(compress(t, kind, []byte(stockRows)))
		if err != nil || string(out) != stockRows {
			t.Fatalf("%s: err=%v", kind, err)
		}
	}
	if _, err := Inflate([]byte("not compressed")); err != ErrBadPayload {
		t.Fatalf("garbage err=%v", err)
	}
	if _, err := Inflate(compress(t, "zlib", bytes.Repeat([]byte("a"), MaxInflatedBytes+1))); err != ErrOverCap {
		t.Fatalf("bomb err=%v", err)
	}
}

func TestParseRowsKeepsFieldsAndClassifies(t *testing.T) {
	rows, err := ParseRows([]byte(stockRows))
	if err != nil || len(rows) != 3 {
		t.Fatalf("rows=%d err=%v", len(rows), err)
	}
	if *rows[0].ClientRowID != 3 || *rows[0].ClientTime != 1761200000 || rows[0].AppVersion != "1.5.82" || rows[0].Class != Error {
		t.Fatalf("traceback row=%+v", rows[0])
	}
	if !rows[1].IsCrash || rows[1].Class != Error {
		t.Fatalf("crash row=%+v", rows[1])
	}
	if rows[2].Class != Routine || rows[2].Extras["scene"] != "lobby" {
		t.Fatalf("routine row=%+v", rows[2])
	}
	if UploadClass(rows, true, false) != Error || UploadClass(rows[2:], true, false) != Routine || UploadClass(rows[2:], false, false) != Anomaly {
		t.Fatal("upload class")
	}
	empty, err := ParseRows([]byte(`{}`))
	if err != nil || len(empty) != 0 {
		t.Fatalf("empty table err=%v", err)
	}
	if _, err := ParseRows([]byte(`[1]`)); err != ErrBadPayload {
		t.Fatalf("non-object row err=%v", err)
	}
	if _, err := ParseRows([]byte("[" + strings.Repeat(`{},`, MaxRowsPerUpload) + `{}]`)); err != ErrOverCap {
		t.Fatalf("row cap err=%v", err)
	}
}

func TestParseRowsTruncatesLongText(t *testing.T) {
	long := strings.Repeat("é", MaxRowTextBytes)
	rows, err := ParseRows([]byte(`[{"log":"` + long + `","isCrash":0}]`))
	if err != nil {
		t.Fatal(err)
	}
	if !rows[0].Truncated || len(rows[0].Log) > MaxRowTextBytes || !strings.HasPrefix(long, rows[0].Log) {
		t.Fatalf("truncated=%v len=%d", rows[0].Truncated, len(rows[0].Log))
	}
}

func TestProbeRowsAreAnomalies(t *testing.T) {
	rows, err := ParseRows([]byte(`[{"log":"{\"__gxb_probe\":1}","isCrash":0}]`))
	if err != nil || rows[0].Class != Anomaly {
		t.Fatalf("probe=%+v err=%v", rows, err)
	}
}

func TestCapabilityRoundTrip(t *testing.T) {
	capability, digest, err := MintCapability()
	if err != nil {
		t.Fatal(err)
	}
	again, valid := CapabilityDigest(capability)
	if !valid || again != digest {
		t.Fatal("capability digest mismatch")
	}
	if _, valid := CapabilityDigest("short"); valid {
		t.Fatal("malformed capability accepted")
	}
	if len(SessionReference("0b6b9c3e-0000-4000-8000-000000000001")) != 32 {
		t.Fatal("session reference length")
	}
}

func TestRetentionAndOutcomes(t *testing.T) {
	received := time.Date(2026, 10, 22, 0, 0, 0, 0, time.UTC)
	if Routine.ExpiresAt(received) != received.Add(7*24*time.Hour) || Error.ExpiresAt(received) != received.Add(30*24*time.Hour) || Anomaly.ExpiresAt(received) != received.Add(30*24*time.Hour) {
		t.Fatal("retention")
	}
	cases := []struct {
		status int
		code   int64
		want   Outcome
		class  RetentionClass
	}{{200, 0, OutcomeOK, Routine}, {200, 20018, OutcomeClientError, Error}, {403, 0, OutcomeClientError, Error}, {503, 0, OutcomeServerError, Error}}
	for _, c := range cases {
		if got := OutcomeOf(c.status, c.code); got != c.want || got.Class() != c.class {
			t.Errorf("OutcomeOf(%d,%d)=%s", c.status, c.code, got)
		}
	}
	if OutcomeUnknownMID.Class() != Anomaly || !OutcomeUndecodable.KeepsRawEnvelope() || OutcomeOK.KeepsRawEnvelope() {
		t.Fatal("anomaly outcomes")
	}
}
