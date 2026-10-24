package combat

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

// TrustProfile names who produces an attempt's battle result (PASS748
// trust_profile_registry). A new behaviour is a new version, never an edit.
type TrustProfile struct {
	ID      string
	Version int
}

type trustRules struct {
	serverResolution bool
	supersedes       bool
	noValue          bool
}

var (
	ServerReport               = TrustProfile{TrustProfileID, TrustProfileVersion}
	ClientSummaryAttested      = TrustProfile{"CLIENT_SUMMARY_ATTESTED_V1", 1}
	ClientFullReportAttested   = TrustProfile{"CLIENT_FULL_REPORT_ATTESTED_V1", 1}
	ServerEntropyClientDerived = TrustProfile{"SERVER_ENTROPY_CLIENT_DERIVED_V1", 1}
	PracticeNoValue            = TrustProfile{"PRACTICE_NO_VALUE_V1", 1}
)

// Only the server profile runs the resolver; the client-run profiles end by
// attestation and close an open attempt on a different-stage START (PASS120).
var trustProfiles = map[TrustProfile]trustRules{
	ServerReport:               {serverResolution: true},
	ClientSummaryAttested:      {supersedes: true},
	ClientFullReportAttested:   {supersedes: true},
	ServerEntropyClientDerived: {supersedes: true},
	PracticeNoValue:            {supersedes: true, noValue: true},
}

func (p TrustProfile) Registered() bool {
	_, ok := trustProfiles[p]
	return ok
}

func (p TrustProfile) ServerResolution() bool { return trustProfiles[p].serverResolution }

func (p TrustProfile) Supersedes() bool { return trustProfiles[p].supersedes }

// SettlesValue is false for a practice profile: no attestation verdict or
// resolution of it may reach a Grant (PASS418 H-28, HRC-50).
func (p TrustProfile) SettlesValue() bool { return !trustProfiles[p].noValue }

func registeredProfileID(id string) bool {
	for profile := range trustProfiles {
		if profile.ID == id {
			return true
		}
	}
	return false
}

// FightExistCode is the source error a duplicate terminal returns (PASS418).
const FightExistCode = 30005

type ReplayResponse string

const (
	ReplayOK                ReplayResponse = "OK"
	ReplayFightExist        ReplayResponse = "FIGHT_EXIST"
	ReplayCurrentProjection ReplayResponse = "CURRENT_PROJECTION"
	ReplayStoredReport      ReplayResponse = "STORED_REPORT"
	ReplaySemanticError     ReplayResponse = "SEMANTIC_ERROR"
)

// ReplaySpec is the mode family's registered answer to a duplicate terminal,
// pinned on the attempt so a replay never consults mutable mode state.
type ReplaySpec struct {
	Response  ReplayResponse
	ErrorCode int
}

func (r ReplaySpec) valid(status ResolverStatus) bool {
	coded := r.Response == ReplayFightExist || r.Response == ReplaySemanticError
	switch r.Response {
	case ReplayOK, ReplayFightExist, ReplayCurrentProjection, ReplaySemanticError:
	case ReplayStoredReport:
		if status == ResolverNotRequired {
			return false
		}
	default:
		return false
	}
	return coded == (r.ErrorCode > 0) && r.ErrorCode >= 0
}

const StartPackagePolicy = "HMAC_SHA256_COUNTER_START_PACKAGE_V1"

// PackageRoot keys the START package stream apart from the resolver stream, so
// issuing a package never shifts a server-resolved report.
func PackageRoot(root [32]byte) [32]byte {
	return mac(root[:], []byte("gxb-combat/start-package/v1"))
}

// StartPackage is the server entropy a client-run attempt receives at START;
// a same-stage START replays these bytes instead of drawing again.
type StartPackage struct {
	AttemptID ids.UUID
	Policy    string
	Draws     uint64
	Canonical json.RawMessage
}

func (p StartPackage) Validate() error {
	canonical, err := CanonicalJSON(p.Canonical)
	if p.AttemptID.IsZero() || p.Policy != StartPackagePolicy || err != nil || !bytes.Equal(canonical, p.Canonical) {
		return ErrInvalid
	}
	return nil
}

func (p StartPackage) Hash() string { return contentHash(p.Canonical) }

type Verdict string

const (
	VerdictAccepted Verdict = "ACCEPTED"
	VerdictRejected Verdict = "REJECTED"
)

// Attestation stores the validator's verdict over a client-produced summary;
// the summary is CLIENT_ATTESTED evidence, never a server replay (D9 Q4).
type Attestation struct {
	AttemptID        ids.UUID
	ValidatorID      string
	ValidatorVersion int
	Verdict          Verdict
	Summary          json.RawMessage
	RecordedAt       time.Time
}

func (a Attestation) Validate() error {
	verdict := a.Verdict == VerdictAccepted || a.Verdict == VerdictRejected
	if a.AttemptID.IsZero() || !versionedID.MatchString(a.ValidatorID) || a.ValidatorVersion <= 0 || !verdict || !canonicalObject(a.Summary) || a.RecordedAt.IsZero() || a.RecordedAt.Location() != time.UTC {
		return ErrInvalid
	}
	return nil
}

func (a Attestation) SummaryHash() string { return contentHash(a.Summary) }

func contentHash(raw []byte) string {
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}
