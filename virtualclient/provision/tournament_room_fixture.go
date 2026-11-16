package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TournamentRoomNoPetFixture seeds one stage-7 tournament room whose sides
// picked no pet, so the stock selection window receives the room reply the
// server builds for an empty pet slot.
//
// shortcut: the room, its period and settlement rows are declared fixture data
// written through the Arena store, not proof of the bracket that creates them;
// upgrade when the client can reach stage 7 in a virtual run.
func TournamentRoomNoPetFixture(ctx context.Context, databaseURL, accountID, peerAccountID, roomID string) error {
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-vc-tournament-room-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var owner, peer identity.PlayerID
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&owner); err != nil {
		return fmt.Errorf("tournament fixture owner: %w", err)
	}
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, peerAccountID).Scan(&peer); err != nil {
		return fmt.Errorf("tournament fixture peer: %w", err)
	}
	var revision string
	if err = pool.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions ORDER BY installed_at DESC LIMIT 1`).Scan(&revision); err != nil {
		return fmt.Errorf("tournament fixture revision: %w", err)
	}
	identifier, err := ids.ParseUUID(roomID)
	if err != nil {
		return fmt.Errorf("tournament fixture room id: %w", err)
	}
	now := time.Now().UTC()
	room := d.TournamentRoom{
		Identifier: identifier, Season: 1, Stage: 7, Contest: 1, Status: d.RoomSelecting, StartsAt: now,
		ContentRevision: revision, StateVersion: 1,
		Selection:       d.SelectionRoom{Players: [2]identity.PlayerID{owner, peer}, Team: 1, Turn: 7, Deadline: now.Add(time.Minute)},
		SelectionHeroes: [2]map[string]map[string]any{{}, {}},
		SelectionPets:   [2]map[string]map[string]any{{}, {}},
		Actors:          [2]d.AdmissionContext{fixtureAdmission(owner, "11111111-1111-1111-1111-111111111111"), fixtureAdmission(peer, "22222222-2222-2222-2222-222222222222")},
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		return err
	}
	defer transaction.Rollback(ctx)
	if _, err = transaction.Exec(ctx, `INSERT INTO arena_settlements(season,cutoff_at,settled_at,competition_version,content_revision,recipients)VALUES(1,$1,$1,1,$2,0)ON CONFLICT(season)DO NOTHING`, now, revision); err != nil {
		return fmt.Errorf("tournament fixture settlement: %w", err)
	}
	if _, err = transaction.Exec(ctx, `INSERT INTO arena_tournament_periods(season,content_revision,payload,state_version)VALUES(1,$1::text,jsonb_build_object('season',1,'content_revision',$1::text,'state_version',1),1)ON CONFLICT(season)DO NOTHING`, revision); err != nil {
		return fmt.Errorf("tournament fixture period: %w", err)
	}
	if err = (arenastore.Store{}).SaveTournamentRoomTx(ctx, transaction, room, 0); err != nil {
		return fmt.Errorf("tournament fixture room: %w", err)
	}
	return transaction.Commit(ctx)
}

func fixtureAdmission(player identity.PlayerID, account string) d.AdmissionContext {
	accountID, _ := ids.ParseUUID(account)
	sessionID, _ := ids.ParseUUID("33333333-3333-3333-3333-333333333333")
	contextID, _ := ids.ParseUUID("44444444-4444-4444-4444-444444444444")
	return d.AdmissionContext{AccountID: accountID, AccountUID: "vc-r1-tournament-fixture", SessionID: sessionID, ContextID: contextID,
		LogicalServerID: identity.LogicalServerID(int64(player) / 100000), PlayerID: player, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
