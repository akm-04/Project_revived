package combatresolver

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
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

// borrowedGenuine is the genuine I8-3B fight with its Hero and Pet lent by
// their owner to another player (I8-6A).
func borrowedGenuine(t *testing.T) (owned, borrowed combat.Snapshot) {
	t.Helper()
	raw := readFile(t, filepath.Join("testdata", "i8_3b_owned_snapshot.json"))
	sum := sha256.Sum256(raw)
	owned, err := combat.DecodeSnapshot(raw, hex.EncodeToString(sum[:]))
	if err != nil {
		t.Fatal(err)
	}
	owned.Schema = combat.SnapshotSchema
	borrowed = owned
	lend := func(actors []combat.Actor) []combat.Actor {
		lent := append([]combat.Actor{}, actors...)
		lent[0].Origin, lent[0].Provenance = combat.Borrowed, &combat.Provenance{Capability: "FIXTURE_GUILD_RENTAL_V1", Reference: "loan/1"}
		return lent
	}
	borrowed.Battle.TeamA, borrowed.Battle.PetsA = lend(owned.Battle.TeamA), lend(owned.Battle.PetsA)
	if _, _, err = borrowed.Canonical(); err != nil {
		t.Fatal(err)
	}
	return owned, borrowed
}

// H-20: a borrowed Hero and Pet fight exactly as their lender's own actors; the
// origin and provenance are snapshot facts the resolver never reads.
func TestBorrowedActorsResolveAsLenderOwned(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	owned, borrowed := borrowedGenuine(t)
	root := sha256.Sum256([]byte("i8-6a-borrowed-root"))
	want, err := Resolve(corpus, owned, root)
	if err != nil {
		t.Fatal(err)
	}
	got, err := Resolve(corpus, borrowed, root)
	if err != nil || !bytes.Equal(got.Report, want.Report) || got.Outcome != want.Outcome || got.EntropyDraws != want.EntropyDraws {
		t.Fatal("borrowed report differs", err)
	}
	if !bytes.Contains(got.Report, []byte(fmt.Sprint(borrowed.Battle.TeamA[0].Player))) {
		t.Fatal("report participants must carry the lender")
	}
}
