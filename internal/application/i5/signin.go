package i5

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type SignInStore interface {
	LockSignInTx(context.Context, tx.Tx, identity.PlayerID, objective.SignRoot) (objective.SignRoot, error)
	ReadSignInTx(context.Context, tx.Queryer, identity.PlayerID) (objective.SignRoot, error)
	SaveSignInTx(context.Context, tx.Tx, identity.PlayerID, objective.SignRoot, int64) error
}
type SignInContent interface {
	SignInCatalogTx(context.Context, tx.Queryer, string) (objective.SignCatalog, error)
	SummonCatalogTx(context.Context, tx.Queryer, string) (summon.Catalog, error)
}
type SignInHeroes interface {
	LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error
	AwardStoryPartnerTx(context.Context, tx.Tx, identity.PlayerID, int64, string, operation.Context) (character.Hero, *character.CollectionAdmissionProof, error)
}
type SignInRuntime struct {
	Store    SignInStore
	Content  SignInContent
	Heroes   SignInHeroes
	HeroWire func(character.Hero) (map[string]any, error)
}

func (s Service) signInRoot(ctx context.Context, t tx.Tx, pid identity.PlayerID, revision string, at time.Time) (objective.SignRoot, error) {
	if s.SignIn == nil || s.SignIn.Store == nil || s.SignIn.Content == nil {
		return objective.SignRoot{}, errors.New("sign-in unavailable")
	}
	initial, err := (objective.SignRoot{StateVersion: 1}).Refresh(at, revision)
	if err != nil {
		return initial, err
	}
	root, err := s.SignIn.Store.LockSignInTx(ctx, t, pid, initial)
	if err != nil {
		return root, err
	}
	next, err := root.Refresh(at, revision)
	if err != nil {
		return root, err
	}
	if next != root {
		next.StateVersion++
		if err = s.SignIn.Store.SaveSignInTx(ctx, t, pid, next, root.StateVersion); err != nil {
			return root, err
		}
	}
	return next, nil
}
func (s Service) signInProjection(ctx context.Context, q tx.Queryer, root objective.SignRoot) (map[string]any, error) {
	catalog, err := s.SignIn.Content.SignInCatalogTx(ctx, q, root.ContentRevision)
	if err != nil {
		return nil, err
	}
	month, err := catalog.Month(root.Month % 100)
	if err != nil {
		return nil, err
	}
	return map[string]any{"awards": month.Awards, "is_signed": root.Signed, "sign_times": root.Count, "month": month.Month, "partner_id": month.PartnerID, "is_skin": month.IsSkin}, nil
}
func (s Service) ReadSignIn(ctx context.Context, actor identity.ActorContext, op operation.Context) (map[string]any, error) {
	timed, err := s.missionOperation(ctx, op)
	if err != nil {
		return nil, err
	}
	scope, err := missionScope(actor.PlayerID, timed)
	if err != nil {
		return nil, err
	}
	var body map[string]any
	_, err = s.Runner.Run(ctx, timed.Operation(), s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, tr tx.Scope) error {
		if err := s.Store.FenceActorTx(ctx, tr.Tx, actor, scope.DecisionAt); err != nil {
			return err
		}
		root, err := s.signInRoot(ctx, tr.Tx, actor.PlayerID, scope.ContentRevision, scope.DecisionAt)
		if err != nil {
			return err
		}
		body, err = s.signInProjection(ctx, tr.Tx, root)
		return err
	})
	return body, err
}

type signInResult struct {
	Award  map[string]any `json:"award"`
	Count  int64          `json:"sign_times"`
	Signed int64          `json:"is_signed"`
	Grant  *GrantResult   `json:"grant,omitempty"`
}

