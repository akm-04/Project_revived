package characterstore

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func scanPracticeRoot(row tx.Row) (apppractice.Root, error) {
	var r apppractice.Root
	var pid int64
	var free, epoch sql.NullTime
	var epochPolicy, privilegeRevision, contentRevision sql.NullString
	var vip sql.NullInt64
	if err := row.Scan(&pid, &free, &epoch, &epochPolicy, &r.BlessRemaining, &r.BlessCapacityAtEpoch, &vip, &privilegeRevision, &contentRevision, &r.BaseMana, &r.BaseCrystal, &r.StateVersion, &r.CreatedAt, &r.UpdatedAt); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) || errors.Is(err, sql.ErrNoRows) {
			return r, apppractice.ErrRootMissing
		}
		return r, err
	}
	r.PlayerID = identity.PlayerID(pid)
	if free.Valid {
		t := free.Time.UTC()
		r.FreeLastConsumedAt = &t
	}
	if epoch.Valid {
		t := epoch.Time.UTC()
		r.DailyEpochStartAt = &t
	}
	if epochPolicy.Valid {
		r.DailyEpochPolicyVersion = epochPolicy.String
	}
	if vip.Valid {
		v := vip.Int64
		r.BlessVIPLevelAtEpoch = &v
	}
	if privilegeRevision.Valid {
		r.BlessPrivilegeProviderRevision = privilegeRevision.String
	}
	if contentRevision.Valid {
		r.BlessContentRevision = contentRevision.String
	}
	r.CreatedAt, r.UpdatedAt = r.CreatedAt.UTC(), r.UpdatedAt.UTC()
	if err := r.Validate(); err != nil {
		return apppractice.Root{}, err
	}
	return r, nil
}

func (Store) ReadPracticeRootTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (apppractice.Root, error) {
	if q == nil || !pid.Valid() {
		return apppractice.Root{}, errors.New("character practice store: invalid root read")
	}
	return scanPracticeRoot(q.QueryRow(ctx, characterqueries.ReadPracticeRoot, int64(pid)))
}

func (Store) LockPracticeRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (apppractice.Root, error) {
	if t == nil || !pid.Valid() {
		return apppractice.Root{}, errors.New("character practice store: invalid root lock")
	}
	return scanPracticeRoot(t.QueryRow(ctx, characterqueries.LockPracticeRoot, int64(pid)))
}

func (Store) EnsureRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, now time.Time) (bool, error) {
	if t == nil || !pid.Valid() || now.IsZero() {
		return false, errors.New("character practice store: invalid root ensure")
	}
	tag, err := t.Exec(ctx, characterqueries.InsertPracticeRoot, int64(pid), now.UTC())
	if err != nil {
		return false, err
	}
	n := tag.RowsAffected()
	if n != 0 && n != 1 {
		return false, errors.New("character practice store: root ensure affected unexpected rows")
	}
	return n == 1, nil
}

func (Store) SaveGenerationTx(ctx context.Context, t tx.Tx, next apppractice.Root, oldVersion int64) error {
	if t == nil || oldVersion <= 0 || next.StateVersion != oldVersion+1 || next.Validate() != nil || next.DailyEpochStartAt == nil || next.BlessVIPLevelAtEpoch == nil {
		return errors.New("character practice store: invalid generation update")
	}
	tag, err := t.Exec(ctx, characterqueries.SavePracticeRootGeneration,
		int64(next.PlayerID), next.DailyEpochStartAt.UTC(), next.DailyEpochPolicyVersion,
		next.BlessRemaining, next.BlessCapacityAtEpoch, *next.BlessVIPLevelAtEpoch,
		next.BlessPrivilegeProviderRevision, next.BlessContentRevision,
		next.BaseMana, next.BaseCrystal, next.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return apppractice.ErrStaleVersion
	}
	return nil
}

func nullableTimeUTC(v *time.Time) any {
	if v == nil {
		return nil
	}
	return v.UTC()
}

func nullableInt64(v *int64) any {
	if v == nil {
		return nil
	}
	return *v
}

