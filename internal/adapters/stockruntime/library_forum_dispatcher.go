package stockruntime

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/libraryforum"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/libraryforum"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type LibraryForumPort interface {
	Read(context.Context, identity.ActorContext, app.PageQuery, operation.Context) (app.Page, error)
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
}

type LibraryForumDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   LibraryForumPort
}

func (d LibraryForumDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	actor, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failForum(app.ErrUnavailable)
	}
	params := req.Envelope.Params
	switch req.Envelope.MID {
	case 832:
		if !onlyStockGameplayParams(params, "start_pos", "end_pos", "table_id", "forum_type") {
			return badForum("invalid_library_forum_params")
		}
		start, e := requiredInt64(params, "start_pos")
		if e != nil {
			return badForum("invalid_library_forum_page")
		}
		end, e := requiredInt64(params, "end_pos")
		if e != nil {
			return badForum("invalid_library_forum_page")
		}
		tableID, e := requiredInt64(params, "table_id")
		if e != nil {
			return badForum("invalid_library_forum_table")
		}
		forumType, e := requestForumType(params)
		if e != nil {
			return badForum("invalid_library_forum_type")
		}
		query := app.PageQuery{ForumType: forumType, TableID: tableID, Start: start, End: end}
		if query.Validate() != nil {
			return badForum("invalid_library_forum_page")
		}
		page, e := d.Service.Read(ctx, actor, query, req.Envelope.Operation)
		if e != nil {
			return failForum(e)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"comments": forumRows(page.Rows, forumType)}}
	case 833:
		if !onlyStockGameplayParams(params, "player_id", "table_id", "forum_type") {
			return badForum("invalid_library_forum_params")
		}
		author, e := requiredInt64(params, "player_id")
		if e != nil {
			return badForum("invalid_library_forum_author")
		}
		tableID, e := requiredInt64(params, "table_id")
		if e != nil {
			return badForum("invalid_library_forum_table")
		}
		forumType, e := requestForumType(params)
		if e != nil {
			return badForum("invalid_library_forum_type")
		}
		command := app.Command{Family: app.Like, ForumType: forumType, TableID: tableID, Author: author}
		if command.Validate() != nil {
			return badForum("invalid_library_forum_like")
		}
		out, e := d.Service.Command(ctx, actor, command, req.Envelope.Operation)
		if e != nil {
			return failForum(e)
		}
		if out.TableID != tableID {
			return failForum(app.ErrUnavailable)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"comments": forumRows(out.Rows, forumType)}}
	case 834:
		if !onlyStockGameplayParams(params, "id", "comment", "forum_type") {
			return badForum("invalid_library_forum_params")
		}
		instance, e := requiredInt64(params, "id")
		if e != nil {
			return badForum("invalid_library_forum_instance")
		}
		text, ok := strictStringParam(params, "comment")
		if !ok {
			return badForum("invalid_library_forum_comment")
		}
		forumType, e := requestForumType(params)
		if e != nil {
			return badForum("invalid_library_forum_type")
		}
		command := app.Command{Family: app.Comment, ForumType: forumType, Instance: instance, Text: text}
		if e := command.Validate(); e != nil {
			return failForum(e)
		}
		out, e := d.Service.Command(ctx, actor, command, req.Envelope.Operation)
		if e != nil {
			return failForum(e)
		}
		if out.TableID <= 0 {
			return failForum(app.ErrUnavailable)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	default:
		return badForum("unsupported_library_forum_mid")
	}
}

func requestForumType(params map[string]any) (int64, error) {
	raw, present := params["forum_type"]
	if !present || raw == nil {
		return library.HeroForum, nil
	}
	forumType, e := requiredInt64(params, "forum_type")
	if e != nil || (forumType != library.HeroForum && forumType != library.PetForum) {
		return 0, errors.New("invalid forum type")
	}
	return forumType, nil
}

func forumRows(rows []app.Row, forumType int64) []any {
	out := make([]any, 0, len(rows))
	for _, r := range rows {
		row := map[string]any{
			"player_id":       r.PlayerID,
			"player_name":     r.PlayerName,
			"avatar_id":       r.AvatarID,
			"avatar_frame_id": r.AvatarFrameID,
			"region":          r.Region,
			"player_lev":      r.PlayerLevel,
			"conquer_lev":     r.ConquerLevel,
			"conquer_loop_id": r.ConquerLoopID,
			"comment":         r.Comment,
			"like":            r.Likes,
			"is_commented":    libraryBit(r.ViewerLiked),
			"table_id":        r.TableID,
		}
		if forumType == library.PetForum {
			row["pet_lev"], row["pet_color"], row["pet_star"] = r.PetLevel, r.PetColor, r.PetStar
		} else {
			row["hero_lev"], row["hero_color"], row["hero_star"] = r.HeroLevel, r.HeroColor, r.HeroStar
		}
		out = append(out, row)
	}
	return out
}

func badForum(code string) httpedge.Response {
	return failureReply(malformed(code))
}

var forumFailureRows = []failureRow{
	{match: app.ErrRejected, class: failureRefusal, code: unprovenRefusalCode},
	{match: app.ErrRequest, class: failureMalformed, detail: "invalid_library_forum_request"},
	{match: app.ErrUnavailable, class: failureUnavailable},
}

// failForum refuses business conflicts on 409 so the stock callbacks see ERROR
// instead of an OK body they would index (I9_LIBRARY_V1 C2).
func failForum(e error) httpedge.Response {
	return failureFromRows(forumFailureRows, e)
}
