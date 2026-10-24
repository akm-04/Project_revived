package guildinvite

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

func coreWitness(r receipt.Receipt) gi.CoreReceipt {
	return gi.CoreReceipt{ID: r.ID, OwnerKind: r.Identity.OwnerKind, OwnerKey: r.Identity.OwnerKey, Domain: r.Identity.Domain, Operation: r.Identity.Operation, SemanticKey: r.Identity.SemanticKey, Schema: r.ResultSchema, Fingerprint: r.RequestFingerprint, OperationClass: r.OperationClass, PolicyVersion: r.PolicyVersion, ActorAccountUID: r.ActorAccountUID, ContextID: r.ContextID, OperationStartedAt: r.OperationStartedAt.UTC(), OperationPolicyRefs: r.OperationPolicyRefs}
}

func coreIdentity(w gi.CoreReceipt) receipt.Identity {
	return receipt.Identity{OwnerKind: w.OwnerKind, OwnerKey: w.OwnerKey, Domain: w.Domain, Operation: w.Operation, SemanticKey: w.SemanticKey}
}

func validateCore(r receipt.Receipt, w gi.CoreReceipt, gid guild.ID) error {
	if r.Validate() != nil || w.Validate() != nil || r.ID != w.ID || r.Identity != coreIdentity(w) || r.OperationClass != w.OperationClass || r.ResultSchema != w.Schema || r.RequestFingerprint != w.Fingerprint || r.PolicyVersion != w.PolicyVersion || r.ActorAccountUID != w.ActorAccountUID || r.ContextID != w.ContextID || r.OperationStartedAt.UnixMicro() != w.OperationStartedAt.UnixMicro() || !r.OperationPolicyRefs.Equal(w.OperationPolicyRefs) || r.RetainUntil != nil {
		return gi.ErrEvidence
	}
	d := json.NewDecoder(bytes.NewReader(r.ResultPayload))
	d.DisallowUnknownFields()
	switch w.Operation {
	case "create":
		var v struct {
			GuildID int64 `json:"guild_id"`
			Role    int16 `json:"role"`
		}
		if d.Decode(&v) != nil || v.GuildID != int64(gid) || v.Role != int16(guild.Leader) {
			return gi.ErrEvidence
		}
	case "join_immediate":
		var v struct {
			GuildID         int64 `json:"guild_id"`
			Joined, Applied bool
		}
		if d.Decode(&v) != nil || v.GuildID != int64(gid) || !v.Joined || v.Applied {
			return gi.ErrEvidence
		}
	default:
		var v struct {
			GuildID int64 `json:"guild_id"`
		}
		if d.Decode(&v) != nil || v.GuildID != int64(gid) {
			return gi.ErrEvidence
		}
	}
	if d.Decode(new(any)) != io.EOF {
		return gi.ErrEvidence
	}
	return nil
}

type SourceReader struct {
	Store    Store
	Bindings GuildBindings
	Receipts receipt.Store
	Content  ContentReader
}

