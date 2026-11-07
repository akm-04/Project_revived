package dormhouse

import (
	"errors"
	"math"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

func socialPlayer(number int64) identity.PlayerID {
	if number > 0 && number < 100000 {
		return identity.PlayerID(125000 + number)
	}
	return identity.PlayerID(number)
}

func socialTarget() RoomTarget {
	return RoomTarget{Server: identity.LogicalServerID(1), Owner: socialPlayer(7), HouseID: 3}
}

func socialTime(minutes int64) time.Time {
	return time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC).Add(time.Duration(minutes) * time.Minute)
}

func liveComment(id, author int64, created time.Time, content string) HouseComment {
	return HouseComment{ID: id, Owner: socialPlayer(7), HouseID: 3, Author: socialPlayer(author), Content: content, CreatedAt: created}
}

func listed(comment HouseComment, likes int64) ListedComment {
	return ListedComment{Comment: comment, Likes: likes}
}

func roomComments(count int64, likes map[int64]int64) []ListedComment {
	rows := make([]ListedComment, 0, count)
	for i := int64(1); i <= count; i++ {
		rows = append(rows, listed(liveComment(i, 1000+i, socialTime(i), "row"), likes[i]))
	}
	return rows
}

func TestNormalizeRoomNameDisplayWidth(t *testing.T) {
	for _, name := range []string{
		"",
		"abcdefghijkl",
		"éééééééééééé",
		"一二三四五六",
		"abcdef一二三",
		strings.Repeat("😀", 6),
		strings.Repeat(string(rune(0x40000)), 12),
	} {
		got, err := NormalizeRoomName(name)
		if err != nil || got != name {
			t.Fatal("accepted name", name, got, err)
		}
	}
	for _, name := range []string{
		"abcdefghijklm",
		"ééééééééééééé",
		"一二三四五六七",
		"abcdef一二三四",
		strings.Repeat("😀", 7),
		strings.Repeat(string(rune(0x40000)), 13),
		"a\x00b",
		string([]byte{0xc3, 0x28}),
	} {
		if _, err := NormalizeRoomName(name); !errors.Is(err, ErrInvalidFacts) {
			t.Fatal("bad name accepted", name, err)
		}
	}
}

func TestPlanCommentWidthHalfUnits(t *testing.T) {
	target := socialTarget()
	at := socialTime(0)
	for _, content := range []string{
		strings.Repeat("a", 60),
		strings.Repeat("一", 30),
		strings.Repeat("1", 50),
		strings.Repeat("1", 60),
		strings.Repeat("a", 30) + strings.Repeat("一", 15),
		strings.Repeat("😀", 6) + strings.Repeat("a", 48),
	} {
		if _, err := PlanComment(nil, target, socialPlayer(9), 100, content, at); err != nil {
			t.Fatal("client-emitted comment refused", len(content), err)
		}
	}
	for _, content := range []string{
		"",
		strings.Repeat("a", 61),
		strings.Repeat("一", 31),
		strings.Repeat("1", 61),
		strings.Repeat("a", 30) + strings.Repeat("一", 16),
		strings.Repeat("😀", 7) + strings.Repeat("a", 47),
		"ab\x00c",
		string([]byte{0xc3, 0x28}),
	} {
		if _, err := PlanComment(nil, target, socialPlayer(9), 100, content, at); !errors.Is(err, ErrInvalidFacts) {
			t.Fatal("bad content accepted", len(content), err)
		}
	}
}

