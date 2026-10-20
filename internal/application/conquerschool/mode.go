package conquerschool

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Mode composes the Conquer School mode (C5E_CONQUER_SCHOOL_MODE_V1) over the
// I7C-2J facts seam: run and progress change only through PrepareWriteTx and
// ApplyWriteTx. Lock order: actor fence 315, I4 player root, facts row, mode
// row, I5 mail 610 and values 700+, directory 740.
type Mode struct {
	Facts       Service
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Store       ModeStore
	Content     ModeContent
	Fence       Fence
	Functions   Functions
	Privileges  i5.PrivilegeSnapshotProvider
	Costs       i5.TxMaterialCostDebiter
	Grants      Grants
	Mail        Mail
	Heroes      Roster
	Pets        Roster
	Directory   Directory
	Projection  Projection
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}

type ModeStore interface {
	ReadModeTx(context.Context, tx.Queryer, identity.PlayerID, bool) (d.Mode, bool, error)
	InsertModeTx(context.Context, tx.Tx, d.Mode, identity.LogicalServerID, string) error
	SaveModeTx(context.Context, tx.Tx, d.Mode, int64) error
	InsertReportTx(context.Context, tx.Tx, d.Report, int64) error
	ReportsTx(context.Context, tx.Queryer, int64, int64, int64, int64) ([]d.Report, error)
	ReportTx(context.Context, tx.Queryer, string) (d.Report, bool, error)
	InsertViewTx(context.Context, tx.Tx, string, identity.PlayerID, int64, time.Time) (bool, error)
}

type ModeContent interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ConquerModeCatalogTx(context.Context, tx.Queryer, string) (d.ModeCatalog, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Functions interface {
	ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error)
}

type Grants interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

type Mail interface {
	DeliverTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}

// Roster is the stock roster composer (MID1 key 49 Heroes, 780 Pets).
type Roster interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

// Projection is the I4 directory conquer_lev/conquer_loop_id projection.
type Projection interface {
	ProjectConquerTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, time.Time) error
}

const viewMailKind = "CONQUER_SCHOOL_REPORT_VIEW"

