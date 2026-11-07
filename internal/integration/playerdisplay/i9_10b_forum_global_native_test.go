//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"fmt"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/nativebirth"
	app "gxb.local/backend/v2/internal/application/libraryforum"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

const forumHero = int64(1)

type forumRowState struct {
	Text      string
	CreatedAt time.Time
	UpdatedAt time.Time
	Retired   bool
	Likes     int64
}

func insertForumCommentRow(t *testing.T, p *pg.Pool, tableID, author int64, text string, createdAt time.Time) {
	t.Helper()
	exec(t, p, `INSERT INTO library_forum_comments(forum_type,table_id,author_player_id,comment,created_at,updated_at) VALUES($1,$2,$3,$4,$5,$5)`, forumHero, tableID, author, text, createdAt.UTC())
}

func insertForumReactionRow(t *testing.T, p *pg.Pool, tableID, author, viewer int64, createdAt time.Time) {
	t.Helper()
	exec(t, p, `INSERT INTO library_forum_reactions(forum_type,table_id,author_player_id,viewer_player_id,created_at) VALUES($1,$2,$3,$4,$5)`, forumHero, tableID, author, viewer, createdAt.UTC())
}

func retireForumCommentRow(t *testing.T, p *pg.Pool, tableID, author int64, at time.Time) {
	t.Helper()
	exec(t, p, `UPDATE library_forum_comments SET retired_at=$4 WHERE forum_type=$1 AND table_id=$2 AND author_player_id=$3`, forumHero, tableID, author, at.UTC())
}

func forumRow(t *testing.T, p *pg.Pool, tableID, author int64) forumRowState {
	t.Helper()
	var out forumRowState
	var retired *time.Time
	e := p.QueryRow(ctx, `SELECT comment,created_at,updated_at,retired_at,(SELECT count(*) FROM library_forum_reactions r WHERE r.forum_type=c.forum_type AND r.table_id=c.table_id AND r.author_player_id=c.author_player_id) FROM library_forum_comments c WHERE forum_type=$1 AND table_id=$2 AND author_player_id=$3`, forumHero, tableID, author).Scan(&out.Text, &out.CreatedAt, &out.UpdatedAt, &retired, &out.Likes)
	if e != nil {
		t.Fatal("forum row", author, e)
	}
	out.Retired = retired != nil
	out.CreatedAt, out.UpdatedAt = out.CreatedAt.UTC(), out.UpdatedAt.UTC()
	return out
}

func forumCounts(t *testing.T, p *pg.Pool, tableID int64) (live, retired, total int64) {
	t.Helper()
	e := p.QueryRow(ctx, `SELECT count(*) FILTER (WHERE retired_at IS NULL),count(*) FILTER (WHERE retired_at IS NOT NULL),count(*) FROM library_forum_comments WHERE forum_type=$1 AND table_id=$2`, forumHero, tableID).Scan(&live, &retired, &total)
	if e != nil {
		t.Fatal("forum counts", e)
	}
	return live, retired, total
}

func forumRetiredAuthors(t *testing.T, p *pg.Pool, tableID int64) []int64 {
	t.Helper()
	rows, e := p.Raw().Query(ctx, `SELECT author_player_id FROM library_forum_comments WHERE forum_type=$1 AND table_id=$2 AND retired_at IS NOT NULL ORDER BY author_player_id`, forumHero, tableID)
	if e != nil {
		t.Fatal("retired authors", e)
	}
	defer rows.Close()
	out := []int64{}
	for rows.Next() {
		var author int64
		if e = rows.Scan(&author); e != nil {
			t.Fatal(e)
		}
		out = append(out, author)
	}
	if e = rows.Err(); e != nil {
		t.Fatal(e)
	}
	return out
}

func forumReceiptCount(t *testing.T, p *pg.Pool) int64 {
	t.Helper()
	var count int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE domain='library-forum'`).Scan(&count); e != nil {
		t.Fatal("forum receipts", e)
	}
	return count
}

func forumBoardCount(t *testing.T, p *pg.Pool, tableID int64) int64 {
	t.Helper()
	var count int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM library_forum_boards WHERE forum_type=$1 AND table_id=$2`, forumHero, tableID).Scan(&count); e != nil {
		t.Fatal("forum boards", e)
	}
	return count
}

