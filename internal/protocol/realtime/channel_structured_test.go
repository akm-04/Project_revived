package realtime

import (
	"encoding/json"
	"fmt"
	cc "gxb.local/backend/v2/internal/application/channelchat"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	"strings"
	"testing"
)

func structuredFixtures() []cc.Structured {
	profile := cc.Profile{PlayerID: 100001, Name: "canonical", Level: 50, AvatarID: 1, AvatarFrameID: 1, ConquerLoopID: 1}
	return []cc.Structured{
		{Kind: cc.ArenaReference, Arena: &cc.Arena{PlayerID: 100001, PlayerName: "canonical", EnemyName: "enemy", RecordID: 2}},
		{Kind: cc.PeakReference, Peak: &cc.Peak{PlayerID: 100001, PlayerName: strings.Repeat("甲", 100), EnemyName: "enemy", RecordID: 2, Attack: profile, Defense: profile}},
		{Kind: cc.ScratchShare, Scratch: &cc.Scratch{PlayerID: 100001, PlayerName: "canonical", RandomCards: []int64{1, 2}, Cards: []int64{1, 1, 2}, ScratchStatus: []int64{0, 1}}},
		{Kind: cc.IllusionInvitation, Illusion: &cc.Invitation{RoomID: 1, BossName: "boss", Level: 20}},
		{Kind: cc.OccultInvitation, Occult: &cc.Occult{RoomID: 1, ChapterID: 1, Force: 0}},
		{Kind: cc.AdventureIllusionInvitation, AdventureIllusion: &cc.Invitation{RoomID: 1, BossName: "boss", Level: 20}},
		{Kind: cc.DefenseInvitation, Defense: &cc.Defense{RoomID: 1, Level: 20}},
		{Kind: cc.CampMessage, Camp: &cc.Camp{DisplayRoomID: 0, CampID: 0, Text: strings.Repeat("\"", 40)}},
		{Kind: cc.RagnarokInvitation, Ragnarok: &cc.Invitation{RoomID: 1, BossName: "boss", Level: 20}},
	}
}
func chatObject(text string, kind, channel int64) *amf3.Object {
	return &amf3.Object{Properties: []amf3.Property{{Name: "message", Value: text}, {Name: "type", Value: float64(kind)}, {Name: "channel", Value: float64(channel)}}}
}
func TestStructuredNineSourceVariantsAndRoleCrossProduct(t *testing.T) {
	reg, e := NewChannelChatEventRegistry()
	if e != nil {
		t.Fatal(e)
	}
	for _, fixture := range structuredFixtures() {
		t.Run(string(fixture.Kind), func(t *testing.T) {
			msg, e := ProjectStructuredMessage(fixture, 4)
			if e != nil {
				t.Fatal(e)
			}
			sel, e := ParseStructuredMessage(msg, StructuredWireType(fixture.Kind), 4)
			if e != nil || sel.Kind != fixture.Kind {
				t.Fatal(sel, e)
			}
			ingress, e := ParseChannelChatIngress(chatObject(msg, StructuredWireType(fixture.Kind), 4))
			if e != nil || ingress.Selector.Kind != fixture.Kind {
				t.Fatal(e)
			}
			payload := ordinaryFixture("x")
			for i := range payload.Properties {
				if payload.Properties[i].Name == "type" {
					payload.Properties[i].Value = float64(StructuredWireType(fixture.Kind))
				}
				if payload.Properties[i].Name == "message" {
					payload.Properties[i].Value = msg
				}
			}
			for _, role := range []Role{World, Guild, Service} {
				e := reg.ValidateDirect(mids.MIDChatMessage, role, payload)
				allowed := role == Service || fixture.Kind != cc.CampMessage && (role == Guild || StructuredWireType(fixture.Kind) <= 2)
				if allowed != (e == nil) {
					t.Fatal(role, e)
				}
			}
			// Every schema rejects extra keys and duplicate keys, without changing its valid reference.
			for _, bad := range []string{strings.TrimSuffix(msg, "}") + `,"forged":1}`, `{"type":1,"type":1}`, msg + ` {}`, strings.Replace(msg, `"player_id":100001`, `"player_id":true`, 1)} {
				if bad == msg {
					continue
				}
				if _, e := ParseStructuredMessage(bad, StructuredWireType(fixture.Kind), 4); e == nil {
					t.Fatal("accepted", bad)
				}
			}
		})
	}
}
func TestStructuredOrdinary140AndEncoded8192Boundaries(t *testing.T) {
	for _, n := range []int{140, 141} {
		_, e := ParseChannelChatIngress(chatObject(strings.Repeat("🙂", n), 0, 0))
		if (e == nil) != (n == 140) {
			t.Fatal(n, e)
		}
	}
	fixture := structuredFixtures()[1]
	msg, e := ProjectStructuredMessage(fixture, 4)
	if e != nil || len([]rune(msg)) <= 140 {
		t.Fatal(e)
	}
	padded := msg + strings.Repeat(" ", 8192-len(msg))
	if _, e := ParseStructuredMessage(padded, 1, 4); e != nil {
		t.Fatal(e)
	}
	if _, e := ParseStructuredMessage(padded+" ", 1, 4); e == nil {
		t.Fatal("8193")
	}
	camp := structuredFixtures()[7]
	if _, e := ProjectStructuredMessage(camp, 4); e != nil {
		t.Fatal(e)
	}
	camp.Camp.Text = strings.Repeat("🙂", 41)
	if _, e := ProjectStructuredMessage(camp, 4); e == nil {
		t.Fatal("41")
	}
	camp.Camp.Text = ""
	camp.Camp.IsEmoticon = true
	camp.Camp.EmoticonID = 1
	if _, e := ProjectStructuredMessage(camp, 4); e != nil {
		t.Fatal(e)
	}
	camp.Camp.EmoticonID = 0
	if _, e := ProjectStructuredMessage(camp, 4); e == nil {
		t.Fatal("emotion0")
	}
}
func TestStructuredDecoderExactNumbersAndResourceBudgets(t *testing.T) {
	for _, s := range []string{`{"a":9007199254740992}`, `{"a":9007199254740991.1}`, `{"a":1e-100000000}`, `{"a":1e100000000}`, `{"a":NaN}`, `{"a":null}`, `{"a":1,"a":2}`, `{"a":{"b":{"c":{"d":{}}}}}`, `[1]`, `{"a":"` + string([]byte{0xff}) + `"}`} {
		if _, e := DecodeFiniteStructuredJSON(s); e == nil {
			t.Fatal(s)
		}
	}
	for _, s := range []string{`{"a":9007199254740991}`, `{"a":1e0}`, `{"a":false}`, `{"a":0}`} {
		if _, e := DecodeFiniteStructuredJSON(s); e != nil {
			t.Fatal(s, e)
		}
	}
	m := map[string]any{}
	for i := 0; i < 65; i++ {
		m[fmt.Sprint(i)] = 1
	}
	raw, _ := json.Marshal(m)
	if _, e := DecodeFiniteStructuredJSON(string(raw)); e == nil {
		t.Fatal("65keys")
	}
	for _, n := range []int{64, 65} {
		raw, _ := json.Marshal(map[string]any{"a": make([]int, n)})
		_, e := DecodeFiniteStructuredJSON(string(raw))
		if (e == nil) != (n == 64) {
			t.Fatal(n, e)
		}
	}
	m = map[string]any{}
	for i := 0; i < 8; i++ {
		m[fmt.Sprint(i)] = make([]int, 64)
	}
	raw, _ = json.Marshal(m)
	if _, e := DecodeFiniteStructuredJSON(string(raw)); e == nil {
		t.Fatal("totalvalues")
	}
}
func TestStructuredPeakBooleanAndRequiredProfiles(t *testing.T) {
	msg, e := ProjectStructuredMessage(structuredFixtures()[1], 4)
	if e != nil {
		t.Fatal(e)
	}
	for _, s := range []string{strings.Replace(msg, `"isAttack":false`, `"isAttack":0`, 1), strings.Replace(msg, `"isWin":false`, `"isWin":0`, 1), strings.TrimSuffix(msg, "}") + `,"id":2}`, strings.Replace(msg, `"conquer_loop_id":1`, `"conquer_loop_id":null`, 1)} {
		if _, e := ParseStructuredMessage(s, 1, 4); e == nil {
			t.Fatal(s)
		}
	}
}
func TestStructuredScratchCollectionShapeAndUnion(t *testing.T) {
	fixture := structuredFixtures()[2]
	fixture.Scratch.RandomCards = []int64{}
	fixture.Scratch.Cards = []int64{}
	fixture.Scratch.ScratchStatus = []int64{}
	if _, e := ProjectStructuredMessage(fixture, 4); e != nil {
		t.Fatal(e)
	}
	fixture.Scratch.RandomCards = nil
	if _, e := ProjectStructuredMessage(fixture, 4); e == nil {
		t.Fatal("nilarray")
	}
	fixture.Scratch.RandomCards = make([]int64, 65)
	if _, e := ProjectStructuredMessage(fixture, 4); e == nil {
		t.Fatal("65array")
	}
	fixture.Arena = &cc.Arena{}
	if _, e := ProjectStructuredMessage(fixture, 4); e == nil {
		t.Fatal("union")
	}
}

