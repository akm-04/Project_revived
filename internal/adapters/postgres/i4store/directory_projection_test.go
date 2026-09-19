package i4store

import "testing"

func TestDecodeOwnedPlayerSummariesRequiresCompleteProfile(t *testing.T) {
	good := `{"root_count":1,"players":[{"player_id":100001,"logical_server_id":1,"profile_present":true,"name":"","lev":1,"vip":0,"avatar_id":110001001,"avatar_frame_id":0,"conquer_lev":0,"conquer_loop_id":1}]}`
	got, err := decodeOwnedPlayerSummaries(good)
	if err != nil || len(got) != 1 {
		t.Fatalf("good projection: got=%#v err=%v", got, err)
	}
	if got[0].Level != 1 || got[0].AvatarID != 110001001 || got[0].Name != "" {
		t.Fatalf("stock baseline drift: %#v", got[0])
	}
	missing := `{"root_count":1,"players":[{"player_id":100001,"logical_server_id":1,"profile_present":false,"name":"","lev":0,"vip":0,"avatar_id":0,"avatar_frame_id":0,"conquer_lev":0,"conquer_loop_id":0}]}`
	if _, err := decodeOwnedPlayerSummaries(missing); err == nil {
		t.Fatal("half-character directory projection must fail closed")
	}
}