func seedForumAuthors(t *testing.T, p *pg.Pool, tableID int64, count int, createdAt func(index int) time.Time, revision string) []identity.PlayerID {
	t.Helper()
	out := make([]identity.PlayerID, 0, count)
	for i := 0; i < count; i++ {
		a, _ := playerRoot(t, p, 1)
		seedForumHero(t, p, a.PlayerID, tableID, revision)
		insertForumCommentRow(t, p, tableID, int64(a.PlayerID), fmt.Sprintf("seed-%d", i), createdAt(i))
		out = append(out, a.PlayerID)
	}
	return out
}

// seedForumHero gives a fixture author the roster row the production 832/833
// row composer reads. The mutation under test still runs through the service.
func seedForumHero(t *testing.T, p *pg.Pool, author identity.PlayerID, tableID int64, revision string) {
	t.Helper()
	exec(t, p, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at) VALUES($1,1,0,1,now(),now()) ON CONFLICT(player_id) DO NOTHING`, int64(author))
	exec(t, p, `INSERT INTO player_heroes(player_id,partner_id,table_id,origin_table_id,star,level,exp,color,raw_skill_1,raw_skill_2,raw_skill_3,raw_skill_4,raw_skill_5,raw_skill_6,raw_skill_id_1,raw_skill_id_2,raw_skill_id_3,raw_skill_id_4,raw_skill_id_5,raw_skill_id_6,skill_seed_policy_id,creation_content_revision,state_version,created_at,updated_at) VALUES($1,1,$2,$2,5,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,'I7C2A_V1_RAW_SKILL_SEED_V1',$3,1,now(),now()) ON CONFLICT(player_id,partner_id) DO NOTHING`, int64(author), tableID, revision)
}

// postForumComment runs the production dispatcher and returns the status.
func postForumComment(t *testing.T, p *pg.Pool, actor identity.ActorContext, text string) httpedge.Response {
	t.Helper()
	return forumDispatch(t, p, actor, 834, map[string]any{"id": int64(1), "comment": text}, op())
}

func TestI9_10BForumCapRetentionAndRepost(t *testing.T) {
	p := pool(t)
	resetForumBoards(t, p)
	rev := installed(t, p)
	first := companionActor(t, p)
	tableID := companionHero(t, p, first).TableID
	viewer := companionActor(t, p)

	oldest := bornActor(t, p)
	bornHero(t, p, oldest, rev, tableID, 1)
	edited := bornActor(t, p)
	bornHero(t, p, edited, rev, tableID, 1)

	const cap = 200
	authors := make([]identity.PlayerID, 0, cap)
	authors = append(authors, oldest.PlayerID, edited.PlayerID)
	base := time.Now().UTC().Add(-time.Hour).Truncate(time.Microsecond)
	for len(authors) < cap {
		a, _ := playerRoot(t, p, 1)
		authors = append(authors, a.PlayerID)
	}
	for index, author := range authors {
		createdAt := base.Add(time.Duration(index) * time.Second)
		if index < 3 {
			createdAt = base
		}
		insertForumCommentRow(t, p, tableID, int64(author), fmt.Sprintf("legacy-%d", index), createdAt)
	}
	insertForumReactionRow(t, p, tableID, int64(edited.PlayerID), int64(viewer.PlayerID), base)

	live, retired, total := forumCounts(t, p, tableID)
	if live != cap || retired != 0 || total != cap {
		t.Fatalf("seed live=%d retired=%d total=%d", live, retired, total)
	}

	newAuthor := companionActor(t, p)
	response := postForumComment(t, p, newAuthor, "new author")
	if response.HTTPStatus != 200 {
		t.Fatalf("new author at cap status %d body %+v", response.HTTPStatus, response.Body)
	}
	live, retired, total = forumCounts(t, p, tableID)
	if live != cap || retired != 1 || total != cap+1 {
		t.Fatalf("after cap post live=%d retired=%d total=%d", live, retired, total)
	}
	if got := forumRetiredAuthors(t, p, tableID); len(got) != 1 || got[0] != int64(oldest.PlayerID) {
		t.Fatalf("retired authors %+v want exactly oldest %d", got, oldest.PlayerID)
	}
	if state := forumRow(t, p, tableID, int64(oldest.PlayerID)); state.Text != "legacy-0" || state.Retired != true {
		t.Fatalf("oldest row changed %+v", state)
	}
	if state := forumRow(t, p, tableID, int64(newAuthor.PlayerID)); state.Text != "new author" || state.Retired || !state.CreatedAt.After(base) {
		t.Fatalf("new author row %+v", state)
	}

	before := forumRow(t, p, tableID, int64(edited.PlayerID))
	response = postForumComment(t, p, edited, "edited")
	if response.HTTPStatus != 200 {
		t.Fatalf("active edit status %d body %+v", response.HTTPStatus, response.Body)
	}
	after := forumRow(t, p, tableID, int64(edited.PlayerID))
	if !after.CreatedAt.Equal(before.CreatedAt) || after.Likes != before.Likes || after.Text != "edited" {
		t.Fatalf("active edit changed creation/likes before=%+v after=%+v", before, after)
	}
	live, retired, total = forumCounts(t, p, tableID)
	if live != cap || retired != 1 || total != cap+1 {
		t.Fatalf("active edit evicted live=%d retired=%d total=%d", live, retired, total)
	}

	insertForumReactionRow(t, p, tableID, int64(oldest.PlayerID), int64(viewer.PlayerID), base)
	before = forumRow(t, p, tableID, int64(oldest.PlayerID))
	if before.Likes != 1 || !before.Retired {
		t.Fatalf("retired oldest fixture %+v", before)
	}
	response = postForumComment(t, p, oldest, "reborn")
	if response.HTTPStatus != 200 {
		t.Fatalf("retired repost status %d body %+v", response.HTTPStatus, response.Body)
	}
	reborn := forumRow(t, p, tableID, int64(oldest.PlayerID))
	if reborn.Retired || reborn.Text != "reborn" || reborn.Likes != 0 || !reborn.CreatedAt.After(before.CreatedAt) {
		t.Fatalf("repost did not reset creation/likes/retirement %+v", reborn)
	}
	live, retired, total = forumCounts(t, p, tableID)
	if live != cap || retired != 1 || total != cap+1 {
		t.Fatalf("repost live=%d retired=%d total=%d", live, retired, total)
	}
	got := forumRetiredAuthors(t, p, tableID)
	if len(got) != 1 || got[0] != int64(authors[1]) {
		t.Fatalf("repost retired exactly one other %+v want %d", got, authors[1])
	}
	var rowsForOldest int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM library_forum_comments WHERE forum_type=$1 AND table_id=$2 AND author_player_id=$3`, forumHero, tableID, int64(oldest.PlayerID)).Scan(&rowsForOldest); e != nil || rowsForOldest != 1 {
		t.Fatalf("one stored row per author rows=%d err=%v", rowsForOldest, e)
	}
}

