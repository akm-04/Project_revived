package guildinvite

import (
	"bytes"
	"encoding/json"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"time"
)

// These finite references extend the existing Guild materialization process,
// physical queue mapping, operation budget, and worker profile. No job field
// authorizes a Notice or carries mutable eligibility.
const (
	Queue         = "guild.materialization"
	WorkerProfile = "guild-broadcast-mail-v1"
	IssueKind     = "guild.invite.notice.v1"
	MarkerKind    = "guild.invite.cleanup.v1"
)

func IssueObligation(id ids.UUID, at time.Time) (obligation.Obligation, error) {
	return reference(IssueKind, id, at)
}
func MarkerObligation(id ids.UUID, at time.Time) (obligation.Obligation, error) {
	return reference(MarkerKind, id, at)
}
func reference(kind string, id ids.UUID, at time.Time) (obligation.Obligation, error) {
	if id.IsZero() || at.IsZero() || kind != IssueKind && kind != MarkerKind {
		return obligation.Obligation{}, gi.ErrEvidence
	}
	raw, e := json.Marshal(struct {
		SourceID string `json:"source_id"`
	}{id.String()})
	if e != nil {
		return obligation.Obligation{}, e
	}
	return obligation.Obligation{Kind: kind, SemanticKey: id.String(), Queue: Queue, Profile: WorkerProfile, DueAt: at.UTC(), Args: raw}, nil
}

func NormalizeStoredObligation(o obligation.Obligation) (obligation.Obligation, error) {
	if o.Validate() != nil || o.Queue != Queue || o.Profile != WorkerProfile || o.DueAt.IsZero() || o.Kind != IssueKind && o.Kind != MarkerKind {
		return o, gi.ErrEvidence
	}
	m, e := finitejson.Decode(string(o.Args), 128, 2, 2, 1)
	if e != nil || len(m) != 1 {
		return o, gi.ErrEvidence
	}
	raw, ok := m["source_id"].(string)
	if !ok {
		return o, gi.ErrEvidence
	}
	id, e := ids.ParseUUID(raw)
	if e != nil || id.IsZero() || id.String() != raw {
		return o, gi.ErrEvidence
	}
	canonical, e := reference(o.Kind, id, o.DueAt)
	if e != nil || canonical.SemanticKey != o.SemanticKey {
		return o, gi.ErrEvidence
	}
	o.Args = canonical.Args
	return o, nil
}

func DecodeObligation(o obligation.Obligation) (ids.UUID, error) {
	canonical, e := NormalizeStoredObligation(o)
	if e != nil || !bytes.Equal(o.Args, canonical.Args) {
		return ids.UUID{}, gi.ErrEvidence
	}
	return ids.ParseUUID(o.SemanticKey)
}
