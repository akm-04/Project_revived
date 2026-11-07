package eventcentre

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"strconv"
	"time"

	appbook "gxb.local/backend/v2/internal/application/bookskill"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	Recycle        = "EVENT_CENTRE_RECYCLE"
	Make           = "EVENT_CENTRE_MAKE"
	CancelMake     = "EVENT_CENTRE_CANCEL_MAKE"
	ConfirmMake    = "EVENT_CENTRE_CONFIRM_MAKE"
	AccelerateMake = "EVENT_CENTRE_ACCELERATE_MAKE"
	AdminExchange  = "EVENT_CENTRE_ADMIN_EXCHANGE"
	BoardReceive   = "EVENT_CENTRE_BOARD_RECEIVE"
	BoardGiveUp    = "EVENT_CENTRE_BOARD_GIVE_UP"
	BoardConfirm   = "EVENT_CENTRE_BOARD_CONFIRM_AWARD"
)

var ErrUnavailable = errors.New("event centre: unavailable")
var ErrStale = errors.New("event centre: stale captured decision time")
var ErrRejected = errors.New("event centre: command rejected")
var ErrProof = errors.New("event centre: invalid operation proof")

type Command struct {
	Family                               string
	ItemID, ItemNum, BuildingType, PetID int64
	SpeedNum, FromType, ToType           int64
	MissionID, Leader, WishCrystal       int64
	Partners                             []int64
}

func (c Command) Validate() error {
	switch c.Family {
	case Recycle:
		if c.ItemID <= 0 || c.ItemNum <= 0 {
			return ErrInvalid
		}
	case Make:
		if c.ItemID <= 0 || c.BuildingType != DeskBuilding && c.BuildingType != PetRoomBuilding || c.BuildingType == DeskBuilding && c.PetID != 0 || c.BuildingType == PetRoomBuilding && c.PetID <= 0 {
			return ErrInvalid
		}
	case AccelerateMake:
		if c.BuildingType != DeskBuilding && c.BuildingType != PetRoomBuilding || c.SpeedNum <= 0 {
			return ErrInvalid
		}
	case CancelMake, ConfirmMake:
		if c.BuildingType != DeskBuilding && c.BuildingType != PetRoomBuilding {
			return ErrInvalid
		}
	case AdminExchange:
		if c.FromType <= 0 || c.ToType <= 0 || c.FromType == c.ToType {
			return ErrInvalid
		}
	case BoardReceive:
		if c.MissionID <= 0 || c.Leader <= 0 || len(c.Partners) > 5 || c.WishCrystal < 0 || c.WishCrystal > 1 {
			return ErrInvalid
		}
	case BoardGiveUp:
		if c.MissionID <= 0 {
			return ErrInvalid
		}
	case BoardConfirm:
	default:
		return ErrUnqualified
	}
	return nil
}

type Admission struct {
	Operation       operation.Context
	DecisionAt      time.Time
	Actor           appbook.DurableActor
	Command         Command
	ContentRevision string
}

type Result struct {
	Schema          string
	Command         Command
	Actor           appbook.DurableActor
	OperationID     ids.UUID
	Entropy         [32]byte
	ContentRevision string
	DecisionAt      time.Time
	Body            map[string]any
}

type OwnerPort interface {
	ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (Root, bool, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (Root, bool, error)
	EnsureRootTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) error
	SaveRootTx(context.Context, tx.Tx, Root, int64) error
	InsertBoardReportTx(context.Context, tx.Tx, identity.PlayerID, int64, string, time.Time) error
	ReadBoardReportTx(context.Context, tx.Queryer, identity.PlayerID, int64) (string, bool, error)
	DeleteBoardReportsExceptTx(context.Context, tx.Tx, identity.PlayerID, []int64) error
}
type ContentPort interface {
	WorkshopInputsActive(context.Context) (string, bool, error)
	WorkshopInputsTx(context.Context, tx.Queryer, string) (Catalog, error)
}
type BookPort interface {
	BookInputsTx(context.Context, tx.Queryer, appbook.InputScope) (appbook.Inputs, error)
}
type PetPort interface {
	FindPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, bool, error)
}
type ActorFence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type CostPort interface {
	PrepareMaterialDebitTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (*i5.PreparedMaterialDebit, error)
	ApplyMaterialDebitTx(context.Context, tx.Tx, *i5.PreparedMaterialDebit) (i5.MaterialDebitResult, error)
}
type GrantPort interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

