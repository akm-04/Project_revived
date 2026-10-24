package socialinboxstore

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type inboxTestTag int64

func (t inboxTestTag) RowsAffected() int64 { return int64(t) }

type inboxTestRow struct{ scan func(...any) error }

func (r inboxTestRow) Scan(v ...any) error { return r.scan(v...) }

type inboxTestTx struct{ row func(string, ...any) tx.Row }

func (*inboxTestTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return inboxTestTag(1), nil
}
func (t *inboxTestTx) QueryRow(_ context.Context, q string, args ...any) tx.Row {
	return t.row(q, args...)
}
func (*inboxTestTx) Commit(context.Context) error   { return nil }
func (*inboxTestTx) Rollback(context.Context) error { return nil }

func TestNextNoticeIDUsesInboxSequence(t *testing.T) {
	q := &inboxTestTx{row: func(query string, args ...any) tx.Row {
		if query != nextNoticeIDSQL || len(args) != 0 {
			t.Fatalf("query=%q args=%v", query, args)
		}
		return inboxTestRow{scan: func(v ...any) error { *(v[0].(*int64)) = 41; return nil }}
	}}
	id, err := (Store{}).NextNoticeIDTx(context.Background(), q)
	if err != nil || id != 41 {
		t.Fatalf("id=%d err=%v", id, err)
	}
}

func TestLockNoticeAllowsSourceEventBeforeMaterializationTime(t *testing.T) {
	noticeTime := time.Unix(100, 0).UTC()
	created := time.Unix(200, 0).UTC()
	q := &inboxTestTx{row: func(query string, args ...any) tx.Row {
		if query != lockNoticeSQL || args[0] != int64(100001) || args[1] != int64(7) {
			t.Fatalf("query=%q args=%v", query, args)
		}
		return inboxTestRow{scan: func(v ...any) error {
			*(v[0].(*int64)) = 100001
			*(v[1].(*int64)) = 7
			*(v[2].(*int16)) = 1
			*(v[3].(*string)) = "friend-request"
			*(v[4].(*string)) = "r:3:accepted"
			var related int64 = 200001
			*(v[5].(**int64)) = &related
			*(v[6].(*bool)) = true
			*(v[7].(*time.Time)) = noticeTime
			*(v[8].(**time.Time)) = nil
			*(v[9].(*int64)) = 1
			*(v[10].(*time.Time)) = created
			*(v[11].(*time.Time)) = created
			return nil
		}}
	}}
	got, ok, err := (Store{}).LockNoticeTx(context.Background(), q, 100001, socialinbox.NoticeID(7))
	if err != nil || !ok || got.RelatedPlayerID != 200001 || !got.NoticeTime.Equal(noticeTime) {
		t.Fatalf("got=%+v ok=%v err=%v", got, ok, err)
	}
}
