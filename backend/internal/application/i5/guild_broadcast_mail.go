package i5

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/application/playerroot"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
)

var ErrGuildBroadcastConflict = errors.New("Guild broadcast Mail proof conflict")

type GuildBroadcastSourceReader interface {
	ReadGuildBroadcastMailSourceTx(context.Context, tx.Queryer, ids.UUID, identity.PlayerID) (gb.Source, gb.Binding, error)
}
type GuildBroadcastMailStore interface {
	LockMailNamespaceCounterTx(context.Context, tx.Tx, identity.PlayerID, mail.Namespace) error
	CheckGuildBroadcastWireCapacityTx(context.Context, tx.Tx, identity.PlayerID) error
	AllocateMailWireIDTx(context.Context, tx.Tx, identity.PlayerID, mail.Namespace) (int64, error)
	InsertMailTx(context.Context, tx.Tx, mail.Record) error
	ReadGuildBroadcastMailTx(context.Context, tx.Queryer, identity.PlayerID, ids.UUID) (mail.Record, bool, error)
}

// GuildBroadcastMailService admits only a canonical source reference. Text,
// timestamp, recipient and policy come from the immutable Guild owner proof.
type GuildBroadcastMailService struct {
	Runner   tx.Runner
	Reads    tx.Runner
	Sources  GuildBroadcastSourceReader
	Players  playerroot.RecipientLocker
	Mail     GuildBroadcastMailStore
	Receipts receipt.Store
}

func broadcastTargetIdentity(id ids.UUID, pid identity.PlayerID) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(pid), 10), Domain: "guild-source-mail", Operation: "materialize", SemanticKey: id.String()}
}

type broadcastTargetResult struct {
	State  gb.State `json:"state"`
	MailID ids.UUID `json:"mail_id"`
	WireID int64    `json:"wire_id"`
}

func targetProof(s gb.Source, pid identity.PlayerID, r receipt.Receipt, x broadcastTargetResult) (gb.TargetProof, error) {
	fp, e := s.Fingerprint()
	if e != nil {
		return gb.TargetProof{}, e
	}
	p := gb.TargetProof{SourceID: s.Operation.ID, RecipientID: pid, SourceFingerprint: fp, ReceiptID: r.ID, State: x.State, MailID: x.MailID, WireID: x.WireID}
	return p, p.Validate()
}
func mailMatchesSource(m mail.Record, s gb.Source, pid identity.PlayerID) bool {
	return m.Validate() == nil && m.Recipient == pid && m.SourceKind == "GUILD_BROADCAST" && m.SourceKey == s.Operation.ID.String() && m.Address.Namespace == mail.Normal && m.Address.WireID > 0 && m.Address.WireID <= 9007199254740991 && m.Category == 0 && m.Platform == mail.AnyPlatform && m.Title == s.Request.Title && m.Body == s.Request.Content && m.Sender == s.LeaderName && m.CreatedAt.UnixMicro() == s.DecisionAt.UnixMicro() && m.ExpiresAt == nil && m.ClaimedAt == nil && len(m.Attachments) == 0 && m.CompatibilityPolicyVersion == s.PolicyID
}
func bindingMatchesProof(b gb.Binding, p gb.TargetProof) bool {
	if b.State == gb.Pending {
		return true
	}
	return b.State == p.State && b.TargetReceiptID == p.ReceiptID && b.MailID == p.MailID && b.WireID == p.WireID
}