type BoardHeroes interface {
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
}
type BoardLevels interface {
	ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error)
}
type BoardStats interface {
	HeroTx(context.Context, ca.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error)
}
type BoardCombat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, appcombat.StartRequest) (appcombat.Started, error)
	Resolve(context.Context, operation.Context, ids.UUID) (appcombat.Resolved, error)
	TerminalTx(context.Context, tx.Tx, appcombat.TerminalRequest) (appcombat.Settled, error)
}

type Service struct {
	Timed    gen.TimedRunner
	Reads    tx.Runner
	Owner    OwnerPort
	Book     BookPort
	Content  ContentPort
	Pets     PetPort
	Players  playerroot.TxLocker
	Fence    ActorFence
	Costs    CostPort
	Grants   GrantPort
	Receipts receipt.Store
	Heroes   BoardHeroes
	Levels   BoardLevels
	Stats    BoardStats
	Combat   BoardCombat
}

func (s Service) complete() bool {
	return s.Timed.Binder.Time != nil && s.Timed.Runner.DB != nil && s.Reads.DB != nil && s.Owner != nil && s.Book != nil && s.Content != nil && s.Pets != nil && s.Players != nil && s.Fence != nil && s.Costs != nil && s.Grants != nil && s.Receipts != nil
}

func Profile() tx.Profile {
	return tx.Profile{Name: "I9_10A_EVENT_CENTRE", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 15 * time.Second}
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}
}

func actorRecord(a identity.ActorContext) appbook.DurableActor {
	return appbook.DurableActor{Account: a.AccountID.UUID(), Session: a.SessionID.UUID(), Context: a.ContextID.UUID(), AccountUID: string(a.AccountUID), Server: int32(a.LogicalServerID), Player: int64(a.PlayerID), Generation: a.ContextGeneration, SessionVersion: a.SessionLivenessVersion, ContextVersion: a.ContextLivenessVersion}
}

func receiptID(d Admission) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(d.Actor.Player, 10), Domain: "event-centre", Operation: d.Command.Family, SemanticKey: d.Operation.ID.String()}
}

func fingerprint(c Command) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{"command": c, "policy": PolicyVersion})
}

func (s Service) proof(ctx context.Context, q tx.Queryer, d Admission) (Result, bool, error) {
	var out Result
	r, ok, err := s.Receipts.FindTx(ctx, q, receiptID(d))
	if err != nil || !ok {
		return out, ok, err
	}
	fp, err := fingerprint(d.Command)
	if err != nil {
		return out, true, err
	}
	if r.Validate() != nil || r.Identity != receiptID(d) || r.RequestFingerprint != fp || r.OperationClass != OperationClass || r.ResultSchema != ResultSchema || r.ActorAccountUID != d.Actor.AccountUID || r.ContextID != d.Actor.Context || r.PolicyVersion != PolicyVersion || r.OperationStartedAt.UnixMicro() != d.Operation.StartedAt.UnixMicro() {
		return out, true, ErrProof
	}
	dec := json.NewDecoder(bytes.NewReader(r.ResultPayload))
	dec.DisallowUnknownFields()
	if err = dec.Decode(&out); err != nil {
		return out, true, err
	}
	var trailing any
	if dec.Decode(&trailing) != io.EOF {
		return out, true, ErrProof
	}
	if !d.DecisionAt.IsZero() && out.DecisionAt.UnixMicro() != d.DecisionAt.UnixMicro() {
		return out, true, ErrProof
	}
	if out.Schema != ResultSchema || !sameCommand(out.Command, d.Command) || out.Actor != d.Actor || out.OperationID != d.Operation.ID || out.Entropy != d.Operation.EntropySeed || out.DecisionAt.IsZero() || out.ContentRevision != d.ContentRevision || out.ContentRevision == "" || out.Body == nil || out.DecisionAt.After(r.RecordedAt) {
		return out, true, ErrProof
	}
	for _, ref := range d.Operation.Policies.Refs() {
		if v, exists := r.OperationPolicyRefs.Get(ref.Name); !exists || v != ref.Version {
			return out, true, ErrProof
		}
	}
	return out, true, nil
}

func sameCommand(left, right Command) bool {
	x, leftErr := fingerprint(left)
	y, rightErr := fingerprint(right)
	return leftErr == nil && rightErr == nil && x == y
}

