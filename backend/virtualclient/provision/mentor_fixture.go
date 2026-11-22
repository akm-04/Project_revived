package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/mentorstore"
	appmentor "gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	mentorFixtureStudentLevel = int64(20)
	mentorFixtureStudents     = 3
)

// MentorFixture seeds the second side of the Mentor MIDs: three same-server
// students for the driven mentor (one find-list candidate and two pending
// applications) and one active relation where the driven player is the student.
// shortcut: the peer rows are fixture data written through the Mentor store, not
// proof of the peer's stock request path; that path is proven natively.
func MentorFixture(ctx context.Context, databaseURL, accountID, peerAccountID string) error {
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-vc-mentor-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var owner, peer identity.PlayerID
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&owner); err != nil {
		return fmt.Errorf("mentor fixture owner: %w", err)
	}
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, peerAccountID).Scan(&peer); err != nil {
		return fmt.Errorf("mentor fixture peer: %w", err)
	}
	revision, err := (contentstore.Store{Queryer: pool}).ActiveRevision(ctx, pool)
	if err != nil {
		return err
	}
	now := time.Now().UTC()
	students, err := seedMentorStudents(ctx, pool, owner)
	if err != nil {
		return err
	}
	server := logicalserver.PlayerRegion(owner)
	relationID, err := ids.NewUUID()
	if err != nil {
		return err
	}
	store := mentorstore.Store{}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		return err
	}
	defer transaction.Rollback(ctx)
	relation := domain.Relationship{ID: relationID, Mentor: peer, Student: owner, Server: server, ContentRevision: revision, PolicyVersion: appmentor.MentorPolicyVersion, AcceptedAt: now, Version: 1}
	if err = store.InsertRelationshipTx(ctx, transaction, relation); err != nil {
		return fmt.Errorf("mentor fixture relation: %w", err)
	}
	for _, student := range students[1:] {
		application := appmentor.Application{Applicant: student, Target: owner, Server: server, RecipientSlot: domain.SlotStudent, Message: "vc-mentor-application", CreatedAt: now, ExpiresAt: now.Add(48 * time.Hour), Status: appmentor.ApplicationPending, Version: 1}
		if err = store.PutApplicationTx(ctx, transaction, nil, application); err != nil {
			return fmt.Errorf("mentor fixture application: %w", err)
		}
	}
	return transaction.Commit(ctx)
}

// MentorTerminateReadyFixture backdates the driven mentor's active relation past
// the stock 24-hour dismissal limit so 1861 can succeed in one run.
func MentorTerminateReadyFixture(ctx context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-vc-mentor-terminate"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var owner identity.PlayerID
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&owner); err != nil {
		return fmt.Errorf("mentor terminate fixture owner: %w", err)
	}
	if _, err = pool.Raw().Exec(ctx, `UPDATE mentor_relations SET accepted_at=accepted_at-interval '25 hours' WHERE mentor_id=$1 AND ended_at IS NULL`, int64(owner)); err != nil {
		return fmt.Errorf("mentor terminate fixture backdate: %w", err)
	}
	return nil
}

func seedMentorStudents(ctx context.Context, pool *postgres.Pool, owner identity.PlayerID) ([]identity.PlayerID, error) {
	var base int64
	if err := pool.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+$2 WHERE logical_server_id=$1 RETURNING next_player_id-$2`, int64(logicalserver.PlayerRegion(owner)), mentorFixtureStudents).Scan(&base); err != nil {
		return nil, fmt.Errorf("mentor fixture player ids: %w", err)
	}
	students := make([]identity.PlayerID, 0, mentorFixtureStudents)
	for index := 0; index < mentorFixtureStudents; index++ {
		player := identity.PlayerID(base + int64(index))
		account, err := ids.NewUUID()
		if err != nil {
			return nil, err
		}
		for _, statement := range []struct {
			sql  string
			args []any
		}{
			{`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{account.String(), fmt.Sprintf("mentor-fixture-%d", player)}},
			{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,clock_timestamp(),'mentor-fixture')`, []any{int64(player), account.String(), int64(logicalserver.PlayerRegion(owner))}},
			{`INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)VALUES($1,'',110001001,0,0,1,clock_timestamp()-interval '1 day',clock_timestamp()-interval '1 day')`, []any{int64(player)}},
			{`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,$2,0,1,clock_timestamp()-interval '1 day')`, []any{int64(player), mentorFixtureStudentLevel}},
			{`INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES($1,1,clock_timestamp()-interval '1 day')`, []any{int64(player)}},
			{`INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,1,0,1,clock_timestamp()-interval '1 day',clock_timestamp()-interval '1 day')`, []any{int64(player)}},
			{`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',1000,1,clock_timestamp()-interval '1 day')`, []any{int64(player)}},
			{`INSERT INTO player_directory_profiles(player_id,name,lev,avatar_id,avatar_frame_id,vip,conquer_lev,state_version,created_at,updated_at)VALUES($1,$2,$3,110001001,0,0,0,1,clock_timestamp()-interval '1 day',clock_timestamp()-interval '1 day')`, []any{int64(player), fmt.Sprintf("Mentor%d", player), mentorFixtureStudentLevel}},
		} {
			if _, err = pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
				return nil, fmt.Errorf("mentor fixture player %d: %w", player, err)
			}
		}
		students = append(students, player)
	}
	return students, nil
}