func TestI9_10BForumConcurrentAuthorsAndLikeRetire(t *testing.T) {
	p := pool(t)
	resetForumBoards(t, p)
	rev := installed(t, p)
	tableID := companionHero(t, p, companionActor(t, p)).TableID

	const firstWave = 6
	firstActors := make([]identity.ActorContext, firstWave)
	for i := range firstActors {
		firstActors[i] = companionActor(t, p)
	}
	responses := runConcurrentForumPosts(t, p, firstActors, "first")
	for i, response := range responses {
		if response.HTTPStatus != 200 {
			t.Fatalf("first board author %d status %d body %+v", i, response.HTTPStatus, response.Body)
		}
	}
	live, retired, total := forumCounts(t, p, tableID)
	if live != firstWave || retired != 0 || total != firstWave {
		t.Fatalf("first board live=%d retired=%d total=%d", live, retired, total)
	}
	if forumBoardCount(t, p, tableID) != 1 {
		t.Fatal("first board must create exactly one board row")
	}

	resetForumBoards(t, p)
	const seeded = 196
	base := time.Now().UTC().Add(-time.Hour).Truncate(time.Microsecond)
	seedForumAuthors(t, p, tableID, seeded, func(index int) time.Time { return base.Add(time.Duration(index) * time.Second) }, rev)
	const secondWave = 8
	secondActors := make([]identity.ActorContext, secondWave)
	for i := range secondActors {
		secondActors[i] = companionActor(t, p)
	}
	responses = runConcurrentForumPosts(t, p, secondActors, "second")
	successes := int64(0)
	for i, response := range responses {
		switch response.HTTPStatus {
		case 200:
			successes++
		case 409, 503:
		default:
			t.Fatalf("second board author %d unexpected status %d body %+v", i, response.HTTPStatus, response.Body)
		}
	}
	live, retired, total = forumCounts(t, p, tableID)
	if live > 200 {
		t.Fatalf("live rows exceeded cap: %d", live)
	}
	if live+retired != seeded+successes {
		t.Fatalf("lost or double rows live=%d retired=%d seeded=%d successes=%d", live, retired, seeded, successes)
	}
	if successes == secondWave && (live != 200 || retired != seeded+successes-200) {
		t.Fatalf("full board live=%d retired=%d successes=%d", live, retired, successes)
	}

	resetForumBoards(t, p)
	author := bornActor(t, p)
	installed(t, p)
	bornHero(t, p, author, rev, tableID, 1)
	insertForumCommentRow(t, p, tableID, int64(author.PlayerID), "target", base)
	seedForumAuthors(t, p, tableID, 199, func(index int) time.Time { return base.Add(time.Duration(index+1) * time.Second) }, rev)
	viewer := companionActor(t, p)
	poster := companionActor(t, p)

	likeOperation := op()
	start := make(chan struct{})
	var likeResponse, postResponse httpedge.Response
	var wait sync.WaitGroup
	wait.Add(2)
	go func() {
		defer wait.Done()
		<-start
		likeResponse = forumDispatch(t, p, viewer, 833, map[string]any{"player_id": int64(author.PlayerID), "table_id": tableID}, likeOperation)
	}()
	go func() {
		defer wait.Done()
		<-start
		postResponse = postForumComment(t, p, poster, "evict target")
	}()
	close(start)
	wait.Wait()
	if postResponse.HTTPStatus != 200 {
		t.Fatalf("retire poster status %d body %+v", postResponse.HTTPStatus, postResponse.Body)
	}
	if likeResponse.HTTPStatus != 200 && likeResponse.HTTPStatus != 409 {
		t.Fatalf("like versus retire status %d body %+v", likeResponse.HTTPStatus, likeResponse.Body)
	}
	target := forumRow(t, p, tableID, int64(author.PlayerID))
	if !target.Retired {
		t.Fatalf("target not retired %+v", target)
	}
	wantLikes := int64(0)
	if likeResponse.HTTPStatus == 200 {
		wantLikes = 1
	}
	if target.Likes != wantLikes {
		t.Fatalf("like versus retire likes=%d want %d (status %d)", target.Likes, wantLikes, likeResponse.HTTPStatus)
	}
	live, retired, total = forumCounts(t, p, tableID)
	if live != 200 || retired != 1 || total != 201 {
		t.Fatalf("like versus retire live=%d retired=%d total=%d", live, retired, total)
	}

	resetForumBoards(t, p)
	activeAuthor := bornActor(t, p)
	bornHero(t, p, activeAuthor, rev, tableID, 1)
	insertForumCommentRow(t, p, tableID, int64(activeAuthor.PlayerID), "active", base)
	likers := []identity.ActorContext{companionActor(t, p), companionActor(t, p)}
	likeResponses := runConcurrentForumLikes(t, p, likers, activeAuthor.PlayerID, tableID)
	for i, response := range likeResponses {
		if response.HTTPStatus != 200 {
			t.Fatalf("concurrent liker %d status %d body %+v", i, response.HTTPStatus, response.Body)
		}
	}
	if state := forumRow(t, p, tableID, int64(activeAuthor.PlayerID)); state.Likes != 2 {
		t.Fatalf("two viewers must add two likes got %+v", state)
	}
}

