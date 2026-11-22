//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// MID 832 (forum page) keeps one snapshot while the author's directory row is
// committed by another transaction.
func TestC13BReadOnlyLibraryForum832Native(t *testing.T) {
	database := pool(t)
	resetForumBoards(t, database)
	installed(t, database)
	author := companionActor(t, database)
	viewer := companionActor(t, database)
	tableID := companionHero(t, database, author).TableID
	if response := forumDispatch(t, database, author, 834, map[string]any{"id": int64(1), "comment": "snapshot"}, op()); response.HTTPStatus != 200 {
		t.Fatalf("834 status %d body %+v", response.HTTPStatus, response.Body)
	}
	profile, found, err := (i4store.PlayerDirectoryReader{}).ProfileTx(ctx, database, author.PlayerID)
	if err != nil || !found {
		t.Fatalf("directory profile %v %v", found, err)
	}
	service := libraryForumService(database)
	gate := newSnapshotGate(database)
	service.Reads = tx.Runner{DB: gate}
	var response httpedge.Response
	err = runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE player_directory_profiles SET name='snapshot-writer' WHERE player_id=$1`, int64(author.PlayerID))
		},
		func(c context.Context) error {
			dispatcher := stockruntime.LibraryForumDispatcher{Authority: fixedLibraryAuthority{actor: viewer}, Service: service}
			response = dispatcher.Dispatch(c, nativeDispatch(viewer, 832, map[string]any{"start_pos": int64(1), "end_pos": int64(50), "table_id": tableID}, op()))
			return nil
		})
	if err != nil {
		t.Fatalf("832 read: %v", err)
	}
	if response.HTTPStatus != 200 {
		t.Fatalf("832 status %d body %+v", response.HTTPStatus, response.Body)
	}
	rows := forumRowsOf(t, response.Body)
	if len(rows) != 1 {
		t.Fatalf("832 rows %+v", rows)
	}
	row := rows[0]
	if row["comment"] != "snapshot" || row["player_name"] != profile.Name {
		t.Fatalf("832 mixed a concurrent commit into the reply: %+v", row)
	}
	for _, key := range []string{"player_id", "player_name", "avatar_id", "avatar_frame_id", "region", "player_lev", "conquer_lev", "conquer_loop_id", "comment", "like", "is_commented", "table_id", "hero_lev", "hero_color", "hero_star"} {
		if _, present := row[key]; !present {
			t.Fatalf("832 reply lost %s: %+v", key, row)
		}
	}
	var current string
	if err := database.QueryRow(ctx, `SELECT name FROM player_directory_profiles WHERE player_id=$1`, int64(author.PlayerID)).Scan(&current); err != nil {
		t.Fatal(err)
	}
	if current != "snapshot-writer" {
		t.Fatalf("concurrent write did not commit: %q", current)
	}
}
