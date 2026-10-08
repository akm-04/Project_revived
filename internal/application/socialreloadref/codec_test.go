package socialreloadref

import (
	"gxb.local/backend/v2/internal/foundation/ids"
	"strings"
	"testing"
)

func TestFiniteCodecRelationCompatibilityGiftCanonical(t *testing.T) {
	old := "r1|200001|100001|3|1|100001|200001|7"
	r, e := DecodeReloadReference(old)
	if e != nil {
		t.Fatal(e)
	}
	raw, e := r.Encode()
	if e != nil || raw != old {
		t.Fatal(raw, e)
	}
	u, _ := ids.ParseUUID("12345678-1234-4234-8234-123456789abc")
	for _, p := range []ReloadPurpose{ReloadGiftRecipientNotice, ReloadGiftSenderList} {
		r = ReloadReference{Recipient: 200001, Actor: 100001, RootVersion: 3, Purpose: p, TransferID: u}
		raw, e = r.Encode()
		if e != nil {
			t.Fatal(e)
		}
		v, e := DecodeReloadReference(raw)
		if e != nil || v != r {
			t.Fatal(v, e)
		}
		for _, bad := range []string{raw + "|x", strings.Replace(raw, "g1|200001", "g1|0200001", 1), strings.Replace(raw, "|100001|", "|200001|", 1), strings.Replace(raw, "|3|", "|0|", 1), strings.ToUpper(raw), strings.Replace(raw, u.String(), "00000000-0000-0000-0000-000000000000", 1), strings.Replace(raw, "g1|", "r1|", 1)} {
			if _, e = DecodeReloadReference(bad); e == nil {
				t.Fatal(bad)
			}
		}
	}
	for _, p := range []ReloadPurpose{0, 7, 255} {
		r.Purpose = p
		if _, e = r.Encode(); e == nil {
			t.Fatal(p)
		}
	}
}