func runConcurrentForumPosts(t *testing.T, p *pg.Pool, actors []identity.ActorContext, label string) []httpedge.Response {
	responses := make([]httpedge.Response, len(actors))
	start := make(chan struct{})
	var wait sync.WaitGroup
	wait.Add(len(actors))
	for index := range actors {
		go func(index int) {
			defer wait.Done()
			<-start
			responses[index] = forumDispatch(t, p, actors[index], 834, map[string]any{"id": int64(1), "comment": label}, op())
		}(index)
	}
	close(start)
	wait.Wait()
	return responses
}

func runConcurrentForumLikes(t *testing.T, p *pg.Pool, actors []identity.ActorContext, author identity.PlayerID, tableID int64) []httpedge.Response {
	responses := make([]httpedge.Response, len(actors))
	start := make(chan struct{})
	var wait sync.WaitGroup
	wait.Add(len(actors))
	for index := range actors {
		go func(index int) {
			defer wait.Done()
			<-start
			responses[index] = forumDispatch(t, p, actors[index], 833, map[string]any{"player_id": int64(author), "table_id": tableID}, op())
		}(index)
	}
	close(start)
	wait.Wait()
	return responses
}

func TestI9_10BForumReceiptReplayAcrossRetirement(t *testing.T) {
	p := pool(t)
	resetForumBoards(t, p)
	rev := installed(t, p)
	tableID := companionHero(t, p, companionActor(t, p)).TableID
	base := time.Now().UTC().Add(-time.Hour).Truncate(time.Microsecond)

	author := bornActor(t, p)
	bornHero(t, p, author, rev, tableID, 1)
	insertForumCommentRow(t, p, tableID, int64(author.PlayerID), "target", base)
	seedForumAuthors(t, p, tableID, 199, func(index int) time.Time { return base.Add(time.Duration(index+1) * time.Second) }, rev)
	viewer := companionActor(t, p)
	poster := companionActor(t, p)

	editOperation := op()
	response := forumDispatch(t, p, author, 834, map[string]any{"id": int64(1), "comment": "edited"}, editOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("edit status %d body %+v", response.HTTPStatus, response.Body)
	}
	likeOperation := op()
	response = forumDispatch(t, p, viewer, 833, map[string]any{"player_id": int64(author.PlayerID), "table_id": tableID}, likeOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("like status %d body %+v", response.HTTPStatus, response.Body)
	}
	likeReceipt := requireForumReceipt(t, p, viewer, app.Like, likeOperation, app.Command{Family: app.Like, ForumType: forumHero, TableID: tableID, Author: int64(author.PlayerID)})
	editReceipt := requireForumReceipt(t, p, author, app.Comment, editOperation, app.Command{Family: app.Comment, ForumType: forumHero, Instance: 1, Text: "edited"})
	if likeReceipt.OperationClass != app.OperationClass || likeReceipt.ResultSchema != app.ResultSchema || likeReceipt.PolicyVersion != app.LifecyclePolicy {
		t.Fatalf("like receipt provenance %+v", likeReceipt)
	}
	if editReceipt.OperationClass != app.OperationClass || editReceipt.ResultSchema != app.ResultSchema || editReceipt.PolicyVersion != app.LifecyclePolicy {
		t.Fatalf("edit receipt provenance %+v", editReceipt)
	}

	response = postForumComment(t, p, poster, "evict author")
	if response.HTTPStatus != 200 {
		t.Fatalf("evict status %d body %+v", response.HTTPStatus, response.Body)
	}
	receiptsBefore := forumReceiptCount(t, p)
	if state := forumRow(t, p, tableID, int64(author.PlayerID)); !state.Retired || state.Text != "edited" {
		t.Fatalf("author eviction %+v", state)
	}
	live, retired, total := forumCounts(t, p, tableID)
	if live != 200 || retired != 1 || total != 201 {
		t.Fatalf("after eviction live=%d retired=%d total=%d", live, retired, total)
	}

	response = forumDispatch(t, p, viewer, 833, map[string]any{"player_id": int64(author.PlayerID), "table_id": tableID}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("inactive like status %d body %+v", response.HTTPStatus, response.Body)
	}

	replay := forumDispatch(t, p, author, 834, map[string]any{"id": int64(1), "comment": "edited"}, editOperation)
	if replay.HTTPStatus != 200 {
		t.Fatalf("comment replay status %d body %+v", replay.HTTPStatus, replay.Body)
	}
	if state := forumRow(t, p, tableID, int64(author.PlayerID)); !state.Retired || state.Text != "edited" {
		t.Fatalf("comment replay resurrected row %+v", state)
	}
	live, retired, total = forumCounts(t, p, tableID)
	if live != 200 || retired != 1 || total != 201 {
		t.Fatalf("comment replay evicted again live=%d retired=%d total=%d", live, retired, total)
	}
	if got := forumReceiptCount(t, p); got != receiptsBefore {
		t.Fatalf("comment replay wrote receipt %d want %d", got, receiptsBefore)
	}

	repost := postForumComment(t, p, author, "reborn")
	if repost.HTTPStatus != 200 {
		t.Fatalf("repost status %d body %+v", repost.HTTPStatus, repost.Body)
	}
	if state := forumRow(t, p, tableID, int64(author.PlayerID)); state.Retired || state.Likes != 0 || state.Text != "reborn" {
		t.Fatalf("repost did not clear old likes %+v", state)
	}
	receiptsBefore = forumReceiptCount(t, p)
	replay = forumDispatch(t, p, viewer, 833, map[string]any{"player_id": int64(author.PlayerID), "table_id": tableID}, likeOperation)
	if replay.HTTPStatus != 200 {
		t.Fatalf("like replay status %d body %+v", replay.HTTPStatus, replay.Body)
	}
	rows := forumRowsOf(t, replay.Body)
	if len(rows) == 0 || rows[0]["like"] != int64(1) {
		t.Fatalf("like replay must return stored snapshot %+v", rows)
	}
	if state := forumRow(t, p, tableID, int64(author.PlayerID)); state.Likes != 0 || state.Retired {
		t.Fatalf("like replay toggled current likes %+v", state)
	}
	if got := forumReceiptCount(t, p); got != receiptsBefore {
		t.Fatalf("like replay wrote receipt %d want %d", got, receiptsBefore)
	}
}

