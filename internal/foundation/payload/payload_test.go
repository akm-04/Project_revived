package payload

import (
	"reflect"
	"strings"
	"testing"
	"time"
)

type inner struct {
	Count int `json:"count"`
}

type base struct {
	Kind string `json:"kind"`
}

type stored struct {
	base
	Name    string           `json:"name"`
	Items   []inner          `json:"items"`
	ByKey   map[string]inner `json:"by_key"`
	When    time.Time        `json:"when"`
	Ignored string           `json:"-"`
}

func TestStrictVersionRefusesUnknownKeyTrailingDataAndNewerVersion(t *testing.T) {
	var out stored
	if err := Decode("t", 1, []byte(`{"name":"a","extra":1}`), &out); err == nil || !strings.Contains(err.Error(), "extra") {
		t.Fatalf("unknown key: %v", err)
	}
	if err := Decode("t", 1, []byte(`{"name":"a"} {}`), &out); err == nil {
		t.Fatal("trailing data accepted")
	}
	if err := Decode("t", Current+1, []byte(`{}`), &out); err == nil {
		t.Fatal("newer version accepted")
	}
	if err := Decode("t", 1, []byte(`{"kind":"k","name":"a","items":[{"count":2}]}`), &out); err != nil || out.Kind != "k" || out.Items[0].Count != 2 {
		t.Fatalf("strict decode: %v %+v", err, out)
	}
}

func TestVersionZeroDecodesLenientlyAndListsEveryDroppedKey(t *testing.T) {
	raw := []byte(`{"Name":"a","old":1,"items":[{"count":1,"gone":2}],"by_key":{"x":{"lost":3}},"when":"2026-11-15T00:00:00Z","Ignored":"x"}`)
	var out stored
	if err := Decode("t", 0, raw, &out); err != nil || out.Name != "a" {
		t.Fatalf("lenient decode: %v %+v", err, out)
	}
	got := UnknownKeys(raw, reflect.TypeOf(out))
	want := []string{"Ignored", "by_key.*.lost", "items.[].gone", "old"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("unknown keys %v, want %v", got, want)
	}
}

func TestEncodeStoresTheCurrentVersion(t *testing.T) {
	raw, version, err := Encode(inner{Count: 1})
	if err != nil || version != Current || string(raw) != `{"count":1}` {
		t.Fatalf("%s %d %v", raw, version, err)
	}
}
