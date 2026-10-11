package profilefeedback

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/profile"
	"strings"
	"time"
	"unicode/utf8"
)

const CommentPolicyVersion = "I7B_PROFILE_COMMENT_V1"
const MaxWireCommentID int64 = 9007199254740991

func ModerateComment(text string, words []string) (string, error) {
	if text == "" || !utf8.ValidString(text) || strings.ContainsRune(text, 0) || utf8.RuneCountInString(text) > 30 {
		return "", ErrInvalid
	}
	return profile.ModerateIntro(text, words)
}

type Comment struct {
	ID             int64
	Target, Author identity.PlayerID
	Content        string
	CreatedAt      time.Time
	CreatedVersion int64
	DeletedAt      *time.Time
	DeletedVersion *int64
	PraiseCount    int64
	HasPraised     bool
}

func (q Comment) Validate() error {
	if q.ID <= 0 || q.ID > MaxWireCommentID || !q.Target.Valid() || int64(q.Target) > MaxWireCommentID || !q.Author.Valid() || int64(q.Author) > MaxWireCommentID || q.Target == q.Author || q.CreatedAt.IsZero() || q.CreatedVersion <= 0 || q.Content == "" || !utf8.ValidString(q.Content) || strings.ContainsRune(q.Content, 0) || utf8.RuneCountInString(q.Content) > 30 || q.PraiseCount < 0 || q.PraiseCount > MaxWireCommentID {
		return ErrInvalid
	}
	if (q.DeletedAt == nil) != (q.DeletedVersion == nil) {
		return ErrInvalid
	}
	if q.DeletedAt != nil && (q.DeletedAt.IsZero() || *q.DeletedVersion <= q.CreatedVersion) {
		return ErrInvalid
	}
	return nil
}

type CommentReaction struct {
	CommentID   int64
	Actor       identity.PlayerID
	FirstAt     time.Time
	RootVersion int64
}

func (r CommentReaction) Validate() error {
	if r.CommentID <= 0 || r.CommentID > MaxWireCommentID || !r.Actor.Valid() || int64(r.Actor) > MaxWireCommentID || r.FirstAt.IsZero() || r.RootVersion <= 0 {
		return ErrInvalid
	}
	return nil
}

// Typed current public projection. It contains no operation receipts or
// credentials; all required author values come from the accepted I4/I5 ports.
type PublicAuthor struct {
	PlayerID int64  `json:"player_id"`
	Name     string `json:"player_name"`
	Avatar   int64  `json:"avatar_id"`
	Frame    int64  `json:"avatar_frame_id"`
	Level    int64  `json:"lev"`
	Region   int32  `json:"region"`
}
type CommentRow struct {
	ID          int64             `json:"comment_id"`
	Owner       identity.PlayerID `json:"player_id"`
	Author      PublicAuthor      `json:"player_info"`
	Content     string            `json:"content"`
	PraiseCount int64             `json:"praise_num"`
	HasPraised  int64             `json:"is_has_praise"`
}
type CommentObservation struct {
	Target, Actor      identity.PlayerID
	RootVersion, Count int64
	Revision           string
	ObservedAt         time.Time
	Best, Rows         []CommentRow
}

func (p CommentObservation) Wire() map[string]any {
	return map[string]any{"best_comments": p.Best, "comment_list": p.Rows, "comment_num": p.Count}
}
