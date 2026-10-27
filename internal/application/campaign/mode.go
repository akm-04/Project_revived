// Package campaign composes the Campaign mode (I9_CAMPAIGN_V1): the world map
// (112, MID1 detail["112"]), FIGHT (113) and FIGHT_RESULT (114) for Normal and
// Super nodes. Lock order (F14): actor fence 315, formation heroes 410,
// campaign row 605, Combat 609, I5 700+; directory reads take no lock.
package campaign

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strconv"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	apppet "gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Mode struct {
	PetAwakening i5.AwakeningPetPort
	Awakening    i5.AwakeningCampaignPort
	Daily        DailyConsumption
	Timed        gen.TimedRunner
	Fresh        tx.Queryer
	Store        Store
	Content      Content
	Fence        Fence
	Functions    Functions
	Directory    Directory
	Heroes       Heroes
	HeroExp      HeroExp
	StoryHeroes  StoryHeroes
	StoryWire    func(character.Hero) (map[string]any, error)
	Pets         Pets
	MaxColor     i5.MaxHeroColorPolicyProvider
	Combat       Combat
	Energy       i5.TxTemporalDebiter
	Grants       Grants
	Privileges   i5.PrivilegeSnapshotProvider
	Costs        i5.TxMaterialCostDebiter
	Progression  Progression
	Stages       Stages
	Facts        Facts
	Receipts     receipt.Store
	ReceiptRead  receipt.Reader
}

type Progression interface {
	ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error)
}

type Store interface {
	ReadTx(context.Context, tx.Queryer, identity.PlayerID) (d.Record, error)
	LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (d.Record, error)
	SaveTx(context.Context, tx.Tx, identity.PlayerID, d.Record, []int64, time.Time) error
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	CampaignCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
	ResolveProgressionPolicyTx(context.Context, tx.Queryer, string) (player.ProgressionPolicy, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Functions interface {
	ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error)
}

type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

// Heroes locks a formation hero (rank 410) before the campaign row; a hero not owned refuses with ErrRefused.
type Heroes interface {
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
}

// HeroExp is Character's same-transaction exp credit, capped by the player level (D99).
type HeroExp interface {
	ApplyDormEXPLockedTx(context.Context, tx.Tx, character.HeroRef, int64, int64, string, time.Time) (character.Hero, bool, error)
}

type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, combat.StartRequest) (combat.Started, error)
	AttestSummaryTx(context.Context, tx.Tx, combat.SummaryRequest) (combat.SummaryAttested, error)
}

type Grants interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

// Stages opens the kind-2 functions of a cleared Normal stage (MF6).
type Stages interface {
	OpenStageFunctionsTx(context.Context, tx.Tx, identity.PlayerID, string, int64, time.Time) ([]int64, error)
}

type Facts interface {
	PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error)
	RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}

// Fight is a 113 request; rented heroes and pets are refused by the dispatcher.
type Fight struct {
	PetFormation []int64
	CampaignID   int64
	Type         int64
	Formation    []int64
	Pet          int64
}

// Result is a 114 request; the client-computed star is the whole summary (D82).
type Result struct {
	AwakeMission    int64
	PetAwakeMission int64
	CampaignID      int64
	Type            int64
	Star            int64
	Formation       []int64
	Pet             int64
}

// Settled is a 114 answer; Duplicate replays the stored body with error_code 30005 (F4e).
type Settled struct {
	Body      map[string]any
	Duplicate bool
}

// Objective fact kinds of a won campaign fight (task_req 102 Normal, 103 Super clears).
const (
	NormalWinKind = "CAMPAIGN_NORMAL_WIN"
	SuperWinKind  = "CAMPAIGN_SUPER_WIN"
)

const (
	campaignEnergy = "energy"
	resultKind     = "CAMPAIGN_RESULT"
)

var summaryPolicy = cd.SummaryPolicy{ID: "CAMPAIGN_SUMMARY_V1", Version: 1, MaxStar: d.MaxStar, WinFromStar: true}