func ModeProfile() tx.Profile {
	return tx.Profile{Name: "conquer-school", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

func (s Mode) ready() bool {
	return s.Facts.Owner != nil && s.Facts.Content != nil && s.Facts.Players != nil && s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil &&
		s.Store != nil && s.Content != nil && s.Fence != nil && s.Functions != nil && s.Privileges != nil && s.Costs != nil && s.Grants != nil && s.Mail != nil &&
		s.Heroes != nil && s.Pets != nil && s.Directory != nil && s.Projection != nil && s.Receipts != nil && s.ReceiptRead != nil
}

// pin binds the active content revision to the operation once, so the facts
// seam, I5 and every retry observe one revision.
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

// session is one locked mode change of the actor.
type session struct {
	catalog  d.ModeCatalog
	prepared *PreparedWrite
	progress d.Progress
	run      d.Run
	newRun   bool
	mode     d.Mode
	before   d.Mode
	found    bool
	revision string
}

func (s Mode) open(c context.Context, sc gen.TimedScope, a identity.ActorContext) (session, error) {
	at, op := sc.Operation.DecisionAt(), sc.Operation.Operation()
	if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
		return session{}, err
	}
	revision, _ := op.Policies.Get("content")
	catalog, err := s.Content.ConquerModeCatalogTx(c, sc.Tx, revision)
	if err != nil {
		return session{}, err
	}
	fact, eligible, err := s.Functions.ReadFunctionEligibilityTx(c, sc.Tx, a.PlayerID, catalog.FunctionID)
	if err != nil {
		return session{}, err
	}
	if !eligible || fact.FunctionID != catalog.FunctionID || at.Before(fact.EligibleAt) {
		return session{}, fmt.Errorf("%w: function %d closed", d.ErrRefused, catalog.FunctionID)
	}
	prepared, err := s.Facts.PrepareWriteTx(c, sc.Tx, a.LogicalServerID, a.PlayerID, revision, op)
	if err != nil {
		return session{}, err
	}
	if !prepared.before.Known() {
		return session{}, fmt.Errorf("%w: legacy progress unknown", d.ErrUnavailable)
	}
	st := session{catalog: catalog, prepared: prepared, progress: *prepared.before.Payload.Progress, revision: revision}
	if run := prepared.before.Payload.Run; run != nil {
		st.run = *run
	} else {
		st.run, st.newRun = catalog.InitialRun(op.ID.String()), true
	}
	st.before, st.found, err = s.Store.ReadModeTx(c, sc.Tx, a.PlayerID, true)
	if err != nil {
		return session{}, err
	}
	st.mode = catalog.NewMode(a.PlayerID, at)
	if st.found {
		st.mode = catalog.Rolled(st.before, at)
	}
	return st, nil
}

// commit saves changed facts through the 2J seam, then the mode row.
func (s Mode) commit(c context.Context, sc gen.TimedScope, a identity.ActorContext, st session, mode d.Mode, run d.Run, progress d.Progress, ref string) error {
	at := sc.Operation.DecisionAt()
	if st.newRun || run != st.run || progress != st.progress {
		if _, err := s.Facts.ApplyWriteTx(c, sc.Tx, st.prepared, progress, &run, ref); err != nil {
			return err
		}
	}
	mode.UpdatedAt = at
	if !st.found {
		mode.StateVersion = 1
		return s.Store.InsertModeTx(c, sc.Tx, mode, a.LogicalServerID, st.revision)
	}
	mode.StateVersion = st.before.StateVersion + 1
	return s.Store.SaveModeTx(c, sc.Tx, mode, st.before.StateVersion)
}

func (s Mode) change(c context.Context, a identity.ActorContext, op operation.Context, apply func(context.Context, gen.TimedScope, session) (d.Mode, error)) (d.InfoView, error) {
	var out d.InfoView
	op, err := s.pin(c, op)
	if err != nil {
		return out, err
	}
	_, _, err = s.Timed.Run(c, op, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		st, err := s.open(c, sc, a)
		if err != nil {
			return err
		}
		mode, err := apply(c, sc, st)
		if err != nil {
			return err
		}
		out = st.catalog.Info(mode, st.run)
		return s.commit(c, sc, a, st, mode, st.run, st.progress, "conquer-school:"+op.ID.String())
	})
	return out, err
}

// Info answers 1568; the first INFO of an INITIAL_NO_PROGRESS player starts run 1.
func (s Mode) Info(c context.Context, a identity.ActorContext, op operation.Context) (d.InfoView, error) {
	return s.change(c, a, op, func(_ context.Context, _ gen.TimedScope, st session) (d.Mode, error) {
		return st.mode, nil
	})
}

// Reset answers 1573 (user decision "Keep it": chances and buff stay).
func (s Mode) Reset(c context.Context, a identity.ActorContext, op operation.Context) (d.InfoView, error) {
	return s.change(c, a, op, func(_ context.Context, _ gen.TimedScope, st session) (d.Mode, error) {
		return st.catalog.Reset(st.mode, st.run)
	})
}

// Start answers 1569 for owned partner ids and an owned pet or none.
func (s Mode) Start(c context.Context, a identity.ActorContext, formation []int64, pet int64, op operation.Context) (d.InfoView, error) {
	return s.change(c, a, op, func(c context.Context, sc gen.TimedScope, st session) (d.Mode, error) {
		at := sc.Operation.DecisionAt()
		heroes, err := s.heroRows(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return st.mode, err
		}
		for _, id := range formation {
			if _, owned := heroes[strconv.FormatInt(id, 10)]; !owned {
				return st.mode, fmt.Errorf("%w: partner %d not owned", d.ErrRefused, id)
			}
		}
		if pet > 0 {
			if _, owned, err := s.petRow(c, sc.Tx, a.PlayerID, pet, at); err != nil || !owned {
				return st.mode, errors.Join(err, fmt.Errorf("%w: pet %d not owned", d.ErrRefused, pet))
			}
		}
		return st.catalog.Start(st.mode, st.run, formation, pet, sc.Operation.Operation().ID.String())
	})
}

