// Package combatstore owns the Combat tables: locator roots (lock rank 609),
// immutable snapshots, resolutions and report blobs, the attempt envelope and
// its START packages and attestations, and member rosters and settlements.
// Every read re-verifies content hashes before returning domain values.
package combatstore

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

var _ app.Store = Store{}

// LockLocatorTx is the rank-609 creation fence: the root row exists before any
// attempt for the locator is discovered or created.
func (Store) LockLocatorTx(c context.Context, t tx.Tx, l d.Locator) error {
	if t == nil || !l.Valid() {
		return d.ErrInvalid
	}
	if _, err := t.Exec(c, `INSERT INTO combat_locator_roots(domain_kind,authority_scope,domain_locator)VALUES($1,$2,$3) ON CONFLICT DO NOTHING`, l.DomainKind, l.AuthorityScope, l.DomainLocator); err != nil {
		return err
	}
	var one int
	return t.QueryRow(c, `SELECT 1 FROM combat_locator_roots WHERE domain_kind=$1 AND authority_scope=$2 AND domain_locator=$3 FOR UPDATE`, l.DomainKind, l.AuthorityScope, l.DomainLocator).Scan(&one)
}

const attemptColumns = `attempt_id::text,domain_kind,authority_scope,domain_locator,actor_player_id,gameplay_context_id::text,generation_ref,start_fingerprint,snapshot_hash,rules_corpus_version,entropy_key_version,resolver_status,COALESCE(resolver_failure,''),state,started_at,result_deadline,state_version,COALESCE(resolution_hash,''),COALESCE(terminal_kind,''),terminal_at,COALESCE(semantic_receipt_id,''),trust_profile_id,trust_profile_version,replay_response,replay_error_code,COALESCE(supersedes_attempt_id::text,'')`

func scanAttempt(row tx.Row) (d.Attempt, bool, error) {
	var a d.Attempt
	var id, supersedes string
	var status, state, replay string
	err := row.Scan(&id, &a.Locator.DomainKind, &a.Locator.AuthorityScope, &a.Locator.DomainLocator, &a.ActorPlayer, &a.GameplayContextID, &a.GenerationRef, &a.StartFingerprint, &a.SnapshotHash, &a.RulesCorpusID, &a.EntropyKeyVersion,
		&status, &a.ResolverFailure, &state, &a.StartedAt, &a.ResultDeadline, &a.StateVersion, &a.ResolutionHash, &a.TerminalKind, &a.TerminalAt, &a.SemanticReceiptID,
		&a.TrustProfile.ID, &a.TrustProfile.Version, &replay, &a.Replay.ErrorCode, &supersedes)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return a, false, nil
	}
	if err != nil {
		return a, false, err
	}
	if a.ID, err = ids.ParseUUID(id); err != nil {
		return a, true, d.ErrIntegrity
	}
	if supersedes != "" {
		if a.SupersedesAttemptID, err = ids.ParseUUID(supersedes); err != nil {
			return a, true, d.ErrIntegrity
		}
	}
	a.ResolverStatus, a.State, a.Replay.Response = d.ResolverStatus(status), d.AttemptState(state), d.ReplayResponse(replay)
	a.StartedAt, a.ResultDeadline = a.StartedAt.UTC(), a.ResultDeadline.UTC()
	if a.TerminalAt != nil {
		at := a.TerminalAt.UTC()
		a.TerminalAt = &at
	}
	if a.Validate() != nil {
		return a, true, d.ErrIntegrity
	}
	return a, true, nil
}

func (Store) FindUnresolvedTx(c context.Context, q tx.Queryer, l d.Locator) (d.Attempt, bool, error) {
	if q == nil || !l.Valid() {
		return d.Attempt{}, false, d.ErrInvalid
	}
	return scanAttempt(q.QueryRow(c, `SELECT `+attemptColumns+` FROM combat_attempts WHERE domain_kind=$1 AND authority_scope=$2 AND domain_locator=$3 AND state<>'TERMINAL'`, l.DomainKind, l.AuthorityScope, l.DomainLocator))
}