func locator(a identity.ActorContext) cd.Locator {
	return cd.Locator{DomainKind: "CAMPAIGN", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprintf("player:%d", a.PlayerID)}
}

// generation is the one open stage of the player's single campaign session (D103).
func generation(kind, id int64) string {
	return fmt.Sprintf("%d/%d", kind, id)
}

// fingerprint keys START replay on the stage and team, not the operation: a
// retransmitted 113 replays, a changed team supersedes so Combat judges the 114
// team against the one frozen last (the row keeps the stage's drops either way).
func fingerprint(a identity.ActorContext, kind, id int64, formation []int64, pet int64, pets []int64) string {
	fields := map[string]any{"policy": d.ContractID, "player": int64(a.PlayerID), "type": kind, "campaign": id, "formation": formation, "pet": pet}
	if d.Cloud(kind) {
		fields["pet_formation"] = pets
	}
	raw, _ := json.Marshal(fields)
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

func ModeProfile() tx.Profile {
	return tx.Profile{Name: "campaign", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

func (s Mode) ready() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Store != nil && s.Content != nil && s.Fence != nil && s.Functions != nil &&
		s.Directory != nil && s.Heroes != nil && s.HeroExp != nil && s.Combat != nil && s.Energy != nil && s.Grants != nil && s.Stages != nil && s.Facts != nil &&
		s.Receipts != nil && s.ReceiptRead != nil
}

// pin binds the active content revision to the operation once, so I5 and every retry observe one revision.
func (s Mode) pin(c context.Context, op operation.Context) (operation.Context, error) {
	if !s.ready() {
		return op, d.ErrUnavailable
	}
	if _, bound := op.Policies.Get("content"); bound {
		return op, nil
	}
	revision, err := s.Content.ActiveRevision(c, s.Fresh)
	if err != nil {
		return op, err
	}
	op.Policies, err = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})...)
	return op, err
}

// view is what every campaign request reads before it decides.
type view struct {
	catalog   d.Catalog
	revision  string
	superOpen bool
	trialOpen bool
	cloudOpen bool
	day       int64
}

func (s Mode) read(c context.Context, q tx.Queryer, pid identity.PlayerID, revision string, at time.Time) (view, error) {
	catalog, err := s.Content.CampaignCatalogTx(c, q, revision)
	if err != nil {
		return view{}, err
	}
	fact, eligible, err := s.Functions.ReadFunctionEligibilityTx(c, q, pid, catalog.SuperFunctionID)
	if err != nil {
		return view{}, err
	}
	superOpen := eligible && fact.FunctionID == catalog.SuperFunctionID && !at.Before(fact.EligibleAt)
	trialOpen, err := s.functionOpen(c, q, pid, 7, at)
	if err != nil {
		return view{}, err
	}
	cloudOpen, err := s.functionOpen(c, q, pid, 42, at)
	if err != nil {
		return view{}, err
	}
	return view{catalog: catalog, revision: revision, superOpen: superOpen, trialOpen: trialOpen, cloudOpen: cloudOpen, day: modes.Day(at)}, nil
}

// World is the one projection of 112 and MID1 detail["112"] (F13, C2).
func (s Mode) World(c context.Context, q tx.Queryer, pid identity.PlayerID, revision string, at time.Time) (map[string]any, error) {
	v, err := s.read(c, q, pid, revision, at)
	if err != nil {
		return nil, err
	}
	record, err := s.Store.ReadTx(c, q, pid)
	if err != nil {
		return nil, err
	}
	return v.catalog.World(record.Progress, v.superOpen, v.day), nil
}

// Load answers 112.
func (s Mode) Load(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	var out map[string]any
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	revision, _ := op.Policies.Get("content")
	_, _, err = s.Timed.Run(c, op, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		out, err = s.World(c, sc.Tx, a.PlayerID, revision, sc.Operation.DecisionAt())
		return err
	})
	return out, err
}