// completeTargetProof never recreates a missing Mail beside a receipt. A typed
// non-reused absent root may retain a historical delivery after cascade delete.
func (v GuildBroadcastMailService) completeTargetProof(c context.Context, q tx.Queryer, s gb.Source, b gb.Binding, root playerroot.RecipientRoot) (gb.TargetProof, bool, error) {
	id := broadcastTargetIdentity(s.Operation.ID, b.RecipientID)
	rr, hasR, e := v.Receipts.FindTx(c, q, id)
	if e != nil {
		return gb.TargetProof{}, false, e
	}
	m, hasM, e := v.Mail.ReadGuildBroadcastMailTx(c, q, b.RecipientID, s.Operation.ID)
	if e != nil {
		return gb.TargetProof{}, false, e
	}
	if !hasR {
		if hasM || b.State != gb.Pending {
			return gb.TargetProof{}, false, ErrGuildBroadcastConflict
		}
		return gb.TargetProof{}, false, nil
	}
	fp, e := s.Fingerprint()
	if e != nil {
		return gb.TargetProof{}, false, e
	}
	x, decodeErr := decodeBroadcastTargetResult(rr.ResultPayload)
	if rr.Validate() != nil || rr.Identity != id || rr.OperationClass != "I7A8A_GUILD_MAIL" || rr.ResultSchema != "gxb.guild-source-mail.result.v1" || rr.PolicyVersion != s.PolicyID || rr.RequestFingerprint != fp || rr.OperationStartedAt.UnixMicro() != s.Operation.StartedAt.UnixMicro() || !rr.OperationPolicyRefs.Equal(s.Operation.Policies) || decodeErr != nil {
		return gb.TargetProof{}, false, ErrGuildBroadcastConflict
	}
	p, e := targetProof(s, b.RecipientID, rr, x)
	if e != nil || !bindingMatchesProof(b, p) {
		return gb.TargetProof{}, false, ErrGuildBroadcastConflict
	}
	switch x.State {
	case gb.Delivered:
		if !hasM {
			if !root.NonReusedAbsent {
				return gb.TargetProof{}, false, ErrGuildBroadcastConflict
			}
		} else if root.NonReusedAbsent || !mailMatchesSource(m, s, b.RecipientID) || m.MailUUID != p.MailID || m.Address.WireID != p.WireID {
			return gb.TargetProof{}, false, ErrGuildBroadcastConflict
		}
	case gb.RecipientGone:
		if !root.NonReusedAbsent || hasM {
			return gb.TargetProof{}, false, ErrGuildBroadcastConflict
		}
	default:
		return gb.TargetProof{}, false, ErrGuildBroadcastConflict
	}
	return p, true, nil
}
func (v GuildBroadcastMailService) loadLocked(c context.Context, t tx.Tx, id ids.UUID, pid identity.PlayerID) (gb.Source, gb.Binding, playerroot.RecipientRoot, error) {
	s, b, e := v.Sources.ReadGuildBroadcastMailSourceTx(c, t, id, pid)
	if e != nil {
		return s, b, playerroot.RecipientRoot{}, e
	}
	if s.Validate() != nil || b.Validate() != nil || b.SourceID != id || b.RecipientID != pid {
		return s, b, playerroot.RecipientRoot{}, ErrGuildBroadcastConflict
	}
	root, e := v.Players.LockBoundRecipientTx(c, t, s.Server, pid)
	if e != nil {
		return s, b, root, e
	}
	if !root.NonReusedAbsent && (root.Root.PlayerID != pid || root.Root.LogicalServerID != s.Server) {
		return s, b, root, ErrGuildBroadcastConflict
	}
	return s, b, root, nil
}
func (v GuildBroadcastMailService) valid() bool {
	return v.Runner.DB != nil && v.Reads.DB != nil && v.Sources != nil && v.Players != nil && v.Mail != nil && v.Receipts != nil
}
func (v GuildBroadcastMailService) ReadProof(c context.Context, id ids.UUID, pid identity.PlayerID) (gb.TargetProof, bool, error) {
	if !v.valid() || id.IsZero() || !pid.Valid() {
		return gb.TargetProof{}, false, ErrGuildBroadcastConflict
	}
	// Source operation is read once before transaction admission; the immutable
	// owner rechecks it in the coherent proof transaction.
	s, _, e := v.readSource(c, id, pid)
	if e != nil {
		return gb.TargetProof{}, false, e
	}
	var p gb.TargetProof
	var found bool
	_, e = v.Reads.Run(c, s.Operation, DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		ss, b, root, e := v.loadLocked(c, sc.Tx, id, pid)
		if e != nil {
			return e
		}
		p, found, e = v.completeTargetProof(c, sc.Tx, ss, b, root)
		return e
	})
	return p, found, e
}
func (v GuildBroadcastMailService) readSource(c context.Context, id ids.UUID, pid identity.PlayerID) (gb.Source, gb.Binding, error) {
	// Use a bounded transaction rather than mixing pool reads of source/receipt.
	// Admission context carries no gameplay decision or random outcome.
	var s gb.Source
	var b gb.Binding
	// Runner needs a profile but accepts a zero operation for read-only discovery.
	_, e := v.Reads.Run(c, s.Operation, DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		s, b, e = v.Sources.ReadGuildBroadcastMailSourceTx(c, sc.Tx, id, pid)
		return e
	})
	return s, b, e
}

type broadcastResolver struct {
	Service GuildBroadcastMailService
	ID      ids.UUID
	PID     identity.PlayerID
}

