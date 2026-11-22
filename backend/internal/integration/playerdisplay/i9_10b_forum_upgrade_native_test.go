//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"reflect"
	"runtime"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	app "gxb.local/backend/v2/internal/application/libraryforum"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

// TestI9_10BForumLegacy111To118Upgrade proves the real d1f521e schema-111 forum
// data survives the 118 global migration and that an old receipt replays
// without writing. It needs GXB_I9_10B_LEGACY_MIGRATIONS pointing at the
// read-only d1f521e worktree's migrations directory.
func TestI9_10BForumLegacy111To118Upgrade(t *testing.T) {
	legacy := os.Getenv("GXB_I9_10B_LEGACY_MIGRATIONS")
	if legacy == "" {
		t.Skip("GXB_I9_10B_LEGACY_MIGRATIONS not set")
	}
	base := os.Getenv("GXB_I7B6A_DSN")
	if base == "" {
		t.Fatal("native DSN required")
	}
	dsn, cleanup := disposableNativeDatabase(t, base, "upgrade")
	defer cleanup()
	runTool(t, "goose", "-dir", legacy, "postgres", dsn, "up")
	p := openNativePool(t, dsn)
	defer p.Close()

	tableID := int64(4242)
	baseTime := time.Now().UTC().Add(-2 * time.Hour).Truncate(time.Microsecond)
	const legacyComments = 205
	authors := make([]identity.PlayerID, 0, legacyComments)
	for index := 0; index < legacyComments; index++ {
		a := forumLegacyActor(t, p, 1)
		authors = append(authors, a.PlayerID)
		forumLegacyComment(t, p, a.PlayerID, tableID, fmt.Sprintf("legacy-%d", index), baseTime.Add(time.Duration(index)*time.Second))
	}
	likedAuthor := authors[0]
	likedViewer := forumLegacyActor(t, p, 1)
	forumLegacyReaction(t, p, likedAuthor, likedViewer.PlayerID, tableID, baseTime)

	serverTwo := forumLegacyActor(t, p, 2)
	otherBoard := int64(4243)
	forumLegacyComment(t, p, serverTwo.PlayerID, otherBoard, "server-two", baseTime)

	likeCommand := app.Command{Family: app.Like, ForumType: forumHero, TableID: tableID, Author: int64(likedAuthor)}
	likeResult := app.Result{
		Schema:      app.ResultSchema,
		Command:     likeCommand,
		Actor:       durableForumActor(likedViewer),
		OperationID: ids.UUID{},
		DecisionAt:  baseTime.Add(time.Minute),
		TableID:     tableID,
		Rows: []app.Row{{
			PlayerID: int64(likedAuthor), PlayerName: "legacy", AvatarID: 110001001, Region: int64(logicalserver.PlayerRegion(likedAuthor)),
			PlayerLevel: 1, ConquerLoopID: 1, HeroLevel: 1, HeroColor: 1, HeroStar: 5, Comment: "legacy-0", Likes: 1, ViewerLiked: true, TableID: tableID,
		}},
	}
	replayOperation := forumLegacyReceipt(t, p, likedViewer, likeCommand, &likeResult)

	commentHashBefore := forumCommentHash(t, p, tableID)
	reactionHashBefore := forumReactionHash(t, p, tableID)
	receiptCountBefore := forumReceiptCount(t, p)
	commentsBefore, reactionsBefore := forumRawCounts(t, p)

	runTool(t, "goose", "-dir", migrationsRoot(t), "postgres", dsn, "up")

	if got := forumCommentHash(t, p, tableID); got != commentHashBefore {
		t.Fatalf("legacy comment text/time changed %s want %s", got, commentHashBefore)
	}
	if got := forumReactionHash(t, p, tableID); got != reactionHashBefore {
		t.Fatalf("legacy reactions changed %s want %s", got, reactionHashBefore)
	}
	commentsAfter, reactionsAfter := forumRawCounts(t, p)
	if commentsAfter != commentsBefore || reactionsAfter != reactionsBefore {
		t.Fatalf("migration deleted rows comments %d->%d reactions %d->%d", commentsBefore, commentsAfter, reactionsBefore, reactionsAfter)
	}

	live, retired, total := forumCounts(t, p, tableID)
	if live != 200 || retired != legacyComments-200 || total != legacyComments {
		t.Fatalf("retention live=%d retired=%d total=%d", live, retired, total)
	}
	wantRetired := make([]int64, 0, legacyComments-200)
	for _, author := range authors[:legacyComments-200] {
		wantRetired = append(wantRetired, int64(author))
	}
	if got := forumRetiredAuthors(t, p, tableID); !reflect.DeepEqual(got, wantRetired) {
		t.Fatalf("deterministic retention %v want %v", got, wantRetired)
	}
	if got := forumRetiredAuthors(t, p, otherBoard); len(got) != 0 {
		t.Fatalf("board under cap must stay fully live %v", got)
	}
	var violations int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM library_forum_comments WHERE retired_at IS NOT NULL AND retired_at < created_at`).Scan(&violations); e != nil || violations != 0 {
		t.Fatalf("retirement ordering violations=%d err=%v", violations, e)
	}
	if e := p.QueryRow(ctx, `SELECT count(*) FROM library_forum_reactions r LEFT JOIN library_forum_comments c ON c.forum_type=r.forum_type AND c.table_id=r.table_id AND c.author_player_id=r.author_player_id WHERE c.author_player_id IS NULL`).Scan(&violations); e != nil || violations != 0 {
		t.Fatalf("foreign key integrity violations=%d err=%v", violations, e)
	}
	if e := p.QueryRow(ctx, `SELECT count(*) FROM (SELECT forum_type,table_id,author_player_id FROM library_forum_comments GROUP BY 1,2,3 HAVING count(*)>1) d`).Scan(&violations); e != nil || violations != 0 {
		t.Fatalf("author uniqueness violations=%d err=%v", violations, e)
	}
	if e := p.QueryRow(ctx, `SELECT count(*) FROM library_forum_boards`).Scan(&violations); e != nil || violations < 2 {
		t.Fatalf("board rows=%d err=%v", violations, e)
	}
	var legacyColumn int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM information_schema.columns WHERE table_name='library_forum_comments' AND column_name='logical_server_id'`).Scan(&legacyColumn); e != nil || legacyColumn != 0 {
		t.Fatalf("legacy scope column survived %d %v", legacyColumn, e)
	}

	service := libraryForumService(p)
	out, e := service.Command(ctx, mustForumActor(t, likeResult.Actor), likeCommand, replayOperation)
	if e != nil {
		t.Fatalf("old receipt replay %v", e)
	}
	if !reflect.DeepEqual(out, likeResult) {
		t.Fatalf("old receipt replay changed result %+v want %+v", out, likeResult)
	}
	if got := forumReceiptCount(t, p); got != receiptCountBefore {
		t.Fatalf("replay wrote receipt %d want %d", got, receiptCountBefore)
	}
	if c, r := forumRawCounts(t, p); c != commentsAfter || r != reactionsAfter {
		t.Fatalf("replay wrote forum rows comments %d->%d reactions %d->%d", commentsAfter, c, reactionsAfter, r)
	}
	if state := forumRow(t, p, tableID, int64(likedAuthor)); !state.Retired || state.Likes != 1 {
		t.Fatalf("stored snapshot must show the now-retired row without mutation %+v", state)
	}
}