func (s Mode) lockFormation(c context.Context, t tx.Tx, pid identity.PlayerID, formation []int64) ([]int64, error) {
	heroes := []int64{}
	for _, id := range formation {
		if id == 0 {
			continue
		}
		if id < 0 {
			return nil, d.ErrInvalid
		}
		if _, err := s.Heroes.LockHeroByPartnerIDTx(c, t, pid, id); err != nil {
			return nil, err
		}
		heroes = append(heroes, id)
	}
	if len(heroes) == 0 {
		return nil, d.ErrInvalid
	}
	return heroes, nil
}

func (s Mode) lockFightFormation(c context.Context, t tx.Tx, pid identity.PlayerID, r Fight) ([]int64, error) {
	if !d.Cloud(r.Type) {
		if len(r.PetFormation) > 0 {
			return nil, d.ErrInvalid
		}
		return s.lockFormation(c, t, pid, r.Formation)
	}
	if len(r.Formation) > 0 || r.Pet != 0 || len(r.PetFormation) < 1 || len(r.PetFormation) > 5 {
		return nil, d.ErrInvalid
	}
	if s.Pets == nil {
		return nil, d.ErrUnavailable
	}
	ids := append([]int64{}, r.PetFormation...)
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	for i, id := range ids {
		if id <= 0 || i > 0 && id == ids[i-1] {
			return nil, d.ErrInvalid
		}
		if e := s.Pets.LockCampaignPetTx(c, t, pid, id); e != nil {
			if errors.Is(e, apppet.ErrPetNotFound) {
				return nil, d.ErrRefused
			}
			return nil, e
		}
	}
	return []int64{}, nil
}

// checkFormation reads Character facts; RESULT calls it only after terminal replay.
func (s Mode) checkFormation(c context.Context, q tx.Queryer, pid identity.PlayerID, ids []int64, catalog d.Catalog, kind, nodeID int64) error {
	if kind == d.Normal || kind == d.Super || d.Cloud(kind) {
		return nil
	}
	roster, err := s.Heroes.ListHeroesTx(c, q, pid)
	if err != nil {
		return err
	}
	node, ok := catalog.Node(nodeID)
	if !ok {
		return d.ErrInvalid
	}
	if kind == d.Challenge && (node.ChallengeMode < 1 || node.ChallengeMode > 8) {
		return d.ErrUnavailable
	}
	purple := false
	for _, hero := range roster {
		purple = purple || hero.Color >= 7
		for _, id := range ids {
			if hero.PartnerID == id {
				if !catalog.AllowFaction(kind, hero.TableID) {
					return d.ErrRefused
				}
				if kind == d.Challenge {
					for _, excluded := range node.ExcludedHeroes {
						if hero.TableID == excluded {
							return d.ErrRefused
						}
					}
				}
			}
		}
	}
	if kind == d.Challenge && (node.ChallengeMode == 6 && len(ids) != 1 || (node.ChallengeMode == 1 || node.ChallengeMode == 3) && len(ids) > 4) {
		return d.ErrRefused
	}
	if kind >= 16 && kind <= 21 && !purple {
		return d.ErrRefused
	}
	return nil
}

