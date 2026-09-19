package grant

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"testing"
)

func TestGrantSemanticIdentityIsSourceBusinessIdentityNotMID(t *testing.T) {
	p := Plan{PlayerID: identity.PlayerID(100001), Source: SourceIdentity{Domain: "mail", Operation: "claim", BusinessKey: "NORMAL:7", PolicyVersion: "p1"}, Lines: []Line{{Kind: StackItem, ItemID: 42, Amount: 3}}}
	id, e := p.ReceiptIdentity()
	if e != nil {
		t.Fatal(e)
	}
	if id.SemanticKey == "" || id.Operation != "settle" {
		t.Fatalf("id=%+v", id)
	}
	q := p
	q.Source.BusinessKey = "NORMAL:8"
	id2, _ := q.ReceiptIdentity()
	if id.SemanticKey == id2.SemanticKey {
		t.Fatal("different source business keys collapsed")
	}
}
func TestOverflowMailKeyIsStableAndLineSpecific(t *testing.T) {
	p := Plan{PlayerID: identity.PlayerID(100001), Source: SourceIdentity{Domain: "redeem", Operation: "redeem", BusinessKey: "redemption:abc", PolicyVersion: "p1"}, Lines: []Line{{Kind: StackItem, ItemID: 42, Amount: 3}, {Kind: StackItem, ItemID: 42, Amount: 4}}}
	a, e := p.OverflowMailSourceKey(42, 0)
	if e != nil {
		t.Fatal(e)
	}
	b, _ := p.OverflowMailSourceKey(42, 1)
	a2, _ := p.OverflowMailSourceKey(42, 0)
	if a != a2 || a == b {
		t.Fatalf("a=%q a2=%q b=%q", a, a2, b)
	}
}

func TestGrantSemanticIdentityV2ExcludesPolicyVersionAndV1RemainsReconstructable(t *testing.T) {
	p := Plan{PlayerID: identity.PlayerID(100001), Source: SourceIdentity{Domain: "mail", Operation: "claim", BusinessKey: "mail:7", Occurrence: "1", PolicyVersion: "p1"}, Lines: []Line{{Kind: StackItem, ItemID: 42, Amount: 1}}}
	q := p
	q.Source.PolicyVersion = "p2"
	v2a, v1a, err := p.ReceiptIdentities()
	if err != nil {
		t.Fatal(err)
	}
	v2b, v1b, err := q.ReceiptIdentities()
	if err != nil {
		t.Fatal(err)
	}
	if v2a.SemanticKey != v2b.SemanticKey {
		t.Fatalf("v2 changed with policy revision: %s != %s", v2a.SemanticKey, v2b.SemanticKey)
	}
	if v1a.SemanticKey == v1b.SemanticKey {
		t.Fatal("legacy v1 failed to preserve PolicyVersion in the historical key")
	}
}

func TestOverflowMailIdentityVersioningPreservesLegacyDerivation(t *testing.T) {
	p := Plan{PlayerID: identity.PlayerID(100001), Source: SourceIdentity{Domain: "redeem", Operation: "redeem", BusinessKey: "r:1", PolicyVersion: "p1"}, Lines: []Line{{Kind: StackItem, ItemID: 42, Amount: 2}}}
	v2, err := p.OverflowMailSourceKey(42, 0)
	if err != nil {
		t.Fatal(err)
	}
	v1, err := p.LegacyOverflowMailSourceKeyV1(42, 0)
	if err != nil {
		t.Fatal(err)
	}
	if v2 == v1 || len(v2) < len("grant-overflow:v2:") || v2[:len("grant-overflow:v2:")] != "grant-overflow:v2:" {
		t.Fatalf("unexpected v2/v1 keys: %q / %q", v2, v1)
	}
}
