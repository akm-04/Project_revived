package mentor

import (
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

func TestRelationshipProofAndTerminalValidation(t *testing.T) {
	identifier, _ := ids.NewUUID()
	at := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	valid := Relationship{ID: identifier, Mentor: 125001, Student: 125002, Server: 1, ContentRevision: strings.Repeat("a", 64), PolicyVersion: MinimumLevelGapPolicy, AcceptedAt: at, Version: 1}
	if err := valid.Validate(); err != nil {
		t.Fatal(err)
	}
	cases := map[string]func(*Relationship){
		"self":                 func(record *Relationship) { record.Student = record.Mentor },
		"cross-server":         func(record *Relationship) { record.Student = 225002 },
		"wrong-server":         func(record *Relationship) { record.Server = 2 },
		"bad-revision":         func(record *Relationship) { record.ContentRevision = strings.Repeat("z", 64) },
		"missing-policy":       func(record *Relationship) { record.PolicyVersion = "" },
		"missing-identity":     func(record *Relationship) { record.ID = ids.UUID{} },
		"bad-version":          func(record *Relationship) { record.Version = 0 },
		"unqualified-timezone": func(record *Relationship) { record.AcceptedAt = at.In(time.FixedZone("other", 3600)) },
		"end-before-start":     func(record *Relationship) { ended := at.Add(-time.Second); record.EndedAt = &ended; record.Version = 2 },
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			record := valid
			mutate(&record)
			if record.Validate() == nil {
				t.Fatal("invalid relationship admitted")
			}
		})
	}
	ended := at.Add(time.Hour)
	valid.EndedAt = &ended
	valid.Version = 2
	if err := valid.Validate(); err != nil {
		t.Fatal(err)
	}
}

func TestRelationshipPolicyVersionIsCanonical(t *testing.T) {
	identifier, _ := ids.NewUUID()
	record := Relationship{
		ID: identifier, Mentor: 125001, Student: 125002, Server: 1,
		ContentRevision: strings.Repeat("a", 64), PolicyVersion: " I9_MENTOR_LEVEL_GAP_AT_LEAST_V1 ",
		AcceptedAt: time.Date(2026, 1, 2, 0, 0, 0, 0, time.UTC), Version: 1,
	}
	if err := record.Validate(); !errors.Is(err, ErrRelationship) {
		t.Fatalf("padded policy version admitted: %v", err)
	}
	record.PolicyVersion = "anything"
	if err := record.Validate(); !errors.Is(err, ErrRelationship) {
		t.Fatalf("unknown policy version admitted: %v", err)
	}
	record.PolicyVersion = MinimumLevelGapPolicy
	if err := record.Validate(); err != nil {
		t.Fatal(err)
	}
}
