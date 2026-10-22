package combatresolver

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"path/filepath"
	"testing"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

// The I8-4 schema bump and the trust profile are envelope facts: the genuine
// I8-3B owned fight resolves to the same report bytes in every encoding.
func TestSchema3KeepsGenuineReport(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	raw := readFile(t, filepath.Join("testdata", "i8_3b_owned_snapshot.json"))
	sum := sha256.Sum256(raw)
	genuine, err := combat.DecodeSnapshot(raw, hex.EncodeToString(sum[:]))
	if err != nil || genuine.Schema != combat.ContextSnapshotSchema {
		t.Fatal("genuine fixture", genuine.Schema, err)
	}
	root := sha256.Sum256([]byte("i8-4-schema-3-root"))
	want, err := Resolve(corpus, genuine, root)
	if err != nil {
		t.Fatal(err)
	}
	for _, profile := range []string{combat.TrustProfileID, combat.ClientSummaryAttested.ID} {
		current := genuine
		current.Schema, current.TrustProfile = combat.SnapshotSchema, profile
		if _, _, err = current.Canonical(); err != nil {
			t.Fatal(profile, err)
		}
		got, err := Resolve(corpus, current, root)
		if err != nil || !bytes.Equal(got.Report, want.Report) || got.Outcome != want.Outcome || got.EntropyDraws != want.EntropyDraws {
			t.Fatal("schema 3 report differs", profile, err)
		}
	}
}