func requireForumReceipt(t *testing.T, p *pg.Pool, actor identity.ActorContext, family string, opCtx operation.Context, command app.Command) receipt.Receipt {
	t.Helper()
	id := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprintf("%d", int64(actor.PlayerID)), Domain: "library-forum", Operation: family, SemanticKey: opCtx.ID.String()}
	stored, ok, e := (kernelstore.Store{}).FindTx(ctx, p, id)
	if e != nil || !ok {
		t.Fatalf("forum receipt %s %v %v", family, ok, e)
	}
	want, e := receipt.FingerprintRequest(map[string]any{"family": command.Family, "forum_type": command.ForumType, "table_id": command.TableID, "author": command.Author, "instance": command.Instance, "comment": command.Text, "policy": app.LifecyclePolicy})
	if e != nil {
		t.Fatal(e)
	}
	if !bytes.Equal(stored.RequestFingerprint[:], want[:]) {
		t.Fatalf("forum receipt fingerprint changed %x want %x", stored.RequestFingerprint, want)
	}
	if stored.ActorAccountUID != string(actor.AccountUID) || stored.ContextID != actor.ContextID.UUID() || stored.OperationStartedAt.UnixMicro() != opCtx.StartedAt.UnixMicro() {
		t.Fatalf("forum receipt provenance %+v", stored)
	}
	return stored
}

func TestI9_10BForumCrossServerAuthorRegion(t *testing.T) {
	p := pool(t)
	resetForumBoards(t, p)
	installed(t, p)
	serverOne := companionActor(t, p)
	serverTwo, account := playerRoot(t, p, 2)
	if e := nativebirth.Persist(ctx, p, account, serverTwo.LogicalServerID, serverTwo.PlayerID); e != nil {
		t.Fatal(e)
	}
	tableID := companionHero(t, p, serverOne).TableID
	response := postForumComment(t, p, serverTwo, "server two")
	if response.HTTPStatus != 200 {
		t.Fatalf("server two post status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = forumCall(t, p, serverOne, 833, map[string]any{"player_id": int64(serverTwo.PlayerID), "table_id": tableID})
	if response.HTTPStatus != 200 {
		t.Fatalf("cross-server like status %d body %+v", response.HTTPStatus, response.Body)
	}
	rows := forumRowsOf(t, response.Body)
	if len(rows) != 1 || rows[0]["player_id"] != int64(serverTwo.PlayerID) || rows[0]["region"] != int64(2) {
		t.Fatalf("actual author region must be server two: %+v", rows)
	}
}
