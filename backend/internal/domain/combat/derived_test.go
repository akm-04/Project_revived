package combat

import (
	"bytes"
	"encoding/json"
	"testing"
	"time"
)

var dodgeballPolicy = DrawPolicy{ID: "FIXTURE_DODGEBALL_DRAWS_V1", Version: 1, Streams: []DrawStream{{Name: "self_rd", Length: 60, Low: 1, High: PermilleScale}, {Name: "friend_rd", Length: 60, Low: 1, High: PermilleScale}}}

// challengeSnapshot is a battle-less Dodgeball START: three targets, the
// first and third of the same sandbag table id.
func challengeSnapshot() Snapshot {
	s := fixtureSnapshot()
	s.TrustProfile, s.Battle, s.Players, s.ProducerProfile = ServerEntropyClientDerived.ID, Battle{}, nil, ""
	s.Challenge = &Challenge{Targets: []int64{101, 102, 101}}
	return s
}

func TestChallengeSnapshotRules(t *testing.T) {
	raw, hash, err := challengeSnapshot().Canonical()
	if err != nil {
		t.Fatal(err)
	}
	if _, err = DecodeSnapshot(raw, hash); err != nil {
		t.Fatal(err)
	}
	plain, _, err := fixtureSnapshot().Canonical()
	if err != nil || bytes.Contains(plain, []byte("challenge")) {
		t.Fatal("a battle snapshot must keep its bytes", err)
	}
	cases := map[string]func(*Snapshot){
		"other profile":    func(s *Snapshot) { s.TrustProfile = ClientSummaryAttested.ID },
		"schema 2":         func(s *Snapshot) { s.Schema = ContextSnapshotSchema },
		"battle beside it": func(s *Snapshot) { s.Battle = fixtureSnapshot().Battle },
		"campaign type":    func(s *Snapshot) { s.Battle.CampaignType = 1 },
		"players":          func(s *Snapshot) { s.Players = fixtureSnapshot().Players },
		"producer profile": func(s *Snapshot) { s.ProducerProfile = ProducerProfileID },
		"no targets":       func(s *Snapshot) { s.Challenge.Targets = nil },
		"zero target":      func(s *Snapshot) { s.Challenge.Targets[1] = 0 },
	}
	for name, mutate := range cases {
		s := challengeSnapshot()
		mutate(&s)
		if s.Validate() == nil {
			t.Fatal(name)
		}
	}
	derivedBattle := fixtureSnapshot()
	derivedBattle.TrustProfile = ServerEntropyClientDerived.ID
	if derivedBattle.Validate() != nil {
		t.Fatal("a client-derived START may still freeze a battle")
	}
}

func TestDrawPolicyBuildDeterministicPerAttempt(t *testing.T) {
	build := func(seed byte) json.RawMessage {
		value, err := dodgeballPolicy.Build(NewStream(PackageRoot([32]byte{seed})))
		if err != nil {
			t.Fatal(err)
		}
		canonical, err := CanonicalJSON(value)
		if err != nil {
			t.Fatal(err)
		}
		return canonical
	}
	first := build(1)
	if !bytes.Equal(first, build(1)) || bytes.Equal(first, build(2)) {
		t.Fatal("draws must repeat per attempt root and differ across attempts")
	}
	pack, err := DecodeDrawPackage(StartPackage{Canonical: first})
	if err != nil || !dodgeballPolicy.Issued(pack) {
		t.Fatal("decode", err)
	}
	for _, s := range dodgeballPolicy.Streams {
		draws := pack.Streams[s.Name]
		if len(draws) != s.Length {
			t.Fatal(s.Name, len(draws))
		}
		for _, draw := range draws {
			if draw < s.Low || draw > s.High {
				t.Fatal(s.Name, draw)
			}
		}
	}
	other := dodgeballPolicy
	other.Version = 2
	if other.Issued(pack) {
		t.Fatal("another version issued the package")
	}
	if _, err = DecodeDrawPackage(StartPackage{Canonical: json.RawMessage(`{"seeds":[1]}`)}); err == nil {
		t.Fatal("a package without a draw policy decoded")
	}
	invalid := []DrawPolicy{
		{ID: "FIXTURE_V1", Version: 1},
		{ID: "fixture_V1", Version: 1, Streams: dodgeballPolicy.Streams},
		{ID: "FIXTURE_V1", Streams: dodgeballPolicy.Streams},
		{ID: "FIXTURE_V1", Version: 1, Streams: []DrawStream{{Name: "a", Length: 1, High: 1}, {Name: "a", Length: 1, High: 1}}},
		{ID: "FIXTURE_V1", Version: 1, Streams: []DrawStream{{Name: "a", Length: 0, High: 1}}},
		{ID: "FIXTURE_V1", Version: 1, Streams: []DrawStream{{Name: "a", Length: maxDrawLength + 1, High: 1}}},
		{ID: "FIXTURE_V1", Version: 1, Streams: []DrawStream{{Name: "a", Length: 1, Low: 2, High: 1}}},
		{ID: "FIXTURE_V1", Version: 1, Streams: []DrawStream{{Name: "a", Length: 1, High: PermilleScale + 1}}},
		{ID: "FIXTURE_V1", Version: 1, Streams: []DrawStream{{Length: 1, High: 1}}},
	}
	for _, policy := range invalid {
		if policy.Valid() {
			t.Fatal("invalid policy accepted", policy)
		}
	}
}