func TestPlanPraiseBoundedFacts(t *testing.T) {
	target := socialTarget()
	at := socialTime(0)
	first, err := PlanPraise(PraiseFacts{}, target, socialPlayer(9), at)
	if err != nil || !first.Created || first.Count != 1 || first.Praise.FirstAt != at || first.Praise.Owner != target.Owner || first.Praise.HouseID != target.HouseID || first.Praise.Actor != socialPlayer(9) {
		t.Fatal("first praise", first, err)
	}
	repeat, err := PlanPraise(PraiseFacts{Count: 1, Actor: &first.Praise}, target, socialPlayer(9), at.Add(time.Hour))
	if err != nil || repeat.Created || repeat.Count != 1 || !repeat.Praise.FirstAt.Equal(at) {
		t.Fatal("repeat must be idempotent without moving FirstAt", repeat, err)
	}
	other, err := PlanPraise(PraiseFacts{Count: 1}, target, socialPlayer(10), at)
	if err != nil || !other.Created || other.Count != 2 {
		t.Fatal("second actor", other, err)
	}
	maxExisting, err := PlanPraise(PraiseFacts{Count: MaxWireID, Actor: &first.Praise}, target, socialPlayer(9), at)
	if err != nil || maxExisting.Created || maxExisting.Count != MaxWireID {
		t.Fatal("count max with existing actor", maxExisting, err)
	}
	full, err := PlanPraise(PraiseFacts{Count: MaxWireID - 1}, target, socialPlayer(9), at)
	if err != nil || !full.Created || full.Count != MaxWireID {
		t.Fatal("count max-1 creates max", full, err)
	}
	for _, facts := range []PraiseFacts{
		{Count: -1},
		{Count: MaxWireID + 1},
		{Count: MaxWireID},
		{Count: 0, Actor: &first.Praise},
		{Count: 2, Actor: &HousePraise{Owner: socialPlayer(8), HouseID: 3, Actor: socialPlayer(9), FirstAt: at}},
		{Count: 2, Actor: &HousePraise{Owner: socialPlayer(7), HouseID: 4, Actor: socialPlayer(9), FirstAt: at}},
		{Count: 2, Actor: &HousePraise{Owner: socialPlayer(7), HouseID: 3, Actor: socialPlayer(10), FirstAt: at}},
		{Count: 2, Actor: &HousePraise{Owner: socialPlayer(7), HouseID: 3, Actor: socialPlayer(9)}},
	} {
		if _, err = PlanPraise(facts, target, socialPlayer(9), at); !errors.Is(err, ErrInvalidFacts) {
			t.Fatal("bad fact accepted", facts, err)
		}
	}
	if _, err = PlanPraise(PraiseFacts{}, target, target.Owner, at); !errors.Is(err, ErrUnqualified) {
		t.Fatal("owner self praise", err)
	}
	if _, err = PlanPraise(PraiseFacts{}, target, 0, at); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("invalid actor", err)
	}
	if _, err = PlanPraise(PraiseFacts{}, target, socialPlayer(9), time.Time{}); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("zero time", err)
	}
	for _, bad := range []RoomTarget{
		{Server: 0, Owner: socialPlayer(7), HouseID: 3},
		{Server: 1, Owner: socialPlayer(0), HouseID: 3},
		{Server: 1, Owner: socialPlayer(7), HouseID: 0},
		{Server: 1, Owner: socialPlayer(7), HouseID: MaxWireID + 1},
	} {
		if _, err = PlanPraise(PraiseFacts{}, bad, socialPlayer(9), at); !errors.Is(err, ErrInvalidFacts) {
			t.Fatal("invalid target accepted", bad, err)
		}
	}
}