// Fight answers 113: admission (F6), a CLIENT_SUMMARY_ATTESTED attempt, the
// energy preview and the stage's drops, frozen on the campaign row (C4, C6).
func (s Mode) Fight(c context.Context, a identity.ActorContext, request Fight, op operation.Context) (map[string]any, error) {
	var out map[string]any
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	_, _, err = s.Timed.Run(c, op, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		at, current := sc.Operation.DecisionAt(), sc.Operation.Operation()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		revision, _ := current.Policies.Get("content")
		v, err := s.read(c, sc.Tx, a.PlayerID, revision, at)
		if err != nil {
			return err
		}
		heroes, err := s.lockFightFormation(c, sc.Tx, a.PlayerID, request)
		if err != nil {
			return err
		}
		if err = s.checkFormation(c, sc.Tx, a.PlayerID, heroes, v.catalog, request.Type, request.CampaignID); err != nil {
			return err
		}
		if request.Pet > 0 {
			if s.Pets == nil {
				return d.ErrUnavailable
			}
			if err := s.Pets.LockCampaignPetTx(c, sc.Tx, a.PlayerID, request.Pet); err != nil {
				if errors.Is(err, apppet.ErrPetNotFound) {
					return d.ErrRefused
				}
				return err
			}
		}
		record, err := s.Store.LockTx(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return err
		}
		profile, found, err := s.Directory.ProfileTx(c, sc.Tx, a.PlayerID)
		if err != nil || !found {
			return errors.Join(err, d.ErrUnavailable)
		}
		node, err := s.admit(c, sc.Tx, a.PlayerID, v, record, request.Type, request.CampaignID, profile.Level)
		if err != nil {
			return err
		}
		started, err := s.start(c, sc, a, v, node, record, heroes, request)
		if err != nil {
			return err
		}
		balance, err := s.Energy.TemporalBalanceTx(c, sc.Tx, a.PlayerID, campaignEnergy, current)
		if err != nil {
			return err
		}
		if balance < node.EnergyCost {
			return fmt.Errorf("%w: energy %d below %d", d.ErrRefused, balance, node.EnergyCost)
		}
		stage := generation(node.Type, node.ID)
		if record.PendingGeneration != stage {
			if started.Package == nil {
				return d.ErrUnavailable
			}
			record.PendingGeneration, record.PendingItems = stage, []d.Item{}
			items, frozen, e := readAwakeningPackage(started.Package.Canonical)
			if e != nil {
				return e
			}
			record.PendingItems = items
			record.PendingAwakening = frozen
			if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, record, nil, at); err != nil {
				return err
			}
		}
		if record.PendingGeneration == stage && started.Package != nil {
			_, frozen, e := readAwakeningPackage(started.Package.Canonical)
			if e != nil {
				return e
			}
			if !bytes.Equal(frozen, record.PendingAwakening) {
				record.PendingAwakening = frozen
				if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, record, nil, at); err != nil {
					return err
				}
			}
		}
		preview := append([]d.Item{}, record.PendingItems...)
		frozen, e := readAwakeningPending(record.PendingAwakening)
		if e != nil {
			return e
		}
		if frozen != nil {
			for _, drop := range frozen.Drops {
				if drop.Count > 0 {
					preview = append(preview, d.Item{ItemID: drop.ItemID, Num: drop.Count})
				}
			}
		}
		out = map[string]any{"battle_id": 1, "report": map[string]any{}, "seed": 1, "enemy_info": map[string]any{}, "items": preview}
		return nil
	})
	return out, err
}

