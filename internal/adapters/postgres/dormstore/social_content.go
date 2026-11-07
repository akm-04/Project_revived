package dormstore

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	domain "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func decodeCountMap(raw string) (map[int64]int64, error) {
	var decoded map[string]int64
	if err := json.Unmarshal([]byte(raw), &decoded); err != nil {
		return nil, err
	}
	out := make(map[int64]int64, len(decoded))
	for key, value := range decoded {
		id, err := strconv.ParseInt(key, 10, 64)
		if err != nil || id < 1 {
			return nil, domain.ErrInvalidFacts
		}
		out[id] = value
	}
	return out, nil
}

func (Store) PraiseCountsTx(ctx context.Context, query tx.Queryer, owner identity.PlayerID) (map[int64]int64, error) {
	var raw string
	if err := query.QueryRow(ctx, `SELECT COALESCE(jsonb_object_agg(house_id::text,praise_count),'{}'::jsonb)::text FROM (SELECT house_id,COUNT(*) AS praise_count FROM player_dorm_praises WHERE player_id=$1 GROUP BY house_id) p`, int64(owner)).Scan(&raw); err != nil {
		return nil, err
	}
	return decodeCountMap(raw)
}

type praiseJSON struct {
	PlayerID int64     `json:"player_id"`
	HouseID  int64     `json:"house_id"`
	ActorID  int64     `json:"actor_player_id"`
	FirstAt  time.Time `json:"first_at"`
}

func (Store) ActorPraisesTx(ctx context.Context, query tx.Queryer, owner, actor identity.PlayerID) (map[int64]domain.HousePraise, error) {
	var raw string
	if err := query.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'house_id',house_id,'actor_player_id',actor_player_id,'first_at',first_at)),'[]'::jsonb)::text FROM player_dorm_praises WHERE player_id=$1 AND actor_player_id=$2`, int64(owner), int64(actor)).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []praiseJSON
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make(map[int64]domain.HousePraise, len(rows))
	for _, row := range rows {
		praise := domain.HousePraise{Owner: identity.PlayerID(row.PlayerID), HouseID: row.HouseID, Actor: identity.PlayerID(row.ActorID), FirstAt: row.FirstAt.UTC()}
		if err := praise.Validate(); err != nil {
			return nil, err
		}
		out[praise.HouseID] = praise
	}
	return out, nil
}

func (Store) PraiseCountTx(ctx context.Context, query tx.Queryer, target domain.RoomTarget) (int64, error) {
	var count int64
	if err := query.QueryRow(ctx, `SELECT COUNT(*) FROM player_dorm_praises WHERE player_id=$1 AND house_id=$2`, int64(target.Owner), target.HouseID).Scan(&count); err != nil {
		return 0, err
	}
	return count, nil
}

func (Store) ReadPraiseTx(ctx context.Context, query tx.Queryer, target domain.RoomTarget, actor identity.PlayerID) (*domain.HousePraise, error) {
	var raw string
	err := query.QueryRow(ctx, `SELECT jsonb_build_object('player_id',player_id,'house_id',house_id,'actor_player_id',actor_player_id,'first_at',first_at)::text FROM player_dorm_praises WHERE player_id=$1 AND house_id=$2 AND actor_player_id=$3`, int64(target.Owner), target.HouseID, int64(actor)).Scan(&raw)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var row praiseJSON
	if err = json.Unmarshal([]byte(raw), &row); err != nil {
		return nil, err
	}
	praise := domain.HousePraise{Owner: identity.PlayerID(row.PlayerID), HouseID: row.HouseID, Actor: identity.PlayerID(row.ActorID), FirstAt: row.FirstAt.UTC()}
	if err = praise.Validate(); err != nil {
		return nil, err
	}
	return &praise, nil
}

func (Store) PagePraisesTx(ctx context.Context, query tx.Queryer, target domain.RoomTarget, start, offset int64) ([]domain.HousePraise, error) {
	var raw string
	if err := query.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'house_id',house_id,'actor_player_id',actor_player_id,'first_at',first_at) ORDER BY first_at DESC,actor_player_id DESC),'[]'::jsonb)::text FROM (SELECT player_id,house_id,actor_player_id,first_at FROM player_dorm_praises WHERE player_id=$1 AND house_id=$2 ORDER BY first_at DESC,actor_player_id DESC LIMIT $3 OFFSET $4) p`, int64(target.Owner), target.HouseID, offset, start).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []praiseJSON
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]domain.HousePraise, 0, len(rows))
	for _, row := range rows {
		praise := domain.HousePraise{Owner: identity.PlayerID(row.PlayerID), HouseID: row.HouseID, Actor: identity.PlayerID(row.ActorID), FirstAt: row.FirstAt.UTC()}
		if err := praise.Validate(); err != nil {
			return nil, err
		}
		out = append(out, praise)
	}
	return out, nil
}