func (s Mode) heroRows(c context.Context, q tx.Queryer, pid identity.PlayerID, at time.Time) (map[string]any, error) {
	detail := map[string]any{}
	if err := s.Heroes.OverlayMID1(c, q, identity.ActorContext{PlayerID: pid}, false, at, detail); err != nil {
		return nil, err
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	return rows, nil
}

func (s Mode) petRow(c context.Context, q tx.Queryer, pid identity.PlayerID, pet int64, at time.Time) (map[string]any, bool, error) {
	detail := map[string]any{}
	if err := s.Pets.OverlayMID1(c, q, identity.ActorContext{PlayerID: pid}, false, at, detail); err != nil {
		return nil, false, err
	}
	body, _ := detail["780"].(map[string]any)
	raw, _ := body["pets"].([]any)
	for _, x := range raw {
		if row, ok := x.(map[string]any); ok && fmt.Sprint(row["pet_id"]) == strconv.FormatInt(pet, 10) {
			return row, true, nil
		}
	}
	return nil, false, nil
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}

// receipted runs one value-moving change; an unknown COMMIT resolves to the
// receipted view without a second grant or debit.
func (s Mode) receipted(c context.Context, a identity.ActorContext, op operation.Context, name string, request map[string]any, apply func(context.Context, gen.TimedScope) (d.ResultView, error)) (d.ResultView, error) {
	var out d.ResultView
	op, err := s.pin(c, op)
	if err != nil {
		return out, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "conquer-school", Operation: name, SemanticKey: op.ID.String()}
	request["player"], request["operation"] = int64(a.PlayerID), name
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return out, err
	}
	_, res, err := s.Timed.Run(c, op, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}}, func(c context.Context, sc gen.TimedScope) error {
		view, err := apply(c, sc)
		if err != nil {
			return err
		}
		out = view
		raw, err := json.Marshal(view)
		if err != nil {
			return err
		}
		r, err := receipt.New(sc.Operation.Operation(), id, "I7C5E_CONQUER_SCHOOL", "gxb.conquer-school."+name+".v1", raw, fingerprint)
		if err != nil {
			return err
		}
		r.PolicyVersion, r.ActorAccountUID, r.ContextID = d.ModeContractID, string(a.AccountUID), a.ContextID.UUID()
		_, err = s.Receipts.PutTx(c, sc.Tx, r)
		return err
	})
	if err != nil || !res.Reconciled {
		return out, err
	}
	stored, ok := res.Evidence.(receipt.Receipt)
	if !ok {
		return out, d.ErrConflict
	}
	return out, json.Unmarshal(stored.ResultPayload, &out)
}

// Buy answers 2790: one chance for crystal with an active monthly card.
func (s Mode) Buy(c context.Context, a identity.ActorContext, op operation.Context) (d.InfoView, error) {
	view, err := s.receipted(c, a, op, "buy", map[string]any{}, func(c context.Context, sc gen.TimedScope) (d.ResultView, error) {
		st, err := s.open(c, sc, a)
		if err != nil {
			return d.ResultView{}, err
		}
		privilege, err := s.Privileges.SnapshotTx(c, sc.Tx, a.PlayerID, sc.Operation.DecisionAt())
		if err != nil {
			return d.ResultView{}, err
		}
		mode, cost, err := st.catalog.Buy(st.mode, privilege.MonthlyPrivilegeActive)
		if err != nil {
			return d.ResultView{}, err
		}
		if err = s.commit(c, sc, a, st, mode, st.run, st.progress, "conquer-school:buy:"+sc.Operation.Operation().ID.String()); err != nil {
			return d.ResultView{}, err
		}
		_, err = s.Costs.DebitMaterialCostTx(c, sc.Tx, a.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: cost}}}, sc.Operation.Operation())
		return d.ResultView{Info: st.catalog.Info(mode, st.run)}, err
	})
	return view.Info, err
}