// start opens the stage's attempt; the enemy lineup is client-side, so none is frozen.
func (s Mode) start(c context.Context, sc gen.TimedScope, a identity.ActorContext, v view, node d.Node, record d.Record, heroes []int64, request Fight) (combat.Started, error) {
	at, op := sc.Operation.DecisionAt(), sc.Operation.Operation()
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: op, Attempt: sc.Attempt, Options: sc.Options}, v.revision, at)
	if err != nil {
		return combat.Started{}, err
	}
	battle := combat.BattleRequest{CampaignType: node.Type, BattleID: node.ID, PetsA: []combat.Participant{}, Formation: request.Formation}
	for _, id := range heroes {
		battle.TeamA = append(battle.TeamA, combat.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: id})
	}
	if request.Pet > 0 {
		battle.PetsA = append(battle.PetsA, combat.Participant{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: a.PlayerID, Identity: request.Pet})
	}
	if d.Cloud(node.Type) {
		battle.Formation = append([]int64{}, node.SelfTeam...)
		for _, id := range node.SelfTeam {
			battle.TeamA = append(battle.TeamA, combat.Participant{Origin: cd.Template, Kind: cd.HeroActor, Identity: id, TemplateParams: map[string]any{"table_id": id}})
		}
		for _, id := range request.PetFormation {
			battle.PetsA = append(battle.PetsA, combat.Participant{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: a.PlayerID, Identity: id})
		}
	}
	box := node.BattleBox(record.Progress)
	frozen, err := s.freezeAwakening(c, sc.Tx, a.PlayerID, node, record.Progress, v.day, request.Formation, request.Pet)
	if err != nil {
		return combat.Started{}, err
	}
	var petAwakening *i5.AwakeningPetContext
	if d.Cloud(node.Type) && s.PetAwakening != nil {
		petAwakening, err = s.PetAwakening.FreezeAwakeningPetTx(c, sc.Tx, a.PlayerID, node.ID, request.PetFormation)
		if err != nil {
			return combat.Started{}, err
		}
	}
	drops := func(stream *cd.Stream) (any, error) {
		if petAwakening != nil {
			return awakeningStartPackage{Items: v.catalog.Drop(box, stream), PetAwakening: petAwakening}, nil
		}

		if frozen == nil {
			return v.catalog.Drop(box, stream), nil
		}
		next := *frozen
		items := []d.Item{}
		if record.PendingGeneration == generation(node.Type, node.ID) {
			items = append(items, record.PendingItems...)
			old, e := readAwakeningPending(record.PendingAwakening)
			if e != nil {
				return nil, e
			}
			if old != nil {
				next.Drops = old.Drops
			} else {
				next.Drops = nil
			}
		} else {
			items = v.catalog.Drop(box, stream)
			next = next.Draw(stream)
		}
		return awakeningStartPackage{Items: items, Awakening: &next}, nil
	}
	window := time.Duration(v.catalog.PrivatePolicy.ResultWindowSeconds) * time.Second
	return s.Combat.StartTx(c, sc.Tx, scope, combat.StartRequest{Actor: a, Locator: locator(a), GenerationRef: generation(node.Type, node.ID),
		StartFingerprint: fingerprint(a, node.Type, node.ID, request.Formation, request.Pet, request.PetFormation), ResultDeadline: at.Add(window), Battle: battle,
		TrustProfile: cd.ClientSummaryAttested, Replay: cd.ReplaySpec{Response: cd.ReplayOK}, Package: drops})
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}

// Result answers 114 (C5): Combat judges the star against the frozen START,
// then the server settles energy, value, hero exp, openings and facts. An
// unknown COMMIT resolves to the receipted answer without a second grant.
func (s Mode) Result(c context.Context, a identity.ActorContext, request Result, op operation.Context) (Settled, error) {
	var out Settled
	op, err := s.pin(c, op)
	if err != nil {
		return out, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "campaign", Operation: "result", SemanticKey: op.ID.String()}
	fields := map[string]any{"player": int64(a.PlayerID), "operation": "result", "campaign_id": request.CampaignID, "type": request.Type,
		"star": request.Star, "formation": request.Formation, "pet": request.Pet}
	// Preserve receipt fingerprints of pre-awakening requests with no markers.
	if request.AwakeMission != 0 {
		fields["awake_mission"] = request.AwakeMission
	}
	if request.PetAwakeMission != 0 {
		fields["pet_awaken_mission"] = request.PetAwakeMission
	}
	fingerprint, err := receipt.FingerprintRequest(fields)
	if err != nil {
		return out, err
	}
	var rejected bool
	_, res, err := s.Timed.Run(c, op, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}}, func(c context.Context, sc gen.TimedScope) error {
		settled, refused, err := s.settle(c, sc, a, request)
		if err != nil {
			return err
		}
		out, rejected = settled, refused
		raw, err := json.Marshal(settled)
		if err != nil {
			return err
		}
		r, err := receipt.New(sc.Operation.Operation(), id, "I9_3A_CAMPAIGN", "gxb.campaign.result.v1", raw, fingerprint)
		if err != nil {
			return err
		}
		r.PolicyVersion, r.ActorAccountUID, r.ContextID = d.PolicyID, string(a.AccountUID), a.ContextID.UUID()
		_, err = s.Receipts.PutTx(c, sc.Tx, r)
		return err
	})
	if err != nil {
		return out, err
	}
	if res.Reconciled {
		stored, ok := res.Evidence.(receipt.Receipt)
		if !ok {
			return out, d.ErrUnavailable
		}
		err = json.Unmarshal(stored.ResultPayload, &out)
		rejected = err == nil && out.Body == nil
	}
	if err == nil && rejected {
		err = fmt.Errorf("%w: summary rejected or no open attempt", d.ErrRefused)
	}
	return out, err
}