func judgedPackage() DrawPackage {
	return DrawPackage{Policy: dodgeballPolicy.ID, Version: 1, Streams: map[string][]int64{"self_rd": {200, 900, 1000}, "friend_rd": {50, 700, 1}}}
}

func acceptedDerivation() Derivation {
	return Derivation{Claims: []DrawClaim{
		{Stream: "self_rd", Index: 1, Target: 1, Permille: 200},
		{Stream: "self_rd", Index: 1, Target: 3, Permille: 500},
		{Stream: "friend_rd", Index: 1, Target: 0, Permille: 100},
		{Stream: "friend_rd", Index: 1, Target: 2, Permille: 1000},
	}}
}

func TestDrawPackageJudge(t *testing.T) {
	if verdict, reason := judgedPackage().Judge(challengeSnapshot(), acceptedDerivation()); verdict != VerdictAccepted || reason != "" {
		t.Fatal(verdict, reason)
	}
	if verdict, _ := judgedPackage().Judge(challengeSnapshot(), Derivation{}); verdict != VerdictAccepted {
		t.Fatal("no success is a valid derivation")
	}
	cases := map[string]struct {
		mutate func(*Derivation)
		reason string
	}{
		"unknown stream":     {func(d *Derivation) { d.Claims[0].Stream = "boss_rd" }, "STREAM_UNKNOWN"},
		"index zero":         {func(d *Derivation) { d.Claims[0].Index = 0 }, "INDEX_OUT_OF_RANGE"},
		"index past draws":   {func(d *Derivation) { d.Claims[0].Index = 4 }, "INDEX_OUT_OF_RANGE"},
		"target past layout": {func(d *Derivation) { d.Claims[0].Target = 4 }, "TARGET_UNKNOWN"},
		"negative target":    {func(d *Derivation) { d.Claims[0].Target = -1 }, "TARGET_UNKNOWN"},
		"target won twice":   {func(d *Derivation) { d.Claims[1].Target = 1 }, "TARGET_DUPLICATE"},
		"gate drawn twice":   {func(d *Derivation) { d.Claims = append(d.Claims, d.Claims[2]) }, "GATE_DUPLICATE"},
		"negative permille":  {func(d *Derivation) { d.Claims[2].Permille = -1 }, "PERMILLE_OUT_OF_RANGE"},
		"permille above 1":   {func(d *Derivation) { d.Claims[2].Permille = PermilleScale + 1 }, "PERMILLE_OUT_OF_RANGE"},
		"draw denies hit":    {func(d *Derivation) { d.Claims[0].Permille = 199 }, "DRAW_ABOVE_CLAIM"},
		"certain only":       {func(d *Derivation) { d.Claims[0].Index, d.Claims[0].Permille = 3, 999 }, "DRAW_ABOVE_CLAIM"},
	}
	for name, c := range cases {
		derivation := acceptedDerivation()
		c.mutate(&derivation)
		if verdict, reason := judgedPackage().Judge(challengeSnapshot(), derivation); verdict != VerdictRejected || reason != c.reason {
			t.Fatal(name, verdict, reason)
		}
	}
	battle := fixtureSnapshot()
	battle.TrustProfile = ServerEntropyClientDerived.ID
	if verdict, reason := judgedPackage().Judge(battle, acceptedDerivation()); verdict != VerdictRejected || reason != "TARGET_UNKNOWN" {
		t.Fatal("a battle START has no challenge targets", reason)
	}
}

