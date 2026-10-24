package publicprofile

import (
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"gxb.local/backend/v2/internal/foundation/ids"
	"testing"
)

func TestMediaURLSelectedLiteralHTTPPolicy(t *testing.T) {
	for _, origin := range []string{"", "https://media.example", "http://user:password@media.example", "http://media.example/path", "http://media.example?q=1", "http://media.example#x", "http://media.example\n"} {
		if _, e := NewMediaURL(origin); e == nil {
			t.Fatalf("bad origin accepted: %q", origin)
		}
	}
	u, e := NewMediaURL("http://media.example:8080/")
	if e != nil {
		t.Fatal(e)
	}
	op, _ := ids.NewUUID()
	d := asset.Descriptor{Policy: asset.Policy, SHA256: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", MD5: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", Size: 100, Width: 150, Height: 150}
	r, e := u.Reference(op, d)
	if e != nil || r.Validate() != nil {
		t.Fatal("serverowned capability", e)
	}
	r.URL = "http://media.example/profile-media/" + op.String() + "/../other.png"
	if r.Validate() == nil {
		t.Fatal("unbound path accepted")
	}
}