func (s Service) ClaimSignIn(ctx context.Context, actor identity.ActorContext, op operation.Context) (map[string]any, error) {
	if s.SignIn == nil || s.SignIn.Store == nil || s.SignIn.Content == nil {
		return nil, errors.New("sign-in unavailable")
	}
	timed, err := s.missionOperation(ctx, op)
	if err != nil {
		return nil, err
	}
	scope, err := missionScope(actor.PlayerID, timed)
	if err != nil {
		return nil, err
	}
	// shortcut: stock353 has no nonce; a new operation cannot distinguish a retry from a deliberate VIP bonus. Upgrade only with a qualified client nonce.
	id := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(actor.PlayerID), Domain: "objective", Operation: "sign-in", SemanticKey: op.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(map[string]any{"command": "sign-in"})
	if err != nil {
		return nil, err
	}
	var out signInResult
	replay := false
	result, err := s.Runner.Run(ctx, timed.Operation(), s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}, func(ctx context.Context, tr tx.Scope) error {
		if err := s.Store.FenceActorTx(ctx, tr.Tx, actor, scope.DecisionAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(ctx, tr.Tx, id); err != nil {
			return err
		} else if ok {
			if prior.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: id}
			}
			replay = true
			return json.Unmarshal(prior.ResultPayload, &out)
		}
		if s.SignIn.Heroes != nil {
			if err := s.SignIn.Heroes.LockStoryRosterTx(ctx, tr.Tx, actor.PlayerID); err != nil {
				return err
			}
		}
		root, err := s.signInRoot(ctx, tr.Tx, actor.PlayerID, scope.ContentRevision, scope.DecisionAt)
		if err != nil {
			return err
		}
		catalog, err := s.SignIn.Content.SignInCatalogTx(ctx, tr.Tx, root.ContentRevision)
		if err != nil {
			return err
		}
		month, err := catalog.Month(root.Month % 100)
		if err != nil {
			return err
		}
		privilege, err := s.Privileges.SnapshotTx(ctx, tr.Tx, actor.PlayerID, scope.DecisionAt)
		if err != nil {
			return err
		}
		next, award, occurrence, err := root.Claim(month, privilege.VIPLevel)
		if err != nil {
			return err
		}
		lines := []grant.Line{}
		wire := map[string]any{"table_id": award.ItemID, "item_num": award.ItemNum, "to_stone": false}
		if award.Crystal > 0 {
			wire["table_id"] = int64(-1)
			wire["item_num"] = award.Crystal
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: award.Crystal})
		} else if award.ItemID >= 10000000 && award.ItemID < 20000000 {
			if award.ItemNum != 1 || s.SignIn.Heroes == nil || s.SignIn.HeroWire == nil {
				return errors.New("sign-in Hero owner unavailable")
			}
			hero, admission, err := s.SignIn.Heroes.AwardStoryPartnerTx(ctx, tr.Tx, actor.PlayerID, award.ItemID, root.ContentRevision, timed.Operation())
			if err != nil {
				return err
			}
			if admission == nil {
				summons, err := s.SignIn.Content.SummonCatalogTx(ctx, tr.Tx, root.ContentRevision)
				if err != nil {
					return err
				}
				stone, err := summons.Fragments(award.ItemID)
				if err != nil {
					return err
				}
				wire = map[string]any{"table_id": stone[0], "item_num": stone[1], "to_stone": true}
				lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: stone[0], Amount: stone[1]})
			} else {
				wire, err = s.SignIn.HeroWire(hero)
				if err != nil {
					return err
				}
				wire["is_partner"] = true
			}
		} else {
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: award.ItemID, Amount: award.ItemNum})
		}
		out = signInResult{Award: wire, Count: next.Count, Signed: next.Signed}
		if len(lines) > 0 {
			// The entitlement pins the month's content, even if another revision is active now.
			pinned, err := bindContentRevisionForSign(timed.Operation(), root.ContentRevision)
			if err != nil {
				return err
			}
			plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "objective", Operation: "sign-in", BusinessKey: "monthly", Occurrence: occurrence, PolicyVersion: "I9_MONTHLY_SIGNIN_V1"}, Lines: lines}
			granted, err := s.SettleGrantTx(ctx, tr.Tx, actor, plan, pinned, GrantTxOptions{AllowOverflowMail: true})
			if err != nil {
				return err
			}
			out.Grant = &granted
		}
		if err = s.SignIn.Store.SaveSignInTx(ctx, tr.Tx, actor.PlayerID, next, root.StateVersion); err != nil {
			return err
		}
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		record, err := receipt.New(timed.Operation(), id, "I5_OBJECTIVE", "gxb.i5.sign-in.v1", raw, fingerprint)
		if err != nil {
			return err
		}
		record.ActorAccountUID, record.ContextID = string(actor.AccountUID), actor.ContextID.UUID()
		_, err = s.Receipts.PutTx(ctx, tr.Tx, record)
		return err
	})
	if err != nil {
		return nil, err
	}
	if result.Reconciled {
		record, ok := result.Evidence.(receipt.Receipt)
		if !ok {
			return nil, errors.New("sign-in recovery evidence missing")
		}
		if err = json.Unmarshal(record.ResultPayload, &out); err != nil {
			return nil, err
		}
		replay = true
	}
	body := map[string]any{"award": out.Award, "sign_times": out.Count, "is_signed": out.Signed}
	if out.Grant != nil {
		projected, err := s.projectSettlement(ctx, actor, []GrantResult{*out.Grant}, op, replay)
		if err != nil {
			return nil, err
		}
		if len(projected.Economy) > 0 {
			body["economy_"] = projected.Economy
		}
		if len(projected.NewFunctionIDs) > 0 {
			body["new_funcs_"] = projected.NewFunctionIDs
		}
	}
	return body, nil
}

func bindContentRevisionForSign(op operation.Context, revision string) (operation.Context, error) {
	refs := op.Policies.Refs()
	for i := range refs {
		if refs[i].Name == "content" {
			refs[i].Version = revision
			var err error
			op.Policies, err = policy.NewSet(refs...)
			return op, err
		}
	}
	return bindContentRevision(op, revision)
}

type SignInBootstrap struct{ Owner Service }

func (SignInBootstrap) Name() string     { return "i5.sign-in" }
func (SignInBootstrap) Claims() []string { return []string{"352"} }
func (b SignInBootstrap) ReconcileCharacterLogin(ctx context.Context, t tx.Tx, actor identity.ActorContext, op operation.Context, at time.Time) error {
	bound, err := b.Owner.bindActiveContentTx(ctx, t, op)
	if err != nil {
		return err
	}
	revision, err := requireContentRevision(bound)
	if err != nil {
		return err
	}
	_, err = b.Owner.signInRoot(ctx, t, actor.PlayerID, revision, at)
	return err
}
func (b SignInBootstrap) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	root, err := b.Owner.SignIn.Store.ReadSignInTx(ctx, q, actor.PlayerID)
	if err != nil {
		return err
	}
	detail["352"], err = b.Owner.signInProjection(ctx, q, root)
	return err
}
