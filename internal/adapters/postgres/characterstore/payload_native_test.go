//go:build postgres

package characterstore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	app "gxb.local/backend/v2/internal/application/heroevolution"
	"gxb.local/backend/v2/internal/domain/character"
	evo "gxb.local/backend/v2/internal/domain/heroevolution"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func storedPayload[T any](t *testing.T, p *pg.Pool, table, column, where string, out *T, args ...any) {
	t.Helper()
	var raw []byte
	var version int16
	if err := p.QueryRow(context.Background(), `SELECT `+column+`::text,payload_version FROM `+table+` WHERE `+where, args...).Scan(&raw, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("%s.%s payload_version=%d want %d", table, column, version, payload.Current)
	}
	if err := payload.Decode(table, version, raw, out); err != nil {
		t.Fatalf("%s.%s strict decode: %v", table, column, err)
	}
}

func samePayload(t *testing.T, written, decoded any) {
	t.Helper()
	writtenRaw, err := json.Marshal(written)
	if err != nil {
		t.Fatal(err)
	}
	decodedRaw, err := json.Marshal(decoded)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(decodedRaw, writtenRaw) {
		t.Fatalf("payload changed: decoded=%s written=%s", decodedRaw, writtenRaw)
	}
}

func TestPayloadVersionRoundTripCharacterStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2B_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_2B_DSN required")
	}
	ctx := context.Background()
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-2b-characterstore-native"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	var rev string
	if err = p.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions ORDER BY revision_id LIMIT 1`).Scan(&rev); err != nil {
		t.Fatal(err)
	}
	pid := identity.PlayerID(110003)
	accountID, _ := ids.NewUUID()
	if _, err = p.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, accountID.String(), accountID.String()); err != nil {
		t.Fatal(err)
	}
	if _, err = p.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,clock_timestamp(),'r8-2b-native')`, int64(pid), accountID.String()); err != nil {
		t.Fatal(err)
	}
	at := time.Now().UTC().Add(-time.Hour)
	if _, err = p.Raw().Exec(ctx, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,10,0,1,$2,$2)`, int64(pid), at); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		p.Raw().Exec(ctx, `DELETE FROM player_hero_evolution_admissions WHERE player_id=$1`, int64(pid))
		p.Raw().Exec(ctx, `DELETE FROM player_hero_evolution WHERE player_id=$1`, int64(pid))
		p.Raw().Exec(ctx, `DELETE FROM player_hero_practice_candidates WHERE player_id=$1`, int64(pid))
		p.Raw().Exec(ctx, `DELETE FROM player_pet_practice_candidates WHERE player_id=$1`, int64(pid))
		p.Raw().Exec(ctx, `DELETE FROM player_practice_roots WHERE player_id=$1`, int64(pid))
		p.Raw().Exec(ctx, `DELETE FROM player_hero_roots WHERE player_id=$1`, int64(pid))
		p.Raw().Exec(ctx, `DELETE FROM players WHERE player_id=$1`, int64(pid))
		p.Raw().Exec(ctx, `DELETE FROM accounts WHERE account_id=$1`, accountID.String())
	})
	evolution := characterstore.EvolutionStore{}
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = evolution.EnsureHeroTx(ctx, tr, pid, 1, at); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var seed evo.Facts
	storedPayload(t, p, "player_hero_evolution", "facts", "player_id=$1 AND partner_id=1", &seed, int64(pid))
	samePayload(t, evo.Seed(), seed)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	facet, err := evolution.LockHeroTx(ctx, tr, pid, 1)
	if err != nil {
		t.Fatal(err)
	}
	facet.Facts.Stage = 2
	facet.Facts.Points["4"] = 10
	facet.Version++
	facet.UpdatedAt = at.Add(time.Second)
	if err = evolution.SaveHeroTx(ctx, tr, facet, 1); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var facts evo.Facts
	storedPayload(t, p, "player_hero_evolution", "facts", "player_id=$1 AND partner_id=1", &facts, int64(pid))
	samePayload(t, facet.Facts, facts)
	if _, err = evolution.ReadHeroTx(ctx, p, pid, 1); err != nil {
		t.Fatal(err)
	}

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = evolution.InitFreshHeroTx(ctx, tr, character.HeroRef{PlayerID: pid, PartnerID: 2}, at); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var fresh evo.Facts
	storedPayload(t, p, "player_hero_evolution", "facts", "player_id=$1 AND partner_id=2", &fresh, int64(pid))
	samePayload(t, evo.Seed(), fresh)

	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: rev}, policy.Ref{Name: "heroevolution", Version: app.LifecyclePolicy})
	if err != nil {
		t.Fatal(err)
	}
	operationID, _ := ids.NewUUID()
	admission := app.Admission{
		Operation:       operation.Context{ID: operationID, StartedAt: at, Policies: policies},
		DecisionAt:      at,
		Actor:           app.DurableActor{Account: accountID, Session: operationID, Context: operationID, AccountUID: accountID.String(), Server: 1, Player: int64(pid), Generation: 1, SessionVersion: 1, ContextVersion: 1},
		Command:         app.Command{Family: app.Advance, PartnerID: 1},
		ContentRevision: rev,
		State:           "PENDING",
	}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = evolution.SaveAdmissionTx(ctx, tr, admission); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var decoded app.Admission
	storedPayload(t, p, "player_hero_evolution_admissions", "operation_context", "player_id=$1", &decoded, int64(pid))
	samePayload(t, admission, decoded)
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	locked, exists, err := evolution.LockAdmissionTx(ctx, tr, pid, "EVOLUTION")
	if err != nil || !exists || locked.Operation.ID != operationID {
		t.Fatalf("LockAdmissionTx exists=%v id=%s err=%v", exists, locked.Operation.ID, err)
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}

	sessionUUID, _ := ids.NewUUID()
	contextUUID, _ := ids.NewUUID()
	sessionID, err := identity.SessionIDFrom(sessionUUID)
	if err != nil {
		t.Fatal(err)
	}
	contextID, err := identity.ContextIDFrom(contextUUID)
	if err != nil {
		t.Fatal(err)
	}
	refs, err := policy.NewSet(policy.Ref{Name: "content", Version: rev}, policy.Ref{Name: "practice.bounds", Version: "PRACTICE_BOUNDS_V1"})
	if err != nil {
		t.Fatal(err)
	}
	proposal := apppractice.Proposal{
		PlayerID: pid, SessionID: sessionID, ActorID: 1, ActorStateVersion: 1,
		Proposed: character.PracticeAttrs{11, 12, 13}, GenerationOperationID: operationID, GenerationContextID: contextID,
		GenerationKind: apppractice.PendingManual, GenerationContentRevision: rev,
		GenerationPolicyRefs: refs, CreatedAt: at, UpdatedAt: at,
	}
	practice := characterstore.Store{Queryer: p}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = practice.EnsureRootTx(ctx, tr, pid, at); err != nil {
		t.Fatal(err)
	}
	if err = practice.UpsertHeroProposalTx(ctx, tr, proposal); err != nil {
		t.Fatal(err)
	}
	if err = practice.UpsertPetProposalTx(ctx, tr, proposal); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var heroRefs policy.Set
	storedPayload(t, p, "player_hero_practice_candidates", "generation_policy_refs", "player_id=$1 AND partner_id=1", &heroRefs, int64(pid))
	samePayload(t, refs, heroRefs)
	var petRefs policy.Set
	storedPayload(t, p, "player_pet_practice_candidates", "generation_policy_refs", "player_id=$1 AND pet_id=1", &petRefs, int64(pid))
	samePayload(t, refs, petRefs)
	if _, err = practice.ReadHeroProposalTx(ctx, p, pid, sessionID, 1); err != nil {
		t.Fatal(err)
	}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = practice.LockHeroProposalTx(ctx, tr, pid, sessionID, 1); err != nil {
		t.Fatal(err)
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err = practice.ReadPetProposalTx(ctx, p, pid, sessionID, 1); err != nil {
		t.Fatal(err)
	}
}