func TestPagePraisesBoundedPage(t *testing.T) {
	target := socialTarget()
	rows := []HousePraise{
		{Owner: socialPlayer(7), HouseID: 3, Actor: socialPlayer(13), FirstAt: socialTime(3)},
		{Owner: socialPlayer(7), HouseID: 3, Actor: socialPlayer(12), FirstAt: socialTime(3)},
	}
	page, err := PagePraises(rows, 3, target, target.Owner, 0, 2)
	if err != nil || page.Total != 3 || len(page.Rows) != 2 || page.Rows[0].Actor != socialPlayer(13) || page.Rows[1].Actor != socialPlayer(12) {
		t.Fatal("first page", page, err)
	}
	last, err := PagePraises(rows[1:], 3, target, target.Owner, 2, 2)
	if err != nil || len(last.Rows) != 1 || last.Rows[0].Actor != socialPlayer(12) || last.Total != 3 {
		t.Fatal("second page", last, err)
	}
	empty, err := PagePraises(nil, 0, target, target.Owner, 0, 20)
	if err != nil || len(empty.Rows) != 0 || empty.Total != 0 {
		t.Fatal("empty room", empty, err)
	}
	end, err := PagePraises(nil, 3, target, target.Owner, 3, 20)
	if err != nil || len(end.Rows) != 0 || end.Total != 3 {
		t.Fatal("page at end", end, err)
	}
	for _, tc := range []struct {
		rows          []HousePraise
		total, start  int64
		offset        int64
		viewer        identity.PlayerID
		expectedError error
	}{
		{rows: rows, total: -1, offset: 20, viewer: target.Owner},
		{rows: rows, total: MaxWireID + 1, offset: 20, viewer: target.Owner},
		{rows: rows, total: 3, start: -1, offset: 20, viewer: target.Owner},
		{rows: rows, total: 3, start: 4, offset: 20, viewer: target.Owner},
		{rows: rows, total: 3, offset: 0, viewer: target.Owner},
		{rows: rows, total: 3, offset: 21, viewer: target.Owner},
		{rows: rows, total: 1, offset: 20, viewer: target.Owner},
		{rows: rows, total: 2, offset: 1, viewer: target.Owner},
		{rows: rows, total: math.MaxInt64, start: math.MaxInt64, offset: 20, viewer: target.Owner},
		{rows: []HousePraise{rows[0], rows[0]}, total: 2, offset: 20, viewer: target.Owner},
		{rows: []HousePraise{{Owner: socialPlayer(8), HouseID: 3, Actor: socialPlayer(13), FirstAt: socialTime(3)}}, total: 1, offset: 20, viewer: target.Owner},
		{rows: []HousePraise{{Owner: socialPlayer(7), HouseID: 4, Actor: socialPlayer(13), FirstAt: socialTime(3)}}, total: 1, offset: 20, viewer: target.Owner},
		{rows: []HousePraise{{Owner: socialPlayer(7), HouseID: 3, Actor: socialPlayer(13)}}, total: 1, offset: 20, viewer: target.Owner},
		{rows: nil, total: 0, offset: 20, viewer: socialPlayer(9), expectedError: ErrUnqualified},
		{rows: nil, total: 0, offset: 20, viewer: 225009, expectedError: ErrInvalidFacts},
	} {
		expected := tc.expectedError
		if expected == nil {
			expected = ErrInvalidFacts
		}
		if _, err = PagePraises(tc.rows, tc.total, target, tc.viewer, tc.start, tc.offset); !errors.Is(err, expected) {
			t.Fatal("praise page accepted", tc, err)
		}
	}
}