func (Store) InsertPraiseTx(ctx context.Context, transaction tx.Tx, praise domain.HousePraise) error {
	tag, err := transaction.Exec(ctx, `INSERT INTO player_dorm_praises(player_id,house_id,actor_player_id,first_at) VALUES($1,$2,$3,$4)`, int64(praise.Owner), praise.HouseID, int64(praise.Actor), praise.FirstAt)
	if err != nil {
		return err
	}
	return one(tag, "praise")
}

type listedCommentJSON struct {
	CommentID  int64      `json:"comment_id"`
	PlayerID   int64      `json:"player_id"`
	HouseID    int64      `json:"house_id"`
	AuthorID   int64      `json:"author_player_id"`
	Content    string     `json:"content"`
	CreatedAt  time.Time  `json:"created_at"`
	DeletedAt  *time.Time `json:"deleted_at"`
	Likes      int64      `json:"likes"`
	HasReacted bool       `json:"has_reacted"`
}

func (row listedCommentJSON) listed() domain.ListedComment {
	comment := domain.HouseComment{ID: row.CommentID, Owner: identity.PlayerID(row.PlayerID), HouseID: row.HouseID, Author: identity.PlayerID(row.AuthorID), Content: row.Content, CreatedAt: row.CreatedAt.UTC()}
	if row.DeletedAt != nil {
		deleted := row.DeletedAt.UTC()
		comment.DeletedAt = &deleted
	}
	return domain.ListedComment{Comment: comment, Likes: row.Likes, HasReacted: row.HasReacted}
}

func (Store) ListLiveCommentsTx(ctx context.Context, query tx.Queryer, target domain.RoomTarget, viewer identity.PlayerID) ([]domain.ListedComment, error) {
	var raw string
	sql := `SELECT COALESCE(jsonb_agg(jsonb_build_object('comment_id',c.comment_id,'player_id',c.player_id,'house_id',c.house_id,'author_player_id',c.author_player_id,'content',c.content,'created_at',c.created_at,'deleted_at',c.deleted_at,'likes',(SELECT COUNT(*) FROM player_dorm_comment_reactions r WHERE r.player_id=c.player_id AND r.house_id=c.house_id AND r.comment_id=c.comment_id),'has_reacted',EXISTS(SELECT 1 FROM player_dorm_comment_reactions r WHERE r.player_id=c.player_id AND r.house_id=c.house_id AND r.comment_id=c.comment_id AND r.actor_player_id=$3)) ORDER BY c.created_at DESC,c.comment_id DESC),'[]'::jsonb)::text FROM (SELECT * FROM player_dorm_comments WHERE player_id=$1 AND house_id=$2 AND deleted_at IS NULL ORDER BY created_at DESC,comment_id DESC LIMIT 201) c`
	if err := query.QueryRow(ctx, sql, int64(target.Owner), target.HouseID, int64(viewer)).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []listedCommentJSON
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]domain.ListedComment, 0, len(rows))
	for _, row := range rows {
		out = append(out, row.listed())
	}
	return out, nil
}

