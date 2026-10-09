package httpedge

import (
	"gxb.local/backend/v2/internal/protocol/limits"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

func TestGuildBroadcastRawBoundaryCannotLoseDuplicateEvidence(t *testing.T) {
	for _, raw := range []string{
		`{"mid":588,"title":"a","title":"b","content":"body"}`,
		`{"mid":588,"title":"a","\u0074itle":"b","content":"body"}`,
		`{"mid":588,"mid":56,"title":"a","content":"body"}`,
		`{"mid":56,"mid":588,"title":"a","content":"body"}`,
		`{"mid":588,"title":"\ud800","content":"body"}`,
	} {
		r := httptest.NewRequest("POST", "/", strings.NewReader(url.Values{"payload": {raw}}.Encode()))
		r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		if _, e := Decode(r, limits.Default()); e == nil {
			t.Fatal("ambiguous588 raw accepted", raw)
		}
	}
	raw := `{"mid":588,"token":"t","region":1,"v_":"v","app_v":"a","platform":3,"title":" a ","content":"\t body \n"}`
	r := httptest.NewRequest("POST", "/", strings.NewReader(url.Values{"payload": {raw}}.Encode()))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	d, e := Decode(r, limits.Default())
	if e != nil || d.MID != 588 || d.Params["title"] != " a " || d.Params["content"] != "\t body \n" {
		t.Fatal("588 byte preservation", d, e)
	}
}
