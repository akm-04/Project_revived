package realtime

import (
	"encoding/json"
	"errors"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
)

func TestJSONFrameDecodeMatchesAMF3ValueShapes(t *testing.T) {
	frame, err := DecodeJSONFrame([]byte(`{"mid":32782,"data":{"message":"hi","channel":0,"small":12,"exact":9007199254740992,"large":9007199254740993,"none":null,"list":[1,null,"x"],"nested":{}}}`), limits.Default())
	if err != nil {
		t.Fatal(err)
	}
	if frame.MID != 32782 {
		t.Fatalf("mid=%d", frame.MID)
	}
	object, ok := frame.Params.(*amf3.Object)
	if !ok {
		t.Fatalf("params type %T", frame.Params)
	}
	values, err := object.StrictMap()
	if err != nil {
		t.Fatal(err)
	}
	if message, _ := values["message"].(string); message != "hi" {
		t.Fatalf("message=%v", values["message"])
	}
	if small, ok := values["small"].(int32); !ok || small != 12 {
		t.Fatalf("small=%T %v", values["small"], values["small"])
	}
	if exact, ok := values["exact"].(float64); !ok || exact != 9007199254740992 {
		t.Fatalf("exact=%T %v", values["exact"], values["exact"])
	}
	if large, ok := values["large"].(int64); !ok || large != 9007199254740993 {
		t.Fatalf("large=%T %v", values["large"], values["large"])
	}
	if values["none"] != nil {
		t.Fatalf("null=%v", values["none"])
	}
	list, ok := values["list"].([]any)
	if !ok || len(list) != 3 || list[1] != nil {
		t.Fatalf("list=%#v", values["list"])
	}
	if nested, ok := values["nested"].(*amf3.Object); !ok || len(nested.Properties) != 0 {
		t.Fatalf("nested=%#v", values["nested"])
	}
}

func TestJSONFrameEncodeKeepsNullsAndExactIntegers(t *testing.T) {
	body, err := EncodeJSONFrame(Frame{MID: 514, Params: &amf3.Object{Properties: []amf3.Property{
		{Name: "message", Value: "hello"},
		{Name: "none", Value: nil},
		{Name: "present", Value: int64(9007199254740992)},
		{Name: "large", Value: int64(9007199254740993)},
		{Name: "list", Value: []any{int32(1), nil}},
	}}}, limits.Default())
	if err != nil {
		t.Fatal(err)
	}
	var decoded map[string]any
	if err := json.Unmarshal(body, &decoded); err != nil {
		t.Fatal(err)
	}
	if decoded["mid"] != float64(514) {
		t.Fatalf("mid=%v", decoded["mid"])
	}
	data, ok := decoded["data"].(map[string]any)
	if !ok {
		t.Fatalf("data=%T", decoded["data"])
	}
	if data["none"] != nil {
		t.Fatalf("null field missing")
	}
	if data["present"] != float64(9007199254740992) {
		t.Fatalf("present=%v", data["present"])
	}
	if data["large"] != "9007199254740993" {
		t.Fatalf("large=%v", data["large"])
	}
	if list, ok := data["list"].([]any); !ok || list[1] != nil {
		t.Fatalf("list=%#v", data["list"])
	}
}

func TestJSONFrameEncodeUndefinedAndEmptyObject(t *testing.T) {
	body, err := EncodeJSONFrame(Frame{MID: 32797, Params: &amf3.Object{}}, limits.Default())
	if err != nil {
		t.Fatal(err)
	}
	if string(body) != `{"mid":32797,"data":{}}` {
		t.Fatalf("body=%s", body)
	}
	body, err = EncodeJSONFrame(Frame{MID: 1, Params: amf3.UndefinedValue}, limits.Default())
	if err != nil {
		t.Fatal(err)
	}
	if string(body) != `{"mid":1,"data":null}` {
		t.Fatalf("body=%s", body)
	}
}

func TestJSONFrameRejectsMalformedEnvelopes(t *testing.T) {
	cases := []string{
		``,
		`[]`,
		`{"data":{}}`,
		`{"mid":"1","data":{}}`,
		`{"mid":70000,"data":{}}`,
		`{"mid":1.5,"data":{}}`,
		`{"mid":1,"mid":2,"data":{}}`,
		`{"mid":1,"data":{},"extra":true}`,
		`{"mid":1,"data":{"a":1,"a":2}}`,
		`{"mid":1,"data":{}} trailing`,
		`{"mid":1,"data":[1,}`,
	}
	for _, input := range cases {
		if _, err := DecodeJSONFrame([]byte(input), limits.Default()); !errors.Is(err, ErrMalformedJSONFrame) {
			t.Fatalf("input %q err=%v", input, err)
		}
	}
	if _, err := DecodeJSONFrame([]byte(`{"mid":1,"data":{}}`), limits.Default()); err != nil {
		t.Fatal(err)
	}
	if _, err := DecodeJSONFrame([]byte(strings.Repeat(" ", limits.NativeFramePayloadMax+1)), limits.Default()); !errors.Is(err, ErrFrameTooLarge) {
		t.Fatalf("oversize err=%v", err)
	}
}
