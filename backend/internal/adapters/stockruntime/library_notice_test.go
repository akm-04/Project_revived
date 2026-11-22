package stockruntime

import (
	"testing"

	app "gxb.local/backend/v2/internal/application/librarylocal"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/protocol/amf3"
)

func TestLibraryMissionNoticeFrameValidatesNotice20(t *testing.T) {
	frame := libraryMissionNoticeFrame(app.MissionNotice{PartnerID: 7, MissionID: 1001, Process: 1, MissionState: lib.MissionAwarded, Favor: 118})
	if err := ValidateLibraryMissionNotice(frame); err != nil {
		t.Fatalf("frame %v", err)
	}
	fields, ok := libraryMissionNoticeFields(frame)
	if !ok || fields["partner_id"] != int64(7) || fields["favor"] != int64(118) {
		t.Fatalf("fields %#v", fields)
	}
	noFavor := &amf3.Object{Properties: []amf3.Property{
		{Name: "notice_type", Value: LibraryMissionNoticeType},
		{Name: "params", Value: &amf3.Object{Properties: []amf3.Property{
			{Name: "partner_id", Value: int64(7)},
			{Name: "mission_info", Value: &amf3.Object{Properties: []amf3.Property{
				{Name: "mission_id", Value: int64(1001)}, {Name: "process", Value: int64(1)}, {Name: "mission_state", Value: int64(lib.MissionAwarded)},
			}}},
		}}},
	}}
	if err := ValidateLibraryMissionNotice(noFavor); err == nil {
		t.Fatal("missing favor validated")
	}
	wrongType := libraryMissionNoticeFrame(app.MissionNotice{PartnerID: 7, MissionID: 1001, Process: 1, MissionState: lib.MissionAwarded, Favor: 118})
	wrongType.Properties[0].Value = int64(19)
	if err := ValidateLibraryMissionNotice(wrongType); err == nil {
		t.Fatal("notice 19 validated as notice 20")
	}
}

func TestParseLibraryMissionNoticeRef(t *testing.T) {
	player, partner, mission, err := parseLibraryMissionNoticeRef("100001:7:1001")
	if err != nil || int64(player) != 100001 || partner != 7 || mission != 1001 {
		t.Fatalf("ref (%d,%d,%d,%v)", player, partner, mission, err)
	}
	for _, raw := range []string{"", "100001:7", "100001:7:", "100001::1001", "0100001:7:1001", "100001:0:1001", "100001:7:0", "x:7:1001"} {
		if _, _, _, err := parseLibraryMissionNoticeRef(raw); err == nil {
			t.Fatalf("%q parsed", raw)
		}
	}
}

func TestParseLibraryPartnerLogRef(t *testing.T) {
	player, partner, err := parseLibraryPartnerLogRef("100001:7")
	if err != nil || int64(player) != 100001 || partner != 7 {
		t.Fatalf("ref (%d,%d,%v)", player, partner, err)
	}
	for _, raw := range []string{"", "100001", "100001:", ":7", "100001:7:8", "0100001:7", "100001:0", "x:7"} {
		if _, _, err := parseLibraryPartnerLogRef(raw); err == nil {
			t.Fatalf("%q parsed", raw)
		}
	}
}

func TestLibraryPartnerLogFrameValidatesNotice24(t *testing.T) {
	frame := libraryPartnerLogFrame(7, map[string]any{"10001": map[string]any{"time": int64(100)}})
	if err := ValidateLibraryPartnerLogNotice(frame); err != nil {
		t.Fatalf("frame %v", err)
	}
	fields, ok := libraryPartnerLogFields(frame)
	if !ok || fields["partner_id"] != int64(7) {
		t.Fatalf("fields %#v", fields)
	}
	if err := ValidateLibraryPartnerLogNotice(libraryPartnerLogFrame(7, nil)); err == nil {
		t.Fatal("nil log map validated")
	}
	wrongType := &amf3.Object{Properties: []amf3.Property{
		{Name: "notice_type", Value: int64(23)},
		{Name: "params", Value: &amf3.Object{Properties: []amf3.Property{{Name: "partner_id", Value: int64(7)}, {Name: "log_info", Value: map[string]any{}}}}},
	}}
	if err := ValidateLibraryPartnerLogNotice(wrongType); err == nil {
		t.Fatal("notice 23 validated as notice 24")
	}
}
