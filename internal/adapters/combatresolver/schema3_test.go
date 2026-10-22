package combatresolver

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"path/filepath"
	"strings"
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

// lineupGenuine is the genuine I8-3B owned team with the assist partner of
// fight 19007 on side A against the monster waves of fight (I8-6B, D23).
func lineupGenuine(t *testing.T, fight int64) combat.Snapshot {
	t.Helper()
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	owned, _ := borrowedGenuine(t)
	_, assist, err := corpus.BattleLineup(19007)
	if err != nil {
		t.Fatal(err)
	}
	waves, _, err := corpus.BattleLineup(fight)
	if err != nil {
		t.Fatal(err)
	}
	shaped := func(origin combat.Origin, id int64) combat.Actor {
		class, present, known := corpus.FighterClass("monster", id)
		if !present || !known {
			t.Fatal("monster class", id)
		}
		params, _ := combat.CanonicalJSON(map[string]any{"table_id": id})
		return combat.Actor{Origin: origin, Kind: combat.HeroActor, Identity: id, TableID: id, FighterClass: class, Params: params}
	}
	s := owned
	trial := shaped(combat.Trial, assist[0])
	trial.Provenance = &combat.Provenance{Capability: "BATTLE_ASSIST_PARTNER_V1", Reference: "battle/19007/1"}
	s.Battle.TeamA = append(append([]combat.Actor{}, owned.Battle.TeamA...), trial)
	s.Battle.WavesB = nil
	for _, wave := range waves {
		actors := []combat.Actor{}
		for _, id := range wave {
			actors = append(actors, shaped(combat.Template, id))
		}
		s.Battle.WavesB = append(s.Battle.WavesB, actors)
	}
	if _, _, err = s.Canonical(); err != nil {
		t.Fatal(err)
	}
	return s
}

// A table-shaped lineup populates from source rows (populateWithTableID) and
// resolves deterministically; a full-params TEMPLATE is unaffected (the
// existing fixture tests keep their bytes). Fight 10000 is one wave.
func TestTableShapedLineupResolves(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	s := lineupGenuine(t, 10000)
	root := sha256.Sum256([]byte("i8-6b-lineup-root"))
	first, err := Resolve(corpus, s, root)
	if err != nil {
		t.Fatal(err)
	}
	again, err := Resolve(corpus, s, root)
	if err != nil || !bytes.Equal(first.Report, again.Report) || first.Outcome != again.Outcome {
		t.Fatal("lineup report not deterministic", err)
	}
	if first.Outcome.Frames <= 0 || !bytes.Contains(first.Report, []byte("90000006")) || !bytes.Contains(first.Report, []byte("80136130")) {
		t.Fatal("lineup report must carry the monsters and the assist partner", first.Outcome)
	}
}

// D23f: a multi-wave fight is refused before the VM runs instead of spinning to
// the frame bound waiting for the client's next-battle press.
func TestMultiWaveLineupRefused(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	_, err = Resolve(corpus, lineupGenuine(t, 19007), sha256.Sum256([]byte("i8-6b-multi-wave")))
	if !errors.Is(err, ErrDeterministic) || !strings.Contains(err.Error(), "multi-wave") {
		t.Fatal("multi-wave lineup must be refused", err)
	}
}
