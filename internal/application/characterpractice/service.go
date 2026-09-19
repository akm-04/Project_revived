package characterpractice

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	BoundsPolicyRef      = "practice.bounds"
	BoundsPolicyV1       = "PRACTICE_BOUNDS_V1"
	FreePolicyRef        = "practice.free_entitlement"
	FreePolicyV1         = "PRACTICE_FREE_ENTITLEMENT_V1"
	PendingPolicyRef     = "practice.pending_proposal"
	PendingPolicyV1      = "PRACTICE_PENDING_PROPOSAL_V1"
	RollPolicyRef        = "practice.roll"
	BaseLedgerPolicyRef  = "practice.base_ledger"
	BaseLedgerPolicyV1   = "PASS574_CA6_3_POLICY_REGISTER_AMENDMENT#base_ledger_compatibility"
	manualReceiptSchema  = "gxb.ca6.practice-manual.v1"
	ticketReceiptSchema  = "gxb.ca6.practice-ticket.v1"
	saveReceiptSchema    = "gxb.ca6.practice-save.v1"
	practiceReceiptClass = "CA6_3_PRACTICE"
)

var (
	ErrPracticeUnavailable = errors.New("character practice: service unavailable")
	ErrPracticeAdmission   = errors.New("character practice: admission rejected")
	ErrPracticePrivilege   = errors.New("character practice: privilege requirement not met")
	ErrPracticeBless       = errors.New("character practice: insufficient Bless")
)

type ActorFencer interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type ServiceDeps struct {
	Fencer         ActorFencer
	HeroOwner      HeroPracticeOwner
	PetOwner       PetPracticeOwner
	Level          appi5.TxPlayerLevelReader
	LevelAndScalar appi5.TxLevelAndScalarDebiter
	TicketDebit    appi5.TxLevelAndStackDebiter
	Receipts       receipt.Store
	ReceiptRead    receipt.Reader
}

type Target struct {
	Hero    bool
	ActorID int64
}

func (t Target) validate() error {
	if t.ActorID <= 0 {
		return errors.New("character practice: invalid actor target")
	}
	return nil
}

func (t Target) kind() string {
	if t.Hero {
		return "hero"
	}
	return "pet"
}

type Info struct {
	LastTime     int64                   `json:"last_time"`
	PracticeAttr character.PracticeAttrs `json:"practice_attr"`
	Lock         []int64                 `json:"lock"`
	Times        int64                   `json:"times"`
	BaseCrystal  int64                   `json:"base_crystal"`
	BaseMana     int64                   `json:"base_mana"`
	BlessValue   int64                   `json:"bless_value"`
}

// PracticeDelta is a wire-visible effective per-axis change, not an absolute
// Practice tuple. Manual rolls may legitimately contain -1, so reusing
// character.PracticeAttrs (whose invariant is [0,200]) would corrupt replay.
type PracticeDelta [3]int64

func (d PracticeDelta) Validate() error {
	for _, v := range d {
		if v < -1 || v > 1 {
			return errors.New("character practice: invalid effective delta")
		}
	}
	return nil
}

type ManualCommand struct {
	Target Target
	Locks  PracticeLocks
	Method int64
}

type ManualResult struct {
	Info     Info
	AddAttr  PracticeDelta
	Replayed bool
}

type SaveResult struct {
	PracticeAttr character.PracticeAttrs
	Replayed     bool
}

type ticketReceiptResult struct {
	Info            Info          `json:"info"`
	AddAttr         PracticeDelta `json:"add_attr"`
	ContentRevision string        `json:"content_revision"`
	RollPolicy      string        `json:"roll_policy"`
}

type manualReceiptResult = ticketReceiptResult

type saveReceiptResult struct {
	PracticeAttr character.PracticeAttrs `json:"practice_attr"`
}

