package dormhouse

import (
	"sort"
	"strings"
	"time"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
)

const (
	MaxRoomNameHalfUnits   = 12
	MaxCommentHalfUnits    = 60
	MaxLiveCommentsPerRoom = 200
	FeaturedCommentCount   = 2
	MaxSocialPageRows      = 20

	// A stale page start can exceed the remaining non-featured rows after the
	// owner deletes a featured comment. The client then refetches with its old
	// loaded count; anything within one cap plus the featured rows is bounded.
	maxStaleCommentStart = MaxLiveCommentsPerRoom + FeaturedCommentCount
)

// RoomTarget is the server-scoped (owner, house) pair a social plan operates
// on. A persisted owner must still lock and verify the room row itself.
type RoomTarget struct {
	Server  identity.LogicalServerID
	Owner   identity.PlayerID
	HouseID int64
}

func (t RoomTarget) Validate() error {
	if !t.Server.Valid() || !validSocialPlayer(t.Owner) || logicalserver.PlayerRegion(t.Owner) != t.Server || !validHouseID(t.HouseID) {
		return ErrInvalidFacts
	}
	return nil
}

func validSocialPlayer(player identity.PlayerID) bool {
	return player.Valid() && int64(player) <= MaxWireID && logicalserver.PlayerRegion(player).Valid()
}

func validRoomPlayer(player identity.PlayerID, target RoomTarget) bool {
	return validSocialPlayer(player) && logicalserver.PlayerRegion(player) == target.Server
}

func validHouseID(id int64) bool {
	return id >= 1 && id <= MaxWireID
}

// Limits are integer half-units of the stock width gate: a code point whose
// UTF-8 lead byte is 226..240 counts two half-units and every other code point
// one. The comment truncator charges digits 0.65 units, so this superset
// accepts everything getTextstrNewTTF can emit.
func displayHalfUnits(text string) int {
	halfUnits := 0
	for _, character := range text {
		halfUnits++
		if character >= 0x2000 && character <= 0x3FFFF {
			halfUnits++
		}
	}
	return halfUnits
}

func validBoundedText(text string, maxHalfUnits int) bool {
	if !utf8.ValidString(text) || strings.ContainsRune(text, 0) {
		return false
	}
	halfUnits := displayHalfUnits(text)
	return halfUnits >= 1 && halfUnits <= maxHalfUnits
}

// NormalizeRoomName applies the source six-unit limit only. Public-profile
// moderation stays an application port; an empty name means the client shows
// its own default.
func NormalizeRoomName(name string) (string, error) {
	if name == "" {
		return "", nil
	}
	if !validBoundedText(name, MaxRoomNameHalfUnits) {
		return "", ErrInvalidFacts
	}
	return name, nil
}

type HousePraise struct {
	Owner   identity.PlayerID
	HouseID int64
	Actor   identity.PlayerID
	FirstAt time.Time
}

func (praise HousePraise) Validate() error {
	if !validSocialPlayer(praise.Owner) || !validHouseID(praise.HouseID) || !validSocialPlayer(praise.Actor) || praise.Actor == praise.Owner || logicalserver.PlayerRegion(praise.Actor) != logicalserver.PlayerRegion(praise.Owner) || praise.FirstAt.IsZero() {
		return ErrInvalidFacts
	}
	return nil
}

type HouseComment struct {
	ID        int64
	Owner     identity.PlayerID
	HouseID   int64
	Author    identity.PlayerID
	Content   string
	CreatedAt time.Time
	DeletedAt *time.Time
}

func (comment HouseComment) Live() bool { return comment.DeletedAt == nil }

func (comment HouseComment) Validate() error {
	if comment.ID < 1 || comment.ID > MaxWireID || !validSocialPlayer(comment.Owner) || !validHouseID(comment.HouseID) || !validSocialPlayer(comment.Author) || comment.Author == comment.Owner || logicalserver.PlayerRegion(comment.Author) != logicalserver.PlayerRegion(comment.Owner) || !validBoundedText(comment.Content, MaxCommentHalfUnits) || comment.CreatedAt.IsZero() {
		return ErrInvalidFacts
	}
	if comment.DeletedAt != nil && (comment.DeletedAt.IsZero() || comment.DeletedAt.Before(comment.CreatedAt)) {
		return ErrInvalidFacts
	}
	return nil
}

type CommentReaction struct {
	CommentID int64
	Actor     identity.PlayerID
	FirstAt   time.Time
}

func (reaction CommentReaction) Validate() error {
	if reaction.CommentID < 1 || reaction.CommentID > MaxWireID || !validSocialPlayer(reaction.Actor) || reaction.FirstAt.IsZero() {
		return ErrInvalidFacts
	}
	return nil
}

