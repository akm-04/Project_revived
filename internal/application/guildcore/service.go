package guildcore

import (
	"bytes"
	"context"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrInvalidService          = errors.New("guild service ports incomplete")
	ErrAlreadyInGuild          = errors.New("player already has canonical guild membership")
	ErrGuildNotFound           = errors.New("guild not found")
	ErrGuildRetired            = errors.New("guild retired")
	ErrGuildRegionMismatch     = errors.New("guild logical server mismatch")
	ErrGuildClosed             = errors.New("guild admission closed")
	ErrGuildFull               = errors.New("guild member capacity reached")
	ErrGuildApplicationFull    = errors.New("guild application target is already at member capacity")
	ErrGuildNameTaken          = errors.New("guild name already in use")
	ErrApplicationLimit        = errors.New("guild application limit reached")
	ErrJoinLimit               = errors.New("guild rolling join limit reached")
	ErrLevelTooLow             = errors.New("canonical player level below guild requirement")
	ErrApplicantLimit          = errors.New("guild applicant list full")
	ErrCantJoinGuild           = errors.New("guild join temporarily unavailable")
	ErrInvalidGuildPolicyInput = errors.New("invalid guild policy input")
)

type JoinCooldownKind uint8

const (
	JoinCooldownOtherGuild JoinCooldownKind = iota + 1
	JoinCooldownSameGuild
)

type CantJoinError struct {
	Kind             JoinCooldownKind
	RemainingSeconds int64
}

func (e *CantJoinError) Error() string {
	return fmt.Sprintf("%v: kind=%d remaining=%d", ErrCantJoinGuild, e.Kind, e.RemainingSeconds)
}
func (e *CantJoinError) Unwrap() error { return ErrCantJoinGuild }

type Service struct {
	Timed          appgeneration.TimedRunner
	Store          Store
	Fencer         ActorFencer
	PlayerRoots    PlayerRootLocker
	Level          LevelReader
	Scalar         ScalarDebiter
	LevelAndScalar LevelAndScalarDebiter
	Receipts       receipt.Store
	ReceiptRead    receipt.Reader
	Policy         PolicyBinding
	Profile        tx.Profile
}

func DefaultProfile() tx.Profile {
	return tx.Profile{Name: "I6C_GUILD_WRITE", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}
func (s Service) profile() tx.Profile {
	if s.Profile.Name == "" {
		return DefaultProfile()
	}
	return s.Profile
}
func (s Service) validate() error {
	if s.Store == nil || s.Fencer == nil || s.PlayerRoots == nil || s.Level == nil || s.Scalar == nil || s.LevelAndScalar == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return ErrInvalidService
	}
	if err := s.Policy.Validate(); err != nil {
		return ErrInvalidService
	}
	return nil
}

func bindGuildPolicy(op operation.Context, revision string) (operation.Context, error) {
	if revision == "" {
		return operation.Context{}, ErrInvalidGuildPolicyInput
	}
	if cur, ok := op.Policies.Get("guild-core"); ok {
		if cur != revision {
			return operation.Context{}, errors.New("guild policy revision conflict")
		}
		return op, nil
	}
	refs := op.Policies.Refs()
	refs = append(refs, policy.Ref{Name: "guild-core", Version: revision})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, err
	}
	op.Policies = set
	return op, nil
}

type CreateRequest struct {
	Name      string
	Icon      int64
	IconFrame int64
}
type CreateResult struct {
	GuildID  int64 `json:"guild_id"`
	Role     int16 `json:"role"`
	Replayed bool  `json:"-"`
}

type ApplyResult struct {
	GuildID  int64 `json:"guild_id"`
	Joined   bool  `json:"joined"`
	Applied  bool  `json:"applied"`
	Replayed bool  `json:"-"`
}

type dynamicResolver struct {
	reader receipt.Reader
	id     receipt.Identity
	fp     [32]byte
	ready  bool
}