// Result answers 1570 for the open attempt (CLIENT_SUMMARY_ATTESTED): the
// server recomputes chances, buff, teams, promotion, rewards and progress.
func (s Mode) Result(c context.Context, a identity.ActorContext, result d.Result, report json.RawMessage, op operation.Context) (d.ResultView, error) {
	request := map[string]any{"campaign_id": result.CampaignID, "team_id": result.TeamID, "win": result.Win, "formation": result.Formation, "pet": result.Pet,
		"damage": result.Damage, "alive": result.Alive, "report_invalid": result.ReportInvalid, "report": string(report)}
	return s.receipted(c, a, op, "result", request, func(c context.Context, sc gen.TimedScope) (d.ResultView, error) {
		at, current := sc.Operation.DecisionAt(), sc.Operation.Operation()
		st, err := s.open(c, sc, a)
		if err != nil {
			return d.ResultView{}, err
		}
		settled, err := st.catalog.Settle(st.mode, st.run, st.progress, result)
		if err != nil {
			return d.ResultView{}, err
		}
		attempt := "conquer-school:attempt:" + settled.Attempt.ID
		if err = s.commit(c, sc, a, st, settled.Mode, settled.Run, settled.Progress, attempt); err != nil {
			return d.ResultView{}, err
		}
		view := d.ResultView{Info: st.catalog.Info(settled.Mode, settled.Run), Promoted: settled.Promoted, Rewards: settled.Rewards, Progress: settled.Progress}
		if view.Region, err = st.prepared.catalog.Region(settled.Progress); err != nil {
			return d.ResultView{}, err
		}
		if settled.Promoted {
			lines := make([]grant.Line, 0, len(settled.Rewards))
			for _, reward := range settled.Rewards {
				lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: reward[0], Amount: reward[1]})
			}
			plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "conquer-school", Operation: "promote", BusinessKey: attempt, Occurrence: current.ID.String(), PolicyVersion: d.ModeContractID}, Lines: lines}
			if _, err = s.Grants.SettleGrantTx(c, sc.Tx, a, plan, current, i5.GrantTxOptions{}); err != nil {
				return d.ResultView{}, err
			}
		}
		if settled.KeepReport {
			if err = s.keep(c, sc, a, st.catalog, settled, result, report); err != nil {
				return d.ResultView{}, err
			}
		}
		if settled.Promoted {
			err = s.Projection.ProjectConquerTx(c, sc.Tx, a.PlayerID, settled.Progress.Level, settled.Progress.Loop, at)
		}
		return view, err
	})
}

// keep stores a won fight's report with the owner card and girl snapshots.
func (s Mode) keep(c context.Context, sc gen.TimedScope, a identity.ActorContext, catalog d.ModeCatalog, settled d.Settlement, result d.Result, report json.RawMessage) error {
	at := sc.Operation.DecisionAt()
	var body map[string]any
	if err := json.Unmarshal(report, &body); err != nil || body == nil {
		return fmt.Errorf("%w: report is not an object", d.ErrInvalid)
	}
	profile, found, err := s.Directory.ProfileTx(c, sc.Tx, a.PlayerID)
	if err != nil || !found {
		return errors.Join(err, d.ErrUnavailable)
	}
	roster, err := s.heroRows(c, sc.Tx, a.PlayerID, at)
	if err != nil {
		return err
	}
	heroes := make([]any, 0, len(settled.Attempt.Formation))
	for _, id := range settled.Attempt.Formation {
		if row, ok := roster[strconv.FormatInt(id, 10)]; ok {
			heroes = append(heroes, row)
		}
	}
	pet := map[string]any{}
	if settled.Attempt.Pet > 0 {
		if pet, _, err = s.petRow(c, sc.Tx, a.PlayerID, settled.Attempt.Pet, at); err != nil {
			return err
		}
	}
	key, err := ids.NewUUID()
	if err != nil {
		return err
	}
	heroJSON, err := json.Marshal(heroes)
	if err != nil {
		return err
	}
	petJSON, err := json.Marshal(pet)
	if err != nil {
		return err
	}
	kept := d.Report{Key: key.String(), Owner: a.PlayerID, Loop: settled.Attempt.Loop, MissionID: settled.Attempt.MissionID, TeamID: result.TeamID,
		Score: catalog.Score(result.Alive, result.Damage), Heroes: heroJSON, Pet: petJSON, Body: report, AttemptID: settled.Attempt.ID, RecordedAt: at,
		Profile: d.ReportProfile{Name: profile.Name, Level: profile.Level, ConquerLevel: settled.Progress.Level, ConquerLoop: settled.Progress.Loop, Server: int64(a.LogicalServerID),
			AvatarID: profile.AvatarID, FrameID: profile.AvatarFrameID}}
	return s.Store.InsertReportTx(c, sc.Tx, kept, catalog.ReportLimit)
}

