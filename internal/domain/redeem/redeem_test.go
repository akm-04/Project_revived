package redeem

import (
	"bytes"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"testing"
	"time"
)

func TestExactNormalizationPreservesCaseWhitespacePolicy(t *testing.T) {
	v, e := Normalize(" AbC ", ExactCode)
	if e != nil || v != " AbC " {
		t.Fatalf("v=%q e=%v", v, e)
	}
	u, _ := Normalize(" AbC ", TrimAndUpperASCII)
	if u != "ABC" {
		t.Fatalf("u=%q", u)
	}
}
func TestLookupDigestIsSecretKeyedAndDoesNotExposeCode(t *testing.T) {
	a, e := LookupDigest([]byte("0123456789abcdef"), "SECRET-CODE")
	if e != nil {
		t.Fatal(e)
	}
	b, _ := LookupDigest([]byte("fedcba9876543210"), "SECRET-CODE")
	if bytes.Equal(a[:], b[:]) {
		t.Fatal("digest not keyed")
	}
}
func TestStockLevel10GateAndServerAudience(t *testing.T) {
	u, _ := ids.NewUUID()
	aid, _ := identity.AccountIDFrom(u)
	a := Actor{PlayerID: identity.PlayerID(100001), AccountID: aid, LogicalServerID: 1, Level: 10}
	c := Campaign{Status: Active, Subject: PlayerSubject, Audience: AudiencePolicy{LogicalServers: map[identity.LogicalServerID]struct{}{1: {}}}, PolicyVersion: "p1"}
	if e := Eligible(c, a, time.Unix(10, 0)); e != nil {
		t.Fatal(e)
	}
	a.Level = 9
	if e := Eligible(c, a, time.Unix(10, 0)); e == nil {
		t.Fatal("level 9 unexpectedly eligible")
	}
}

func TestGeneratedCodeAlphabetIsAPowerOfTwo(t *testing.T) {
	if len(GeneratedCodeAlphabet) != 32 {
		t.Fatalf("alphabet length = %d", len(GeneratedCodeAlphabet))
	}
}

func TestGenerateCodeUsesTheUnambiguousAlphabet(t *testing.T) {
	code, err := GenerateCode(bytes.NewReader([]byte{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}))
	if err != nil || len(code) != GeneratedCodeLength {
		t.Fatalf("code=%q err=%v", code, err)
	}
	for _, c := range code {
		if !bytes.ContainsRune([]byte(GeneratedCodeAlphabet), c) {
			t.Fatalf("code %q has %q outside the alphabet", code, c)
		}
	}
	if _, err := GenerateCode(bytes.NewReader([]byte{1, 2})); err == nil {
		t.Fatal("a short random source was accepted")
	}
}