func (r *dynamicResolver) set(id receipt.Identity, fp [32]byte) { r.id = id; r.fp = fp; r.ready = true }
func (r *dynamicResolver) ResolveTimed(ctx context.Context, _ appgeneration.TimedResolutionRequest) (tx.Resolution, error) {
	if !r.ready {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return (receipt.Resolver{Reader: r.reader, Identity: r.id, Fingerprint: r.fp}).Resolve(ctx, tx.ResolutionRequest{})
}

func (s Service) Create(ctx context.Context, actor identity.ActorContext, req CreateRequest, op operation.Context) (CreateResult, error) {
	if err := s.validate(); err != nil {
		return CreateResult{}, err
	}
	p := s.Policy.Policy
	if !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || !p.ValidName(req.Name) || !p.AllowsIcon(req.Icon) || req.IconFrame != 0 {
		return CreateResult{}, ErrInvalidGuildPolicyInput
	}
	// Stock Create has no client operation nonce. A read-only convergence fast
	// path handles the common post-commit retry without allocating another Guild.
	// Canonical mutation authorization is still repeated under locks below.
	if existing, ok, err := s.Store.ReadMembership(ctx, actor.PlayerID); err != nil {
		return CreateResult{}, err
	} else if ok {
		if g, gok, err := s.Store.ReadGuild(ctx, existing.GuildID); err != nil {
			return CreateResult{}, err
		} else if gok && g.RetiredAt == nil && existing.Role == guild.Leader && g.LogicalServerID == actor.LogicalServerID && g.Name == req.Name && g.Icon == req.Icon && g.IconFrame == req.IconFrame {
			return CreateResult{GuildID: int64(g.ID), Role: int16(existing.Role), Replayed: true}, nil
		}
		return CreateResult{}, ErrAlreadyInGuild
	}
	fp, err := receipt.FingerprintRequest(req)
	if err != nil {
		return CreateResult{}, err
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return CreateResult{}, err
	}
	var out CreateResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: false}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		serial, allocVer, err := s.Store.LockAllocatorTx(txctx, scope.Tx, actor.LogicalServerID, at)
		if err != nil {
			return err
		}
		// SOURCE_FACT: message 30019 rejects duplicate Guild names. The
		// server-local exact-text scope is the explicit I6C reconstruction
		// policy. The allocator lock serializes create/rename name decisions.
		if taken, err := s.Store.GuildNameInUseTx(txctx, scope.Tx, actor.LogicalServerID, req.Name, 0); err != nil {
			return err
		} else if taken {
			return ErrGuildNameTaken
		}
		gid, err := guild.WireID(actor.LogicalServerID, serial)
		if err != nil {
			return err
		}
		g := guild.Guild{ID: gid, LogicalServerID: actor.LogicalServerID, Name: req.Name, Icon: req.Icon, IconFrame: req.IconFrame, Description: "", ApplyType: guild.ApplyByApplication, MinAllowLevel: p.JoinLevelMin, Vitality: p.InitialVitality, PolicyRevision: s.Policy.Revision, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
		// Create the new Guild root (rank 310) before crossing the I4 player-root
		// fence (315) and GuildMembership (320). If a concurrent membership won
		// the player root first, this whole speculative Guild row rolls back.
		if err := s.Store.InsertGuildTx(txctx, scope.Tx, g); err != nil {
			return err
		}
		if _, err := s.PlayerRoots.LockPlayerRootsTx(txctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID}); err != nil {
			return err
		}
		if _, has, err := s.Store.LockMembershipTx(txctx, scope.Tx, actor.PlayerID); err != nil {
			return err
		} else if has {
			return ErrAlreadyInGuild
		}
		epoch, err := s.Store.MembershipEpochTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		rid := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "guild", Operation: "create", SemanticKey: fmt.Sprintf("epoch:%d:%x", epoch, fp[:8])}
		resolver.set(rid, fp)
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, rid); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: rid}
			}
			if err := json.Unmarshal(prior.ResultPayload, &out); err != nil {
				return err
			}
			out.Replayed = true
			return nil
		}
		m := guild.Membership{PlayerID: actor.PlayerID, GuildID: gid, Role: guild.Leader, JoinedAt: at, MembershipVersion: 1, StateVersion: 1, UpdatedAt: at}
		if err := s.Store.InsertMembershipTx(txctx, scope.Tx, m); err != nil {
			return err
		}
		// F2 invariant: canonical membership makes every outgoing application
		// obsolete. Create must enforce the same cleanup as all other membership
		// establishment paths before crossing into I5-owned locks.
		if err := s.Store.DeleteApplicationsForPlayerTx(txctx, scope.Tx, actor.PlayerID); err != nil {
			return err
		}
		ev := guild.MembershipEvent{PlayerID: actor.PlayerID, GuildID: gid, Kind: guild.EventJoin, OccurredAt: at, ActorPlayerID: actor.PlayerID, PolicyRevision: s.Policy.Revision}
		if err := s.Store.AppendMembershipEventTx(txctx, scope.Tx, ev, bound.ID); err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "CREATE", actor.PlayerID, actor.PlayerID, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
			return err
		}
		if err := s.Store.AdvanceAllocatorTx(txctx, scope.Tx, actor.LogicalServerID, serial, allocVer, at); err != nil {
			return err
		}
		// All Guild-owned rows are already created/locked before crossing into
		// I5 ranks 700/710/720. A failed level/currency gate rolls back the
		// entire transaction, including allocator advance and Guild rows.
		if _, _, err := s.LevelAndScalar.AuthorizeLevelAndDebitScalarTx(txctx, scope.Tx, actor.PlayerID, p.CreateLevel, "crystal", p.CreateCrystalCost, at); err != nil {
			if errors.Is(err, appi5.ErrLevelRequirement) {
				return ErrLevelTooLow
			}
			return err
		}
		out = CreateResult{GuildID: int64(gid), Role: int16(guild.Leader)}
		raw, _ := json.Marshal(out)
		rr, err := receipt.New(bound, rid, "I6C_GUILD", "gxb.i6c.guild.create.v1", raw, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID = string(actor.AccountUID)
		rr.ContextID = actor.ContextID.UUID()
		rr.PolicyVersion = s.Policy.Revision
		_, err = s.Receipts.PutTx(txctx, scope.Tx, rr)
		return err
	})
	return out, err
}