// Reports answers 1571 with the best kept reports of one team, across servers.
func (s Mode) Reports(c context.Context, loop, mission, team int64, op operation.Context) ([]d.Report, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	revision, _ := op.Policies.Get("content")
	catalog, err := s.Content.ConquerModeCatalogTx(c, s.Fresh, revision)
	if err != nil {
		return nil, err
	}
	return s.Store.ReportsTx(c, s.Fresh, loop, mission, team, catalog.ReportLimit)
}

// Report answers 1572. A viewer's first view of another player's report on a
// 05:00 day mails its owner the view reward, at most report_reward_limit a day.
func (s Mode) Report(c context.Context, a identity.ActorContext, key string, op operation.Context) (d.Report, error) {
	var out d.Report
	if _, err := ids.ParseUUID(key); err != nil {
		return out, d.ErrInvalid
	}
	op, err := s.pin(c, op)
	if err != nil {
		return out, err
	}
	_, _, err = s.Timed.Run(c, op, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		revision, _ := sc.Operation.Operation().Policies.Get("content")
		catalog, err := s.Content.ConquerModeCatalogTx(c, sc.Tx, revision)
		if err != nil {
			return err
		}
		report, found, err := s.Store.ReportTx(c, sc.Tx, key)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		out = report
		if report.Owner == a.PlayerID {
			return nil
		}
		return s.rewardView(c, sc, catalog, report, a.PlayerID)
	})
	return out, err
}

func (s Mode) rewardView(c context.Context, sc gen.TimedScope, catalog d.ModeCatalog, report d.Report, viewer identity.PlayerID) error {
	at := sc.Operation.DecisionAt()
	day := catalog.Day(at)
	first, err := s.Store.InsertViewTx(c, sc.Tx, report.Key, viewer, day, at)
	if err != nil || !first {
		return err
	}
	owner, found, err := s.Store.ReadModeTx(c, sc.Tx, report.Owner, true)
	if err != nil || !found {
		return errors.Join(err, d.ErrConflict)
	}
	next, rewarded := catalog.RewardView(owner, at)
	if !rewarded {
		return nil
	}
	next.StateVersion, next.UpdatedAt = owner.StateVersion+1, at
	if err = s.Store.SaveModeTx(c, sc.Tx, next, owner.StateVersion); err != nil {
		return err
	}
	_, _, err = s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: report.Owner, SourceKind: viewMailKind, SourceKey: fmt.Sprintf("%s:%d:%d", report.Key, viewer, day),
		Title: catalog.Mail["CONQUER_SCHOOL_MAIL_TITLE"], Sender: catalog.Mail["CONQUER_SCHOOL_MAIL_NAME"], Body: fmt.Sprintf(catalog.Mail["CONQUER_SCHOOL_MAIL_TEXT"], 1),
		PolicyVersion: d.ModeContractID, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: catalog.ReportReward}}, At: at})
	return err
}
