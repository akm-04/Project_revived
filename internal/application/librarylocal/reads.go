package librarylocal

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// SchoolStoryCountTx is 100020's owner fact: the academy stories this player
// has claimed. Every player_library_talk_claims row is written by the
// LIBRARY_SCHOOL_STORY family, so the row count is the completed-story count.
func (s Service) SchoolStoryCountTx(c context.Context, q tx.Queryer, p identity.PlayerID) (int64, error) {
	if s.Library == nil {
		return 0, ErrUnavailable
	}
	claims, e := s.Library.ListTalkClaimsTx(c, q, p)
	if e != nil {
		return 0, e
	}
	return int64(len(claims)), nil
}
