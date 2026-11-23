package identitylifecycle

import (
	"crypto/sha256"
	"encoding/hex"
	"strings"
	"testing"

	"golang.org/x/crypto/pbkdf2"
)

func TestNormalizeSDKLoginTrimsAndCaseFolds(t *testing.T) {
	cases := map[string]string{
		"  Player@Example.COM ": "player@example.com",
		"PLAYER@EXAMPLE.COM":    "player@example.com",
		"Straße":                "strasse",
		"":                      "",
	}
	for input, want := range cases {
		if got := NormalizeSDKLogin(input); got != want {
			t.Fatalf("NormalizeSDKLogin(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestHashSDKPasswordMatchesThePythonRecordLayout(t *testing.T) {
	algorithm, iterations, saltHex, hashHex, err := HashSDKPassword("password-1")
	if err != nil {
		t.Fatal(err)
	}
	if algorithm != "pbkdf2-sha256" || iterations != 200000 {
		t.Fatalf("record = %s %d", algorithm, iterations)
	}
	salt, err := hex.DecodeString(saltHex)
	if err != nil || len(salt) != 16 {
		t.Fatalf("salt = %q err=%v, want 16 bytes of hex", saltHex, err)
	}
	hash, err := hex.DecodeString(hashHex)
	if err != nil || len(hash) != 32 {
		t.Fatalf("hash = %q err=%v, want 32 bytes of hex", hashHex, err)
	}
	if want := pbkdf2.Key([]byte("password-1"), salt, 200000, 32, sha256.New); hex.EncodeToString(want) != hashHex {
		t.Fatal("the hash is not pbkdf2-sha256 over the stored salt")
	}
	if !VerifySDKPassword(algorithm, iterations, saltHex, hashHex, "password-1") {
		t.Fatal("the correct password was refused")
	}
	if VerifySDKPassword(algorithm, iterations, saltHex, hashHex, "password-2") {
		t.Fatal("a wrong password was accepted")
	}
	if VerifySDKPassword("bcrypt", iterations, saltHex, hashHex, "password-1") {
		t.Fatal("another algorithm was accepted")
	}
	if VerifySDKPassword(algorithm, iterations, "zz", hashHex, "password-1") {
		t.Fatal("a malformed salt was accepted")
	}
	if VerifySDKPassword(algorithm, iterations, saltHex, "zz", "password-1") {
		t.Fatal("a malformed hash was accepted")
	}
}

func sdkImportJSON(t *testing.T) string {
	t.Helper()
	_, _, salt, hash, err := HashSDKPassword("secret-1")
	if err != nil {
		t.Fatal(err)
	}
	return `{
  "accounts": [
    {"uid": "11111111-1111-4111-8111-111111111111", "type": "normal", "username": "player-one"},
    {"uid": "22222222-2222-4222-8222-222222222222", "type": "guest", "username": "guest-22222222"}
  ],
  "logins": [
    {"normalized": "player-one", "display": "Player-One", "account_uid": "11111111-1111-4111-8111-111111111111",
     "algorithm": "pbkdf2-sha256", "iterations": 200000, "salt": "` + salt + `", "hash": "` + hash + `"}
  ],
  "devices": [
    {"device_id": "device-1", "account_uid": "22222222-2222-4222-8222-222222222222"}
  ]
}`
}

func TestDecodeSDKImportAcceptsTheStandInShape(t *testing.T) {
	input, err := DecodeSDKImport(strings.NewReader(sdkImportJSON(t)))
	if err != nil {
		t.Fatal(err)
	}
	if len(input.Accounts) != 2 || len(input.Logins) != 1 || len(input.Devices) != 1 {
		t.Fatalf("decoded = %+v", input)
	}
}

func TestDecodeSDKImportRefusesBrokenRecords(t *testing.T) {
	valid := sdkImportJSON(t)
	cases := map[string]string{
		"unknown field": strings.Replace(valid, `"type": "normal",`, `"type": "normal", "extra": 1,`, 1),
		"bad uid":       strings.Replace(valid, `"11111111-1111-4111-8111-111111111111"`, `"not-a-uuid"`, 1),
		"bad type":      strings.Replace(valid, `"type": "normal"`, `"type": "system"`, 1),
		"blank name":    strings.Replace(valid, `"username": "player-one"`, `"username": " "`, 1),
		"bad algorithm": strings.Replace(valid, `"pbkdf2-sha256"`, `"sha1"`, 1),
		"bad salt":      strings.Replace(valid, `"salt": "`, `"salt": "zz`, 1),
		"bad device":    strings.Replace(valid, `"device-1"`, `""`, 1),
	}
	for name, body := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := DecodeSDKImport(strings.NewReader(body)); err == nil {
				t.Fatalf("broken import accepted: %s", body)
			}
		})
	}
}

func TestDecodeSDKImportRefusesDuplicateLoginsAndDevices(t *testing.T) {
	valid := sdkImportJSON(t)
	loginLine := `{"normalized": "player-one", "display": "Player-One", "account_uid": "11111111-1111-4111-8111-111111111111", "algorithm": "pbkdf2-sha256", "iterations": 200000, "salt": "00000000000000000000000000000000", "hash": "0000000000000000000000000000000000000000000000000000000000000000"}`
	duplicateLogin := strings.Replace(valid, `"logins": [`, `"logins": [`+loginLine+`,`, 1)
	if _, err := DecodeSDKImport(strings.NewReader(duplicateLogin)); err == nil {
		t.Fatal("a duplicate normalized login was accepted")
	}
	duplicateDevice := strings.Replace(valid, `"devices": [`, `"devices": [{"device_id": "device-1", "account_uid": "22222222-2222-4222-8222-222222222222"},`, 1)
	if _, err := DecodeSDKImport(strings.NewReader(duplicateDevice)); err == nil {
		t.Fatal("a duplicate device was accepted")
	}
}