// settle runs one 114 inside its transaction. refused answers a drained or
// rejected RESULT whose closing the transaction still commits.
func (s Mode) settle(c context.Context, sc gen.TimedScope, a identity.ActorContext, request Result) (Settled, bool, error) {
	at, current := sc.Operation.DecisionAt(), sc.Operation.Operation()
	if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
		return Settled{}, false, err
	}
	revision, _ := current.Policies.Get("content")
	v, err := s.read(c, sc.Tx, a.PlayerID, revision, at)
	if err != nil {
		return Settled{}, false, err
	}
	heroes := []int64{}
	if d.Cloud(request.Type) {
		if len(request.Formation) > 0 || request.Pet != 0 {
			return Settled{}, false, d.ErrInvalid
		}
	} else {
		heroes, err = s.lockFormation(c, sc.Tx, a.PlayerID, request.Formation)
		if err != nil {
			return Settled{}, false, err
		}
	}
	if request.Pet > 0 {
		if s.Pets == nil {
			return Settled{}, false, d.ErrUnavailable
		}
		if err := s.Pets.LockCampaignPetTx(c, sc.Tx, a.PlayerID, request.Pet); err != nil {
			if errors.Is(err, apppet.ErrPetNotFound) {
				return Settled{}, false, d.ErrRefused
			}
			return Settled{}, false, err
		}
	}
	record, err := s.Store.LockTx(c, sc.Tx, a.PlayerID, at)
	if err != nil {
		return Settled{}, false, err
	}
	stage := generation(request.Type, request.CampaignID)
	summary := cd.Summary{Star: request.Star, Win: request.Star > 0, Formation: request.Formation, Pet: request.Pet}
	selectedPolicy := summaryPolicy
	if d.Cloud(request.Type) {
		selectedPolicy = cd.SummaryPolicy{ID: "CAMPAIGN_CLOUD_SUMMARY_V1", Version: 1, MaxStar: d.MaxStar, WinFromStar: true, OmitParticipantEcho: true}
	}
	attested, err := s.Combat.AttestSummaryTx(c, sc.Tx, combat.SummaryRequest{Locator: locator(a), GenerationRef: stage, TerminalKind: resultKind, At: at, Policy: selectedPolicy, Summary: summary})
	if err != nil {
		return Settled{}, false, err
	}
	if attested.Drained {
		return s.drained(record, stage)
	}
	if attested.Attestation.Verdict == cd.VerdictRejected {
		return Settled{}, true, nil
	}
	if err = s.checkFormation(c, sc.Tx, a.PlayerID, heroes, v.catalog, request.Type, request.CampaignID); err != nil {
		return Settled{}, false, err
	}
	node, found := v.catalog.Node(request.CampaignID)
	if !found {
		return Settled{}, false, d.ErrInvalid
	}
	if _, trial := v.catalog.Group(request.Type); trial {
		profile, found, e := s.Directory.ProfileTx(c, sc.Tx, a.PlayerID)
		if e != nil || !found {
			return Settled{}, false, errors.Join(e, d.ErrUnavailable)
		}
		if _, e = s.admit(c, sc.Tx, a.PlayerID, v, record, request.Type, request.CampaignID, profile.Level); e != nil {
			return Settled{}, false, e
		}
	}
	outcome, err := v.catalog.Settle(record.Progress, node, request.Star, v.day, v.superOpen)
	if err != nil {
		return Settled{}, false, err
	}
	awakeChanges, err := s.settleAwakening(c, sc.Tx, a.PlayerID, request, &record, outcome.Win)
	if err != nil {
		return Settled{}, false, err
	}
	if outcome.Win && outcome.FirstClear {
		state := outcome.Progress.State(node.ID)
		day := v.day
		state.FirstClearDay = &day
		outcome.Progress.Nodes[node.ID] = state
	}
	c, err = s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
	if err != nil {
		return Settled{}, false, err
	}
	if err = s.debit(c, sc, a.PlayerID, outcome.Energy); err != nil {
		return Settled{}, false, err
	}
	body := map[string]any{"is_win": 0, "result": 0, "items": []any{}}
	for key, value := range awakeChanges {
		body[key] = value
	}
	if outcome.Win {
		body["is_win"], body["result"] = 1, 1
		if err = s.reward(c, sc, a, v, node, outcome, record, heroes, attested.Attempt.ID.String(), request.Pet, body); err != nil {
			return Settled{}, false, err
		}
	}
	info := v.catalog.Info(outcome.Progress, v.superOpen)
	body["chapter_info"] = info.Fields()
	if event := v.catalog.ChapterEvent(outcome.Progress, node.Chapter); event != nil {
		body["chapter_event"] = event
	}
	rows := make([]any, 0, len(outcome.Touched))
	for _, touched := range outcome.Touched {
		rows = append(rows, v.catalog.Row(outcome.Progress, touched, v.day))
	}
	body["campaigns"] = rows
	if g, trial := v.catalog.Group(node.Type); trial {
		buys, e := s.trialBuys(c, sc.Tx, a.PlayerID, v.day)
		if e != nil {
			return Settled{}, false, e
		}
		key := "trial"
		if g.NextID != 0 {
			key = "challenge"
		}
		body[key] = v.catalog.TrialRow(outcome.Progress, g, v.day, buys[g.ConsumeID], v.groupOpen(g))
	}
	balances, functions := changes.Recorded(c)
	stored := map[string]any{"economy_": balances}
	if len(functions) > 0 {
		stored["new_funcs_"] = functions
	}
	for key, value := range body {
		stored[key] = value
	}
	raw, err := json.Marshal(stored)
	if err != nil {
		return Settled{}, false, err
	}
	next := d.Record{Progress: outcome.Progress, LastGeneration: stage, LastResult: raw, StateVersion: record.StateVersion}
	if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, next, []int64{node.ID}, at); err != nil {
		return Settled{}, false, err
	}
	if outcome.Win {
		kind := "CAMPAIGN_TRIAL_WIN"
		if node.Type == d.Normal {
			kind = NormalWinKind
		}
		if node.Type == d.Challenge {
			kind = "CAMPAIGN_CHALLENGE_WIN"
		}
		if node.Type == d.Super {
			kind = SuperWinKind
		}
		if err = s.Facts.RecordTx(c, sc.Tx, current, objective.Fact{PlayerID: a.PlayerID, SourceDomain: "campaign", SourceBusinessKey: attested.Attempt.ID.String(), Kind: kind, Delta: 1}); err != nil {
			return Settled{}, false, err
		}
	}

	for key, value := range changes.RecordedMissions(c) {
		stored[key] = value
	}
	next.LastResult, err = json.Marshal(stored)
	if err != nil {
		return Settled{}, false, err
	}
	next.StateVersion++
	if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, next, nil, at); err != nil {
		return Settled{}, false, err
	}
	return Settled{Body: body}, false, nil
}

