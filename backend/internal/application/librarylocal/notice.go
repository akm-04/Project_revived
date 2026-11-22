package librarylocal

import (
	"context"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// MissionNoticeRoute wakes the realtime projection that pushes notice 20
// (LIBRARY_MISSION). Its reference is "<player>:<partner_id>:<mission_id>".
const MissionNoticeRoute = "library.mission.v1"

// MissionNoticeRef is the bounded wakeup reference of one awarded mission.
func MissionNoticeRef(player identity.PlayerID, partnerID, missionID int64) string {
	return strconv.FormatInt(int64(player), 10) + ":" + strconv.FormatInt(partnerID, 10) + ":" + strconv.FormatInt(missionID, 10)
}

// MissionNotice is the notice-20 body of one awarded partner mission.
type MissionNotice struct {
	Player       identity.PlayerID
	PartnerID    int64
	MissionID    int64
	Process      int64
	MissionState int64
	Favor        int64
}

// MissionNoticePort is the Library owner's read surface for notice 20.
type MissionNoticePort interface {
	ListMissionsTx(context.Context, tx.Queryer, identity.PlayerID) ([]lib.MissionFact, error)
	ReadHeroTx(context.Context, tx.Queryer, character.HeroRef) (lib.HeroFacts, error)
}

// MissionNoticeReader projects one awarded mission after its commit, so the
// pushed row and favor match the durable state the client would load.
type MissionNoticeReader struct {
	Queryer tx.Queryer
	Library MissionNoticePort
}

func (r MissionNoticeReader) ReadMissionNotice(ctx context.Context, player identity.PlayerID, partnerID, missionID int64) (MissionNotice, error) {
	if r.Queryer == nil || r.Library == nil || !player.Valid() || partnerID <= 0 || missionID <= 0 {
		return MissionNotice{}, lib.ErrUnqualified
	}
	rows, err := r.Library.ListMissionsTx(ctx, r.Queryer, player)
	if err != nil {
		return MissionNotice{}, err
	}
	for _, row := range rows {
		if row.PartnerID != partnerID || row.MissionID != missionID {
			continue
		}
		facts, err := r.Library.ReadHeroTx(ctx, r.Queryer, character.HeroRef{PlayerID: player, PartnerID: partnerID})
		if err != nil {
			return MissionNotice{}, err
		}
		return MissionNotice{Player: player, PartnerID: partnerID, MissionID: missionID, Process: row.Process, MissionState: row.MissionState, Favor: facts.Favor}, nil
	}
	return MissionNotice{}, lib.ErrUnqualified
}

// PartnerLogNoticeRoute wakes the realtime projection that pushes notice 24
// (LIBRARY_PARTNER_LOG). Its reference is "<player>:<partner_id>".
const PartnerLogNoticeRoute = "library.partner_log.v1"

// PartnerLogRef is the bounded wakeup reference of one changed Girls Log owner.
func PartnerLogRef(player identity.PlayerID, partnerID int64) string {
	return strconv.FormatInt(int64(player), 10) + ":" + strconv.FormatInt(partnerID, 10)
}

// PartnerLogPort is the Library owner's read surface for the log projection.
type PartnerLogPort interface {
	ListHeroLogsTx(context.Context, tx.Queryer, identity.PlayerID) ([]lib.HeroLogFact, error)
	ListHeroDialogueCountsTx(context.Context, tx.Queryer, identity.PlayerID) (map[int64]int64, error)
	ReadHeroTx(context.Context, tx.Queryer, character.HeroRef) (lib.HeroFacts, error)
}

// PartnerLogReader projects one partner's full Girls Log map with the same
// function 836 uses, so a notice replaces the client cache without divergence.
type PartnerLogReader struct {
	Queryer tx.Queryer
	Library PartnerLogPort
}

func (r PartnerLogReader) ReadPartnerLog(ctx context.Context, player identity.PlayerID, partnerID int64, at time.Time) (map[string]any, error) {
	if r.Queryer == nil || r.Library == nil || !player.Valid() || partnerID <= 0 || at.IsZero() {
		return nil, lib.ErrUnqualified
	}
	rows, err := r.Library.ListHeroLogsTx(ctx, r.Queryer, player)
	if err != nil {
		return nil, err
	}
	dialogueCounts, err := r.Library.ListHeroDialogueCountsTx(ctx, r.Queryer, player)
	if err != nil {
		return nil, err
	}
	facts, err := r.Library.ReadHeroTx(ctx, r.Queryer, character.HeroRef{PlayerID: player, PartnerID: partnerID})
	if err != nil {
		return nil, err
	}
	return partnerLogMap(rows, partnerID, facts.Favor, dialogueCounts[partnerID], facts.CreatedAt, at), nil
}