func (Store) ReadCommentTx(ctx context.Context, query tx.Queryer, target domain.RoomTarget, commentID int64) (*domain.HouseComment, error) {
	var raw string
	err := query.QueryRow(ctx, `SELECT jsonb_build_object('comment_id',comment_id,'player_id',player_id,'house_id',house_id,'author_player_id',author_player_id,'content',content,'created_at',created_at,'deleted_at',deleted_at)::text FROM player_dorm_comments WHERE player_id=$1 AND house_id=$2 AND comment_id=$3`, int64(target.Owner), target.HouseID, commentID).Scan(&raw)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var row listedCommentJSON
	if err = json.Unmarshal([]byte(raw), &row); err != nil {
		return nil, err
	}
	comment := domain.HouseComment{ID: row.CommentID, Owner: identity.PlayerID(row.PlayerID), HouseID: row.HouseID, Author: identity.PlayerID(row.AuthorID), Content: row.Content, CreatedAt: row.CreatedAt.UTC()}
	if row.DeletedAt != nil {
		deleted := row.DeletedAt.UTC()
		comment.DeletedAt = &deleted
	}
	return &comment, nil
}

func (Store) CommentLikesTx(ctx context.Context, query tx.Queryer, target domain.RoomTarget, commentID int64) (int64, error) {
	var likes int64
	if err := query.QueryRow(ctx, `SELECT COUNT(*) FROM player_dorm_comment_reactions WHERE player_id=$1 AND house_id=$2 AND comment_id=$3`, int64(target.Owner), target.HouseID, commentID).Scan(&likes); err != nil {
		return 0, err
	}
	return likes, nil
}

func (Store) ReadCommentReactionTx(ctx context.Context, query tx.Queryer, target domain.RoomTarget, commentID int64, actor identity.PlayerID) (*domain.CommentReaction, error) {
	var raw string
	err := query.QueryRow(ctx, `SELECT jsonb_build_object('comment_id',comment_id,'actor_player_id',actor_player_id,'first_at',first_at)::text FROM player_dorm_comment_reactions WHERE player_id=$1 AND house_id=$2 AND comment_id=$3 AND actor_player_id=$4`, int64(target.Owner), target.HouseID, commentID, int64(actor)).Scan(&raw)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var row struct {
		CommentID int64     `json:"comment_id"`
		ActorID   int64     `json:"actor_player_id"`
		FirstAt   time.Time `json:"first_at"`
	}
	if err = json.Unmarshal([]byte(raw), &row); err != nil {
		return nil, err
	}
	reaction := domain.CommentReaction{CommentID: row.CommentID, Actor: identity.PlayerID(row.ActorID), FirstAt: row.FirstAt.UTC()}
	if err = reaction.Validate(); err != nil {
		return nil, err
	}
	return &reaction, nil
}

func (Store) NextCommentIDTx(ctx context.Context, transaction tx.Tx) (int64, error) {
	var id int64
	if err := transaction.QueryRow(ctx, `SELECT nextval('player_dorm_comment_id_seq')`).Scan(&id); err != nil {
		return 0, err
	}
	return id, nil
}

func (Store) InsertCommentTx(ctx context.Context, transaction tx.Tx, comment domain.HouseComment) error {
	tag, err := transaction.Exec(ctx, `INSERT INTO player_dorm_comments(comment_id,player_id,house_id,author_player_id,content,created_at) VALUES($1,$2,$3,$4,$5,$6)`, comment.ID, int64(comment.Owner), comment.HouseID, int64(comment.Author), comment.Content, comment.CreatedAt)
	if err != nil {
		return err
	}
	return one(tag, "comment")
}