func ordinaryFixture(text string) *amf3.Object {
	return &amf3.Object{Properties: []amf3.Property{{Name: "player_id", Value: 100001.0}, {Name: "player_name", Value: "canonical"}, {Name: "message", Value: text}, {Name: "player_type", Value: 0.0}, {Name: "type", Value: 0.0}, {Name: "avatar_id", Value: 1.0}, {Name: "avatar_frame_id", Value: 1.0}, {Name: "lev", Value: 50.0}, {Name: "np_info", Value: `{"title_info":"@@@@","bubble_info":"10001@0","conquer_lev":0,"conquer_loop_id":0}`}}}
}

func TestStructuredEscapedUnicodeDoesNotLoseInformation(t *testing.T) {
	for _, s := range []string{`{"a":"\uD800"}`, `{"a":"\uDC00"}`, `{"a":"\uD800x"}`, `{"a":"\uD800\u0041"}`} {
		if _, e := DecodeFiniteStructuredJSON(s); e == nil {
			t.Fatal(s)
		}
	}
	for _, s := range []string{`{"a":"\uD83D\uDE00"}`, `{"a":"\\uD800"}`, `{"a":"🙂"}`} {
		if _, e := DecodeFiniteStructuredJSON(s); e != nil {
			t.Fatal(s, e)
		}
	}
}
