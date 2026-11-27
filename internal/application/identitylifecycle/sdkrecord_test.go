package identitylifecycle

import (
	"crypto/rand"
	"encoding/hex"
	"testing"
)

func TestSDKVerifierRejectsMalformedPasswordRecords(t *testing.T) {
	random := make([]byte, 32)
	if _, err := rand.Read(random); err != nil {
		t.Fatal(err)
	}
	secret := hex.EncodeToString(random)
	algorithm, iterations, salt, hash, err := HashSDKPassword(secret)
	if err != nil {
		t.Fatal(err)
	}
	cases := map[string][2]string{
		"empty salt and digest": {"", ""},
		"truncated salt":        {salt[:2], hash},
		"oversized salt":        {salt + "00", hash},
		"truncated digest":      {salt, hash[:2]},
		"oversized digest":      {salt, hash + "00"},
	}
	for name, record := range cases {
		t.Run(name, func(t *testing.T) {
			if VerifySDKPassword(algorithm, iterations, record[0], record[1], secret) {
				t.Fatalf("malformed record accepted: salt=%q hash=%q", record[0], record[1])
			}
		})
	}
	if !VerifySDKPassword(algorithm, iterations, salt, hash, secret) {
		t.Fatal("a well-formed record was refused")
	}
}

func TestSDKImporterRejectsMalformedPasswordRecords(t *testing.T) {
	accountID, err := newSDKAccountID()
	if err != nil {
		t.Fatal(err)
	}
	_, _, salt, hash, err := HashSDKPassword("secret-1")
	if err != nil {
		t.Fatal(err)
	}
	valid := SDKImportLogin{
		Normalized: "record-login", Display: "record-login", AccountUID: accountID.UUID().String(),
		Algorithm: SDKPasswordAlgorithm, Iterations: SDKPasswordIterations, Salt: salt, Hash: hash,
	}
	cases := map[string]func(*SDKImportLogin){
		"empty salt and digest": func(login *SDKImportLogin) { login.Salt, login.Hash = "", "" },
		"truncated salt":        func(login *SDKImportLogin) { login.Salt = salt[:2] },
		"oversized salt":        func(login *SDKImportLogin) { login.Salt = salt + "00" },
		"truncated digest":      func(login *SDKImportLogin) { login.Hash = hash[:2] },
		"oversized digest":      func(login *SDKImportLogin) { login.Hash = hash + "00" },
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			login := valid
			mutate(&login)
			input := SDKImportInput{Logins: []SDKImportLogin{login}}
			if err := input.validate(); err == nil {
				t.Fatalf("import validation accepts a malformed password record: salt=%q hash=%q", login.Salt, login.Hash)
			}
		})
	}
	if err := (SDKImportInput{Logins: []SDKImportLogin{valid}}).validate(); err != nil {
		t.Fatalf("a well-formed record was refused: %v", err)
	}
}
