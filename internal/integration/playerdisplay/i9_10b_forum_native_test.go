//go:build postgres

package playerdisplay_test

import (
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/libraryforumstore"
	"gxb.local/backend/v2/internal/adapters/postgres/nativebirth"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/libraryforum"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func libraryForumService(p *pg.Pool) app.Service {
	return app.Service{
		Timed:      gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}},
		Reads:      tx.Runner{DB: p},
		Store:      libraryforumstore.Store{},
		Players:    i4store.PlayerRootLocker{},
		Fence:      i5store.Store{Queryer: p},
		Receipts:   kernelstore.Store{},
		Directory:  i4store.PlayerDirectoryReader{},
		Characters: characterstore.Store{Queryer: p},
	}
}

func forumDispatch(t *testing.T, p *pg.Pool, actor identity.ActorContext, mid uint16, params map[string]any, opCtx operation.Context) httpedge.Response {
	t.Helper()
	dispatcher := stockruntime.LibraryForumDispatcher{Authority: fixedLibraryAuthority{actor: actor}, Service: libraryForumService(p)}
	return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: mid, Operation: opCtx, ReceivedAt: time.Now().UTC(),
		Claims: wire.CredentialClaims{Token: "fixture", Region: int64(actor.LogicalServerID)}, Params: params}})
}

func forumCall(t *testing.T, p *pg.Pool, actor identity.ActorContext, mid uint16, params map[string]any) httpedge.Response {
	t.Helper()
	return forumDispatch(t, p, actor, mid, params, op())
}

func forumRowsOf(t *testing.T, body map[string]any) []map[string]any {
	t.Helper()
	raw, ok := body["comments"].([]any)
	if !ok {
		t.Fatalf("comments %T %+v", body["comments"], body)
	}
	rows := make([]map[string]any, 0, len(raw))
	for _, row := range raw {
		table, ok := row.(map[string]any)
		if !ok {
			t.Fatalf("comment row %T", row)
		}
		rows = append(rows, table)
	}
	return rows
}

func companionHero(t *testing.T, p *pg.Pool, actor identity.ActorContext) character.Hero {
	t.Helper()
	hero, e := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, p, actor.PlayerID, 1)
	if e != nil {
		t.Fatal(e)
	}
	return hero
}

func resetForumBoards(t *testing.T, p *pg.Pool) {
	t.Helper()
	exec(t, p, `DELETE FROM library_forum_reactions`)
	exec(t, p, `DELETE FROM library_forum_comments`)
}

