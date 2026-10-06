package httpedge

import (
	"gxb.local/backend/v2/internal/protocol/limits"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

func TestSocialRawDuplicateBudgetAndLegacyIsolation(t *testing.T) {
	cases := []struct {
		raw string
		bad bool
	}{
		{`{"mid":188,"msg":"x","msg":"y"}`, true},
		{`{"mid":188,"mid":56,"msg":"x"}`, true},
		{`{"mid":56,"mid":188,"msg":"x"}`, true},
		{`{"mid":184,"notice_ids":[1],"notice_ids":[2]}`, true},
		{`{"mid":188,"msg":{"x":1,"x":2}}`, true},
		{`{"mid":188,"token":"x","region":1,"v_":"a","app_v":"b","platform":3,"msg":"x"}`, false},
		{`{"mid":56,"msg":"x","msg":"y"}`, false},
	}
	for _, c := range cases {
		r := httptest.NewRequest("POST", "/", strings.NewReader(url.Values{"payload": {c.raw}}.Encode()))
		r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		_, e := Decode(r, limits.Default())
		if (e != nil) != c.bad {
			t.Fatalf("raw=%s error=%v", c.raw, e)
		}
	}
	cfg := limits.Default()
	if e := validateSocialRaw([]byte(`{"mid":188,"x":[1,2,3]}`), true, 64, 3); e == nil {
		t.Fatal("raw budget ignored")
	}
	_ = cfg
}
