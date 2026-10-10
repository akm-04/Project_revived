// Package guildinvite defines retained Guild-source presentation obligations.
// Invite eligibility remains Guild-owned; a Notice never authorizes membership.
package guildinvite

import (
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
)

var ErrEvidence = errors.New("Guild Invite immutable evidence conflict")

const (
	PolicyID          = "GUILD_INVITE_PRESENTATION_V1"
	SourceKind        = "guild.invite.v1"
	NoticeType  int16 = 10
	MaxNoticeID int64 = 1<<53 - 1
)

type Tuple struct {
	GuildID    guild.ID
	Recipient  identity.PlayerID
	Generation int64
}

func (v Tuple) Validate() error {
	server := int64(v.GuildID) / 1000000
	if v.GuildID <= 0 || server < 1 || server > math.MaxInt32 || int64(v.GuildID)%1000000 == 0 || !v.Recipient.Valid() || int64(v.Recipient)/100000 != server || v.Generation < 1 {
		return ErrEvidence
	}
	return nil
}
func (v Tuple) SourceKey() (string, error) {
	if e := v.Validate(); e != nil {
		return "", e
	}
	return fmt.Sprintf("%d:%d:%d", v.GuildID, v.Recipient, v.Generation), nil
}

// NextGeneration conservatively includes the complete retained Foundation
// witness. No cursor is advanced until the caller's complete source plan closes.
func NextGeneration(cursor, current, historical int64) (int64, error) {
	if cursor < 0 || current < 0 || historical < 0 {
		return 0, ErrEvidence
	}
	high := max(cursor, current, historical)
	if high == math.MaxInt64 {
		return 0, ErrEvidence
	}
	return high + 1, nil
}

type CoreReceipt struct {
	ID                                                  ids.UUID
	OwnerKind, OwnerKey, Domain, Operation, SemanticKey string
	Schema                                              string
	Fingerprint                                         [32]byte
	OperationClass, PolicyVersion, ActorAccountUID      string
	ContextID                                           ids.UUID
	OperationStartedAt                                  time.Time
	OperationPolicyRefs                                 policy.Set
}

func (r CoreReceipt) Validate() error {
	if r.ID.IsZero() || r.OwnerKind == "" || r.OwnerKey == "" || r.Domain != "guild" || r.Operation == "" || r.SemanticKey == "" || r.Schema == "" || r.OperationClass != "I6C_GUILD" || !revision(r.PolicyVersion) || r.ActorAccountUID == "" || r.ContextID.IsZero() || r.OperationStartedAt.IsZero() {
		return ErrEvidence
	}
	return nil
}

func (r CoreReceipt) MatchOperation(op operation.Context, uid, core string) bool {
	return r.ActorAccountUID == uid && r.PolicyVersion == core && r.OperationStartedAt.UnixMicro() == op.StartedAt.UnixMicro() && r.OperationPolicyRefs.Equal(op.Policies)
}

func canonicalPositive(s string) (int64, error) {
	n, e := strconv.ParseInt(s, 10, 64)
	if e != nil || n < 1 || strconv.FormatInt(n, 10) != s {
		return 0, ErrEvidence
	}
	return n, nil
}

func InviteReceiptGeneration(key string) (actorVersion int64, target identity.PlayerID, generation int64, err error) {
	p := strings.Split(key, ":")
	if len(p) != 6 || p[0] != "actorver" || p[2] != "target" || p[4] != "gen" {
		err = ErrEvidence
		return
	}
	a, e := canonicalPositive(p[1])
	if e != nil {
		err = e
		return
	}
	t, e := canonicalPositive(p[3])
	if e != nil {
		err = e
		return
	}
	g, e := canonicalPositive(p[5])
	if e != nil {
		err = e
		return
	}
	return a, identity.PlayerID(t), g, nil
}

type Issue struct {
	Operation                                    operation.Context
	Tuple                                        Tuple
	Serial                                       int64
	Server                                       identity.LogicalServerID
	Inviter                                      identity.PlayerID
	ActorAccountUID                              string
	DecisionAt, ExpiresAt                        time.Time
	GuildName                                    string
	LastJoinEventID                              int64
	LastJoinedAt                                 time.Time
	SendEventID                                  int64
	ContentRevision, GuildCoreRevision, PolicyID string
	Core                                         CoreReceipt
}

func revision(s string) bool {
	if len(s) != 64 {
		return false
	}
	for _, c := range []byte(s) {
		if !(c >= '0' && c <= '9' || c >= 'a' && c <= 'f') {
			return false
		}
	}
	return true
}
func validOperation(op operation.Context, content, core string) bool {
	if op.ID.IsZero() || op.StartedAt.IsZero() || op.StartedAt.Location() != time.UTC || !revision(content) || !revision(core) {
		return false
	}
	for k, want := range map[string]string{"content": content, "guild-core": core, "guild-invite": PolicyID} {
		v, ok := op.Policies.Get(k)
		if !ok || v != want {
			return false
		}
	}
	return true
}
func (s Issue) Validate() error {
	if s.Tuple.Validate() != nil || s.Serial < 1 || !s.Server.Valid() || int64(s.Server) != int64(s.Tuple.GuildID)/1000000 || !s.Inviter.Valid() || s.Inviter == s.Tuple.Recipient || int64(s.Inviter)/100000 != int64(s.Server) || s.ActorAccountUID == "" || s.DecisionAt.IsZero() || s.DecisionAt.Location() != time.UTC || !s.ExpiresAt.After(s.DecisionAt) || s.ExpiresAt.Location() != time.UTC || s.GuildName == "" || !utf8.ValidString(s.GuildName) || strings.ContainsRune(s.GuildName, 0) || s.LastJoinEventID < 0 || s.SendEventID < 1 || s.PolicyID != PolicyID || s.Core.Validate() != nil || s.Core.Operation != "invite" || s.Core.OwnerKind != "guild" || s.Core.OwnerKey != fmt.Sprint(s.Tuple.GuildID) || !validOperation(s.Operation, s.ContentRevision, s.GuildCoreRevision) {
		return ErrEvidence
	}
	if (s.LastJoinEventID == 0) != s.LastJoinedAt.IsZero() || !s.LastJoinedAt.IsZero() && (s.LastJoinedAt.Location() != time.UTC || s.LastJoinedAt.After(s.DecisionAt)) {
		return ErrEvidence
	}
	_, target, gen, e := InviteReceiptGeneration(s.Core.SemanticKey)
	if e != nil || target != s.Tuple.Recipient || gen != s.Tuple.Generation || s.Core.Schema != "gxb.i6c.guild.invite.v1" || !s.Core.MatchOperation(s.Operation, s.ActorAccountUID, s.GuildCoreRevision) {
		return ErrEvidence
	}
	return nil
}
func (s Issue) Fingerprint() ([32]byte, error) {
	if e := s.Validate(); e != nil {
		return [32]byte{}, e
	}
	raw, e := json.Marshal(s)
	if e != nil {
		return [32]byte{}, e
	}
	return sha256.Sum256(raw), nil
}