func TestPageCommentsOrderingAndBoundedStaleStart(t *testing.T) {
	target := socialTarget()
	comments := roomComments(45, map[int64]int64{44: 3, 45: 3})
	comments[44].HasReacted = true

	first, err := PageComments(comments, target, socialPlayer(9), 0, 20)
	if err != nil || first.Total != 45 || len(first.Best) != 2 || first.Best[0].Comment.ID != 44 || first.Best[1].Comment.ID != 45 || len(first.Rows) != 20 {
		t.Fatal("first page", first, err)
	}
	if first.Best[0].Likes != 3 || first.Best[1].Likes != 3 || !first.Best[1].HasReacted || first.Best[0].HasReacted {
		t.Fatal("best rows carry aggregate and viewer bit", first.Best)
	}
	if first.Rows[0].Comment.ID != 43 || first.Rows[1].Comment.ID != 42 {
		t.Fatal("normal rows newest first", first.Rows[0], first.Rows[1])
	}
	loaded := append([]ListedComment(nil), first.Rows...)
	second, err := PageComments(comments, target, socialPlayer(9), int64(len(loaded)), 20)
	if err != nil || len(second.Rows) != 20 {
		t.Fatal("second request", second, err)
	}
	loaded = append(loaded, second.Rows...)
	third, err := PageComments(comments, target, socialPlayer(9), int64(len(loaded)), 20)
	if err != nil || len(third.Rows) != 3 {
		t.Fatal("third request", third, err)
	}
	loaded = append(loaded, third.Rows...)
	if len(loaded) != 43 {
		t.Fatal("non-best rows", len(loaded))
	}

	withoutReactions := roomComments(45, nil)
	newest, err := PageComments(withoutReactions, target, socialPlayer(9), 0, 20)
	if err != nil || newest.Best[0].Comment.ID != 1 || newest.Best[1].Comment.ID != 2 || newest.Rows[0].Comment.ID != 45 {
		t.Fatal("zero-like featured is oldest-first and normal is newest-first", newest, err)
	}

	// Dorm.lua deleteComment refetches with the old loaded count after the
	// owner deletes a featured row: 44 live, 2 best, 42 non-best, start 43.
	afterDelete := roomComments(44, map[int64]int64{43: 3, 44: 3})
	stale, err := PageComments(afterDelete, target, socialPlayer(9), 43, 20)
	if err != nil || len(stale.Rows) != 0 || stale.Total != 44 || len(stale.Best) != 2 || stale.Best[0].Comment.ID != 43 || stale.Best[1].Comment.ID != 44 {
		t.Fatal("stale bounded start must be an empty normal page with current best", stale, err)
	}
	if stale.Rows == nil {
		t.Fatal("empty normal rows must be an empty slice")
	}
	boundedStale, err := PageComments(afterDelete, target, socialPlayer(9), maxStaleCommentStart, 20)
	if err != nil || len(boundedStale.Rows) != 0 || boundedStale.Total != 44 {
		t.Fatal("start at cap plus featured is empty", boundedStale, err)
	}
	for _, start := range []int64{int64(maxStaleCommentStart) + 1, math.MaxInt64} {
		if _, err = PageComments(afterDelete, target, socialPlayer(9), start, 20); !errors.Is(err, ErrInvalidFacts) {
			t.Fatal("unbounded stale start accepted", start, err)
		}
	}
	empty, err := PageComments(nil, target, socialPlayer(9), 0, 20)
	if err != nil || len(empty.Best) != 0 || len(empty.Rows) != 0 || empty.Total != 0 {
		t.Fatal("empty board", empty, err)
	}
	atCap := roomComments(MaxLiveCommentsPerRoom, nil)
	capPage, err := PageComments(atCap, target, socialPlayer(9), 0, 20)
	if err != nil || capPage.Total != MaxLiveCommentsPerRoom || len(capPage.Best) != 2 || len(capPage.Rows) != 20 {
		t.Fatal("200 live comments", capPage, err)
	}
	overCap := roomComments(MaxLiveCommentsPerRoom+1, nil)
	if _, err = PageComments(overCap, target, socialPlayer(9), 0, 20); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("201 live comments accepted", err)
	}
}