func (r broadcastResolver) Resolve(c context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	p, ok, e := r.Service.ReadProof(c, r.ID, r.PID)
	if e != nil {
		return tx.Resolution{}, e
	}
	if !ok {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: p}, nil
}
func (v GuildBroadcastMailService) Materialize(c context.Context, id ids.UUID, pid identity.PlayerID) (gb.TargetProof, error) {
	if !v.valid() || id.IsZero() || !pid.Valid() {
		return gb.TargetProof{}, ErrGuildBroadcastConflict
	}
	s, _, e := v.readSource(c, id, pid)
	if e != nil {
		return gb.TargetProof{}, e
	}
	var out gb.TargetProof
	result, e := v.Runner.Run(c, s.Operation, DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, broadcastResolver{v, id, pid}, func(c context.Context, sc tx.Scope) error {
		source, b, root, e := v.loadLocked(c, sc.Tx, id, pid)
		if e != nil {
			return e
		}
		prior, found, e := v.completeTargetProof(c, sc.Tx, source, b, root)
		if e != nil {
			return e
		}
		if found {
			out = prior
			return nil
		}
		x := broadcastTargetResult{State: gb.RecipientGone}
		if !root.NonReusedAbsent {
			// Root315 then NORMAL namespace610. Preparation does not allocate an ID.
			if e = v.Mail.LockMailNamespaceCounterTx(c, sc.Tx, pid, mail.Normal); e != nil {
				return e
			}
			if e = v.Mail.CheckGuildBroadcastWireCapacityTx(c, sc.Tx, pid); e != nil {
				return e
			}
			wire, e := v.Mail.AllocateMailWireIDTx(c, sc.Tx, pid, mail.Normal)
			if e != nil {
				return e
			}
			if wire <= 0 || wire > 9007199254740991 {
				return ErrGuildBroadcastConflict
			}
			mid, e := ids.NewUUID()
			if e != nil {
				return e
			}
			m := mail.Record{MailUUID: mid, Recipient: pid, Address: mail.Address{Namespace: mail.Normal, WireID: wire}, SourceKind: "GUILD_BROADCAST", SourceKey: id.String(), Category: 0, Title: source.Request.Title, Sender: source.LeaderName, Body: source.Request.Content, CreatedAt: source.DecisionAt, Shown: true, Platform: mail.AnyPlatform, CompatibilityPolicyVersion: source.PolicyID, StateVersion: 1}
			if e = v.Mail.InsertMailTx(c, sc.Tx, m); e != nil {
				return e
			}
			x = broadcastTargetResult{State: gb.Delivered, MailID: mid, WireID: wire}
		}
		raw, e := json.Marshal(x)
		if e != nil {
			return e
		}
		fp, e := source.Fingerprint()
		if e != nil {
			return e
		}
		rr, e := receipt.New(source.Operation, broadcastTargetIdentity(id, pid), "I7A8A_GUILD_MAIL", "gxb.guild-source-mail.result.v1", raw, fp)
		if e != nil {
			return e
		}
		rr.PolicyVersion = source.PolicyID
		put, e := v.Receipts.PutTx(c, sc.Tx, rr)
		if e != nil {
			return e
		}
		if !put.Inserted {
			return ErrGuildBroadcastConflict
		}
		out, e = targetProof(source, pid, put.Receipt, x)
		return e
	})
	if e != nil {
		return gb.TargetProof{}, e
	}
	if result.Reconciled {
		p, ok := result.Evidence.(gb.TargetProof)
		if !ok {
			return gb.TargetProof{}, ErrGuildBroadcastConflict
		}
		out = p
	}
	return out, nil
}

// ReadGuildBroadcastProofTx uses the caller's coherent transaction. The I4 root
// fence prevents concurrent deletion while the Guild owner acknowledges proof.
func (v GuildBroadcastMailService) ReadGuildBroadcastProofTx(c context.Context, t tx.Tx, id ids.UUID, pid identity.PlayerID) (gb.TargetProof, bool, error) {
	if !v.valid() || t == nil || id.IsZero() || !pid.Valid() {
		return gb.TargetProof{}, false, ErrGuildBroadcastConflict
	}
	source, b, root, e := v.loadLocked(c, t, id, pid)
	if e != nil {
		return gb.TargetProof{}, false, e
	}
	return v.completeTargetProof(c, t, source, b, root)
}

func decodeBroadcastTargetResult(raw []byte) (broadcastTargetResult, error) {
	m, e := finitejson.Decode(string(raw), 256, 2, 4, 3)
	if e != nil || len(m) != 3 {
		return broadcastTargetResult{}, ErrGuildBroadcastConflict
	}
	state, ok := m["state"].(string)
	if !ok {
		return broadcastTargetResult{}, ErrGuildBroadcastConflict
	}
	text, ok := m["mail_id"].(string)
	if !ok {
		return broadcastTargetResult{}, ErrGuildBroadcastConflict
	}
	id, e := ids.ParseUUID(text)
	if e != nil || id.String() != text {
		return broadcastTargetResult{}, ErrGuildBroadcastConflict
	}
	wire, ok := m["wire_id"].(int64)
	if !ok {
		return broadcastTargetResult{}, ErrGuildBroadcastConflict
	}
	return broadcastTargetResult{State: gb.State(state), MailID: id, WireID: wire}, nil
}
