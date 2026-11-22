package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// dormSocialStage is the Normal stage whose first clear opens function 71
// (function.lua:71 raw_open_value "2|100018"); Function 71 gates every Dorm
// command and read.
const dormSocialStage = int64(100018)

// dormSocialComments is more than one comment page so the scenario can page.
const dormSocialComments = 23

// DormSocialFixture opens the Dorm function for the driven player through the
// production I5 stage-opening owner, then declares the peer social rows the
// single-client stock scenario would otherwise need a second client to make.
// shortcut: the peer rows are fixture data written through the Dorm store, not
// proof of the peer's stock request path; that path is proven natively.
func DormSocialFixture(ctx context.Context, databaseURL, accountID, peerAccountID string) error {
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-vc-dorm-social-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var owner, peer identity.PlayerID
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&owner); err != nil {
		return fmt.Errorf("dorm social fixture owner: %w", err)
	}
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, peerAccountID).Scan(&peer); err != nil {
		return fmt.Errorf("dorm social fixture peer: %w", err)
	}
	content := contentstore.Store{Queryer: pool}
	revision, err := content.ActiveRevision(ctx, pool)
	if err != nil {
		return err
	}
	now := time.Now().UTC()
	if err = openDormFunction(ctx, pool, revision, owner, now); err != nil {
		return err
	}
	rooms, err := (dormstore.Store{}).ListRoomsTx(ctx, pool, owner)
	if err != nil {
		return fmt.Errorf("dorm social fixture rooms: %w", err)
	}
	var house dorm.Room
	for _, room := range rooms {
		if room.ID == 1 {
			house = room
		}
	}
	if house.ID != 1 {
		return fmt.Errorf("dorm social fixture requires the birth room")
	}
	target := dorm.RoomTarget{Server: logicalserver.PlayerRegion(owner), Owner: owner, HouseID: house.ID}
	if err = target.Validate(); err != nil {
		return err
	}
	return seedPeerSocial(ctx, pool, target, peer, now)
}

func openDormFunction(ctx context.Context, pool *postgres.Pool, revision string, owner identity.PlayerID, now time.Time) error {
	ownerService := appi5.Service{Store: i5store.Store{Queryer: pool}, Content: contentstore.Store{Queryer: pool}}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		return err
	}
	defer transaction.Rollback(ctx)
	opened, err := ownerService.OpenStageFunctionsTx(ctx, transaction, owner, revision, dormSocialStage, now)
	if err != nil {
		return fmt.Errorf("dorm function opening: %w", err)
	}
	found := false
	for _, functionID := range opened {
		found = found || functionID == 71
	}
	if !found {
		return fmt.Errorf("dorm function 71 was already open or not announced by stage %d", dormSocialStage)
	}
	return transaction.Commit(ctx)
}

func seedPeerSocial(ctx context.Context, pool *postgres.Pool, target dorm.RoomTarget, peer identity.PlayerID, now time.Time) error {
	store := dormstore.Store{}
	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		return err
	}
	defer transaction.Rollback(ctx)
	praise := dorm.HousePraise{Owner: target.Owner, HouseID: target.HouseID, Actor: peer, FirstAt: now}
	if err = store.InsertPraiseTx(ctx, transaction, praise); err != nil {
		return fmt.Errorf("dorm social fixture praise: %w", err)
	}
	reactionIDs := make([]int64, 0, 2)
	for index := 1; index <= dormSocialComments; index++ {
		commentID, err := store.NextCommentIDTx(ctx, transaction)
		if err != nil {
			return err
		}
		comment := dorm.HouseComment{ID: commentID, Owner: target.Owner, HouseID: target.HouseID, Author: peer, Content: fmt.Sprintf("vc-peer-comment-%02d", index), CreatedAt: now.Add(time.Duration(index) * time.Millisecond)}
		if err = store.InsertCommentTx(ctx, transaction, comment); err != nil {
			return fmt.Errorf("dorm social fixture comment %d: %w", index, err)
		}
		if len(reactionIDs) < cap(reactionIDs) {
			reactionIDs = append(reactionIDs, commentID)
		}
	}
	for _, commentID := range reactionIDs {
		reaction := dorm.CommentReaction{CommentID: commentID, Actor: peer, FirstAt: now}
		if err = store.InsertCommentReactionTx(ctx, transaction, target, reaction); err != nil {
			return fmt.Errorf("dorm social fixture reaction %d: %w", commentID, err)
		}
	}
	return transaction.Commit(ctx)
}