func (Store) FindTerminalTx(c context.Context, q tx.Queryer, l d.Locator, receipt string) (d.Attempt, bool, error) {
	if q == nil || !l.Valid() || receipt == "" {
		return d.Attempt{}, false, d.ErrInvalid
	}
	return scanAttempt(q.QueryRow(c, `SELECT `+attemptColumns+` FROM combat_attempts WHERE domain_kind=$1 AND authority_scope=$2 AND domain_locator=$3 AND state='TERMINAL' AND semantic_receipt_id=$4`, l.DomainKind, l.AuthorityScope, l.DomainLocator, receipt))
}

func (Store) ReadAttemptTx(c context.Context, q tx.Queryer, id ids.UUID) (d.Attempt, bool, error) {
	if q == nil || id.IsZero() {
		return d.Attempt{}, false, d.ErrInvalid
	}
	return scanAttempt(q.QueryRow(c, `SELECT `+attemptColumns+` FROM combat_attempts WHERE attempt_id=$1`, id.String()))
}

func (Store) LockAttemptTx(c context.Context, t tx.Tx, id ids.UUID) (d.Attempt, error) {
	if t == nil || id.IsZero() {
		return d.Attempt{}, d.ErrInvalid
	}
	a, found, err := scanAttempt(t.QueryRow(c, `SELECT `+attemptColumns+` FROM combat_attempts WHERE attempt_id=$1 FOR UPDATE`, id.String()))
	if err == nil && !found {
		err = app.ErrAttemptNotFound
	}
	return a, err
}

func (Store) InsertAttemptTx(c context.Context, t tx.Tx, a d.Attempt) error {
	if t == nil || a.Validate() != nil || a.State != d.Staged || a.StateVersion != 1 {
		return d.ErrInvalid
	}
	var supersedes any
	if !a.SupersedesAttemptID.IsZero() {
		supersedes = a.SupersedesAttemptID.String()
	}
	_, err := t.Exec(c, `INSERT INTO combat_attempts(attempt_id,domain_kind,authority_scope,domain_locator,actor_player_id,gameplay_context_id,generation_ref,start_fingerprint,trust_profile_id,trust_profile_version,snapshot_hash,rules_corpus_version,entropy_policy_version,entropy_key_version,resolver_status,state,started_at,result_deadline,state_version,replay_response,replay_error_code,supersedes_attempt_id)VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,1,$19,$20,$21)`,
		a.ID.String(), a.Locator.DomainKind, a.Locator.AuthorityScope, a.Locator.DomainLocator, a.ActorPlayer, a.GameplayContextID, a.GenerationRef, a.StartFingerprint, a.TrustProfile.ID, a.TrustProfile.Version, a.SnapshotHash, a.RulesCorpusID, d.EntropyPolicyVersion, a.EntropyKeyVersion, string(a.ResolverStatus), string(a.State), a.StartedAt, a.ResultDeadline,
		string(a.Replay.Response), a.Replay.ErrorCode, supersedes)
	return err
}

func nullable(s string) any {
	if s == "" {
		return nil
	}
	return s
}

// SaveAttemptTx is a compare-and-swap on state_version.
func (Store) SaveAttemptTx(c context.Context, t tx.Tx, a d.Attempt, previous int64) error {
	if t == nil || a.Validate() != nil || a.StateVersion != previous+1 {
		return d.ErrInvalid
	}
	var terminalAt any
	if a.TerminalAt != nil {
		terminalAt = *a.TerminalAt
	}
	tag, err := t.Exec(c, `UPDATE combat_attempts SET resolver_status=$2,resolver_failure=$3,state=$4,state_version=$5,resolution_hash=$6,terminal_kind=$7,terminal_at=$8,semantic_receipt_id=$9 WHERE attempt_id=$1 AND state_version=$10`,
		a.ID.String(), string(a.ResolverStatus), nullable(a.ResolverFailure), string(a.State), a.StateVersion, nullable(a.ResolutionHash), nullable(a.TerminalKind), terminalAt, nullable(a.SemanticReceiptID), previous)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return d.ErrStale
	}
	return nil
}