// PraiseFacts is the bounded praise click input. Count is the room's lifetime
// praise COUNT and Actor is the requesting actor's membership, if any; the
// store proves both under the locked Dorm root.
type PraiseFacts struct {
	Count int64
	Actor *HousePraise
}

type PraisePlan struct {
	Praise  HousePraise
	Count   int64
	Created bool
}

type PraisePage struct {
	Rows  []HousePraise
	Total int64
}

// ListedComment is one live comment projection: the comment plus its
// aggregate like count and the viewer's own reaction. The store proves the
// aggregate; the reaction unique key still owns one-per-actor.
type ListedComment struct {
	Comment    HouseComment
	Likes      int64
	HasReacted bool
}

type CommentPageResult struct {
	Best  []ListedComment
	Rows  []ListedComment
	Total int64
}

type CommentPlan struct {
	Comment          HouseComment
	PrunedCommentIDs []int64
	LiveCount        int64
}

// ReactionFacts is one live comment with its aggregate like COUNT and the
// requesting actor's reaction, if any. A nil Comment means the room has no
// such comment.
type ReactionFacts struct {
	Comment *HouseComment
	Likes   int64
	Actor   *CommentReaction
}

type ReactionPlan struct {
	Reaction CommentReaction
	Likes    int64
	Created  bool
}

type DeleteCommentPlan struct {
	Comment HouseComment
	Changed bool
}

func validatePraiseFacts(facts PraiseFacts, target RoomTarget, actor identity.PlayerID) error {
	if facts.Count < 0 || facts.Count > MaxWireID {
		return ErrInvalidFacts
	}
	if facts.Actor == nil {
		return nil
	}
	if err := facts.Actor.Validate(); err != nil {
		return err
	}
	if facts.Actor.Owner != target.Owner || facts.Actor.HouseID != target.HouseID || facts.Actor.Actor != actor || facts.Count < 1 {
		return ErrInvalidFacts
	}
	return nil
}

func validateListedComments(rows []ListedComment, target RoomTarget) error {
	if len(rows) > MaxLiveCommentsPerRoom {
		return ErrInvalidFacts
	}
	seen := map[int64]bool{}
	for _, row := range rows {
		if err := row.Comment.Validate(); err != nil {
			return err
		}
		comment := row.Comment
		if !comment.Live() || comment.Owner != target.Owner || comment.HouseID != target.HouseID || seen[comment.ID] || row.Likes < 0 || row.Likes > MaxWireID {
			return ErrInvalidFacts
		}
		seen[comment.ID] = true
	}
	return nil
}

func featuredOrder(rows []ListedComment) []ListedComment {
	out := append([]ListedComment(nil), rows...)
	sort.Slice(out, func(i, j int) bool {
		if out[i].Likes != out[j].Likes {
			return out[i].Likes > out[j].Likes
		}
		if !out[i].Comment.CreatedAt.Equal(out[j].Comment.CreatedAt) {
			return out[i].Comment.CreatedAt.Before(out[j].Comment.CreatedAt)
		}
		return out[i].Comment.ID < out[j].Comment.ID
	})
	return out
}

func newestCommentOrder(rows []ListedComment) []ListedComment {
	out := append([]ListedComment(nil), rows...)
	sort.Slice(out, func(i, j int) bool {
		if !out[i].Comment.CreatedAt.Equal(out[j].Comment.CreatedAt) {
			return out[i].Comment.CreatedAt.After(out[j].Comment.CreatedAt)
		}
		return out[i].Comment.ID > out[j].Comment.ID
	})
	return out
}

func oldestNonFeaturedCommentID(rows []ListedComment) (int64, bool) {
	ranked := featuredOrder(rows)
	featured := map[int64]bool{}
	for i, row := range ranked {
		if i >= FeaturedCommentCount {
			break
		}
		featured[row.Comment.ID] = true
	}
	var oldest *HouseComment
	for i := range rows {
		comment := &rows[i].Comment
		if featured[comment.ID] {
			continue
		}
		if oldest == nil || comment.CreatedAt.Before(oldest.CreatedAt) || (comment.CreatedAt.Equal(oldest.CreatedAt) && comment.ID < oldest.ID) {
			oldest = comment
		}
	}
	if oldest == nil {
		return 0, false
	}
	return oldest.ID, true
}