func nullableString(v string) any {
	if v == "" {
		return nil
	}
	return v
}

// SaveAccountingTx is the Root450-owned full accounting CAS used when one
// caller-owned command must settle lazy generation and command accounting in a
// single durable root transition. It never bypasses Root validation/provenance.
func (Store) SaveAccountingTx(ctx context.Context, t tx.Tx, next apppractice.Root, oldVersion int64) error {
	if t == nil || oldVersion <= 0 || next.StateVersion != oldVersion+1 || next.Validate() != nil {
		return errors.New("character practice store: invalid accounting update")
	}
	tag, err := t.Exec(ctx, characterqueries.SavePracticeRootAccounting,
		int64(next.PlayerID), nullableTimeUTC(next.FreeLastConsumedAt), nullableTimeUTC(next.DailyEpochStartAt), nullableString(next.DailyEpochPolicyVersion),
		next.BlessRemaining, next.BlessCapacityAtEpoch, nullableInt64(next.BlessVIPLevelAtEpoch),
		nullableString(next.BlessPrivilegeProviderRevision), nullableString(next.BlessContentRevision),
		next.BaseMana, next.BaseCrystal, next.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return apppractice.ErrStaleVersion
	}
	return nil
}

func parseProposal(row tx.Row) (apppractice.Proposal, error) {
	var p apppractice.Proposal
	var pid int64
	var sid, opid, cid, rawPolicies string
	var kind string
	if err := row.Scan(&pid, &sid, &p.ActorID, &p.ActorStateVersion, &p.Proposed[0], &p.Proposed[1], &p.Proposed[2], &opid, &cid, &kind, &p.GenerationContentRevision, &rawPolicies, &p.CreatedAt, &p.UpdatedAt); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) || errors.Is(err, sql.ErrNoRows) {
			return p, apppractice.ErrCandidateMissing
		}
		return p, err
	}
	su, err := ids.ParseUUID(sid)
	if err != nil {
		return p, err
	}
	p.SessionID, err = identity.SessionIDFrom(su)
	if err != nil {
		return p, err
	}
	p.GenerationOperationID, err = ids.ParseUUID(opid)
	if err != nil {
		return p, err
	}
	cu, err := ids.ParseUUID(cid)
	if err != nil {
		return p, err
	}
	p.GenerationContextID, err = identity.ContextIDFrom(cu)
	if err != nil {
		return p, err
	}
	p.GenerationPolicyRefs, err = policy.ParseCanonicalJSON([]byte(rawPolicies))
	if err != nil {
		return p, err
	}
	p.PlayerID = identity.PlayerID(pid)
	p.GenerationKind = apppractice.PendingKind(kind)
	p.CreatedAt, p.UpdatedAt = p.CreatedAt.UTC(), p.UpdatedAt.UTC()
	if err := p.Validate(); err != nil {
		return apppractice.Proposal{}, err
	}
	return p, nil
}

func proposalArgs(p apppractice.Proposal) ([]any, error) {
	if err := p.Validate(); err != nil {
		return nil, err
	}
	raw, err := policy.MarshalCanonicalJSON(p.GenerationPolicyRefs)
	if err != nil {
		return nil, err
	}
	return []any{int64(p.PlayerID), p.SessionID.UUID().String(), p.ActorID, p.ActorStateVersion, p.Proposed[0], p.Proposed[1], p.Proposed[2], p.GenerationOperationID.String(), p.GenerationContextID.UUID().String(), string(p.GenerationKind), p.GenerationContentRevision, string(raw), p.CreatedAt.UTC(), p.UpdatedAt.UTC()}, nil
}