type MarkerKind string

const (
	Join   MarkerKind = "JOIN"
	Retire MarkerKind = "RETIRE"
)

type Marker struct {
	Operation                                    operation.Context
	Kind                                         MarkerKind
	GuildID                                      guild.ID
	Server                                       identity.LogicalServerID
	Actor, Subject                               identity.PlayerID
	ActorAccountUID                              string
	EventID                                      int64
	DecisionAt                                   time.Time
	MaxIssueSerial                               int64
	ContentRevision, GuildCoreRevision, PolicyID string
	Core                                         CoreReceipt
}

func (m Marker) Validate() error {
	if !validOperation(m.Operation, m.ContentRevision, m.GuildCoreRevision) || m.Kind != Join && m.Kind != Retire || m.GuildID <= 0 || int64(m.GuildID)%1000000 == 0 || !m.Server.Valid() || int64(m.GuildID)/1000000 != int64(m.Server) || !m.Actor.Valid() || !m.Subject.Valid() || int64(m.Actor)/100000 != int64(m.Server) || int64(m.Subject)/100000 != int64(m.Server) || m.ActorAccountUID == "" || m.EventID < 1 || m.DecisionAt.IsZero() || m.DecisionAt.Location() != time.UTC || m.MaxIssueSerial < 0 || m.PolicyID != PolicyID || m.Core.Validate() != nil {
		return ErrEvidence
	}
	if m.Kind == Retire && (m.Actor != m.Subject || m.Core.Operation != "dissolve") {
		return ErrEvidence
	}
	if m.Kind == Join {
		switch m.Core.Operation {
		case "create", "join_immediate", "accept_application", "accept_invite":
		default:
			return ErrEvidence
		}
	}
	if !m.Core.MatchOperation(m.Operation, m.ActorAccountUID, m.GuildCoreRevision) {
		return ErrEvidence
	}
	if m.Core.Operation == "create" {
		if m.Actor != m.Subject || m.Core.OwnerKind != "player" || m.Core.OwnerKey != fmt.Sprint(m.Subject) || m.Core.Schema != "gxb.i6c.guild.create.v1" {
			return ErrEvidence
		}
	} else if m.Core.OwnerKind != "guild" || m.Core.OwnerKey != fmt.Sprint(m.GuildID) {
		return ErrEvidence
	}
	if m.Core.Operation != "create" {
		want := map[string]string{"join_immediate": "gxb.i6c.guild.join_immediate.v2", "accept_application": "gxb.i6c.guild.accept_application.v1", "accept_invite": "gxb.i6c.guild.accept_invite.v1", "dissolve": "gxb.i6c.guild.dissolve.v1"}[m.Core.Operation]
		if want == "" || m.Core.Schema != want {
			return ErrEvidence
		}
	}
	return nil
}
func (m Marker) Fingerprint() ([32]byte, error) {
	if e := m.Validate(); e != nil {
		return [32]byte{}, e
	}
	raw, e := json.Marshal(m)
	if e != nil {
		return [32]byte{}, e
	}
	return sha256.Sum256(raw), nil
}

// Snapshot is a pure typed Guild observation. Current eligibility cannot be
// manufactured from a job payload or from incomplete restored JOIN history.
type Snapshot struct {
	Issue                                Issue
	GuildPresent, Retired, CurrentMember bool
	CurrentGeneration                    int64
	CurrentSourceID                      ids.UUID
	LatestJoinEventID                    int64
	RetirementMarkerID                   ids.UUID
}

func (v Snapshot) Eligible(at time.Time) (bool, error) {
	if v.Issue.Validate() != nil || at.IsZero() || at.Before(v.Issue.DecisionAt) || v.LatestJoinEventID < v.Issue.LastJoinEventID || !v.GuildPresent && !v.Retired {
		return false, ErrEvidence
	}
	if v.CurrentGeneration < 0 {
		return false, ErrEvidence
	}
	if v.CurrentGeneration == 0 && !v.Retired && !v.CurrentMember && v.LatestJoinEventID == v.Issue.LastJoinEventID {
		return false, ErrEvidence
	}
	if v.CurrentGeneration == v.Issue.Tuple.Generation && v.CurrentSourceID != v.Issue.Operation.ID {
		return false, ErrEvidence
	}
	return !v.Retired && !v.CurrentMember && v.LatestJoinEventID == v.Issue.LastJoinEventID && v.CurrentGeneration == v.Issue.Tuple.Generation && at.Before(v.Issue.ExpiresAt), nil
}