func practiceProfile() tx.Profile {
	return tx.Profile{Name: "CA6_3_PRACTICE", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func (s Service) validateMutation() error {
	d := s.Deps
	if s.Runner.DB == nil || s.Store == nil || s.Content == nil || s.Privileges == nil || d.Fencer == nil || d.HeroOwner == nil || d.PetOwner == nil || d.Receipts == nil || d.ReceiptRead == nil {
		return ErrPracticeUnavailable
	}
	return nil
}

func (s Service) bindCA63Operation(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	bound, revision, err := s.bindDailyOperation(ctx, op)
	if err != nil {
		return operation.Context{}, "", err
	}
	for _, p := range [][2]string{
		{BoundsPolicyRef, BoundsPolicyV1},
		{FreePolicyRef, FreePolicyV1},
		{PendingPolicyRef, PendingPolicyV1},
		{RollPolicyRef, RollPolicyV1},
		{BaseLedgerPolicyRef, BaseLedgerPolicyV1},
	} {
		bound, err = bindPolicyRef(bound, p[0], p[1])
		if err != nil {
			return operation.Context{}, "", err
		}
	}
	return bound, revision, nil
}

func validateCA63Info(info Info) error {
	if info.LastTime < 0 || info.PracticeAttr.Validate() != nil || info.PracticeAttr != (character.PracticeAttrs{}) || len(info.Lock) != 0 || info.Times != 0 || info.BaseCrystal < 0 || info.BaseMana < 0 || info.BlessValue < 0 {
		return errors.New("character practice: invalid CA6-3 info projection")
	}
	return nil
}

func rootInfo(r Root) Info {
	last := int64(0)
	if r.FreeLastConsumedAt != nil {
		last = r.FreeLastConsumedAt.UTC().Unix()
	}
	return Info{LastTime: last, PracticeAttr: character.PracticeAttrs{}, Lock: []int64{}, Times: 0, BaseCrystal: r.BaseCrystal, BaseMana: r.BaseMana, BlessValue: r.BlessRemaining}
}

func (s Service) GetInfo(ctx context.Context, pid identity.PlayerID, op operation.Context) (Info, error) {
	root, err := s.EnsureDailyGeneration(ctx, pid, op)
	if err != nil {
		return Info{}, err
	}
	return rootInfo(root), nil
}

func practiceReceiptIdentity(pid identity.PlayerID, target Target, operationName string, op operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(pid), 10), Domain: "character-practice", Operation: target.kind() + "-" + operationName, SemanticKey: op.ID.String()}
}

func manualFingerprint(cmd ManualCommand) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{"actor_kind": cmd.Target.kind(), "actor_id": cmd.Target.ActorID, "locks": []bool{cmd.Locks[0], cmd.Locks[1], cmd.Locks[2]}, "method": cmd.Method})
}

func actorFingerprint(target Target) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{"actor_kind": target.kind(), "actor_id": target.ActorID})
}

func findReceipt(ctx context.Context, r receipt.Reader, id receipt.Identity, fp [32]byte) (receipt.Receipt, bool, error) {
	got, ok, err := r.Find(ctx, id)
	if err != nil || !ok {
		return receipt.Receipt{}, ok, err
	}
	if !bytes.Equal(got.RequestFingerprint[:], fp[:]) {
		return receipt.Receipt{}, false, &receipt.ConflictError{Identity: id}
	}
	return got, true, nil
}

func findReceiptTx(ctx context.Context, st receipt.Store, q tx.Queryer, id receipt.Identity, fp [32]byte) (receipt.Receipt, bool, error) {
	got, ok, err := st.FindTx(ctx, q, id)
	if err != nil || !ok {
		return receipt.Receipt{}, ok, err
	}
	if !bytes.Equal(got.RequestFingerprint[:], fp[:]) {
		return receipt.Receipt{}, false, &receipt.ConflictError{Identity: id}
	}
	return got, true, nil
}

func putPracticeReceipt(ctx context.Context, st receipt.Store, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, schema string, payload any) error {
	raw, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, practiceReceiptClass, schema, raw, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	if schema == manualReceiptSchema || schema == ticketReceiptSchema {
		rr.PolicyVersion = RollPolicyV1
	}
	_, err = st.PutTx(ctx, t, rr)
	return err
}

func decodeManualReceipt(r receipt.Receipt, schema string) (ManualResult, error) {
	if r.ResultSchema != schema {
		return ManualResult{}, fmt.Errorf("character practice: unsupported receipt schema %q", r.ResultSchema)
	}
	var p manualReceiptResult
	if err := json.Unmarshal(r.ResultPayload, &p); err != nil {
		return ManualResult{}, err
	}
	if len(p.ContentRevision) != 64 || p.RollPolicy != RollPolicyV1 || p.AddAttr.Validate() != nil || validateCA63Info(p.Info) != nil {
		return ManualResult{}, errors.New("character practice: invalid terminal receipt")
	}
	return ManualResult{Info: p.Info, AddAttr: p.AddAttr, Replayed: true}, nil
}