func (r SourceReader) policy(c context.Context, q tx.Queryer, rev, core string) error {
	if r.Store == nil || r.Bindings == nil || r.Receipts == nil || r.Content == nil {
		return gi.ErrEvidence
	}
	p, ok, e := r.Content.ReadInvitePolicy(c, q, rev)
	if e != nil {
		return e
	}
	if !ok || p.Revision != rev || p.GuildCoreRevision != core || p.PolicyID != gi.PolicyID {
		return gi.ErrEvidence
	}
	return nil
}
func (r SourceReader) ReadIssueEvidenceTx(c context.Context, q tx.Queryer, id ids.UUID) (gi.Issue, error) {
	if r.Store == nil {
		return gi.Issue{}, gi.ErrEvidence
	}
	s, ok, e := r.Store.ReadIssueTx(c, q, id)
	if e != nil {
		return s, e
	}
	if !ok {
		return s, gi.ErrEvidence
	}
	if e = r.policy(c, q, s.ContentRevision, s.GuildCoreRevision); e != nil {
		return s, e
	}
	rr, ok, e := r.Receipts.FindTx(c, q, coreIdentity(s.Core))
	if e != nil {
		return s, e
	}
	if !ok || validateCore(rr, s.Core, s.Tuple.GuildID) != nil {
		return s, gi.ErrEvidence
	}
	if e = r.Bindings.ValidateIssueBindingsTx(c, q, s); e != nil {
		return s, e
	}
	d, ok, e := r.Store.ReadDeliveryTx(c, q, id)
	if e != nil {
		return s, e
	}
	if !ok || d.Validate() != nil || d.Recipient != s.Tuple.Recipient {
		return s, gi.ErrEvidence
	}
	return s, nil
}
func (r SourceReader) ReadMarkerEvidenceTx(c context.Context, q tx.Queryer, id ids.UUID) (gi.Marker, error) {
	if r.Store == nil {
		return gi.Marker{}, gi.ErrEvidence
	}
	m, progress, ok, e := r.Store.ReadMarkerTx(c, q, id)
	if e != nil {
		return m, e
	}
	if !ok {
		return m, gi.ErrEvidence
	}
	if e = r.policy(c, q, m.ContentRevision, m.GuildCoreRevision); e != nil {
		return m, e
	}
	rr, ok, e := r.Receipts.FindTx(c, q, coreIdentity(m.Core))
	if e != nil {
		return m, e
	}
	if !ok || validateCore(rr, m.Core, m.GuildID) != nil {
		return m, gi.ErrEvidence
	}
	if e = r.Bindings.ValidateMarkerBindingsTx(c, q, m); e != nil {
		return m, e
	}
	if e = r.ValidateCursorEvidenceTx(c, q, m, progress); e != nil {
		return m, e
	}
	return m, nil
}
func (r SourceReader) ReadInviteSnapshotTx(c context.Context, q tx.Queryer, id ids.UUID) (gi.Snapshot, error) {
	s, e := r.ReadIssueEvidenceTx(c, q, id)
	if e != nil {
		return gi.Snapshot{}, e
	}
	v, e := r.Bindings.ReadGuildInviteSnapshotTx(c, q, s)
	if e != nil {
		return v, e
	}
	retainedRetirement, err := r.Store.ReadRetainedValidityTx(c, q, s)
	if err != nil {
		return v, err
	}
	if !v.RetirementMarkerID.IsZero() && v.RetirementMarkerID != retainedRetirement {
		return v, gi.ErrEvidence
	}
	if !retainedRetirement.IsZero() {
		v.RetirementMarkerID = retainedRetirement
		v.Retired = true
	}
	if !v.RetirementMarkerID.IsZero() {
		m, e := r.ReadMarkerEvidenceTx(c, q, v.RetirementMarkerID)
		if e != nil {
			return v, e
		}
		if m.Kind != gi.Retire || m.GuildID != s.Tuple.GuildID || m.DecisionAt.Before(s.DecisionAt) || m.MaxIssueSerial < s.Serial {
			return v, gi.ErrEvidence
		}
	}
	return v, nil
}

func (p ContentPolicy) Validate() error {
	// The domain validates immutable content/core revision encodings together
	// with operation refs; the policy reader also requires this finite bundle.
	if len(p.Revision) != 64 || len(p.GuildCoreRevision) != 64 || p.PolicyID != gi.PolicyID {
		return fmt.Errorf("%w: incomplete Invite capability", gi.ErrEvidence)
	}
	return nil
}

var _ ImmutableReader = SourceReader{}

func (r SourceReader) ReadIssueDeliveryEvidenceTx(c context.Context, q tx.Queryer, id ids.UUID) (gi.Delivery, error) {
	s, e := r.ReadIssueEvidenceTx(c, q, id)
	if e != nil {
		return gi.Delivery{}, e
	}
	d, ok, e := r.Store.ReadDeliveryTx(c, q, id)
	if e != nil {
		return d, e
	}
	if !ok || d.Validate() != nil || d.Recipient != s.Tuple.Recipient {
		return d, gi.ErrEvidence
	}
	return d, nil
}

func (r SourceReader) ReadIssueTupleEvidenceTx(c context.Context, q tx.Queryer, tuple gi.Tuple) (gi.Issue, error) {
	if r.Store == nil || tuple.Validate() != nil {
		return gi.Issue{}, gi.ErrEvidence
	}
	s, ok, e := r.Store.ReadIssueTupleTx(c, q, tuple)
	if e != nil {
		return s, e
	}
	if !ok {
		return s, gi.ErrEvidence
	}
	return r.ReadIssueEvidenceTx(c, q, s.Operation.ID)
}