func TestI9_10BForumLegacyMismatchAborts(t *testing.T) {
	legacy := os.Getenv("GXB_I9_10B_LEGACY_MIGRATIONS")
	if legacy == "" {
		t.Skip("GXB_I9_10B_LEGACY_MIGRATIONS not set")
	}
	base := os.Getenv("GXB_I7B6A_DSN")
	if base == "" {
		t.Fatal("native DSN required")
	}
	dsn, cleanup := disposableNativeDatabase(t, base, "mismatch")
	defer cleanup()
	runTool(t, "goose", "-dir", legacy, "postgres", dsn, "up")
	p := openNativePool(t, dsn)
	defer p.Close()

	author := forumLegacyActor(t, p, 1)
	if _, e := p.Raw().Exec(ctx, `INSERT INTO library_forum_comments(logical_server_id,forum_type,table_id,author_player_id,comment,created_at,updated_at) VALUES(2,1,7777,$1,'bad',now(),now())`, int64(author.PlayerID)); e != nil {
		t.Fatal(e)
	}
	command := osexec.Command("goose", "-dir", migrationsRoot(t), "postgres", dsn, "up")
	if output, e := command.CombinedOutput(); e == nil {
		t.Fatalf("mismatched legacy author must abort migration: %s", output)
	}
	var column, rows, boards int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM information_schema.columns WHERE table_name='library_forum_comments' AND column_name='logical_server_id'`).Scan(&column); e != nil || column != 1 {
		t.Fatalf("aborted migration dropped legacy column %d %v", column, e)
	}
	if e := p.QueryRow(ctx, `SELECT count(*) FROM information_schema.columns WHERE table_name='library_forum_comments' AND column_name='retired_at'`).Scan(&rows); e != nil || rows != 0 {
		t.Fatalf("aborted migration added retired_at %d %v", rows, e)
	}
	if e := p.QueryRow(ctx, `SELECT count(*) FROM library_forum_comments WHERE table_id=7777`).Scan(&rows); e != nil || rows != 1 {
		t.Fatalf("aborted migration changed rows %d %v", rows, e)
	}
	if e := p.QueryRow(ctx, `SELECT count(*) FROM information_schema.tables WHERE table_name='library_forum_boards'`).Scan(&boards); e != nil || boards != 0 {
		t.Fatalf("aborted migration created board table %d %v", boards, e)
	}
}

func forumLegacyActor(t *testing.T, p *pg.Pool, server identity.LogicalServerID) identity.ActorContext {
	t.Helper()
	actor, _ := playerRoot(t, p, server)
	return actor
}

func forumLegacyComment(t *testing.T, p *pg.Pool, author identity.PlayerID, tableID int64, text string, at time.Time) {
	t.Helper()
	if _, e := p.Raw().Exec(ctx, `INSERT INTO library_forum_comments(logical_server_id,forum_type,table_id,author_player_id,comment,created_at,updated_at) VALUES($1,1,$2,$3,$4,$5,$5)`, int64(logicalserver.PlayerRegion(author)), tableID, int64(author), text, at.UTC()); e != nil {
		t.Fatal(e)
	}
}

func forumLegacyReaction(t *testing.T, p *pg.Pool, author, viewer identity.PlayerID, tableID int64, at time.Time) {
	t.Helper()
	if _, e := p.Raw().Exec(ctx, `INSERT INTO library_forum_reactions(logical_server_id,forum_type,table_id,author_player_id,viewer_player_id,created_at) VALUES($1,1,$2,$3,$4,$5)`, int64(logicalserver.PlayerRegion(author)), tableID, int64(author), int64(viewer), at.UTC()); e != nil {
		t.Fatal(e)
	}
}

func durableForumActor(a identity.ActorContext) app.DurableActor {
	return app.DurableActor{Account: a.AccountID.UUID(), Session: a.SessionID.UUID(), Context: a.ContextID.UUID(), AccountUID: string(a.AccountUID), Server: int32(a.LogicalServerID), Player: int64(a.PlayerID), Generation: a.ContextGeneration, SessionVersion: a.SessionLivenessVersion, ContextVersion: a.ContextLivenessVersion}
}

func mustForumActor(t *testing.T, d app.DurableActor) identity.ActorContext {
	t.Helper()
	a, e := d.Actor()
	if e != nil {
		t.Fatal(e)
	}
	return a
}

// forumLegacyReceipt writes the receipt the schema-111 service would have
// written: same class, schema, policy, fingerprint and stored result payload.
func forumLegacyReceipt(t *testing.T, p *pg.Pool, actor identity.ActorContext, command app.Command, result *app.Result) operation.Context {
	t.Helper()
	policies, e := policy.NewSet(policy.Ref{Name: "forum", Version: app.LifecyclePolicy})
	if e != nil {
		t.Fatal(e)
	}
	opCtx, e := (operation.Factory{Clock: systemForumClock{}}).New(policies)
	if e != nil {
		t.Fatal(e)
	}
	result.OperationID = opCtx.ID
	result.Entropy = opCtx.EntropySeed
	raw, e := json.Marshal(result)
	if e != nil {
		t.Fatal(e)
	}
	fingerprint, e := receipt.FingerprintRequest(map[string]any{"family": command.Family, "forum_type": command.ForumType, "table_id": command.TableID, "author": command.Author, "instance": command.Instance, "comment": command.Text, "policy": app.LifecyclePolicy})
	if e != nil {
		t.Fatal(e)
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprintf("%d", int64(actor.PlayerID)), Domain: "library-forum", Operation: command.Family, SemanticKey: opCtx.ID.String()}
	stored, e := receipt.New(opCtx, id, app.OperationClass, app.ResultSchema, raw, fingerprint)
	if e != nil {
		t.Fatal(e)
	}
	stored.ActorAccountUID = string(actor.AccountUID)
	stored.ContextID = actor.ContextID.UUID()
	stored.PolicyVersion = app.LifecyclePolicy
	if e = stored.Validate(); e != nil {
		t.Fatal(e)
	}
	refs, e := json.Marshal(stored.OperationPolicyRefs)
	if e != nil {
		t.Fatal(e)
	}
	// The database is still at schema 111: write the row a 111-era build wrote. Today's kernelstore also writes the
	// R8 columns (operation_id, payload_version) that only migrations 163/164 add.
	if _, e = p.Raw().Exec(ctx, `INSERT INTO gxb_operation_receipts(receipt_id,owner_kind,owner_key,domain,operation,operation_class,semantic_key,request_fingerprint,result_schema,result_payload,operation_started_at,policy_version,operation_policy_refs,actor_account_uid,context_id)
VALUES($1::uuid,$2,$3,$4,$5,$6,$7,$8::bytea,$9,$10::jsonb,$11::timestamptz,$12,$13::jsonb,$14,$15::uuid)`,
		stored.ID.String(), id.OwnerKind, id.OwnerKey, id.Domain, id.Operation, stored.OperationClass, id.SemanticKey, stored.RequestFingerprint[:], stored.ResultSchema, string(stored.ResultPayload),
		stored.OperationStartedAt.UTC(), stored.PolicyVersion, string(refs), stored.ActorAccountUID, stored.ContextID.String()); e != nil {
		t.Fatal(e)
	}
	return operation.Context{ID: opCtx.ID, StartedAt: opCtx.StartedAt, EntropySeed: opCtx.EntropySeed, Policies: policies}
}

type systemForumClock struct{}

func (systemForumClock) Now() time.Time { return time.Now().UTC() }

func forumCommentHash(t *testing.T, p *pg.Pool, tableID int64) string {
	t.Helper()
	var hash string
	if e := p.QueryRow(ctx, `SELECT md5(COALESCE(string_agg(author_player_id||':'||comment||':'||created_at::text||':'||updated_at::text,'|' ORDER BY author_player_id),'')) FROM library_forum_comments WHERE forum_type=1 AND table_id=$1`, tableID).Scan(&hash); e != nil {
		t.Fatal(e)
	}
	return hash
}

func forumReactionHash(t *testing.T, p *pg.Pool, tableID int64) string {
	t.Helper()
	var hash string
	if e := p.QueryRow(ctx, `SELECT md5(COALESCE(string_agg(author_player_id||':'||viewer_player_id||':'||created_at::text,'|' ORDER BY author_player_id,viewer_player_id),'')) FROM library_forum_reactions WHERE forum_type=1 AND table_id=$1`, tableID).Scan(&hash); e != nil {
		t.Fatal(e)
	}
	return hash
}

func forumRawCounts(t *testing.T, p *pg.Pool) (comments, reactions int64) {
	t.Helper()
	if e := p.QueryRow(ctx, `SELECT count(*) FROM library_forum_comments`).Scan(&comments); e != nil {
		t.Fatal(e)
	}
	if e := p.QueryRow(ctx, `SELECT count(*) FROM library_forum_reactions`).Scan(&reactions); e != nil {
		t.Fatal(e)
	}
	return comments, reactions
}

func disposableNativeDatabase(t *testing.T, baseDSN, suffix string) (string, func()) {
	t.Helper()
	base, e := url.Parse(baseDSN)
	if e != nil {
		t.Fatal(e)
	}
	name := "pfg02_proof_" + suffix + "_" + strings.ReplaceAll(uuid().String(), "-", "")
	runTool(t, "createdb", "--maintenance-db", baseDSN, name)
	target := *base
	target.Path = "/" + name
	return target.String(), func() {
		osexec.Command("dropdb", "--force", "--maintenance-db", baseDSN, name).Run()
	}
}

func openNativePool(t *testing.T, dsn string) *pg.Pool {
	t.Helper()
	p, e := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	return p
}

func runTool(t *testing.T, name string, args ...string) string {
	t.Helper()
	out, e := osexec.Command(name, args...).CombinedOutput()
	if e != nil {
		t.Fatalf("%s %v: %v %s", name, args, e, out)
	}
	return string(out)
}

func migrationsRoot(t *testing.T) string {
	t.Helper()
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("caller unavailable")
	}
	return filepath.Clean(filepath.Join(filepath.Dir(file), "..", "..", "..", "migrations"))
}