func TestPageCommentsRejectsMalformedProjections(t *testing.T) {
	target := socialTarget()
	comment := liveComment(10, 9, socialTime(0), "hello")
	deletedAt := socialTime(1)
	deleted := comment
	deleted.DeletedAt = &deletedAt
	foreignHouse := comment
	foreignHouse.HouseID = 4
	foreignOwner := comment
	foreignOwner.Owner = socialPlayer(8)
	badContent := comment
	badContent.Content = strings.Repeat("a", 61)
	for _, rows := range [][]ListedComment{
		{listed(comment, 0), listed(comment, 0)},
		{listed(deleted, 0)},
		{listed(foreignHouse, 0)},
		{listed(foreignOwner, 0)},
		{listed(badContent, 0)},
		{listed(comment, -1)},
		{listed(comment, MaxWireID+1)},
	} {
		if _, err := PageComments(rows, target, socialPlayer(11), 0, 20); !errors.Is(err, ErrInvalidFacts) {
			t.Fatal("malformed projection accepted", rows, err)
		}
	}
	if _, err := PageComments([]ListedComment{listed(comment, MaxWireID)}, target, socialPlayer(11), 0, 20); err != nil {
		t.Fatal("max likes projection refused", err)
	}
	for _, tc := range []struct{ start, offset int64 }{{-1, 20}, {0, 0}, {0, 21}, {math.MaxInt64, 20}} {
		if _, err := PageComments([]ListedComment{listed(comment, 0)}, target, socialPlayer(11), tc.start, tc.offset); !errors.Is(err, ErrInvalidFacts) {
			t.Fatal("bounds accepted", tc, err)
		}
	}
	if _, err := PageComments([]ListedComment{listed(comment, 0)}, target, 225011, 0, 20); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("foreign viewer accepted", err)
	}
}

func TestPlanCommentAtCapPrunesOldestNonFeatured(t *testing.T) {
	target := socialTarget()
	liked := roomComments(MaxLiveCommentsPerRoom, map[int64]int64{198: 5, 199: 5, 200: 5})
	plan, err := PlanComment(liked, target, socialPlayer(9000), 201, "new", socialTime(500))
	if err != nil || plan.LiveCount != MaxLiveCommentsPerRoom || len(plan.PrunedCommentIDs) != 1 || plan.PrunedCommentIDs[0] != 1 || plan.Comment.ID != 201 {
		t.Fatal("prune at cap", plan, err)
	}
	equal := make([]ListedComment, 0, MaxLiveCommentsPerRoom)
	for i := int64(1); i <= MaxLiveCommentsPerRoom; i++ {
		equal = append(equal, listed(liveComment(i, 1000+i, socialTime(0), "row"), 0))
	}
	equalPlan, err := PlanComment(equal, target, socialPlayer(9000), 201, "new", socialTime(500))
	if err != nil || len(equalPlan.PrunedCommentIDs) != 1 || equalPlan.PrunedCommentIDs[0] != 3 {
		t.Fatal("equal likes featured order then oldest non-featured", equalPlan, err)
	}
	under := liked[:MaxLiveCommentsPerRoom-1]
	underPlan, err := PlanComment(under, target, socialPlayer(9000), 201, "new", socialTime(500))
	if err != nil || underPlan.LiveCount != MaxLiveCommentsPerRoom || len(underPlan.PrunedCommentIDs) != 0 {
		t.Fatal("under cap", underPlan, err)
	}
	if _, err = PlanComment(liked, target, socialPlayer(9000), 199, "new", socialTime(500)); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("duplicate new id", err)
	}
	overCap := roomComments(MaxLiveCommentsPerRoom+1, nil)
	if _, err = PlanComment(overCap, target, socialPlayer(9000), 500, "new", socialTime(500)); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("over cap stored facts", err)
	}
	if _, err = PlanComment(liked, target, target.Owner, 201, "new", socialTime(500)); !errors.Is(err, ErrUnqualified) {
		t.Fatal("owner self comment", err)
	}
	if _, err = PlanComment(liked, target, socialPlayer(9000), 0, "new", socialTime(500)); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("zero comment id", err)
	}
	if _, err = PlanComment(liked, target, socialPlayer(9000), MaxWireID+1, "new", socialTime(500)); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("wire comment id", err)
	}
	if _, err = PlanComment(liked, target, socialPlayer(9000), 201, "new", time.Time{}); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("zero time", err)
	}
}