func PlanPraise(facts PraiseFacts, target RoomTarget, actor identity.PlayerID, at time.Time) (PraisePlan, error) {
	if err := target.Validate(); err != nil {
		return PraisePlan{}, err
	}
	if !validRoomPlayer(actor, target) || at.IsZero() {
		return PraisePlan{}, ErrInvalidFacts
	}
	if actor == target.Owner {
		return PraisePlan{}, ErrUnqualified
	}
	if err := validatePraiseFacts(facts, target, actor); err != nil {
		return PraisePlan{}, err
	}
	if facts.Actor != nil {
		return PraisePlan{Praise: *facts.Actor, Count: facts.Count}, nil
	}
	if facts.Count >= MaxWireID {
		return PraisePlan{}, ErrInvalidFacts
	}
	praise := HousePraise{Owner: target.Owner, HouseID: target.HouseID, Actor: actor, FirstAt: at.UTC()}
	if err := praise.Validate(); err != nil {
		return PraisePlan{}, err
	}
	return PraisePlan{Praise: praise, Count: facts.Count + 1, Created: true}, nil
}

// PagePraises serves only the owner: the stock room window opens the praise
// list for the self dorm and sends no host_id. Rows are the store's bounded
// page already ordered newest-first.
func PagePraises(rows []HousePraise, total int64, target RoomTarget, viewer identity.PlayerID, start, offset int64) (PraisePage, error) {
	if err := target.Validate(); err != nil {
		return PraisePage{}, err
	}
	if !validRoomPlayer(viewer, target) {
		return PraisePage{}, ErrInvalidFacts
	}
	if viewer != target.Owner {
		return PraisePage{}, ErrUnqualified
	}
	if total < 0 || total > MaxWireID || start < 0 || start > total || offset < 1 || offset > MaxSocialPageRows {
		return PraisePage{}, ErrInvalidFacts
	}
	if int64(len(rows)) > offset || int64(len(rows)) > total-start {
		return PraisePage{}, ErrInvalidFacts
	}
	seen := map[identity.PlayerID]bool{}
	for _, praise := range rows {
		if err := praise.Validate(); err != nil {
			return PraisePage{}, err
		}
		if praise.Owner != target.Owner || praise.HouseID != target.HouseID || seen[praise.Actor] {
			return PraisePage{}, ErrInvalidFacts
		}
		seen[praise.Actor] = true
	}
	return PraisePage{Rows: append([]HousePraise(nil), rows...), Total: total}, nil
}

// PageComments mirrors Dorm.lua getCommentInfos: best comments are separate,
// and start is the number of non-best rows the model has already loaded. A
// bounded stale start after a featured delete yields an empty normal page.
func PageComments(rows []ListedComment, target RoomTarget, viewer identity.PlayerID, start, offset int64) (CommentPageResult, error) {
	if err := target.Validate(); err != nil {
		return CommentPageResult{}, err
	}
	if !validRoomPlayer(viewer, target) || start < 0 || offset < 1 || offset > MaxSocialPageRows {
		return CommentPageResult{}, ErrInvalidFacts
	}
	if start > int64(maxStaleCommentStart) {
		return CommentPageResult{}, ErrInvalidFacts
	}
	if err := validateListedComments(rows, target); err != nil {
		return CommentPageResult{}, err
	}
	ranked := featuredOrder(rows)
	best := append([]ListedComment{}, ranked[:min(len(ranked), FeaturedCommentCount)]...)
	featured := map[int64]bool{}
	for _, row := range best {
		featured[row.Comment.ID] = true
	}
	nonBest := make([]ListedComment, 0, len(rows))
	for _, row := range newestCommentOrder(rows) {
		if !featured[row.Comment.ID] {
			nonBest = append(nonBest, row)
		}
	}
	if start > int64(len(nonBest)) {
		return CommentPageResult{Best: best, Rows: []ListedComment{}, Total: int64(len(rows))}, nil
	}
	end := min(start+offset, int64(len(nonBest)))
	return CommentPageResult{Best: best, Rows: append([]ListedComment{}, nonBest[start:end]...), Total: int64(len(rows))}, nil
}

func PlanComment(rows []ListedComment, target RoomTarget, author identity.PlayerID, commentID int64, content string, at time.Time) (CommentPlan, error) {
	if err := target.Validate(); err != nil {
		return CommentPlan{}, err
	}
	if !validRoomPlayer(author, target) || commentID < 1 || commentID > MaxWireID || !validBoundedText(content, MaxCommentHalfUnits) || at.IsZero() {
		return CommentPlan{}, ErrInvalidFacts
	}
	if author == target.Owner {
		return CommentPlan{}, ErrUnqualified
	}
	if err := validateListedComments(rows, target); err != nil {
		return CommentPlan{}, err
	}
	// Live projections cannot see tombstones; the store's unique key remains
	// authoritative for a replayed comment ID.
	for _, row := range rows {
		if row.Comment.ID == commentID {
			return CommentPlan{}, ErrInvalidFacts
		}
	}
	pruned := []int64{}
	if len(rows) == MaxLiveCommentsPerRoom {
		id, found := oldestNonFeaturedCommentID(rows)
		if !found {
			return CommentPlan{}, ErrInvalidFacts
		}
		pruned = append(pruned, id)
	}
	comment := HouseComment{ID: commentID, Owner: target.Owner, HouseID: target.HouseID, Author: author, Content: content, CreatedAt: at.UTC()}
	if err := comment.Validate(); err != nil {
		return CommentPlan{}, err
	}
	return CommentPlan{Comment: comment, PrunedCommentIDs: pruned, LiveCount: int64(len(rows)) + 1 - int64(len(pruned))}, nil
}

