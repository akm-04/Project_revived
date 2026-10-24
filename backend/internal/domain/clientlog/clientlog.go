// Package clientlog holds the private policy for stock client log uploads and
// the per-uid request journal (I85_CLIENT_LOG_INGEST_V1, I85_REQUEST_JOURNAL_V1,
// I85_LOG_RETENTION_V1).
package clientlog

import (
	"bytes"
	"compress/flate"
	"compress/gzip"
	"compress/zlib"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"
	"time"
	"unicode/utf8"
)

// RetentionClass decides how long a row is kept (D34).
type RetentionClass string

const (
	Routine RetentionClass = "ROUTINE"
	Error   RetentionClass = "ERROR"
	Anomaly RetentionClass = "ANOMALY"
)

const (
	RoutineRetention  = 7 * 24 * time.Hour
	IncidentRetention = 30 * 24 * time.Hour
)

// ExpiresAt is the receive time plus the class retention.
func (c RetentionClass) ExpiresAt(received time.Time) time.Time {
	if c == Routine {
		return received.Add(RoutineRetention)
	}
	return received.Add(IncidentRetention)
}

// PRIVATE_POLICY caps (I85_CLIENT_LOG_INGEST_V1 R5).
const (
	MaxErrorLogBodyBytes   = 1 << 20
	MaxCrashBodyBytes      = 4 << 20
	MaxInflatedBytes       = 8 << 20
	MaxRowsPerUpload       = 500
	MaxRowTextBytes        = 64 << 10
	UploadsPerMinute       = 60
	CapabilityLifetime     = 7 * 24 * time.Hour
	MaxRawEnvelopeBytes    = 16 << 10
	MaxCauseBytes          = 2 << 10
	capabilityRandomBytes  = 32
	sessionReferenceLength = 32
)

// Kind is the stock Backend:log type.
type Kind int16

const (
	KindErrorLog Kind = 0
	KindCrash    Kind = 1
)

var (
	ErrOverCap    = errors.New("clientlog: upload over cap")
	ErrBadPayload = errors.New("clientlog: payload is not a deflated errorlog row array")
)

// Inflate accepts the stock zlib stream and, like the V1 receiver, raw deflate
// and gzip. Output above MaxInflatedBytes is ErrOverCap.
func Inflate(payload []byte) ([]byte, error) {
	readers := []func() (io.Reader, error){
		func() (io.Reader, error) { return zlib.NewReader(bytes.NewReader(payload)) },
		func() (io.Reader, error) { return gzip.NewReader(bytes.NewReader(payload)) },
		func() (io.Reader, error) { return flate.NewReader(bytes.NewReader(payload)), nil },
	}
	for _, open := range readers {
		reader, err := open()
		if err != nil {
			continue
		}
		out, err := io.ReadAll(io.LimitReader(reader, MaxInflatedBytes+1))
		if err != nil {
			continue
		}
		if len(out) > MaxInflatedBytes {
			return nil, ErrOverCap
		}
		return out, nil
	}
	return nil, ErrBadPayload
}

// Row is one stock errorlog row as sent; unknown fields stay in Extras.
type Row struct {
	ClientRowID *int64
	ClientTime  *int64
	AppVersion  string
	Version     string
	IsCrash     bool
	Dump        string
	Log         string
	Truncated   bool
	Extras      map[string]any
	Class       RetentionClass
}

const probeTag = "__gxb_probe"

// ParseRows decodes json.encode(errorLog:getAll()). The stock encoder writes an
// empty Lua table as an object, so "{}" is zero rows.
func ParseRows(inflated []byte) ([]Row, error) {
	decoder := json.NewDecoder(bytes.NewReader(inflated))
	decoder.UseNumber()
	var value any
	if err := decoder.Decode(&value); err != nil {
		return nil, ErrBadPayload
	}
	if object, isObject := value.(map[string]any); isObject && len(object) == 0 {
		return nil, nil
	}
	items, isArray := value.([]any)
	if !isArray {
		return nil, ErrBadPayload
	}
	if len(items) > MaxRowsPerUpload {
		return nil, ErrOverCap
	}
	rows := make([]Row, 0, len(items))
	for _, item := range items {
		fields, isObject := item.(map[string]any)
		if !isObject {
			return nil, ErrBadPayload
		}
		rows = append(rows, parseRow(fields))
	}
	return rows, nil
}