func TestPlanReactionBoundedFacts(t *testing.T) {
	target := socialTarget()
	comment := liveComment(10, 9, socialTime(0), "hello")
	at := socialTime(1)
	first, err := PlanReaction(ReactionFacts{Comment: &comment}, target, socialPlayer(11), 10, at)
	if err != nil || !first.Created || first.Likes != 1 || first.Reaction.CommentID != 10 || first.Reaction.Actor != socialPlayer(11) || first.Reaction.FirstAt != at {
		t.Fatal("first reaction", first, err)
	}
	repeat, err := PlanReaction(ReactionFacts{Comment: &comment, Likes: 1, Actor: &first.Reaction}, target, socialPlayer(11), 10, at.Add(time.Hour))
	if err != nil || repeat.Created || repeat.Likes != 1 || !repeat.Reaction.FirstAt.Equal(at) {
		t.Fatal("idempotent reaction", repeat, err)
	}
	maxExisting := first.Reaction
	maxExisting.FirstAt = socialTime(2)
	maxed, err := PlanReaction(ReactionFacts{Comment: &comment, Likes: MaxWireID, Actor: &maxExisting}, target, socialPlayer(11), 10, at)
	if err != nil || maxed.Created || maxed.Likes != MaxWireID {
		t.Fatal("likes max with existing actor", maxed, err)
	}
	full, err := PlanReaction(ReactionFacts{Comment: &comment, Likes: MaxWireID - 1}, target, socialPlayer(11), 10, at)
	if err != nil || !full.Created || full.Likes != MaxWireID {
		t.Fatal("likes max-1 creates max", full, err)
	}
	for _, facts := range []ReactionFacts{
		{Comment: &comment, Likes: -1},
		{Comment: &comment, Likes: MaxWireID + 1},
		{Comment: &comment, Likes: MaxWireID},
		{Comment: &comment, Likes: 0, Actor: &first.Reaction},
		{Comment: &comment, Likes: 2, Actor: &CommentReaction{CommentID: 11, Actor: socialPlayer(11), FirstAt: socialTime(2)}},
		{Comment: &comment, Likes: 2, Actor: &CommentReaction{CommentID: 10, Actor: socialPlayer(12), FirstAt: socialTime(2)}},
		{Comment: &comment, Likes: 2, Actor: &CommentReaction{CommentID: 10, Actor: socialPlayer(11), FirstAt: comment.CreatedAt.Add(-time.Second)}},
		{Comment: &HouseComment{}},
		{Comment: &HouseComment{ID: 11, Owner: socialPlayer(7), HouseID: 3, Author: socialPlayer(9), Content: "hello", CreatedAt: socialTime(0)}},
		{Comment: &HouseComment{ID: 10, Owner: socialPlayer(8), HouseID: 3, Author: socialPlayer(9), Content: "hello", CreatedAt: socialTime(0)}},
		{Comment: &HouseComment{ID: 10, Owner: socialPlayer(7), HouseID: 4, Author: socialPlayer(9), Content: "hello", CreatedAt: socialTime(0)}},
	} {
		if _, err = PlanReaction(facts, target, socialPlayer(11), 10, at); !errors.Is(err, ErrInvalidFacts) {
			t.Fatal("bad reaction fact accepted", facts, err)
		}
	}
	deletedAt := socialTime(2)
	deleted := comment
	deleted.DeletedAt = &deletedAt
	if _, err = PlanReaction(ReactionFacts{Comment: &deleted}, target, socialPlayer(11), 10, socialTime(3)); !errors.Is(err, ErrUnqualified) {
		t.Fatal("deleted comment reaction", err)
	}
	if _, err = PlanReaction(ReactionFacts{Comment: &comment}, target, target.Owner, 10, at); !errors.Is(err, ErrUnqualified) {
		t.Fatal("owner reaction must be refused", err)
	}
	if _, err = PlanReaction(ReactionFacts{Comment: &comment}, target, socialPlayer(11), 10, comment.CreatedAt.Add(-time.Second)); !errors.Is(err, ErrStaleTime) {
		t.Fatal("reaction before comment", err)
	}
	if _, err = PlanReaction(ReactionFacts{Comment: &comment}, target, socialPlayer(11), 10, time.Time{}); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("zero time", err)
	}
	if _, err = PlanReaction(ReactionFacts{Comment: &comment}, target, 225011, 10, at); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("foreign actor", err)
	}
}