func (s Service) ApplyOrJoin(ctx context.Context, actor identity.ActorContext, gid guild.ID, op operation.Context) (ApplyResult, error) {
	if err := s.validate(); err != nil {
		return ApplyResult{}, err
	}
	if gid <= 0 {
		return ApplyResult{}, ErrGuildNotFound
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return ApplyResult{}, err
	}
	fp, err := receipt.FingerprintRequest(struct{ GuildID int64 }{int64(gid)})
	if err != nil {
		return ApplyResult{}, err
	}
	var out ApplyResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		g, ok, err := s.Store.LockGuildTx(txctx, scope.Tx, gid)
		if err != nil {
			return err
		}
		if !ok {
			return ErrGuildNotFound
		}
		if g.RetiredAt != nil {
			return ErrGuildRetired
		}
		if g.LogicalServerID != actor.LogicalServerID {
			return ErrGuildRegionMismatch
		}
		if _, err := s.PlayerRoots.LockPlayerRootsTx(txctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID}); err != nil {
			return err
		}
		if m, has, err := s.Store.LockMembershipTx(txctx, scope.Tx, actor.PlayerID); err != nil {
			return err
		} else if has {
			if m.GuildID == gid {
				out = ApplyResult{GuildID: int64(gid), Joined: true, Replayed: true}
				return nil
			}
			return ErrAlreadyInGuild
		}

		// F2: current locked apply_type chooses the stock-facing branch. A legacy
		// apply_or_join.v1 receipt can never override the current Guild mode.
		switch g.ApplyType {
		case guild.ApplyClosed:
			return ErrGuildClosed
		case guild.ApplyByApplication:
			// Current pending application is canonical reversible state. Converge
			// before mutable creation-only cooldown/capacity gates; those gates decide
			// whether a new row may be created, not whether an existing row exists.
			if _, exists, err := s.Store.LockApplicationTx(txctx, scope.Tx, gid, actor.PlayerID); err != nil {
				return err
			} else if exists {
				out = ApplyResult{GuildID: int64(gid), Applied: true, Replayed: true}
				return nil
			}
			if err := s.checkJoinGatesTx(txctx, scope.Tx, actor.PlayerID, gid, at); err != nil {
				return err
			}
			// SOURCE_FACT: message 30016 is specifically the "guild you apply is
			// full" denial, distinct from 30020 for an actual join at capacity.
			members, err := s.Store.CountMembersTx(txctx, scope.Tx, gid)
			if err != nil {
				return err
			}
			if members >= s.Policy.Policy.MemberCap {
				return ErrGuildApplicationFull
			}
			outCount, err := s.Store.CountOutgoingApplicationsTx(txctx, scope.Tx, actor.PlayerID)
			if err != nil {
				return err
			}
			if outCount >= s.Policy.Policy.OutgoingApplicationCap {
				return ErrApplicationLimit
			}
			inCount, err := s.Store.CountGuildApplicationsTx(txctx, scope.Tx, gid)
			if err != nil {
				return err
			}
			if inCount >= s.Policy.Policy.GuildApplicantCap {
				return ErrApplicantLimit
			}
			gen := positiveGeneration(bound.Derive("guild.application-generation", uint64(gid)))
			rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "apply_application", fmt.Sprintf("player:%d:generation:%d", actor.PlayerID, gen))
			resolver.set(rid, fp)
			if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, rid); err != nil {
				return err
			} else if ok {
				if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
					return &receipt.ConflictError{Identity: rid}
				}
				if err := json.Unmarshal(prior.ResultPayload, &out); err != nil {
					return err
				}
				out.Replayed = true
				return nil
			}
			if err := s.Store.InsertApplicationTx(txctx, scope.Tx, guild.Application{GuildID: gid, PlayerID: actor.PlayerID, Generation: gen, CreatedAt: at, StateVersion: 1}); err != nil {
				return err
			}
			if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "APPLY", actor.PlayerID, actor.PlayerID, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
				return err
			}
			// I5 level is intentionally checked after Guild-owned rank-330/350 work;
			// a denial rolls the whole transaction back, including row/audit/receipt.
			level, err := s.Level.PlayerLevelTx(txctx, scope.Tx, actor.PlayerID)
			if err != nil {
				return err
			}
			if level < g.MinAllowLevel {
				return ErrLevelTooLow
			}
			out = ApplyResult{GuildID: int64(gid), Applied: true}
			raw, _ := json.Marshal(out)
			rr, err := receipt.New(bound, rid, "I6C_GUILD", "gxb.i6c.guild.apply_application.v2", raw, fp)
			if err != nil {
				return err
			}
			rr.ActorAccountUID = string(actor.AccountUID)
			rr.ContextID = actor.ContextID.UUID()
			rr.PolicyVersion = s.Policy.Revision
			_, err = s.Receipts.PutTx(txctx, scope.Tx, rr)
			return err

		case guild.ApplyImmediate:
			if err := s.checkJoinGatesTx(txctx, scope.Tx, actor.PlayerID, gid, at); err != nil {
				return err
			}
			n, err := s.Store.CountMembersTx(txctx, scope.Tx, gid)
			if err != nil {
				return err
			}
			if n >= s.Policy.Policy.MemberCap {
				return ErrGuildFull
			}
			// Stock MID580 carries no nonce. This generation is only a retry-stable
			// same-attempt receipt key for UNKNOWN-COMMIT proof; later stock retries
			// converge from canonical GuildMembership above.
			attemptGen := positiveGeneration(bound.Derive("guild.immediate-join-attempt", uint64(gid)))
			rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "join_immediate", fmt.Sprintf("player:%d:attempt:%d", actor.PlayerID, attemptGen))
			resolver.set(rid, fp)
			if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, rid); err != nil {
				return err
			} else if ok {
				if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
					return &receipt.ConflictError{Identity: rid}
				}
				if err := json.Unmarshal(prior.ResultPayload, &out); err != nil {
					return err
				}
				out.Replayed = true
				return nil
			}
			m := guild.Membership{PlayerID: actor.PlayerID, GuildID: gid, Role: guild.Member, JoinedAt: at, MembershipVersion: 1, StateVersion: 1, UpdatedAt: at}
			if err := s.Store.InsertMembershipTx(txctx, scope.Tx, m); err != nil {
				return err
			}
			ev := guild.MembershipEvent{PlayerID: actor.PlayerID, GuildID: gid, Kind: guild.EventJoin, OccurredAt: at, ActorPlayerID: actor.PlayerID, PolicyRevision: s.Policy.Revision}
			if err := s.Store.AppendMembershipEventTx(txctx, scope.Tx, ev, bound.ID); err != nil {
				return err
			}
			if err := s.Store.DeleteApplicationsForPlayerTx(txctx, scope.Tx, actor.PlayerID); err != nil {
				return err
			}
			if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "JOIN", actor.PlayerID, actor.PlayerID, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
				return err
			}
			level, err := s.Level.PlayerLevelTx(txctx, scope.Tx, actor.PlayerID)
			if err != nil {
				return err
			}
			if level < g.MinAllowLevel {
				return ErrLevelTooLow
			}
			out = ApplyResult{GuildID: int64(gid), Joined: true}
			raw, _ := json.Marshal(out)
			rr, err := receipt.New(bound, rid, "I6C_GUILD", "gxb.i6c.guild.join_immediate.v2", raw, fp)
			if err != nil {
				return err
			}
			rr.ActorAccountUID = string(actor.AccountUID)
			rr.ContextID = actor.ContextID.UUID()
			rr.PolicyVersion = s.Policy.Revision
			_, err = s.Receipts.PutTx(txctx, scope.Tx, rr)
			return err
		default:
			return ErrGuildClosed
		}
	})
	return out, err
}

func positiveGeneration(seed [32]byte) int64 {
	v := binary.BigEndian.Uint64(seed[:8]) & 0x7fffffffffffffff
	if v == 0 {
		v = 1
	}
	return int64(v)
}

var _ = economy.ErrInsufficientBalance