func practiceAttempt(start time.Time) Attempt {
	a := clientAttempt(start)
	a.TrustProfile = PracticeNoValue
	return a
}

func TestPracticeSettlesNoValue(t *testing.T) {
	start := time.Unix(1700000000, 0).UTC()
	a := practiceAttempt(start)
	if err := a.Validate(); err != nil || a.TrustProfile.SettlesValue() || !ClientSummaryAttested.SettlesValue() || !ServerReport.SettlesValue() {
		t.Fatal("practice profile", err)
	}
	for _, kind := range []string{"WIN", RejectedKind, PracticeKind} {
		if _, err := a.Attest(kind, "attest:x", start.Add(time.Second)); err == nil {
			t.Fatal("a practice attempt attested", kind)
		}
	}
	if _, err := a.EndPractice(a.ResultDeadline); err == nil {
		t.Fatal("practice ended at the deadline")
	}
	ended, err := a.EndPractice(start.Add(time.Second))
	if err != nil || ended.TerminalKind != PracticeKind || ended.SemanticReceiptID != "practice:"+a.ID.String() || ended.State != Terminal {
		t.Fatal("end practice", ended, err)
	}
	if _, err = ended.EndPractice(start.Add(2 * time.Second)); err == nil {
		t.Fatal("practice ended twice")
	}
	if _, err = clientAttempt(start).EndPractice(start.Add(time.Second)); err == nil {
		t.Fatal("a value-bearing attempt ended as practice")
	}
	if _, err = clientAttempt(start).Attest(PracticeKind, "attest:x", start.Add(time.Second)); err == nil {
		t.Fatal("a value-bearing attempt closed with the practice kind")
	}
	forged := ended
	forged.TrustProfile = ClientSummaryAttested
	if forged.Validate() == nil {
		t.Fatal("practice kind on a value-bearing profile")
	}
}

// FuzzDerivationJudge drives the stock JSON codec into Judge: an accepted
// derivation names known draws and targets once each and every claimed
// success is allowed by its draw.
func FuzzDerivationJudge(f *testing.F) {
	accepted, _ := json.Marshal(acceptedDerivation())
	f.Add(accepted)
	f.Add([]byte(`{"claims":[{"stream":"self_rd","index":2,"target":2,"permille":900},{"stream":"self_rd","index":2,"target":2,"permille":900}]}`))
	f.Add([]byte(`{"claims":[{"stream":"friend_rd","index":3,"target":0,"permille":1},{"stream":"friend_rd","index":3,"target":0,"permille":1}]}`))
	f.Add([]byte(`{"claims":[{"stream":"self_rd","index":-1,"target":99,"permille":-5}]}`))
	pack, snapshot := judgedPackage(), challengeSnapshot()
	f.Fuzz(func(t *testing.T, raw []byte) {
		var derivation Derivation
		if json.Unmarshal(raw, &derivation) != nil {
			return
		}
		verdict, reason := pack.Judge(snapshot, derivation)
		if verdict == VerdictRejected {
			if reason == "" {
				t.Fatal("rejection without reason")
			}
			return
		}
		targets, gates := map[int]bool{}, map[DrawClaim]bool{}
		for _, claim := range derivation.Claims {
			draws := pack.Streams[claim.Stream]
			if claim.Index < 1 || claim.Index > len(draws) || claim.Target < 0 || claim.Target > len(snapshot.Challenge.Targets) || claim.Permille > PermilleScale || draws[claim.Index-1] > claim.Permille {
				t.Fatal("accepted a claim outside the draws or layout", string(raw))
			}
			gate := DrawClaim{Stream: claim.Stream, Index: claim.Index}
			if claim.Target > 0 && targets[claim.Target] || claim.Target == 0 && gates[gate] {
				t.Fatal("accepted a duplicate claim", string(raw))
			}
			if claim.Target > 0 {
				targets[claim.Target] = true
				continue
			}
			gates[gate] = true
		}
	})
}