func (s Service) putReceipt(ctx context.Context, t tx.Tx, d Admission, out Result) error {
	raw, err := json.Marshal(out)
	if err != nil {
		return err
	}
	fp, err := fingerprint(d.Command)
	if err != nil {
		return err
	}
	r, err := receipt.New(d.Operation, receiptID(d), OperationClass, ResultSchema, raw, fp)
	if err != nil {
		return err
	}
	r.ActorAccountUID = d.Actor.AccountUID
	r.ContextID = d.Actor.Context
	r.PolicyVersion = PolicyVersion
	r.RecordedAt = d.DecisionAt
	put, err := s.Receipts.PutTx(ctx, t, r)
	if err != nil {
		return err
	}
	if !put.Inserted {
		return ErrProof
	}
	return nil
}

// All Event Centre mutations take actor fence, player315, then the Event Centre root.
func (s Service) lockPlan(ctx context.Context, t tx.Tx, a identity.ActorContext, at time.Time) error {
	if err := s.Fence.FenceActorTx(ctx, t, a, at); err != nil {
		return err
	}
	roots, err := s.Players.LockPlayerRootsTx(ctx, t, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
	if err != nil {
		return err
	}
	if len(roots) != 1 {
		return ErrUnqualified
	}
	return nil
}

func (s Service) Command(ctx context.Context, a identity.ActorContext, c Command, op operation.Context) (Result, error) {
	if !s.complete() || c.Validate() != nil || op.ID.IsZero() || op.StartedAt.IsZero() {
		return Result{}, ErrUnqualified
	}
	timed, err := s.Timed.Binder.Bind(ctx, op)
	if err != nil {
		return Result{}, err
	}
	var historical Result
	found := false
	check, err := s.Reads.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		if err := s.Fence.FenceActorTx(ctx, sc.Tx, a, timed.DecisionAt()); err != nil {
			return err
		}
		d := Admission{Operation: op, Actor: actorRecord(a), Command: c}
		r, ok, err := s.Receipts.FindTx(ctx, sc.Tx, receiptID(d))
		if err != nil || !ok {
			return err
		}
		for _, ref := range op.Policies.Refs() {
			if v, exists := r.OperationPolicyRefs.Get(ref.Name); !exists || v != ref.Version {
				return ErrProof
			}
		}
		d.Operation.Policies = r.OperationPolicyRefs
		d.ContentRevision, _ = r.OperationPolicyRefs.Get("content")
		historical, found, err = s.proof(ctx, sc.Tx, d)
		return err
	})
	if err != nil {
		return Result{}, err
	}
	if check.Outcome != tx.DefiniteCommit {
		return Result{}, ErrUnavailable
	}
	if found {
		return historical, nil
	}
	revision, active, err := s.Content.WorkshopInputsActive(ctx)
	if err != nil {
		return Result{}, err
	}
	if !active {
		return Result{}, ErrUnavailable
	}
	if v, ok := op.Policies.Get("content"); ok {
		revision = v
	}
	refs := op.Policies.Refs()
	if _, ok := op.Policies.Get("content"); !ok {
		refs = append(refs, policy.Ref{Name: "content", Version: revision})
	}
	if v, ok := op.Policies.Get("event-centre"); ok {
		if v != PolicyVersion {
			return Result{}, ErrProof
		}
	} else {
		refs = append(refs, policy.Ref{Name: "event-centre", Version: PolicyVersion})
	}
	if op.Policies, err = policy.NewSet(refs...); err != nil {
		return Result{}, err
	}
	d := Admission{Operation: op, DecisionAt: timed.DecisionAt(), Actor: actorRecord(a), Command: c, ContentRevision: revision}
	var out Result
	res, err := s.Timed.Runner.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(ctx context.Context, sc tx.Scope) error {
		if err := s.lockPlan(ctx, sc.Tx, a, d.DecisionAt); err != nil {
			return err
		}
		prior, found, err := s.proof(ctx, sc.Tx, d)
		if err != nil {
			return err
		}
		if found {
			out = prior
			return nil
		}
		out = Result{Schema: ResultSchema, Command: d.Command, Actor: d.Actor, OperationID: d.Operation.ID, Entropy: d.Operation.EntropySeed, ContentRevision: d.ContentRevision, DecisionAt: d.DecisionAt}
		out.Body, err = s.apply(ctx, sc, a, d)
		if err != nil {
			return err
		}
		if err = s.putReceipt(ctx, sc.Tx, d, out); err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return Result{}, err
	}
	if res.Outcome != tx.DefiniteCommit {
		return Result{}, ErrUnavailable
	}
	return out, nil
}

