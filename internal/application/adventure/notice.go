package adventure

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	NoticeOccur  int64 = 33
	NoticeFinish int64 = 34
)

// Notice is one PLAYER_NOTICE row: an occur push while the event is live and
// one finish push after its terminal.
type Notice struct {
	Type        int64
	TableID     int64
	SpecialData int64
	OccurredAt  time.Time
	EndTime     time.Time
	ServerTime  time.Time
}

type NoticeTime interface {
	Now(context.Context) (time.Time, error)
}

// NoticeReader reads one player's occurrences for the realtime notice route. A
// read never advances state; expiry only omits an occur push.
type NoticeReader struct {
	Store   Store
	Queryer tx.Queryer
	Time    NoticeTime
}

func (r NoticeReader) ReadNotices(c context.Context, player identity.PlayerID, _ operation.Context) ([]Notice, error) {
	if r.Store == nil || r.Queryer == nil || r.Time == nil || !player.Valid() {
		return nil, nil
	}
	at, err := r.Time.Now(c)
	if err != nil {
		return nil, err
	}
	occurrences, err := r.Store.ListOccurrencesTx(c, r.Queryer, player)
	if err != nil {
		return nil, err
	}
	out := make([]Notice, 0, len(occurrences))
	for _, occurrence := range occurrences {
		if occurrence.Finished() {
			out = append(out, Notice{Type: NoticeFinish, TableID: occurrence.EventType, OccurredAt: occurrence.OccurredAt})
			continue
		}
		if occurrence.Active(at) {
			out = append(out, Notice{Type: NoticeOccur, TableID: occurrence.EventType, SpecialData: occurrence.SpecialData, OccurredAt: occurrence.OccurredAt, EndTime: occurrence.EndTime, ServerTime: at})
		}
	}
	return out, nil
}