func TestI9_10BForum832SharedCommentAndLikeToggle(t *testing.T) {
	p := pool(t)
	resetForumBoards(t, p)
	installed(t, p)
	first := companionActor(t, p)
	second := companionActor(t, p)
	hero := companionHero(t, p, first)
	tableID := hero.TableID
	profile, ok, e := (i4store.PlayerDirectoryReader{}).ProfileTx(ctx, p, first.PlayerID)
	if e != nil || !ok {
		t.Fatalf("directory profile %v %v", ok, e)
	}

	commentOperation := op()
	response := forumDispatch(t, p, first, 834, map[string]any{"id": int64(1), "comment": "hello"}, commentOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("834 status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = forumDispatch(t, p, first, 834, map[string]any{"id": int64(1), "comment": "hello"}, commentOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("834 replay status %d body %+v", response.HTTPStatus, response.Body)
	}

	response = forumCall(t, p, second, 832, map[string]any{"start_pos": int64(1), "end_pos": int64(50), "table_id": tableID})
	if response.HTTPStatus != 200 {
		t.Fatalf("832 status %d body %+v", response.HTTPStatus, response.Body)
	}
	rows := forumRowsOf(t, response.Body)
	if len(rows) != 1 {
		t.Fatalf("832 rows %+v", rows)
	}
	row := rows[0]
	want := map[string]any{
		"player_id":       int64(first.PlayerID),
		"player_name":     profile.Name,
		"avatar_id":       profile.AvatarID,
		"avatar_frame_id": profile.AvatarFrameID,
		"region":          int64(1),
		"player_lev":      profile.Level,
		"conquer_lev":     profile.ConquerLevel,
		"conquer_loop_id": profile.ConquerLoopID,
		"hero_lev":        hero.Level,
		"hero_color":      hero.Color,
		"hero_star":       hero.Star,
		"comment":         "hello",
		"like":            int64(0),
		"is_commented":    int64(0),
		"table_id":        tableID,
	}
	for key, value := range want {
		if row[key] != value {
			t.Fatalf("832 %s=%v want %v (%+v)", key, row[key], value, row)
		}
	}
	if _, hasPet := row["pet_lev"]; hasPet {
		t.Fatalf("hero row carried pet display fields %+v", row)
	}

	likeOperation := op()
	response = forumDispatch(t, p, second, 833, map[string]any{"player_id": int64(first.PlayerID), "table_id": tableID}, likeOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("833 status %d body %+v", response.HTTPStatus, response.Body)
	}
	rows = forumRowsOf(t, response.Body)
	if len(rows) != 1 || rows[0]["like"] != int64(1) || rows[0]["is_commented"] != int64(1) {
		t.Fatalf("833 like rows %+v", rows)
	}
	response = forumDispatch(t, p, second, 833, map[string]any{"player_id": int64(first.PlayerID), "table_id": tableID}, likeOperation)
	rows = forumRowsOf(t, response.Body)
	if response.HTTPStatus != 200 || len(rows) != 1 || rows[0]["like"] != int64(1) || rows[0]["is_commented"] != int64(1) {
		t.Fatalf("833 replay status %d rows %+v", response.HTTPStatus, rows)
	}
	response = forumCall(t, p, first, 832, map[string]any{"start_pos": int64(1), "end_pos": int64(50), "table_id": tableID})
	rows = forumRowsOf(t, response.Body)
	if len(rows) != 1 || rows[0]["like"] != int64(1) || rows[0]["is_commented"] != int64(0) {
		t.Fatalf("author view rows %+v", rows)
	}
	response = forumCall(t, p, second, 833, map[string]any{"player_id": int64(first.PlayerID), "table_id": tableID})
	rows = forumRowsOf(t, response.Body)
	if response.HTTPStatus != 200 || len(rows) != 1 || rows[0]["like"] != int64(0) || rows[0]["is_commented"] != int64(0) {
		t.Fatalf("833 toggle off status %d rows %+v", response.HTTPStatus, rows)
	}

	response = forumCall(t, p, first, 834, map[string]any{"id": int64(1), "comment": "edited"})
	if response.HTTPStatus != 200 {
		t.Fatalf("834 replace status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = forumCall(t, p, second, 832, map[string]any{"start_pos": int64(1), "end_pos": int64(50), "table_id": tableID})
	rows = forumRowsOf(t, response.Body)
	if len(rows) != 1 || rows[0]["comment"] != "edited" || rows[0]["player_id"] != int64(first.PlayerID) {
		t.Fatalf("one comment per author %+v", rows)
	}

	for _, refused := range []map[string]any{
		{"id": int64(1), "comment": ""},
		{"id": int64(1), "comment": strings.Repeat("x", 33)},
		{"id": int64(99), "comment": "unowned"},
		{"id": int64(1), "comment": "wrong type", "forum_type": int64(3)},
	} {
		response = forumCall(t, p, first, 834, refused)
		wantStatus := 409
		if refused["forum_type"] == int64(3) {
			wantStatus = 400
		}
		if response.HTTPStatus != wantStatus {
			t.Fatalf("834 %+v status %d body %+v", refused, response.HTTPStatus, response.Body)
		}
	}
	response = forumCall(t, p, first, 834, map[string]any{"id": int64(1), "comment": nil})
	if response.HTTPStatus != 400 {
		t.Fatalf("834 null comment status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = forumCall(t, p, first, 834, map[string]any{"id": int64(1), "comment": strings.Repeat("字", 32)})
	if response.HTTPStatus != 200 {
		t.Fatalf("834 32 rune comment status %d body %+v", response.HTTPStatus, response.Body)
	}

	response = forumCall(t, p, second, 833, map[string]any{"player_id": int64(second.PlayerID), "table_id": tableID})
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("833 missing comment status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = forumCall(t, p, first, 832, map[string]any{"start_pos": int64(1), "end_pos": int64(51), "table_id": tableID})
	if response.HTTPStatus != 400 {
		t.Fatalf("832 oversized page status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = forumCall(t, p, first, 832, map[string]any{"start_pos": int64(1), "end_pos": int64(50), "table_id": tableID + 900000})
	if response.HTTPStatus != 200 || len(forumRowsOf(t, response.Body)) != 0 {
		t.Fatalf("832 empty board status %d body %+v", response.HTTPStatus, response.Body)
	}
}

func TestI9_10BForum834PetInstanceToTable(t *testing.T) {
	p := pool(t)
	resetForumBoards(t, p)
	rev := installed(t, p)
	actor := bornActor(t, p)
	at := time.Now().UTC().Add(-time.Minute).Truncate(time.Microsecond)
	pet := character.Pet{PlayerID: actor.PlayerID, PetID: 7, TableID: 110030001, OriginTableID: 10030001, Star: 2, Level: 9, Color: 3, Skills: character.DefaultPetSkillLevels(), CreationContentRevision: rev, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (characterstore.Store{}).InsertPetTx(ctx, tr, pet); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	response := forumCall(t, p, actor, 834, map[string]any{"id": int64(7), "forum_type": int64(2), "comment": "pet hi"})
	if response.HTTPStatus != 200 {
		t.Fatalf("pet 834 status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = forumCall(t, p, actor, 832, map[string]any{"start_pos": int64(1), "end_pos": int64(50), "table_id": int64(110030001), "forum_type": int64(2)})
	rows := forumRowsOf(t, response.Body)
	if response.HTTPStatus != 200 || len(rows) != 1 {
		t.Fatalf("pet 832 status %d rows %+v", response.HTTPStatus, rows)
	}
	row := rows[0]
	if row["pet_lev"] != int64(9) || row["pet_color"] != int64(3) || row["pet_star"] != int64(2) || row["comment"] != "pet hi" {
		t.Fatalf("pet row %+v", row)
	}
	if _, hasHero := row["hero_lev"]; hasHero {
		t.Fatalf("pet row carried hero display fields %+v", row)
	}
	response = forumCall(t, p, actor, 832, map[string]any{"start_pos": int64(1), "end_pos": int64(50), "table_id": int64(110030001)})
	if response.HTTPStatus != 200 || len(forumRowsOf(t, response.Body)) != 0 {
		t.Fatalf("hero board leaked pet comment status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = forumCall(t, p, actor, 834, map[string]any{"id": int64(7), "comment": "wrong board"})
	if response.HTTPStatus != 409 {
		t.Fatalf("pet instance on hero board status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = forumCall(t, p, actor, 833, map[string]any{"player_id": int64(actor.PlayerID), "table_id": int64(110030001), "forum_type": int64(2)})
	rows = forumRowsOf(t, response.Body)
	if response.HTTPStatus != 200 || len(rows) != 1 || rows[0]["like"] != int64(1) || rows[0]["is_commented"] != int64(1) {
		t.Fatalf("pet like status %d rows %+v", response.HTTPStatus, rows)
	}
}

func TestI9_10BForumPageCapAndServerIsolation(t *testing.T) {
	p := pool(t)
	resetForumBoards(t, p)
	installed(t, p)
	const authors = 51
	roots := make([]nativebirth.Root, 0, authors)
	players := make([]identity.ActorContext, 0, authors)
	for i := 0; i < authors; i++ {
		if i == 0 {
			players = append(players, companionActor(t, p))
			continue
		}
		a, account := playerRoot(t, p, 1)
		players = append(players, a)
		roots = append(roots, nativebirth.Root{Account: account, Player: a.PlayerID})
	}
	if e := nativebirth.PersistAll(ctx, p, roots); e != nil {
		t.Fatal(e)
	}
	tableID := companionHero(t, p, players[0]).TableID
	for i := 1; i < len(players); i++ {
		if companionHero(t, p, players[i]).TableID != tableID {
			t.Fatalf("companion table drift at %d", i)
		}
		if response := forumCall(t, p, players[i], 834, map[string]any{"id": int64(1), "comment": "c"}); response.HTTPStatus != 200 {
			t.Fatalf("834 author %d status %d body %+v", i, response.HTTPStatus, response.Body)
		}
	}
	if response := forumCall(t, p, players[0], 834, map[string]any{"id": int64(1), "comment": "c"}); response.HTTPStatus != 200 {
		t.Fatalf("834 first author status %d body %+v", response.HTTPStatus, response.Body)
	}

	response := forumCall(t, p, players[0], 832, map[string]any{"start_pos": int64(1), "end_pos": int64(50), "table_id": tableID})
	rows := forumRowsOf(t, response.Body)
	if response.HTTPStatus != 200 || len(rows) != 50 {
		t.Fatalf("832 first page status %d len %d", response.HTTPStatus, len(rows))
	}
	response = forumCall(t, p, players[0], 832, map[string]any{"start_pos": int64(51), "end_pos": int64(51), "table_id": tableID})
	rows = forumRowsOf(t, response.Body)
	if response.HTTPStatus != 200 || len(rows) != 1 {
		t.Fatalf("832 second page status %d len %d", response.HTTPStatus, len(rows))
	}

	last := players[authors-1]
	response = forumCall(t, p, players[0], 833, map[string]any{"player_id": int64(last.PlayerID), "table_id": tableID})
	rows = forumRowsOf(t, response.Body)
	if response.HTTPStatus != 200 || len(rows) != 50 || rows[0]["player_id"] != int64(last.PlayerID) || rows[0]["like"] != int64(1) {
		t.Fatalf("833 order by likes status %d rows %+v", response.HTTPStatus, rows)
	}

	other, otherAccount := playerRoot(t, p, 2)
	if e := nativebirth.PersistAll(ctx, p, []nativebirth.Root{{Account: otherAccount, Player: other.PlayerID}}); e != nil {
		t.Fatal(e)
	}
	if companionHero(t, p, other).TableID != tableID {
		t.Fatalf("server two companion table drift")
	}
	if response := forumCall(t, p, other, 834, map[string]any{"id": int64(1), "comment": "other server"}); response.HTTPStatus != 200 {
		t.Fatalf("834 server two status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = forumCall(t, p, players[0], 832, map[string]any{"start_pos": int64(1), "end_pos": int64(50), "table_id": tableID})
	rows = forumRowsOf(t, response.Body)
	if response.HTTPStatus != 200 || len(rows) != 50 {
		t.Fatalf("server one page sees server two status %d len %d", response.HTTPStatus, len(rows))
	}
	for _, row := range rows {
		if row["player_id"] == int64(other.PlayerID) {
			t.Fatalf("server two comment leaked into server one %+v", row)
		}
	}
	response = forumCall(t, p, other, 832, map[string]any{"start_pos": int64(1), "end_pos": int64(50), "table_id": tableID})
	rows = forumRowsOf(t, response.Body)
	if response.HTTPStatus != 200 || len(rows) != 1 || rows[0]["player_id"] != int64(other.PlayerID) || rows[0]["region"] != int64(2) {
		t.Fatalf("server two board status %d rows %+v", response.HTTPStatus, rows)
	}
}