func (Store) ReadHeroProposalTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, sid identity.SessionID, actorID int64) (apppractice.Proposal, error) {
	if q == nil || !pid.Valid() || sid.UUID().IsZero() || actorID <= 0 {
		return apppractice.Proposal{}, errors.New("character practice store: invalid Hero proposal read")
	}
	return parseProposal(q.QueryRow(ctx, characterqueries.ReadHeroPracticeCandidate, int64(pid), sid.UUID().String(), actorID))
}
func (Store) LockHeroProposalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, sid identity.SessionID, actorID int64) (apppractice.Proposal, error) {
	if t == nil {
		return apppractice.Proposal{}, errors.New("character practice store: nil Hero proposal tx")
	}
	return parseProposal(t.QueryRow(ctx, characterqueries.LockHeroPracticeCandidate, int64(pid), sid.UUID().String(), actorID))
}
func (Store) UpsertHeroProposalTx(ctx context.Context, t tx.Tx, p apppractice.Proposal) error {
	if t == nil {
		return errors.New("character practice store: nil Hero proposal tx")
	}
	a, err := proposalArgs(p)
	if err != nil {
		return err
	}
	tag, err := t.Exec(ctx, characterqueries.UpsertHeroPracticeCandidate, a...)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character practice store: Hero proposal upsert affected unexpected rows")
	}
	return nil
}
func (Store) DeleteHeroProposalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, sid identity.SessionID, actorID int64) error {
	if t == nil || !pid.Valid() || sid.UUID().IsZero() || actorID <= 0 {
		return errors.New("character practice store: invalid Hero proposal delete")
	}
	tag, err := t.Exec(ctx, characterqueries.DeleteHeroPracticeCandidate, int64(pid), sid.UUID().String(), actorID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return apppractice.ErrCandidateMissing
	}
	return nil
}
func (Store) ReadPetProposalTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, sid identity.SessionID, actorID int64) (apppractice.Proposal, error) {
	if q == nil || !pid.Valid() || sid.UUID().IsZero() || actorID <= 0 {
		return apppractice.Proposal{}, errors.New("character practice store: invalid Pet proposal read")
	}
	return parseProposal(q.QueryRow(ctx, characterqueries.ReadPetPracticeCandidate, int64(pid), sid.UUID().String(), actorID))
}
func (Store) LockPetProposalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, sid identity.SessionID, actorID int64) (apppractice.Proposal, error) {
	if t == nil {
		return apppractice.Proposal{}, errors.New("character practice store: nil Pet proposal tx")
	}
	return parseProposal(t.QueryRow(ctx, characterqueries.LockPetPracticeCandidate, int64(pid), sid.UUID().String(), actorID))
}
func (Store) UpsertPetProposalTx(ctx context.Context, t tx.Tx, p apppractice.Proposal) error {
	if t == nil {
		return errors.New("character practice store: nil Pet proposal tx")
	}
	a, err := proposalArgs(p)
	if err != nil {
		return err
	}
	tag, err := t.Exec(ctx, characterqueries.UpsertPetPracticeCandidate, a...)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character practice store: Pet proposal upsert affected unexpected rows")
	}
	return nil
}
func (Store) DeletePetProposalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, sid identity.SessionID, actorID int64) error {
	if t == nil || !pid.Valid() || sid.UUID().IsZero() || actorID <= 0 {
		return errors.New("character practice store: invalid Pet proposal delete")
	}
	tag, err := t.Exec(ctx, characterqueries.DeletePetPracticeCandidate, int64(pid), sid.UUID().String(), actorID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return apppractice.ErrCandidateMissing
	}
	return nil
}

type PracticeBootstrapContributor struct{}

func (PracticeBootstrapContributor) Name() string   { return "ca6.practice" }
func (PracticeBootstrapContributor) Required() bool { return true }
func (PracticeBootstrapContributor) PersistCharacterBootstrap(ctx context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	if t == nil || !b.PlayerID.Valid() || b.Operation.StartedAt.IsZero() {
		return errors.New("character practice store: invalid bootstrap")
	}
	created, err := (Store{}).EnsureRootTx(ctx, t, b.PlayerID, b.Operation.StartedAt)
	if err != nil {
		return err
	}
	if !created {
		return errors.New("character practice store: bootstrap root not inserted")
	}
	return nil
}

var _ apppractice.Store = Store{}
var _ appboot.CharacterBootstrapPersistenceContributor = PracticeBootstrapContributor{}