// drained answers a 114 with no open attempt: the last settled stage replays its stored body (30005), anything else refuses.
func (s Mode) drained(record d.Record, stage string) (Settled, bool, error) {
	if record.LastGeneration != stage || record.LastResult == nil {
		return Settled{}, true, nil
	}
	body := map[string]any{}
	if err := json.Unmarshal(record.LastResult, &body); err != nil {
		return Settled{}, false, err
	}
	return Settled{Body: body, Duplicate: true}, false, nil
}

// debit spends the result's energy (D102); short energy refuses and leaves the attempt open.
func (s Mode) debit(c context.Context, sc gen.TimedScope, pid identity.PlayerID, amount int64) error {
	if amount <= 0 {
		return nil
	}
	_, err := s.Energy.DebitTemporalTx(c, sc.Tx, pid, campaignEnergy, amount, sc.Operation.Operation())
	if errors.Is(err, economy.ErrInsufficientBalance) {
		return fmt.Errorf("%w: energy below %d", d.ErrRefused, amount)
	}
	return err
}

// reward grants a win's value (mana, player exp, star_gift, frozen drops),
// then hero exp at the player level after that exp, the kind-2 openings of a
// first Normal clear and the objective fact.
func (s Mode) reward(c context.Context, sc gen.TimedScope, a identity.ActorContext, v view, node d.Node, outcome d.Outcome, record d.Record, heroes []int64, attempt string, petID int64, body map[string]any) error {
	at, current := sc.Operation.DecisionAt(), sc.Operation.Operation()
	lines := []grant.Line{}
	if outcome.Mana > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: outcome.Mana})
	}
	if outcome.Crystal > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: outcome.Crystal})
		body["star_crystal"] = outcome.Crystal
	}
	if outcome.PlayerExp > 0 {
		lines = append(lines, grant.Line{Kind: grant.PlayerExp, Amount: outcome.PlayerExp})
	}
	if record.PendingGeneration == generation(node.Type, node.ID) {
		for _, item := range record.PendingItems {
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item.ItemID, Amount: item.Num})
		}
	}
	profile, found, err := s.Directory.ProfileTx(c, sc.Tx, a.PlayerID)
	if err != nil || !found {
		return errors.Join(err, d.ErrUnavailable)
	}
	level := profile.Level
	if len(lines) > 0 {
		plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "campaign", Operation: "result", BusinessKey: "campaign:attempt:" + attempt, Occurrence: current.ID.String(), PolicyVersion: d.ContractID}, Lines: lines}
		granted, err := s.Grants.SettleGrantTx(c, sc.Tx, a, plan, current, i5.GrantTxOptions{})
		if err != nil {
			return err
		}
		if granted.Effects != nil {
			for _, effect := range granted.Effects.Progression {
				level = max(level, effect.AfterLevel)
			}
		}
	}
	exps := []any{}
	for _, id := range heroes {
		hero, _, err := s.HeroExp.ApplyDormEXPLockedTx(c, sc.Tx, character.HeroRef{PlayerID: a.PlayerID, PartnerID: id}, outcome.PartnerExp, level, v.revision, at)
		if err != nil {
			return err
		}
		exps = append(exps, map[string]any{"partner_id": id, "exp": hero.Exp})
	}
	body["exps"] = exps
	if petID > 0 && outcome.PartnerExp > 0 {
		pet, err := s.Pets.CreditCampaignEXPTx(c, sc.Tx, a.PlayerID, petID, outcome.PartnerExp, level, v.revision, at)
		if err != nil {
			return err
		}
		body["pet_exps"] = []any{map[string]any{"pet_id": pet.PetID, "exp": pet.Exp}}
	}
	if node.Type == d.Normal && outcome.FirstClear {
		if _, err = s.Stages.OpenStageFunctionsTx(c, sc.Tx, a.PlayerID, v.revision, node.ID, at); err != nil {
			return err
		}
	}
	return nil
}

func (Mode) Name() string     { return "i9-3a.campaign-world" }
func (Mode) Claims() []string { return []string{"112", "115"} }

// OverlayMID1 writes detail["112"] through World, replacing the lobby placeholder.
func (s Mode) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	if q == nil || s.Content == nil || s.Store == nil || s.Functions == nil {
		return d.ErrUnavailable
	}
	revision, err := s.Content.ActiveRevision(c, q)
	if err != nil {
		return err
	}
	world, err := s.World(c, q, a.PlayerID, revision, at)
	if err != nil {
		return err
	}
	detail["112"] = world
	trials, err := s.TrialWorld(c, q, a.PlayerID, revision, at)
	if err != nil {
		return err
	}
	detail["115"] = trials
	return nil
}
