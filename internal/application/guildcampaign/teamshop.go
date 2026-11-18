package guildcampaign

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TeamShopEligibleTx is the server-side team-shop predicate of 11C C3/C12: the
// chapter is open at chapter_version 2 and the member joined the guild strictly
// before the run started (Shop.lua:301-312 mirrors it in the client).
func (m Mode) TeamShopEligibleTx(c context.Context, q tx.Queryer, player identity.PlayerID, chapterID int64) (bool, error) {
	if chapterID <= 0 || m.Settings.ChapterVersion(chapterID) != 2 {
		return false, nil
	}
	membership, joined, err := m.Service.Guilds.ReadMembershipTx(c, q, player)
	if err != nil || !joined {
		return false, err
	}
	chapter, open, err := m.ModeStore.ReadChapterTx(c, q, int64(membership.GuildID), chapterID)
	if err != nil || !open {
		return false, err
	}
	return membership.JoinedAt.Before(chapter.StartTime), nil
}
