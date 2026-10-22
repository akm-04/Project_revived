package combat

import (
	"bytes"
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

var successorAttempt, _ = ids.ParseUUID("6f3c2c1e-8a0b-4f53-9d3e-2b7a4c1d9e02")

func clientAttempt(start time.Time) Attempt {
	a := fixtureAttemptEnvelope(start)
	a.TrustProfile, a.ResolverStatus, a.Replay = ClientSummaryAttested, ResolverNotRequired, ReplaySpec{Response: ReplayFightExist, ErrorCode: FightExistCode}
	return a
}

func TestClientRunAttemptTransitions(t *testing.T) {
	start := time.Unix(1700000000, 0).UTC()
	a := clientAttempt(start)
	if err := a.Validate(); err != nil {
		t.Fatal(err)
	}
	if a.Runnable() {
		t.Fatal("client-run attempt runnable")
	}
	if _, err := a.Resolve(fmt.Sprintf("%064x", 8)); err == nil {
		t.Fatal("client-run attempt resolved")
	}
	if _, err := a.FailResolution(true, "SCRIPT"); err == nil {
		t.Fatal("client-run attempt failed resolution")
	}
	superseded, err := a.Supersede(successorAttempt, start)
	if err != nil || superseded.TerminalKind != SupersededKind || superseded.SemanticReceiptID != "superseded-by:"+successorAttempt.String() {
		t.Fatal("supersede", err)
	}
	if _, err = superseded.Supersede(successorAttempt, start); err == nil {
		t.Fatal("terminal attempt superseded twice")
	}
	if _, err = a.Supersede(a.ID, start); err == nil {
		t.Fatal("attempt superseded by itself")
	}
	attested, err := a.Attest("WIN", "receipt", start)
	if err != nil || attested.Unresolved() || attested.ResolutionHash != "" {
		t.Fatal("attest", err)
	}
	if _, err = a.Attest(SupersededKind, "receipt", start); err == nil {
		t.Fatal("attest used the supersede kind")
	}
	if _, err = a.Close("EXPIRED", "close", a.ResultDeadline); err != nil {
		t.Fatal("expired client-run attempt must close", err)
	}
	server := fixtureAttemptEnvelope(start)
	if _, err = server.Supersede(successorAttempt, start); err == nil {
		t.Fatal("server attempt superseded")
	}
	if _, err = server.Attest("WIN", "receipt", start); err == nil {
		t.Fatal("server attempt attested")
	}
	chained := clientAttempt(start)
	chained.ID, chained.SupersedesAttemptID = successorAttempt, fixtureAttempt
	if err = chained.Validate(); err != nil {
		t.Fatal("chain", err)
	}
}

func TestAttemptProfileInvariants(t *testing.T) {
	start := time.Unix(1700000000, 0).UTC()
	mutations := map[string]func(*Attempt){
		"unregistered profile":      func(a *Attempt) { a.TrustProfile = TrustProfile{"CLIENT_SUMMARY_ATTESTED_V1", 2} },
		"zero profile":              func(a *Attempt) { a.TrustProfile = TrustProfile{} },
		"client profile resolves":   func(a *Attempt) { a.ResolverStatus = ResolverPending },
		"stored report without run": func(a *Attempt) { a.Replay = ReplaySpec{Response: ReplayStoredReport} },
		"fight exist without code":  func(a *Attempt) { a.Replay = ReplaySpec{Response: ReplayFightExist} },
		"ok with code":              func(a *Attempt) { a.Replay = ReplaySpec{Response: ReplayOK, ErrorCode: 1} },
		"unknown replay":            func(a *Attempt) { a.Replay = ReplaySpec{Response: "MATCH_AGAIN"} },
		"chain to itself":           func(a *Attempt) { a.SupersedesAttemptID = a.ID },
		"server not required":       func(a *Attempt) { a.TrustProfile = ServerReport },
		"server chain": func(a *Attempt) {
			a.TrustProfile, a.ResolverStatus, a.SupersedesAttemptID = ServerReport, ResolverPending, successorAttempt
		},
	}
	for name, mutate := range mutations {
		a := clientAttempt(start)
		mutate(&a)
		if a.Validate() == nil {
			t.Fatal("accepted", name)
		}
	}
	server := fixtureAttemptEnvelope(start)
	server.ResolverStatus, server.State, server.TerminalKind, server.TerminalAt, server.SemanticReceiptID = ResolverPermanentFailed, Terminal, SupersededKind, &start, "r"
	if server.Validate() == nil {
		t.Fatal("server attempt ended SUPERSEDED")
	}
}

func provenanced(origin Origin, player int64) Actor {
	a := fixtureActor(origin, player)
	a.Provenance = &Provenance{Capability: "FRIEND_ASSIST_V1", Reference: "loan/1"}
	return a
}

func TestSnapshotSchema3ProfilesAndProvenance(t *testing.T) {
	legacy := fixtureSnapshot()
	legacy.Schema = ContextSnapshotSchema
	raw, _, err := legacy.Canonical()
	if err != nil || bytes.Contains(raw, []byte("provenance")) {
		t.Fatal("schema 2 bytes must stay free of schema 3 fields", err)
	}
	accepted := map[string]func(*Snapshot){
		"client profile": func(s *Snapshot) { s.TrustProfile = ClientFullReportAttested.ID },
		"borrowed":       func(s *Snapshot) { s.Battle.TeamA = append(s.Battle.TeamA, provenanced(Borrowed, 9)) },
		"trial":          func(s *Snapshot) { s.Battle.TeamA = append(s.Battle.TeamA, provenanced(Trial, 0)) },
	}
	for name, mutate := range accepted {
		s := fixtureSnapshot()
		mutate(&s)
		raw, hash, err := s.Canonical()
		if err != nil {
			t.Fatal(name, err)
		}
		if _, err = DecodeSnapshot(raw, hash); err != nil {
			t.Fatal(name, err)
		}
	}
	refused := map[string]func(*Snapshot){
		"client profile in schema 2": func(s *Snapshot) { s.Schema, s.TrustProfile = ContextSnapshotSchema, PracticeNoValue.ID },
		"unknown profile":            func(s *Snapshot) { s.TrustProfile = "CLIENT_GUESS_V1" },
		"borrowed in schema 2": func(s *Snapshot) {
			s.Schema = ContextSnapshotSchema
			s.Battle.TeamA = append(s.Battle.TeamA, provenanced(Borrowed, 9))
		},
		"borrowed without provenance": func(s *Snapshot) { s.Battle.TeamA = append(s.Battle.TeamA, fixtureActor(Borrowed, 9)) },
		"borrowed unknown lender":     func(s *Snapshot) { s.Battle.TeamA = append(s.Battle.TeamA, provenanced(Borrowed, 12)) },
		"trial with owner":            func(s *Snapshot) { s.Battle.TeamA = append(s.Battle.TeamA, provenanced(Trial, 9)) },
		"owned with provenance": func(s *Snapshot) {
			s.Battle.TeamA[0].Provenance = &Provenance{Capability: "FRIEND_ASSIST_V1", Reference: "loan/1"}
		},
		"unversioned capability": func(s *Snapshot) {
			actor := provenanced(Trial, 0)
			actor.Provenance.Capability = "trial"
			s.Battle.TeamA = append(s.Battle.TeamA, actor)
		},
	}
	for name, mutate := range refused {
		s := fixtureSnapshot()
		mutate(&s)
		if s.Validate() == nil {
			t.Fatal("accepted", name)
		}
	}
}

func TestStartPackageAndAttestationRecords(t *testing.T) {
	root := fixtureRoot(t)
	if PackageRoot(root) == root {
		t.Fatal("package stream must differ from the resolver stream")
	}
	pack := StartPackage{AttemptID: fixtureAttempt, Policy: StartPackagePolicy, Draws: 2, Canonical: json.RawMessage(`{"seeds":[1,2]}`)}
	if err := pack.Validate(); err != nil || len(pack.Hash()) != 64 {
		t.Fatal(err)
	}
	pack.Canonical = json.RawMessage(`{"seeds": [1,2]}`)
	if pack.Validate() == nil {
		t.Fatal("non-canonical package accepted")
	}
	at := time.Unix(1700000000, 0).UTC()
	attestation := Attestation{AttemptID: fixtureAttempt, ValidatorID: "TRIAL_SUMMARY_VALIDATOR_V1", ValidatorVersion: 1, Verdict: VerdictAccepted, Summary: json.RawMessage(`{"damage":10}`), RecordedAt: at}
	if err := attestation.Validate(); err != nil {
		t.Fatal(err)
	}
	refused := []func(*Attestation){
		func(a *Attestation) { a.Verdict = "MAYBE" },
		func(a *Attestation) { a.ValidatorVersion = 0 },
		func(a *Attestation) { a.Summary = json.RawMessage(`[1]`) },
		func(a *Attestation) { a.RecordedAt = at.In(time.FixedZone("x", 3600)) },
	}
	for i, mutate := range refused {
		a := attestation
		mutate(&a)
		if a.Validate() == nil {
			t.Fatal("attestation accepted", i)
		}
	}
}
