package lobby

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func view(t *testing.T) BootstrapView {
	u, _ := ids.ParseUUID("33333333-3333-4333-8333-333333333333")
	c, _ := identity.ContextIDFrom(u)
	return BootstrapView{Actor: identity.ActorContext{ContextID: c, AccountUID: identity.AccountUID("20000007"), LogicalServerID: 1, PlayerID: 100001}, RegionName: "Canonical Region", Now: time.Unix(1_700_000_000, 0).UTC()}
}
func TestFrozenMID1DetailComplete(t *testing.T) {
	d, err := BuildMID1Detail(view(t))
	if err != nil {
		t.Fatal(err)
	}
	if len(d) != 33 {
		t.Fatalf("detail=%d", len(d))
	}
	for _, mid := range EmbeddedMID1Records {
		if _, ok := d[fmtMID(mid)]; !ok {
			t.Fatalf("missing %d", mid)
		}
	}
}
func fmtMID(mid uint16) string { // avoid protocol dependency in projection
	if mid == 0 {
		return "0"
	}
	b := make([]byte, 0, 5)
	for mid > 0 {
		b = append([]byte{byte('0' + mid%10)}, b...)
		mid /= 10
	}
	return string(b)
}
func TestCriticalWaveSShapes(t *testing.T) {
	v := view(t)
	d, _ := BuildMID1Detail(v)
	player := d["17"].(map[string]any)
	if player["uid"] != "20000007" || player["player_id"] != int64(100001) || player["uid"] == player["player_id"] {
		t.Fatalf("MID17 account uid/player id identity split lost: %#v", player)
	}
	if player["player_name"] != "" {
		t.Fatalf("fresh player_name must remain empty for stock naming lifecycle: %#v", player["player_name"])
	}
	if player["avatar_id"] != int64(110001001) {
		t.Fatalf("fresh bootstrap avatar drift: %#v", player["avatar_id"])
	}
	if player["region_name"] != "Canonical Region" {
		t.Fatalf("MID17 region_name must be canonical server name: %#v", player["region_name"])
	}
	for _, key := range []string{
		"exp", "mana", "crystal", "lucky_coin", "arena_coin", "march_coin", "top_coin", "guild_coin", "region_coin", "king_coin",
		"lvbu_coin", "spirit_stone", "energy", "spirit_energy", "invitation", "social", "energy_time", "spirit_energy_time",
		"max_energy", "max_invitation", "glory", "vip", "buy_mana_times", "buy_energy_times", "buy_spirit_energy_times", "buy_skill_times",
		"func_ids", "skill_point", "skill_time", "formation", "save_team", "save_team_name", "save_pet", "message_pushes",
	} {
		if _, ok := player[key]; !ok {
			t.Fatalf("MID17 missing source-consumed bootstrap field %q", key)
		}
	}
	mail := d["368"].(map[string]any)
	if _, ok := mail["mail_list"].([]any); !ok {
		t.Fatal("mail_list")
	}
	b := d["1056"].(map[string]any)
	if b["cabinet_info"].(map[string]any)["need_time"] == nil {
		t.Fatal("cabinet need_time")
	}
	if _, ok := d["1304"].([]any); !ok {
		t.Fatal("MID1304 must match current SelfPlayer array consumer")
	}
	gw := d["1152"].(map[string]any)
	if x, ok := gw["is_enroll"].(bool); !ok || x {
		t.Fatalf("guild war inactive type=%T val=%v", gw["is_enroll"], gw["is_enroll"])
	}
}
func TestExplicitSourceShapes(t *testing.T) {
	for _, mid := range []uint16{56, 612, 780, 1056, 176, 1302, 1344, 2754, 2784, 8193} {
		if _, ok := Explicit(mid, view(t)); !ok {
			t.Fatalf("missing %d", mid)
		}
	}
	if got, ok := Explicit(124, view(t)); ok || got != nil {
		t.Fatalf("stale Lobby MID124 response shape remains: got=%v ok=%v", got, ok)
	}
	if _, ok := Explicit(353, view(t)); ok {
		t.Fatal("SIGN mutation must not be exposed by I4 read facade")
	}
}

func TestExplicitMID2784FreshCompatibilityShape(t *testing.T) {
	got, ok := Explicit(2784, view(t))
	if !ok {
		t.Fatal("MID2784 explicit shape missing")
	}
	body, ok := got.(map[string]any)
	if !ok {
		t.Fatalf("MID2784 body type=%T", got)
	}
	awards, ok := body["is_award"].([]any)
	if !ok {
		t.Fatalf("MID2784 is_award must be collection, got %T", body["is_award"])
	}
	if len(awards) != currentAlbumSpecialCollectCount {
		t.Fatalf("MID2784 is_award len=%d want=%d", len(awards), currentAlbumSpecialCollectCount)
	}
	for i, award := range awards {
		v, ok := award.(int64)
		if !ok || v != 0 {
			t.Fatalf("MID2784 is_award[%d]=%#v (%T), want numeric int64(0)", i, award, award)
		}
	}
}

func TestExplicitWhiteAlbumMutationMIDsRemainUnsupported(t *testing.T) {
	for _, mid := range []uint16{72, 2785} {
		if got, ok := Explicit(mid, view(t)); ok || got != nil {
			t.Fatalf("White Album mutation MID%d must remain unsupported: got=%v ok=%v", mid, got, ok)
		}
	}
}
