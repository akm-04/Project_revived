//go:build postgres

package dormstore_test

import (
	"context"
	"os"
	"sort"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	domain "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func socialNativeDSN(t *testing.T) string {
	t.Helper()
	dsn := os.Getenv("GXB_C10S_DSN")
	if dsn == "" {
		t.Skip("GXB_C10S_DSN requires a migrated c10s database")
	}
	return dsn
}

func socialNativePool(t *testing.T) *pg.Pool {
	t.Helper()
	pool, err := pg.Open(context.Background(), socialNativeDSN(t), pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "i9-10c-social"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func socialFixture(t *testing.T, pool *pg.Pool, players ...identity.PlayerID) time.Time {
	t.Helper()
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	seedPlayers(t, pool, 1, players...)
	for _, player := range players {
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_dorm_roots(player_id,next_house_id,state_version,created_at,updated_at) VALUES($1,2,1,$2,$2) ON CONFLICT DO NOTHING`, int64(player), now); err != nil {
			t.Fatal(err)
		}
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_dorm_rooms(player_id,house_id,table_id,house_type,creation_revision,floor,position,comfort,expansion_level,state_version,furniture_record,created_at,updated_at) VALUES($1,1,1000001,1,repeat('a',64),1,1,0,0,1,'{}',$2,$2) ON CONFLICT DO NOTHING`, int64(player), now); err != nil {
			t.Fatal(err)
		}
	}
	t.Cleanup(func() {
		for _, player := range players {
			cleanup, err := pool.Begin(context.Background(), tx.Options{})
			if err != nil {
				t.Error(err)
				return
			}
			for _, statement := range []string{
				`DELETE FROM player_dorm_comment_reactions WHERE player_id=$1`,
				`DELETE FROM player_dorm_comments WHERE player_id=$1`,
				`DELETE FROM player_dorm_praises WHERE player_id=$1`,
				`DELETE FROM player_dorm_room_social WHERE player_id=$1`,
				`DELETE FROM player_dorm_rooms WHERE player_id=$1`,
				`DELETE FROM player_dorm_roots WHERE player_id=$1`,
			} {
				if _, err = cleanup.Exec(context.Background(), statement, int64(player)); err != nil {
					cleanup.Rollback(context.Background())
					t.Error(err)
					return
				}
			}
			if err = cleanup.Commit(context.Background()); err != nil {
				t.Error(err)
			}
		}
	})
	return now
}

func TestDormSocialNativePraisePageOrderAndConcurrentIdempotence(t *testing.T) {
	pool := socialNativePool(t)
	ctx := context.Background()
	owner, actorA, actorB := identity.PlayerID(125701), identity.PlayerID(125702), identity.PlayerID(125703)
	now := socialFixture(t, pool, owner, actorA, actorB)
	store := dormstore.Store{Queryer: pool}
	target := domain.RoomTarget{Server: 1, Owner: owner, HouseID: 1}
	var wait sync.WaitGroup
	errs := make(chan error, 2)
	insert := func(actor identity.PlayerID, at time.Time) {
		defer wait.Done()
		// The production runner retries definite serialization aborts; this test
		// mirrors that bounded retry so the root lock, not a lost commit, decides.
		for attempt := 0; attempt < 8; attempt++ {
			err := func() error {
				transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
				if err != nil {
					return err
				}
				defer transaction.Rollback(ctx)
				if _, err = store.LockRootTx(ctx, transaction, owner); err != nil {
					return err
				}
				if err = store.InsertPraiseTx(ctx, transaction, domain.HousePraise{Owner: owner, HouseID: 1, Actor: actor, FirstAt: at}); err != nil {
					return err
				}
				return transaction.Commit(ctx)
			}()
			if err == nil {
				errs <- nil
				return
			}
			last := err
			if attempt == 7 {
				errs <- last
				return
			}
		}
	}
	wait.Add(2)
	go insert(actorA, now.Add(time.Second))
	go insert(actorB, now.Add(2*time.Second))
	wait.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	if count, err := store.PraiseCountTx(ctx, pool, target); err != nil || count != 2 {
		t.Fatal(count, err)
	}
	page, err := store.PagePraisesTx(ctx, pool, target, 0, 1)
	if err != nil || len(page) != 1 || page[0].Actor != actorB {
		t.Fatalf("newest first: %+v %v", page, err)
	}
	page, err = store.PagePraisesTx(ctx, pool, target, 1, 20)
	if err != nil || len(page) != 1 || page[0].Actor != actorA {
		t.Fatalf("offset page: %+v %v", page, err)
	}
	duplicate, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	duplicateErr := store.InsertPraiseTx(ctx, duplicate, domain.HousePraise{Owner: owner, HouseID: 1, Actor: actorA, FirstAt: now})
	duplicate.Rollback(ctx)
	if duplicateErr == nil {
		t.Fatal("duplicate praise accepted by the owner unique key")
	}
	praises, err := store.ActorPraisesTx(ctx, pool, owner, actorA)
	if err != nil || praises[1].Actor != actorA {
		t.Fatal(praises, err)
	}
}

func TestDormSocialNativeCommentsLikesDeletePruneAndCap(t *testing.T) {
	pool := socialNativePool(t)
	ctx := context.Background()
	owner, author, viewer := identity.PlayerID(125711), identity.PlayerID(125712), identity.PlayerID(125713)
	now := socialFixture(t, pool, owner, author, viewer)
	store := dormstore.Store{Queryer: pool}
	target := domain.RoomTarget{Server: 1, Owner: owner, HouseID: 1}
	insert := func(content string, at time.Time) domain.HouseComment {
		var comment domain.HouseComment
		socialInTx(t, pool, func(transaction tx.Tx) {
			id, err := store.NextCommentIDTx(ctx, transaction)
			if err != nil {
				t.Fatal(err)
			}
			comment = domain.HouseComment{ID: id, Owner: owner, HouseID: 1, Author: author, Content: content, CreatedAt: at}
			if err = store.InsertCommentTx(ctx, transaction, comment); err != nil {
				t.Fatal(err)
			}
		})
		return comment
	}
	older := insert("older", now.Add(time.Second))
	newer := insert("newer", now.Add(2*time.Second))
	reaction := domain.CommentReaction{CommentID: newer.ID, Actor: viewer, FirstAt: now.Add(3 * time.Second)}
	socialInTx(t, pool, func(transaction tx.Tx) {
		if err := store.InsertCommentReactionTx(ctx, transaction, target, reaction); err != nil {
			t.Fatal(err)
		}
	})
	rows, err := store.ListLiveCommentsTx(ctx, pool, target, viewer)
	if err != nil || len(rows) != 2 || rows[0].Comment.ID != newer.ID || rows[0].Likes != 1 || !rows[0].HasReacted || rows[1].Comment.ID != older.ID {
		t.Fatalf("listed comments: %+v %v", rows, err)
	}
	socialInTx(t, pool, func(transaction tx.Tx) {
		if err = store.MarkCommentDeletedTx(ctx, transaction, domain.HouseComment{ID: newer.ID, Owner: owner, HouseID: 1, DeletedAt: timePointer(now.Add(4 * time.Second))}); err != nil {
			t.Fatal(err)
		}
		if err = store.DeleteCommentReactionsTx(ctx, transaction, target, newer.ID); err != nil {
			t.Fatal(err)
		}
	})
	rows, err = store.ListLiveCommentsTx(ctx, pool, target, viewer)
	if err != nil || len(rows) != 1 || rows[0].Comment.ID != older.ID {
		t.Fatalf("deleted comment still visible: %+v %v", rows, err)
	}
	if likes, err := store.CommentLikesTx(ctx, pool, target, newer.ID); err != nil || likes != 0 {
		t.Fatal(likes, err)
	}
	if _, err = pool.Raw().Exec(ctx, `INSERT INTO player_dorm_comments(comment_id,player_id,house_id,author_player_id,content,created_at) SELECT 800000000+n,$1,1,$2,'bulk'||n,$3 FROM generate_series(1,200) n`, int64(owner), int64(author), now); err != nil {
		t.Fatal(err)
	}
	rows, err = store.ListLiveCommentsTx(ctx, pool, target, viewer)
	if err != nil || len(rows) != 201 {
		t.Fatalf("live cap read: %d %v", len(rows), err)
	}
	pruneID := rows[len(rows)-1].Comment.ID
	socialInTx(t, pool, func(transaction tx.Tx) {
		if err = store.DeleteCommentReactionsTx(ctx, transaction, target, pruneID); err != nil {
			t.Fatal(err)
		}
		if err = store.DeleteCommentTx(ctx, transaction, target, pruneID); err != nil {
			t.Fatal(err)
		}
	})
	rows, err = store.ListLiveCommentsTx(ctx, pool, target, viewer)
	if err != nil || len(rows) != 200 {
		t.Fatalf("pruned comment retained: %d %v", len(rows), err)
	}
}

func TestDormSocialNativeHiddenRoomExcludedFromVisitCandidates(t *testing.T) {
	pool := socialNativePool(t)
	ctx := context.Background()
	owner, other := identity.PlayerID(125721), identity.PlayerID(125722)
	now := socialFixture(t, pool, owner, other)
	store := dormstore.Store{Queryer: pool}
	target := domain.RoomTarget{Server: 1, Owner: owner, HouseID: 1}
	visitable, err := store.VisitablePlayersTx(ctx, pool, []int64{int64(owner), int64(other)})
	if err != nil || !visitable[int64(owner)] {
		t.Fatal(visitable, err)
	}
	socialInTx(t, pool, func(transaction tx.Tx) {
		if err = store.SaveSocialRoomTx(ctx, transaction, domain.SocialRoomState{Target: target, Hidden: true, StateVersion: 1, UpdatedAt: now}, 0); err != nil {
			t.Fatal(err)
		}
	})
	visitable, err = store.VisitablePlayersTx(ctx, pool, []int64{int64(owner)})
	if err != nil || visitable[int64(owner)] {
		t.Fatalf("hidden room remained visitable: %+v %v", visitable, err)
	}
	states, err := store.ListSocialRoomsTx(ctx, pool, owner)
	if err != nil || !states[1].Hidden {
		t.Fatal(states, err)
	}
}

func timePointer(at time.Time) *time.Time { return &at }

func socialInTx(t *testing.T, pool *pg.Pool, action func(tx.Tx)) {
	t.Helper()
	transaction, err := pool.Begin(context.Background(), tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(context.Background())
	action(transaction)
	if err = transaction.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
}

func TestDormSocialNativePageBounds(t *testing.T) {
	pool := socialNativePool(t)
	ctx := context.Background()
	owner := identity.PlayerID(125731)
	actors := []identity.PlayerID{125732, 125733}
	seedPlayers(t, pool, 1, actors...)
	now := socialFixture(t, pool, owner)
	store := dormstore.Store{Queryer: pool}
	target := domain.RoomTarget{Server: 1, Owner: owner, HouseID: 1}
	for index, actor := range actors {
		socialInTx(t, pool, func(transaction tx.Tx) {
			if err := store.InsertPraiseTx(ctx, transaction, domain.HousePraise{Owner: owner, HouseID: 1, Actor: actor, FirstAt: now.Add(time.Duration(index) * time.Second)}); err != nil {
				t.Fatal(err)
			}
		})
	}
	rows, err := store.PagePraisesTx(ctx, pool, target, 0, 1)
	if err != nil || len(rows) != 1 || rows[0].Actor != actors[1] {
		t.Fatalf("bounded praise page: %+v %v", rows, err)
	}
	rows, err = store.PagePraisesTx(ctx, pool, target, 2, 1)
	if err != nil || len(rows) != 0 {
		t.Fatalf("start past total: %+v %v", rows, err)
	}
	ids := make([]int64, 0, 2)
	for _, actor := range actors {
		ids = append(ids, int64(actor))
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	empty, err := store.VisitablePlayersTx(ctx, pool, ids)
	if err != nil || len(empty) != 0 {
		t.Fatalf("players without rooms reported visitable: %v %v", empty, err)
	}
	if _, err = pool.Raw().Exec(ctx, `INSERT INTO player_dorm_praises(player_id,house_id,actor_player_id,first_at) VALUES($1,1,$1,$2)`, int64(owner), now); err == nil {
		t.Fatal("self praise accepted by schema")
	}
}