// PlanReaction refuses the owner: DormMessageBoardWindow.lua:223-229 hides the
// praise control in the self dorm, matching the owner refusal for comments.
func PlanReaction(facts ReactionFacts, target RoomTarget, actor identity.PlayerID, commentID int64, at time.Time) (ReactionPlan, error) {
	if err := target.Validate(); err != nil {
		return ReactionPlan{}, err
	}
	if !validRoomPlayer(actor, target) || commentID < 1 || commentID > MaxWireID || at.IsZero() {
		return ReactionPlan{}, ErrInvalidFacts
	}
	if actor == target.Owner {
		return ReactionPlan{}, ErrUnqualified
	}
	if facts.Comment == nil {
		return ReactionPlan{}, ErrUnqualified
	}
	comment := *facts.Comment
	if err := comment.Validate(); err != nil {
		return ReactionPlan{}, err
	}
	if comment.ID != commentID || comment.Owner != target.Owner || comment.HouseID != target.HouseID {
		return ReactionPlan{}, ErrInvalidFacts
	}
	if !comment.Live() {
		return ReactionPlan{}, ErrUnqualified
	}
	if facts.Likes < 0 || facts.Likes > MaxWireID {
		return ReactionPlan{}, ErrInvalidFacts
	}
	// A backward step records the reaction at the comment's stored creation,
	// never before it; the reaction itself still succeeds.
	effective := at
	if comment.CreatedAt.After(effective) {
		effective = comment.CreatedAt
	}
	if facts.Actor != nil {
		if err := facts.Actor.Validate(); err != nil {
			return ReactionPlan{}, err
		}
		if facts.Actor.CommentID != commentID || facts.Actor.Actor != actor || !validRoomPlayer(facts.Actor.Actor, target) || facts.Actor.FirstAt.Before(comment.CreatedAt) || facts.Likes < 1 {
			return ReactionPlan{}, ErrInvalidFacts
		}
		return ReactionPlan{Reaction: *facts.Actor, Likes: facts.Likes}, nil
	}
	if facts.Likes >= MaxWireID {
		return ReactionPlan{}, ErrInvalidFacts
	}
	reaction := CommentReaction{CommentID: commentID, Actor: actor, FirstAt: effective.UTC()}
	if err := reaction.Validate(); err != nil {
		return ReactionPlan{}, err
	}
	return ReactionPlan{Reaction: reaction, Likes: facts.Likes + 1, Created: true}, nil
}

// PlanDeleteComment returns the deleted comment; its ID names the reaction
// rows the application must remove in the same transaction.
func PlanDeleteComment(comment *HouseComment, target RoomTarget, actor identity.PlayerID, commentID int64, at time.Time) (DeleteCommentPlan, error) {
	if err := target.Validate(); err != nil {
		return DeleteCommentPlan{}, err
	}
	if !validRoomPlayer(actor, target) || commentID < 1 || commentID > MaxWireID || at.IsZero() {
		return DeleteCommentPlan{}, ErrInvalidFacts
	}
	if actor != target.Owner {
		return DeleteCommentPlan{}, ErrUnqualified
	}
	if comment == nil {
		return DeleteCommentPlan{}, ErrUnqualified
	}
	if err := comment.Validate(); err != nil {
		return DeleteCommentPlan{}, err
	}
	if comment.ID != commentID || comment.Owner != target.Owner || comment.HouseID != target.HouseID {
		return DeleteCommentPlan{}, ErrInvalidFacts
	}
	if comment.DeletedAt != nil {
		return DeleteCommentPlan{Comment: *comment}, nil
	}
	// A backward step records the deletion at the comment's stored creation,
	// never before it; the deletion itself still succeeds.
	effective := at
	if comment.CreatedAt.After(effective) {
		effective = comment.CreatedAt
	}
	updated := *comment
	deletedAt := effective.UTC()
	updated.DeletedAt = &deletedAt
	if err := updated.Validate(); err != nil {
		return DeleteCommentPlan{}, err
	}
	return DeleteCommentPlan{Comment: updated, Changed: true}, nil
}