func decodeSaveReceipt(r receipt.Receipt) (SaveResult, error) {
	if r.ResultSchema != saveReceiptSchema {
		return SaveResult{}, fmt.Errorf("character practice: unsupported save receipt schema %q", r.ResultSchema)
	}
	var p saveReceiptResult
	if err := json.Unmarshal(r.ResultPayload, &p); err != nil {
		return SaveResult{}, err
	}
	if p.PracticeAttr.Validate() != nil {
		return SaveResult{}, errors.New("character practice: invalid save receipt")
	}
	return SaveResult{PracticeAttr: p.PracticeAttr, Replayed: true}, nil
}

func (s Service) lockTarget(ctx context.Context, t tx.Tx, pid identity.PlayerID, target Target) (int64, character.PracticeAttrs, int64, error) {
	d := s.Deps
	if target.Hero {
		snap, err := d.HeroOwner.LockHeroPracticeTx(ctx, t, character.HeroRef{PlayerID: pid, PartnerID: target.ActorID})
		if err != nil {
			return 0, character.PracticeAttrs{}, 0, err
		}
		return snap.TableID, snap.Practice, snap.StateVersion, nil
	}
	snap, err := d.PetOwner.LockPetPracticeTx(ctx, t, character.PetRef{PlayerID: pid, PetID: target.ActorID})
	if err != nil {
		return 0, character.PracticeAttrs{}, 0, err
	}
	return snap.TableID, snap.Practice, snap.StateVersion, nil
}

func (s Service) actorAwakenedTx(ctx context.Context, q tx.Queryer, revision string, target Target, tableID int64) (bool, error) {
	if target.Hero {
		return s.Content.HeroTemplateAwakenedTx(ctx, q, revision, tableID)
	}
	return s.Content.PetTemplateAwakenedTx(ctx, q, revision, tableID)
}

func countLocks(locks PracticeLocks) int64 {
	var n int64
	for _, v := range locks {
		if v {
			n++
		}
	}
	return n
}

func addEffective(current character.PracticeAttrs, effective [3]int64) (character.PracticeAttrs, error) {
	next := current
	for i := range 3 {
		next[i] += effective[i]
	}
	if err := next.Validate(); err != nil {
		return character.PracticeAttrs{}, err
	}
	return next, nil
}

func (s Service) upsertProposalTx(ctx context.Context, t tx.Tx, target Target, p Proposal) error {
	if target.Hero {
		return s.Store.UpsertHeroProposalTx(ctx, t, p)
	}
	return s.Store.UpsertPetProposalTx(ctx, t, p)
}

func (s Service) lockProposalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, sid identity.SessionID, target Target) (Proposal, error) {
	if target.Hero {
		return s.Store.LockHeroProposalTx(ctx, t, pid, sid, target.ActorID)
	}
	return s.Store.LockPetProposalTx(ctx, t, pid, sid, target.ActorID)
}

func (s Service) deleteProposalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, sid identity.SessionID, target Target) error {
	if target.Hero {
		return s.Store.DeleteHeroProposalTx(ctx, t, pid, sid, target.ActorID)
	}
	return s.Store.DeletePetProposalTx(ctx, t, pid, sid, target.ActorID)
}

func (s Service) applyPracticeTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, target Target, expectedVersion int64, next character.PracticeAttrs, at time.Time) error {
	if target.Hero {
		return s.Deps.HeroOwner.CompareAndSwapHeroPracticeTx(ctx, t, character.HeroRef{PlayerID: pid, PartnerID: target.ActorID}, expectedVersion, next, at)
	}
	return s.Deps.PetOwner.CompareAndSwapPetPracticeTx(ctx, t, character.PetRef{PlayerID: pid, PetID: target.ActorID}, expectedVersion, next, at)
}

func allPracticeAtCap(a character.PracticeAttrs) bool {
	return a[0] >= character.MaxPracticeAttr && a[1] >= character.MaxPracticeAttr && a[2] >= character.MaxPracticeAttr
}
