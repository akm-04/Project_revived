package stockruntime

import (
	"context"
	"gxb.local/backend/v2/internal/domain/arena"
	arenaprojection "gxb.local/backend/v2/internal/projection/arena"
	"net/http"

	"gxb.local/backend/v2/internal/adapters/guildwire"
	guildview "gxb.local/backend/v2/internal/application/guildview"
	appranking "gxb.local/backend/v2/internal/application/ranking"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/oneonone"
	rankingdomain "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/operation"
	oneononeprojection "gxb.local/backend/v2/internal/projection/oneonone"
	projection "gxb.local/backend/v2/internal/projection/ranking"
	topfloorprojection "gxb.local/backend/v2/internal/projection/topfloor"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type BoardRankingReads interface {
	ReadBoard(context.Context, rankingdomain.Board, identity.ActorContext, operation.Context) (appranking.BoardRead, error)
}
type TrophyRanks interface {
	TrophyBoard(context.Context, identity.ActorContext) (achievement.TrophyBoard, error)
}
type TopFloorRanks interface {
	RankList(context.Context, identity.ActorContext) (topfloor.RankList, error)
}
type OneOnOneRanks interface {
	RankList(context.Context, identity.ActorContext, bool) (oneonone.RankList, error)
}
type ArenaRanks interface {
	RankList(context.Context, identity.ActorContext) (arena.RankList, error)
}
type PetCampaignRanks interface {
	RankList(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
}
type IllusionRanks interface {
	RankList(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
}

// GuildRanks is the guild owner's read port for LOAD_RANK_LIST type 4
// (I9_GUILD_ACTIVITY_V1 C12). The player ranking owner keeps no guild state.
type GuildRanks interface {
	ActivityRankList(context.Context, identity.ActorContext, int64) ([]guildview.GuildRank, int64, error)
}

type RankingDispatcher struct {
	PetCampaign PetCampaignRanks
	Illusion    IllusionRanks
	Authority   realtimeauth.GameplayAuthorityPort
	Service     BoardRankingReads
	TopFloor    TopFloorRanks
	OneOnOne    OneOnOneRanks
	Arena       ArenaRanks
	Trophy      TrophyRanks
	Guilds      GuildRanks
}

func (d RankingDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	fail := func(status int) httpedge.Response {
		switch status {
		case http.StatusBadRequest:
			return failureReply(malformed("ranking_request_failed"))
		case http.StatusConflict:
			return failureReply(refusal(unprovenRefusalCode))
		case http.StatusServiceUnavailable:
			return failureReply(defect(nil))
		case http.StatusUnauthorized:
			return failureReply(sessionFailure())
		default:
			return failureReply(refusal(unprovenRefusalCode))
		}
	}
	if d.Authority == nil {
		return failureReply(defect(nil))
	}
	if d.Service == nil {
		return failureReply(defect(nil))
	}
	if r.Envelope.Claims.Token == "" {
		return failureReply(sessionFailure())
	}
	a, e := d.Authority.ResolveGameplayBearer(c, r.Envelope.Claims.Token, r.Envelope.ReceivedAt)
	if e != nil {
		return authFailure(e)
	}
	if r.Envelope.Claims.Region != int64(a.LogicalServerID) {
		return fail(http.StatusForbidden)
	}
	if r.Envelope.MID != 301 {
		return fail(http.StatusNotImplemented)
	}
	if !onlyStockGameplayParams(r.Envelope.Params, "rank_types") {
		return fail(http.StatusBadRequest)
	}
	types, ok := r.Envelope.Params["rank_types"].([]any)
	if !ok || len(types) != 1 {
		return fail(http.StatusBadRequest)
	}
	subtype, e := feedbackInteger(types[0], 1, 9007199254740991)
	if e != nil {
		return fail(http.StatusBadRequest)
	}
	if subtype >= 24 && subtype <= 27 && d.Illusion != nil {
		body, e := d.Illusion.RankList(c, a, subtype, r.Envelope.Operation)
		if e != nil {
			return failureFromRows(nil, e)
		}
		body["error_code"] = int64(0)
		return okI5(body)
	}

	if (subtype == 22 || subtype == 23) && d.PetCampaign != nil {
		body, e := d.PetCampaign.RankList(c, a, subtype, r.Envelope.Operation)
		if e != nil {
			return failureFromRows(nil, e)
		}
		return okI5(body)
	}

	if subtype == 2 && d.TopFloor != nil {
		service, ok := d.TopFloor.(interface {
			TaskRankList(context.Context, identity.ActorContext) (topfloor.RankList, error)
		})
		if !ok {
			return failureReply(defect(nil))
		}
		list, err := service.TaskRankList(c, a)
		if err != nil {
			return failureFromRows(nil, err)
		}
		body := topfloorprojection.RankList(list.Rows, list.MyRank, a.LogicalServerID)
		body["rank_list"].([]map[string]any)[0]["rank_type"] = int64(2)
		return okI5(body)
	}
	if subtype == 1 && d.TopFloor != nil {
		list, e := d.TopFloor.RankList(c, a)
		if e != nil {
			return failureFromRows(nil, e)
		}
		body := topfloorprojection.RankList(list.Rows, list.MyRank, a.LogicalServerID)
		body["error_code"] = int64(0)
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	}
	if (subtype == 3 || subtype == 4) && d.OneOnOne != nil {
		list, e := d.OneOnOne.RankList(c, a, subtype == 3)
		if e != nil {
			return failureFromRows(nil, e)
		}
		body := oneononeprojection.RankList(list, subtype)
		body["error_code"] = int64(0)
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	}
	if subtype == 6 && d.Arena != nil {
		list, e := d.Arena.RankList(c, a)
		if e != nil {
			return failureFromRows(nil, e)
		}
		body := arenaprojection.RankList(list)
		body["error_code"] = int64(0)
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	}
	if subtype == 15 && d.Trophy != nil {
		list, e := d.Trophy.TrophyBoard(c, a)
		if e != nil {
			return failureFromRows(nil, e)
		}
		body := projection.TrophyList(list)
		body["error_code"] = int64(0)
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	}
	if (subtype == 11 || subtype == 39) && d.Guilds != nil {
		rows, mine, err := d.Guilds.ActivityRankList(c, a, 50)
		if err != nil {
			return failureFromRows(nil, err)
		}
		body := guildwire.GuildRankList(subtype, rows, mine)
		body["error_code"] = int64(0)
		return okI5(body)
	}

	if rankingdomain.IsServedEmptySubType(subtype) {
		body := projection.BoardList(subtype, []map[string]any{}, map[string]any{})
		body["error_code"] = int64(0)
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	}

	board, known := rankingdomain.BoardOfSubType(subtype)
	if !known {
		return failureReply(refusal(unprovenRefusalCode))
	}
	read, e := d.Service.ReadBoard(c, board, a, r.Envelope.Operation)
	if e != nil {
		return failureFromRows(nil, e)
	}
	rows, e := projection.BoardRows(read.Rows, read.Displays, board.RowValue)
	if e != nil {
		return failureReply(defect(e))
	}
	mine := map[string]any{}
	if read.MyRank > 0 {
		mineKey := "score"
		if board.RowValue == "point" {
			mineKey = "point"
		}
		mine = map[string]any{"rank": read.MyRank, mineKey: read.MyScore}
	}
	body := projection.BoardList(board.SubType, rows, mine)
	body["error_code"] = int64(0)
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
}