// InsertSnapshotTx is idempotent by content address; a differing body is an integrity failure.
func (Store) InsertSnapshotTx(c context.Context, t tx.Tx, hash string, raw []byte) error {
	s, err := d.DecodeSnapshot(raw, hash)
	if t == nil || err != nil {
		return d.ErrInvalid
	}
	if _, err = t.Exec(c, `INSERT INTO combat_snapshots(snapshot_hash,content_revision,rules_corpus_id,canonical)VALUES($1,$2,$3,$4) ON CONFLICT(snapshot_hash) DO NOTHING`, hash, s.ContentRevision, s.CorpusID, raw); err != nil {
		return err
	}
	stored, err := Store{}.ReadSnapshotTx(c, t, hash)
	if err == nil && !bytes.Equal(stored, raw) {
		err = d.ErrIntegrity
	}
	return err
}

func (Store) ReadSnapshotTx(c context.Context, q tx.Queryer, hash string) ([]byte, error) {
	if q == nil {
		return nil, d.ErrInvalid
	}
	var raw []byte
	if err := q.QueryRow(c, `SELECT canonical FROM combat_snapshots WHERE snapshot_hash=$1`, hash).Scan(&raw); err != nil {
		return nil, err
	}
	if _, err := d.DecodeSnapshot(raw, hash); err != nil {
		return nil, err
	}
	return raw, nil
}

func (Store) InsertResolutionTx(c context.Context, t tx.Tx, hash string, r d.Resolution, report []byte) error {
	got, raw, err := r.Hash()
	if t == nil || err != nil || got != hash || r.ReportSHA256 != d.ReportHash(report) || r.ReportBytes != int64(len(report)) {
		return d.ErrInvalid
	}
	if _, err = t.Exec(c, `INSERT INTO combat_report_blobs(report_sha256,encoding,byte_length,report)VALUES($1,$2,$3,$4) ON CONFLICT(report_sha256) DO NOTHING`, r.ReportSHA256, r.ReportEncoding, r.ReportBytes, report); err != nil {
		return err
	}
	_, err = t.Exec(c, `INSERT INTO combat_resolutions(resolution_hash,attempt_id,report_sha256,canonical)VALUES($1,$2,$3,$4)`, hash, r.AttemptID, r.ReportSHA256, raw)
	return err
}

func (Store) ReadResolutionTx(c context.Context, q tx.Queryer, hash string) (d.Resolution, []byte, error) {
	var r d.Resolution
	if q == nil || hash == "" {
		return r, nil, d.ErrInvalid
	}
	var raw, report []byte
	if err := q.QueryRow(c, `SELECT r.canonical,b.report FROM combat_resolutions r JOIN combat_report_blobs b ON b.report_sha256=r.report_sha256 WHERE r.resolution_hash=$1`, hash).Scan(&raw, &report); err != nil {
		return r, nil, err
	}
	if err := json.Unmarshal(raw, &r); err != nil {
		return r, nil, d.ErrIntegrity
	}
	got, again, err := r.Hash()
	if err != nil || got != hash || !bytes.Equal(again, raw) || r.ReportSHA256 != d.ReportHash(report) || r.ReportBytes != int64(len(report)) {
		return r, nil, d.ErrIntegrity
	}
	return r, report, nil
}

func (Store) InsertStartPackageTx(c context.Context, t tx.Tx, p d.StartPackage) error {
	if t == nil || p.Validate() != nil {
		return d.ErrInvalid
	}
	_, err := t.Exec(c, `INSERT INTO combat_start_packages(attempt_id,package_policy,package_sha256,draws,canonical)VALUES($1,$2,$3,$4,$5)`, p.AttemptID.String(), p.Policy, p.Hash(), int64(p.Draws), []byte(p.Canonical))
	return err
}

func (Store) ReadStartPackageTx(c context.Context, q tx.Queryer, attempt ids.UUID) (d.StartPackage, bool, error) {
	p := d.StartPackage{AttemptID: attempt}
	if q == nil || attempt.IsZero() {
		return p, false, d.ErrInvalid
	}
	var hash string
	var draws int64
	err := q.QueryRow(c, `SELECT package_policy,package_sha256,draws,canonical FROM combat_start_packages WHERE attempt_id=$1`, attempt.String()).Scan(&p.Policy, &hash, &draws, &p.Canonical)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return p, false, nil
	}
	if err != nil {
		return p, false, err
	}
	p.Draws = uint64(draws)
	if p.Validate() != nil || p.Hash() != hash {
		return p, true, d.ErrIntegrity
	}
	return p, true, nil
}

