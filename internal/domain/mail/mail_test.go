package mail

import (
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"reflect"
	"testing"
	"time"
)

func TestNormalWireNamespaceIsBooleanFalseNotNumericZero(t *testing.T) {
	u, _ := ids.NewUUID()
	r := Record{MailUUID: u, Recipient: identity.PlayerID(100001), Address: Address{Namespace: Normal, WireID: 7}, SourceKind: "system", SourceKey: "x", CreatedAt: time.Unix(10, 0), Shown: true, Platform: AnyPlatform, CompatibilityPolicyVersion: "p1", StateVersion: 1}
	m, e := r.WireProjection()
	if e != nil {
		t.Fatal(e)
	}
	v, ok := m["is_region"].(bool)
	if !ok || v {
		t.Fatalf("is_region=%#v must be bool false", m["is_region"])
	}
}
func TestMID370CanonicalizesNamespacesDedupesAndSorts(t *testing.T) {
	got, e := ParseMID370("9|7|9", "3|2", 20)
	if e != nil {
		t.Fatal(e)
	}
	want := []Address{{Normal, 7}, {Normal, 9}, {Region, 2}, {Region, 3}}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got=%v want=%v", got, want)
	}
	a, _ := BatchSemanticKey(identity.PlayerID(100001), got)
	b, _ := BatchSemanticKey(identity.PlayerID(100001), []Address{{Region, 3}, {Normal, 9}, {Normal, 7}, {Region, 2}})
	if a != b {
		t.Fatal("same compound address set produced different semantic key")
	}
}
func TestAttachmentProjectionUsesSourceVisibleAttachShape(t *testing.T) {
	u, _ := ids.NewUUID()
	r := Record{MailUUID: u, Recipient: identity.PlayerID(1), Address: Address{Normal, 1}, SourceKind: "grant-overflow", SourceKey: "k", CreatedAt: time.Unix(1, 0), Shown: true, Platform: AnyPlatform, CompatibilityPolicyVersion: "p1", StateVersion: 1, Attachments: []Attachment{{Ordinal: 0, Line: grant.Line{Kind: grant.StackItem, ItemID: 42, Amount: 3}}}}
	m, e := r.WireProjection()
	if e != nil {
		t.Fatal(e)
	}
	a := m["attach"].([]any)[0].(map[string]any)
	if a["item"] != int64(42) || a["num"] != int64(3) {
		t.Fatalf("attach=%#v", a)
	}
}
