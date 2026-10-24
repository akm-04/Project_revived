package commerceprivilege

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/application/directorysync"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"math"
	"strconv"
	"strings"
	"time"
)

var ErrUnresolved = errors.New("manual privilege import unresolved")

const resultSchema = "gxb.i7c4a.manual-privilege.v1"

// Authority is an already authenticated trusted application input, like the
// accepted I5 AdminOperator seam. It is not a bearer credential and is never
// decoded from a gameplay request. I11 owns authentication and durable audit.
type Authority struct {
	Operator      i5.AdminOperator `json:"operator"`
	Capability    string           `json:"capability"`
	PolicyVersion string           `json:"policy_version"`
}

func (a Authority) Validate() error {
	if a.Operator.Validate() != nil || a.Capability != d.ManualCapability || a.PolicyVersion != d.ManualPolicy {
		return d.ErrUnavailable
	}
	return nil
}

type Import struct {
	PlayerID        identity.PlayerID        `json:"player_id"`
	LogicalServerID identity.LogicalServerID `json:"logical_server_id"`
	CommandKey      string                   `json:"command_key"`
	Charge          int64                    `json:"charge"`
	MonthlyState    string                   `json:"monthly_state"`
}

func (q Import) Validate() error {
	if !q.PlayerID.Valid() || !q.LogicalServerID.Valid() || strings.TrimSpace(q.CommandKey) == "" || q.Charge < 0 || q.Charge > 9007199254740991 || q.MonthlyState != d.MonthlyAbsent {
		return d.ErrConflict
	}
	return nil
}

type Result struct {
	Schema          string    `json:"schema"`
	Authority       Authority `json:"authority"`
	Request         Import    `json:"request"`
	State           d.State   `json:"state"`
	DecisionAt      time.Time `json:"decision_at"`
	ContentRevision string    `json:"content_revision"`
	Changed         bool      `json:"changed"`
}
type ManualContent interface {
	Content
	ActiveRevision(context.Context, tx.Queryer) (string, error)
}
type Service struct {
	Runner      tx.Runner
	Fresh       tx.Queryer
	Time        gen.TimeAuthority
	Players     playerroot.RecipientLocker
	Store       Store
	Content     ManualContent
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
	Effects     i5.PrivilegeTransitionPort
	Directory   directorysync.VIPProjectionPort
	Audit       audit.Emitter
}