func (s Service) Read(ctx context.Context, a identity.ActorContext, mid uint16, op operation.Context) (map[string]any, error) {
	if !s.complete() {
		return nil, ErrUnavailable
	}
	switch mid {
	case 1072, 1074, 1081, 1090:
	default:
		return nil, ErrUnavailable
	}
	revision, active, err := s.Content.WorkshopInputsActive(ctx)
	if err != nil {
		return nil, err
	}
	if !active {
		return nil, ErrUnavailable
	}
	timed, err := s.Timed.Binder.Bind(ctx, op)
	if err != nil {
		return nil, err
	}
	at := timed.DecisionAt()
	var body map[string]any
	result, err := s.Reads.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		if err := s.Fence.FenceActorTx(ctx, sc.Tx, a, at); err != nil {
			return err
		}
		root, exists, err := s.Owner.ReadRootTx(ctx, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		var state State
		if exists {
			state = root.Facts.Clone()
		} else {
			state = Seed()
		}
		catalog, err := s.Content.WorkshopInputsTx(ctx, sc.Tx, revision)
		if err != nil {
			return err
		}
		bookInputs, err := s.Book.BookInputsTx(ctx, sc.Tx, appbook.InputScope{Player: a.PlayerID, ContentRevision: revision, ObservedAt: at})
		if err != nil {
			return err
		}
		if err = state.Validate(); err != nil {
			return err
		}
		if err = state.SettleMakes(at); err != nil {
			return err
		}
		switch mid {
		case 1072:
			body, err = recycleRead(catalog, state, bookInputs, at)
		case 1074:
			body, err = makeRead(DeskBuilding, state.Desk, bookInputs, at)
		case 1090:
			body, err = makeRead(PetRoomBuilding, state.Pet, bookInputs, at)
		case 1081:
			body = adminRead(catalog, state, bookInputs, at)
		}
		return err
	})
	if err != nil {
		return nil, err
	}
	if result.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return body, nil
}

func recycleRead(catalog Catalog, state State, inputs appbook.Inputs, at time.Time) (map[string]any, error) {
	level := buildingLevel(inputs, RecycleBuilding)
	limit, err := catalog.EnergyLimit(level)
	if err != nil {
		return nil, err
	}
	body, err := RecycleWire(state, limit, catalog.Misc.SaturationSeconds, at)
	if err != nil {
		return nil, err
	}
	body["building_info"] = buildingInfo(inputs, RecycleBuilding)
	return body, nil
}

func makeRead(buildingType int64, makeState MakeState, inputs appbook.Inputs, at time.Time) (map[string]any, error) {
	body, err := MakeWire(buildingType, makeState, at)
	if err != nil {
		return nil, err
	}
	body["building_info"] = buildingInfo(inputs, buildingType)
	return body, nil
}

func adminRead(catalog Catalog, state State, inputs appbook.Inputs, at time.Time) map[string]any {
	level := buildingLevel(inputs, AdminBuilding)
	counts := effectiveAdminCounts(state, at)
	info := map[string]any{}
	for _, source := range adminSources {
		for _, destination := range adminDestinations {
			if source == destination {
				continue
			}
			key := AdminKey(source, destination)
			count := counts[key]
			if !catalog.AdminAllowedSource(level, source) {
				count = 0
			}
			info[key] = count
		}
	}
	return map[string]any{"info": info}
}

func buildingLevel(inputs appbook.Inputs, buildingType int64) int64 {
	return inputs.Applied.Buildings[buildingType].Level
}

func buildingInfo(inputs appbook.Inputs, buildingType int64) map[string]any {
	building, exists := inputs.Applied.Buildings[buildingType]
	if !exists {
		return map[string]any{"lev": int64(1), "start_time": int64(0), "need_time": int64(0), "new_evolve": int64(0)}
	}
	return BookBuildingWire(building)
}

func effectiveAdminCounts(state State, at time.Time) map[string]int64 {
	out := map[string]int64{}
	if state.AdminDay != modesDay(at) {
		return out
	}
	for key, count := range state.Admin {
		out[key] = count
	}
	return out
}