func TestPlanDeleteCommentSingleProjection(t *testing.T) {
	target := socialTarget()
	comment := liveComment(10, 9, socialTime(0), "hello")
	at := socialTime(2)
	if _, err := PlanDeleteComment(&comment, target, socialPlayer(9), 10, at); !errors.Is(err, ErrUnqualified) {
		t.Fatal("author delete is not owner-only", err)
	}
	plan, err := PlanDeleteComment(&comment, target, target.Owner, 10, at)
	if err != nil || !plan.Changed || plan.Comment.ID != 10 || plan.Comment.DeletedAt == nil || !plan.Comment.DeletedAt.Equal(at) {
		t.Fatal("owner delete", plan, err)
	}
	repeat, err := PlanDeleteComment(&plan.Comment, target, target.Owner, 10, at.Add(time.Hour))
	if err != nil || repeat.Changed || !repeat.Comment.DeletedAt.Equal(at) {
		t.Fatal("idempotent delete", repeat, err)
	}
	if _, err = PlanDeleteComment(nil, target, target.Owner, 10, at); !errors.Is(err, ErrUnqualified) {
		t.Fatal("unknown comment delete", err)
	}
	if _, err = PlanDeleteComment(&comment, target, target.Owner, 11, at); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("mismatched comment id", err)
	}
	foreign := HouseComment{ID: 12, Owner: socialPlayer(8), HouseID: 3, Author: socialPlayer(9), Content: "x", CreatedAt: socialTime(0)}
	if _, err = PlanDeleteComment(&foreign, target, target.Owner, 12, at); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("foreign comment input", err)
	}
	invalid := comment
	invalid.Author = 0
	if _, err = PlanDeleteComment(&invalid, target, target.Owner, 10, at); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("invalid comment facts", err)
	}
	if _, err = PlanDeleteComment(&comment, target, target.Owner, 10, comment.CreatedAt.Add(-time.Second)); !errors.Is(err, ErrStaleTime) {
		t.Fatal("delete before create", err)
	}
	if _, err = PlanDeleteComment(&comment, target, 225007, 10, at); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("foreign actor", err)
	}
	if _, err = PlanDeleteComment(&comment, target, target.Owner, 0, at); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("zero comment id", err)
	}
	if _, err = PlanDeleteComment(&comment, target, target.Owner, 10, time.Time{}); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("zero time", err)
	}
}

func TestSocialPlansRejectServerIdentityMismatch(t *testing.T) {
	at := socialTime(0)
	target := RoomTarget{Server: 1, Owner: 125007, HouseID: 3}
	wrongOwner := target
	wrongOwner.Owner = 225007
	if _, err := PlanPraise(PraiseFacts{}, wrongOwner, 125009, at); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("foreign-server owner accepted", err)
	}
	if _, err := PlanPraise(PraiseFacts{}, target, 225009, at); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("foreign-server actor accepted", err)
	}
	if _, err := PlanComment(nil, target, 225009, 1, "hello", at); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("foreign-server author accepted", err)
	}
	comment := HouseComment{ID: 1, Owner: 125007, HouseID: 3, Author: 125009, Content: "hello", CreatedAt: at}
	if _, err := PlanReaction(ReactionFacts{Comment: &comment}, target, 225009, 1, at); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("foreign-server reaction accepted", err)
	}
	if _, err := PageComments([]ListedComment{listed(comment, 0)}, target, 225009, 0, 20); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("foreign-server viewer accepted", err)
	}
	if _, err := PagePraises(nil, 0, target, 225009, 0, 20); !errors.Is(err, ErrInvalidFacts) {
		t.Fatal("foreign-server praise viewer accepted", err)
	}
}
