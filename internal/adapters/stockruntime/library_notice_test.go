package stockruntime

import (
	"testing"

	"gxb.local/backend/v2/internal/protocol/amf3"
)

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