func (Store) MarkCommentDeletedTx(ctx context.Context, transaction tx.Tx, comment domain.HouseComment) error {
	if comment.DeletedAt == nil {
		return domain.ErrInvalidFacts
	}
	tag, err := transaction.Exec(ctx, `UPDATE player_dorm_comments SET deleted_at=$4 WHERE player_id=$1 AND house_id=$2 AND comment_id=$3 AND deleted_at IS NULL`, int64(comment.Owner), comment.HouseID, comment.ID, comment.DeletedAt.UTC())
	if err != nil {
		return err
	}
	return one(tag, "comment delete")
}

func (Store) DeleteCommentReactionsTx(ctx context.Context, transaction tx.Tx, target domain.RoomTarget, commentID int64) error {
	_, err := transaction.Exec(ctx, `DELETE FROM player_dorm_comment_reactions WHERE player_id=$1 AND house_id=$2 AND comment_id=$3`, int64(target.Owner), target.HouseID, commentID)
	return err
}

func (Store) DeleteCommentTx(ctx context.Context, transaction tx.Tx, target domain.RoomTarget, commentID int64) error {
	tag, err := transaction.Exec(ctx, `DELETE FROM player_dorm_comments WHERE player_id=$1 AND house_id=$2 AND comment_id=$3`, int64(target.Owner), target.HouseID, commentID)
	if err != nil {
		return err
	}
	return one(tag, "comment prune")
}

func (Store) InsertCommentReactionTx(ctx context.Context, transaction tx.Tx, target domain.RoomTarget, reaction domain.CommentReaction) error {
	tag, err := transaction.Exec(ctx, `INSERT INTO player_dorm_comment_reactions(player_id,house_id,comment_id,actor_player_id,first_at) VALUES($1,$2,$3,$4,$5)`, int64(target.Owner), target.HouseID, reaction.CommentID, int64(reaction.Actor), reaction.FirstAt)
	if err != nil {
		return err
	}
	return one(tag, "comment reaction")
}

// VisitablePlayersTx is a bounded room-ownership read: the application supplies
// the candidate IDs and decides the selection policy.
func (Store) VisitablePlayersTx(ctx context.Context, query tx.Queryer, players []int64) (map[int64]bool, error) {
	out := map[int64]bool{}
	if len(players) == 0 {
		return out, nil
	}
	var raw string
	if err := query.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(DISTINCT r.player_id),'[]'::jsonb)::text FROM player_dorm_rooms r LEFT JOIN player_dorm_room_social s ON s.player_id=r.player_id AND s.house_id=r.house_id WHERE r.player_id=ANY($1) AND COALESCE(s.is_hidden,false)=false`, players).Scan(&raw); err != nil {
		return nil, err
	}
	var ids []int64
	if err := json.Unmarshal([]byte(raw), &ids); err != nil {
		return nil, err
	}
	for _, id := range ids {
		out[id] = true
	}
	return out, nil
}

type socialRoomJSON struct {
	HouseID      int64     `json:"house_id"`
	Name         string    `json:"house_name"`
	Hidden       bool      `json:"is_hidden"`
	StateVersion int64     `json:"state_version"`
	UpdatedAt    time.Time `json:"updated_at"`
}

func (Store) ListSocialRoomsTx(ctx context.Context, query tx.Queryer, owner identity.PlayerID) (map[int64]domain.SocialRoomState, error) {
	var raw string
	if err := query.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('house_id',house_id,'house_name',house_name,'is_hidden',is_hidden,'state_version',state_version,'updated_at',updated_at)),'[]'::jsonb)::text FROM player_dorm_room_social WHERE player_id=$1`, int64(owner)).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []socialRoomJSON
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make(map[int64]domain.SocialRoomState, len(rows))
	for _, row := range rows {
		state := domain.SocialRoomState{Target: domain.RoomTarget{Server: logicalserver.PlayerRegion(owner), Owner: owner, HouseID: row.HouseID}, Name: row.Name, Hidden: row.Hidden, StateVersion: row.StateVersion, UpdatedAt: row.UpdatedAt.UTC()}
		if err := state.Validate(); err != nil {
			return nil, err
		}
		out[row.HouseID] = state
	}
	return out, nil
}
