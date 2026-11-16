//go:build postgres

package profilefeedback_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres/profilefeedbackstore"
	app "gxb.local/backend/v2/internal/application/profilefeedback"
	"testing"
)

type commentAuthorWire struct {
	Best []struct {
		Author map[string]any `json:"from_player_info"`
	} `json:"best_comments"`
	Rows []struct {
		Author map[string]any `json:"from_player_info"`
	} `json:"comment_list"`
}

type praiseAuthorWire struct {
	Rows []struct {
		Author map[string]any `json:"player_info"`
	} `json:"praise_list"`
}

// The stock comment and praise cells read from_player_info/player_info
// conquer_lev and conquer_loop_id (PersonDisplayWindow.lua:1828,
// PersonPraiseWindow.lua:96); the author projection must carry both.
func TestCommentAndPraiseAuthorCarryConquerFields(t *testing.T) {
	p := pool(t)
	installed(t, p)
	authorActor, owner, viewer := actor(t, p), actor(t, p), actor(t, p)
	sqlExec(t, p, `UPDATE player_directory_profiles SET conquer_lev=21,conquer_loop_id=23 WHERE player_id=$1`, int64(authorActor.PlayerID))

	comments := app.CommentService{Base: service(p, p), Store: profilefeedbackstore.Store{}}
	post(t, comments, authorActor, owner.PlayerID, "conquer", op())
	page, e := comments.ListComments(ctx, viewer, owner.PlayerID, app.PageRequest{Offset: 20}, op())
	if e != nil || len(page.Best)+len(page.Rows) != 1 {
		t.Fatal("comment page", e, page)
	}
	raw, e := json.Marshal(page.Wire())
	if e != nil {
		t.Fatal(e)
	}
	var commentList commentAuthorWire
	if e = json.Unmarshal(raw, &commentList); e != nil {
		t.Fatal("comment wire", e, string(raw))
	}
	if len(commentList.Best)+len(commentList.Rows) != 1 {
		t.Fatalf("comment wire rows %s", raw)
	}
	commentAuthors := append(commentList.Best, commentList.Rows...)
	if commentAuthors[0].Author["conquer_lev"] != float64(21) || commentAuthors[0].Author["conquer_loop_id"] != float64(23) {
		t.Fatalf("comment author conquer fields %v", commentAuthors[0].Author)
	}

	praiseService := service(p, p)
	praise(t, praiseService, authorActor, owner.PlayerID, op())
	praisePage, e := praiseService.List(ctx, owner, app.PageRequest{Offset: 20}, op())
	if e != nil || len(praisePage.Rows) != 1 {
		t.Fatal("praise page", e, praisePage)
	}
	raw, e = json.Marshal(praisePage.Wire())
	if e != nil {
		t.Fatal(e)
	}
	var praiseList praiseAuthorWire
	if e = json.Unmarshal(raw, &praiseList); e != nil || len(praiseList.Rows) != 1 {
		t.Fatal("praise wire", e, string(raw))
	}
	if praiseList.Rows[0].Author["conquer_lev"] != float64(21) || praiseList.Rows[0].Author["conquer_loop_id"] != float64(23) {
		t.Fatalf("praise author conquer fields %v", praiseList.Rows[0].Author)
	}
}