func (Store) InsertAttestationTx(c context.Context, t tx.Tx, a d.Attestation) error {
	if t == nil || a.Validate() != nil {
		return d.ErrInvalid
	}
	_, err := t.Exec(c, `INSERT INTO combat_attestations(attempt_id,validator_id,validator_version,verdict,summary_sha256,summary,recorded_at)VALUES($1,$2,$3,$4,$5,$6,$7)`,
		a.AttemptID.String(), a.ValidatorID, a.ValidatorVersion, string(a.Verdict), a.SummaryHash(), []byte(a.Summary), a.RecordedAt)
	return err
}

func (Store) ReadAttestationTx(c context.Context, q tx.Queryer, attempt ids.UUID) (d.Attestation, error) {
	a := d.Attestation{AttemptID: attempt}
	if q == nil || attempt.IsZero() {
		return a, d.ErrInvalid
	}
	var hash, verdict string
	if err := q.QueryRow(c, `SELECT validator_id,validator_version,verdict,summary_sha256,summary,recorded_at FROM combat_attestations WHERE attempt_id=$1`, attempt.String()).Scan(&a.ValidatorID, &a.ValidatorVersion, &verdict, &hash, &a.Summary, &a.RecordedAt); err != nil {
		return a, err
	}
	a.Verdict, a.RecordedAt = d.Verdict(verdict), a.RecordedAt.UTC()
	if a.Validate() != nil || a.SummaryHash() != hash {
		return a, d.ErrIntegrity
	}
	return a, nil
}

func (Store) InsertMembersTx(c context.Context, t tx.Tx, attempt ids.UUID, members []int64) error {
	if t == nil || attempt.IsZero() || len(members) == 0 || d.ValidMembers(members[0], members) != nil {
		return d.ErrInvalid
	}
	for seat, member := range members {
		if _, err := t.Exec(c, `INSERT INTO combat_attempt_members(attempt_id,seat,member_player_id)VALUES($1,$2,$3)`, attempt.String(), seat, member); err != nil {
			return err
		}
	}
	return nil
}

// ReadMembersTx returns the roster by seat; an attempt without one reads empty.
func (Store) ReadMembersTx(c context.Context, q tx.Queryer, attempt ids.UUID) ([]int64, error) {
	if q == nil || attempt.IsZero() {
		return nil, d.ErrInvalid
	}
	var raw string
	if err := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(member_player_id ORDER BY seat),'[]'::jsonb)::text FROM combat_attempt_members WHERE attempt_id=$1`, attempt.String()).Scan(&raw); err != nil {
		return nil, err
	}
	members := []int64{}
	if err := json.Unmarshal([]byte(raw), &members); err != nil {
		return nil, d.ErrIntegrity
	}
	if len(members) > 0 && d.ValidMembers(members[0], members) != nil {
		return nil, d.ErrIntegrity
	}
	return members, nil
}

func (Store) InsertMemberSettlementTx(c context.Context, t tx.Tx, s d.MemberSettlement) error {
	if t == nil || s.Validate() != nil {
		return d.ErrInvalid
	}
	// Under RepeatableRead a racing committed settlement makes DO NOTHING a
	// serialization failure, so the caller's retry replays instead of failing.
	tag, err := t.Exec(c, `INSERT INTO combat_member_settlements(attempt_id,member_player_id,semantic_receipt_id,settled_at)VALUES($1,$2,$3,$4) ON CONFLICT DO NOTHING`, s.AttemptID.String(), s.Member, s.SemanticReceiptID, s.SettledAt)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return d.ErrStale
	}
	return nil
}

func (Store) FindMemberSettlementTx(c context.Context, q tx.Queryer, attempt ids.UUID, member int64) (d.MemberSettlement, bool, error) {
	s := d.MemberSettlement{AttemptID: attempt, Member: member}
	if q == nil || attempt.IsZero() || member <= 0 {
		return s, false, d.ErrInvalid
	}
	err := q.QueryRow(c, `SELECT semantic_receipt_id,settled_at FROM combat_member_settlements WHERE attempt_id=$1 AND member_player_id=$2`, attempt.String(), member).Scan(&s.SemanticReceiptID, &s.SettledAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return s, false, nil
	}
	if err != nil {
		return s, false, err
	}
	if s.Validate() != nil {
		return s, true, d.ErrIntegrity
	}
	return s, true, nil
}
