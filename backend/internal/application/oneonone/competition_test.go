package oneonone

import (
	"context"
	"strconv"
	"testing"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	d "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type noticeMail struct {
	Mail
	notices    []i5.SettlementMailRequest
	deliveries []i5.SettlementMailRequest
}

func (m *noticeMail) LockRecipientsTx(context.Context, tx.Tx, []identity.PlayerID) error { return nil }

func (m *noticeMail) DeliverTx(_ context.Context, _ tx.Tx, request i5.SettlementMailRequest) (mail.Record, bool, error) {
	m.deliveries = append(m.deliveries, request)
	return mail.Record{}, false, nil
}

func (m *noticeMail) DeliverNoticeTx(_ context.Context, _ tx.Tx, request i5.SettlementMailRequest) (mail.Record, bool, error) {
	m.notices = append(m.notices, request)
	return mail.Record{}, false, nil
}

type settlementRecorder struct {
	Store
	settlement *d.Settlement
}

func (s *settlementRecorder) InsertSettlementTx(_ context.Context, _ tx.Tx, settlement d.Settlement) error {
	*s.settlement = settlement
	return nil
}

type weekAchievements struct{ Achievements }

func (weekAchievements) ObserveOneOnOneWeekTx(context.Context, tx.Tx, identity.LogicalServerID, int64, string, []identity.PlayerID, time.Time) error {
	return nil
}

func settlementFixture(t *testing.T, day int64, mailbox *noticeMail) (Service, gen.TimedScope, d.Catalog, []d.Ranked, d.Transition) {
	t.Helper()
	at := d.Instant(day, 79200)
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	op, err := gen.NewTimedOperation(operation.Context{ID: id, StartedAt: at}, at)
	if err != nil {
		t.Fatal(err)
	}
	catalog := d.Catalog{
		Mail: map[string]string{
			"LEGEND_MAIL_TITLE":        "Rank reward",
			"LEGEND_MAIL_TEXT":         "Your rank was %d",
			"LEGEND_MAIL_SENDER":       "Committee Joan",
			"LEGEND_KUAFU_MAIL_TITLE":  "1 on 1 Title Reward",
			"LEGEND_KUAFU_MAIL_TEXT":   "Global 1 on 1 is %d",
			"LEGEND_KUAFU_MAIL_SENDER": "Committee Quinie",
		},
		Rewards: []d.Reward{{ID: 1, Range: 1}},
		Titles:  []d.Title{{TitleID: 100002, First: 1, Last: 1, Seconds: 604800}},
	}
	ranked := []d.Ranked{{Standing: d.Standing{Player: identity.PlayerID(42), Server: identity.LogicalServerID(1)}, Global: 1, ServerRank: 1}}
	service := Service{Store: &settlementRecorder{settlement: &d.Settlement{}}, Mail: mailbox, Achievements: weekAchievements{}}
	scope := gen.TimedScope{Operation: op, Attempt: 1}
	next := d.Transition{Kind: d.TransitionSettle, Key: day, At: at}
	return service, scope, catalog, ranked, next
}

// A Sunday title award sends one text-only LEGEND_KUAFU notice carrying the global rank.
func TestSettleTxSendsTitleNotice(t *testing.T) {
	const sunday int64 = 3
	mailbox := &noticeMail{}
	service, scope, catalog, ranked, next := settlementFixture(t, sunday, mailbox)
	if err := service.settleTx(context.Background(), scope, catalog, "revision", d.Competition{StateVersion: 1}, ranked, next); err != nil {
		t.Fatal(err)
	}
	if len(mailbox.deliveries) != 0 {
		t.Fatalf("a reward without lines must not be delivered: %+v", mailbox.deliveries)
	}
	if len(mailbox.notices) != 1 {
		t.Fatalf("title notices=%d want 1", len(mailbox.notices))
	}
	notice := mailbox.notices[0]
	if notice.Recipient != identity.PlayerID(42) || notice.SourceKind != "ONE_ON_ONE_TITLE" || notice.SourceKey != strconv.FormatInt(sunday, 10) ||
		notice.Title != "1 on 1 Title Reward" || notice.Sender != "Committee Quinie" || notice.Body != "Global 1 on 1 is 1" ||
		notice.PolicyVersion != d.ContractID || len(notice.Lines) != 0 {
		t.Fatalf("notice %+v", notice)
	}
}

// A Wednesday settlement awards no title and therefore sends no notice.
func TestSettleTxSendsNoNoticeWithoutTitle(t *testing.T) {
	const wednesday int64 = 6
	mailbox := &noticeMail{}
	service, scope, catalog, ranked, next := settlementFixture(t, wednesday, mailbox)
	if err := service.settleTx(context.Background(), scope, catalog, "revision", d.Competition{StateVersion: 1}, ranked, next); err != nil {
		t.Fatal(err)
	}
	if len(mailbox.notices) != 0 {
		t.Fatalf("untitled settlement notices=%+v want none", mailbox.notices)
	}
}
