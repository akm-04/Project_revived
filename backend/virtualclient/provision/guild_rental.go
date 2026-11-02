package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// GuildRentalLenderFixture joins the born peer to the driven player's guild and
// places one of its girls on loan. The borrowed table is moved to a content hero
// the driven player never owns, so C11 rule 12 is not what this scenario proves.
func GuildRentalLenderFixture(requestContext context.Context, databaseURL, accountID, peerAccountID string) error {
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-guild-rental-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var guild int64
	if err := pool.QueryRow(requestContext, `SELECT m.guild_id FROM guild_memberships m JOIN players p ON p.player_id=m.player_id WHERE p.account_id=$1 LIMIT 1`, accountID).Scan(&guild); err != nil {
		return fmt.Errorf("guild rental fixture needs the driven player's guild: %w", err)
	}
	var lender, partner int64
	if err := pool.QueryRow(requestContext, `SELECT p.player_id, h.partner_id FROM players p JOIN player_heroes h ON h.player_id=p.player_id WHERE p.account_id=$1 ORDER BY h.partner_id LIMIT 1`, peerAccountID).Scan(&lender, &partner); err != nil {
		return fmt.Errorf("guild rental fixture needs the born peer's hero: %w", err)
	}
	transaction, err := pool.Begin(requestContext, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		return err
	}
	defer transaction.Rollback(requestContext)
	if _, err := transaction.Exec(requestContext, `UPDATE player_heroes SET table_id=10001009,origin_table_id=10001009 WHERE player_id=$1 AND partner_id=$2`, lender, partner); err != nil {
		return err
	}
	if _, err := transaction.Exec(requestContext, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at)
		VALUES($1,$2,0,clock_timestamp(),1,1,clock_timestamp()) ON CONFLICT(player_id) DO UPDATE SET guild_id=EXCLUDED.guild_id,role=0,updated_at=clock_timestamp()`, lender, guild); err != nil {
		return err
	}
	if _, err := transaction.Exec(requestContext, `INSERT INTO guild_rental_offers(lender_id,kind,unit_id,guild_id,force,rent_award,rent_time)
		VALUES($1,'HERO',$2,$3,4000,0,clock_timestamp()) ON CONFLICT DO NOTHING`, lender, partner, guild); err != nil {
		return err
	}
	return transaction.Commit(requestContext)
}