func manualIdentity(a Authority, q Import) receipt.Identity {
	h := sha256.Sum256([]byte(a.Operator.ID + "\x00" + q.CommandKey))
	return receipt.Identity{OwnerKind: "operator", OwnerKey: a.Operator.ID, Domain: "commerce-privilege", Operation: "manual-snapshot", SemanticKey: hex.EncodeToString(h[:])}
}
func fingerprint(a Authority, q Import) ([32]byte, error) {
	return receipt.FingerprintRequest(struct {
		Authority Authority
		Request   Import
	}{a, q})
}
func decode(r receipt.Receipt, a Authority, q Import, fp [32]byte) (Result, error) {
	var out Result
	if r.Validate() != nil || r.Identity != manualIdentity(a, q) || r.RequestFingerprint != fp || r.OperationClass != "I7C4A_MANUAL_PRIVILEGE" || r.ResultSchema != resultSchema || r.PolicyVersion != d.ManualPolicy {
		return out, d.ErrConflict
	}
	dec := json.NewDecoder(bytes.NewReader(r.ResultPayload))
	dec.DisallowUnknownFields()
	if dec.Decode(&out) != nil {
		return Result{}, d.ErrConflict
	}
	var extra any
	if dec.Decode(&extra) != io.EOF || out.Schema != resultSchema || out.Authority != a || out.Request != q || out.State.Validate() != nil || out.State.PlayerID != q.PlayerID || out.State.LogicalServerID != q.LogicalServerID || out.State.Charge != q.Charge || out.DecisionAt.IsZero() || !d.RevisionValid(out.ContentRevision) || out.State.UpdatedAt.After(out.DecisionAt) {
		return Result{}, d.ErrConflict
	}
	pin, ok := r.OperationPolicyRefs.Get("content")
	if !ok || pin != out.ContentRevision {
		return Result{}, d.ErrConflict
	}
	pin, ok = r.OperationPolicyRefs.Get("commerce-privilege")
	if !ok || pin != d.ManualPolicy {
		return Result{}, d.ErrConflict
	}
	return out, nil
}
func (s Service) ImportManual(c context.Context, a Authority, q Import, op operation.Context) (out Result, err error) {
	if a.Validate() != nil || q.Validate() != nil || op.ID.IsZero() || op.StartedAt.IsZero() || s.Runner.DB == nil || s.Fresh == nil || s.Time == nil || s.Players == nil || s.Store == nil || s.Content == nil || s.Receipts == nil || s.ReceiptRead == nil || s.Effects == nil || s.Directory == nil || s.Audit == nil {
		return out, d.ErrUnavailable
	}
	fp, e := fingerprint(a, q)
	if e != nil {
		return out, e
	}
	id := manualIdentity(a, q)
	defer func() {
		outcome := "COMMITTED"
		if err != nil {
			outcome = "REJECTED"
			var unknown *tx.UnknownCommitError
			if errors.Is(err, ErrUnresolved) || errors.As(err, &unknown) {
				outcome = "UNRESOLVED"
			}
		}
		s.Audit.Emit(context.WithoutCancel(c), audit.Event{OccurredAt: op.StartedAt.UTC(), ActorKind: "AdminOperator", ActorID: a.Operator.ID, Action: "commerce.privilege.manual-snapshot", TargetKind: "player", TargetKey: strconv.FormatInt(int64(q.PlayerID), 10), Outcome: outcome, ReasonCode: a.Operator.ReasonCode, CorrelationID: op.ID.String()})
	}()
	// Intrinsic issuer/command identity precedes rebinding active content/time;
	// an old exact command cannot become a new grant after activation/restart.
	prior, found, e := s.ReceiptRead.Find(c, id)
	if e != nil {
		return out, e
	}
	if found {
		return decode(prior, a, q, fp)
	}
	at, e := s.Time.Now(c)
	if e != nil || at.IsZero() {
		if e == nil {
			e = d.ErrUnavailable
		}
		return out, e
	}
	at = at.UTC()
	rev, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil {
		return out, e
	}
	if !d.RevisionValid(rev) {
		return out, d.ErrUnavailable
	}
	refs := op.Policies.Refs()
	for _, r := range []policy.Ref{{Name: "content", Version: rev}, {Name: "commerce-privilege", Version: d.ManualPolicy}} {
		if v, ok := op.Policies.Get(r.Name); ok {
			if v != r.Version {
				return out, d.ErrConflict
			}
		} else {
			refs = append(refs, r)
		}
	}
	op.Policies, e = policy.NewSet(refs...)
	if e != nil {
		return out, e
	}
	resolve := receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}
	res, e := s.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolve, func(c context.Context, sc tx.Scope) error {
		root, e := s.Players.LockBoundRecipientTx(c, sc.Tx, q.LogicalServerID, q.PlayerID)
		if e != nil {
			return e
		}
		if root.NonReusedAbsent || root.Root.Validate() != nil || root.Root.PlayerID != q.PlayerID || root.Root.LogicalServerID != q.LogicalServerID {
			return d.ErrConflict
		}
		prior, ok, e := s.Receipts.FindTx(c, sc.Tx, id)
		if e != nil {
			return e
		}
		if ok {
			out, e = decode(prior, a, q, fp)
			return e
		}
		catalog, e := s.Content.PrivilegeCatalogTx(c, sc.Tx, rev)
		if e != nil {
			return e
		}
		level, e := catalog.Derive(q.Charge)
		if e != nil {
			return e
		}
		newCap, e := catalog.SkillCap(level)
		if e != nil {
			return e
		}
		old, ok, e := s.Store.ReadPrivilegeTx(c, sc.Tx, q.PlayerID, true)
		if e != nil {
			return e
		}
		oldVersion, oldCap := int64(0), int64(10)
		next := d.State{PlayerID: q.PlayerID, LogicalServerID: q.LogicalServerID, Charge: q.Charge, VIPLevel: level, MonthlyState: q.MonthlyState, ContentRevision: rev, PolicyVersion: d.ManualPolicy, OriginClass: d.ManualClass, Issuer: a.Operator.ID, Reason: a.Operator.ReasonCode, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
		changed := true
		if ok {
			if old.Validate() != nil || old.LogicalServerID != q.LogicalServerID || old.UpdatedAt.After(at) || q.Charge < old.Charge || old.StateVersion == math.MaxInt64 {
				return d.ErrConflict
			}
			oc, e := s.Content.PrivilegeCatalogTx(c, sc.Tx, old.ContentRevision)
			if e != nil {
				return e
			}
			if old.ValidateCatalog(oc) != nil {
				return d.ErrConflict
			}
			oldCap, e = oc.SkillCap(old.VIPLevel)
			if e != nil {
				return e
			}
			oldVersion = old.StateVersion
			next.CreatedAt = old.CreatedAt
			next.StateVersion = oldVersion + 1
			if q.Charge == old.Charge {
				changed = false
				next = old
				newCap = oldCap
			}
		}
		// All touched owner keys are acquired before the FIRST durable mutation.
		effect, e := s.Effects.PreparePrivilegeTransitionTx(c, sc.Tx, q.PlayerID, oldCap, newCap, at)
		if e != nil {
			return e
		}
		directory, e := s.Directory.PrepareVIPProjectionTx(c, sc.Tx, q.PlayerID, next.VIPLevel, at)
		if e != nil {
			return e
		}
		if changed {
			if e = s.Store.SavePrivilegeTx(c, sc.Tx, oldVersion, next); e != nil {
				return e
			}
			if e = effect.Apply(c, sc.Tx); e != nil {
				return e
			}
		}
		if e = directory.Apply(c, sc.Tx); e != nil {
			return e
		}
		out = Result{Schema: resultSchema, Authority: a, Request: q, State: next, DecisionAt: at, ContentRevision: rev, Changed: changed}
		raw, e := json.Marshal(out)
		if e != nil {
			return e
		}
		r, e := receipt.New(op, id, "I7C4A_MANUAL_PRIVILEGE", resultSchema, raw, fp)
		if e != nil {
			return e
		}
		r.PolicyVersion = d.ManualPolicy
		put, e := s.Receipts.PutTx(c, sc.Tx, r)
		if e != nil {
			return e
		}
		if !put.Inserted {
			out, e = decode(put.Receipt, a, q, fp)
			return e
		}
		return nil
	})
	if e != nil {
		return Result{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return Result{}, ErrUnresolved
	}
	if res.Reconciled {
		r, ok := res.Evidence.(receipt.Receipt)
		if !ok {
			return Result{}, fmt.Errorf("%w: missing receipt evidence", ErrUnresolved)
		}
		return decode(r, a, q, fp)
	}
	return out, nil
}