func parseRow(fields map[string]any) Row {
	row := Row{
		ClientRowID: integerField(fields["rowid"]),
		ClientTime:  integerField(fields["time"]),
		AppVersion:  stringField(fields["app_v"]),
		Version:     stringField(fields["version"]),
		IsCrash:     truthy(fields["isCrash"]),
	}
	var dumpCut, logCut bool
	row.Dump, dumpCut = Truncate(stringField(fields["dump"]), MaxRowTextBytes)
	row.Log, logCut = Truncate(stringField(fields["log"]), MaxRowTextBytes)
	row.Truncated = dumpCut || logCut
	for key, value := range fields {
		switch key {
		case "rowid", "time", "app_v", "version", "isCrash", "dump", "log":
			continue
		}
		if row.Extras == nil {
			row.Extras = map[string]any{}
		}
		row.Extras[key] = value
	}
	row.Class = classifyRow(row)
	return row
}

func classifyRow(row Row) RetentionClass {
	if strings.Contains(row.Log, probeTag) {
		return Anomaly
	}
	hasTraceback := strings.Contains(row.Log, "stack traceback") || strings.Contains(row.Dump, "stack traceback")
	if row.IsCrash || hasTraceback {
		return Error
	}
	return Routine
}

// UploadClass is the class of the upload record: the most severe of its rows,
// ANOMALY when unattributed or quarantined (R7).
func UploadClass(rows []Row, attributed, quarantined bool) RetentionClass {
	if !attributed || quarantined {
		return Anomaly
	}
	class := Routine
	for _, row := range rows {
		if row.Class == Anomaly {
			return Anomaly
		}
		if row.Class == Error {
			class = Error
		}
	}
	return class
}

func integerField(value any) *int64 {
	number, isNumber := value.(json.Number)
	if !isNumber {
		return nil
	}
	parsed, err := number.Int64()
	if err != nil {
		return nil
	}
	return &parsed
}

func stringField(value any) string {
	switch typed := value.(type) {
	case string:
		return typed
	case json.Number:
		return typed.String()
	default:
		return ""
	}
}

func truthy(value any) bool {
	switch typed := value.(type) {
	case bool:
		return typed
	case json.Number:
		return typed.String() != "0"
	case string:
		return typed != "" && typed != "0" && typed != "false"
	default:
		return false
	}
}

// Truncate cuts text to at most limit bytes on a rune boundary.
func Truncate(text string, limit int) (string, bool) {
	if len(text) <= limit {
		return text, false
	}
	cut := limit
	for cut > 0 && !utf8.RuneStart(text[cut]) {
		cut--
	}
	return text[:cut], true
}

// MintCapability returns the URL capability and the digest stored for it.
func MintCapability() (string, [32]byte, error) {
	random := make([]byte, capabilityRandomBytes)
	if _, err := rand.Read(random); err != nil {
		return "", [32]byte{}, fmt.Errorf("clientlog capability: %w", err)
	}
	capability := base64.RawURLEncoding.EncodeToString(random)
	return capability, sha256.Sum256([]byte(capability)), nil
}

// CapabilityDigest validates the capability shape and returns its digest.
func CapabilityDigest(capability string) ([32]byte, bool) {
	decoded, err := base64.RawURLEncoding.DecodeString(capability)
	if err != nil || len(decoded) != capabilityRandomBytes {
		return [32]byte{}, false
	}
	return sha256.Sum256([]byte(capability)), true
}

// SessionReference is the stored stand-in for a session id (D44).
func SessionReference(sessionID string) string {
	digest := sha256.Sum256([]byte(sessionID))
	return hex.EncodeToString(digest[:])[:sessionReferenceLength]
}
