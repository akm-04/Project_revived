package client

import (
	"encoding/json"
	"reflect"
	"testing"
)

func TestNullFields(t *testing.T) {
	var decoded any
	if err := json.Unmarshal([]byte(`{"base_info":{"left_times":10,"last_fight_time":null},"defense":[1,null],"ok":[]}`), &decoded); err != nil {
		t.Fatal(err)
	}
	if got, want := nullFields(decoded, ""), []string{".base_info.last_fight_time", ".defense[1]"}; !reflect.DeepEqual(got, want) {
		t.Fatalf("nullFields=%v want %v", got, want)
	}
}
