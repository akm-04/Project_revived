// Package roominvite materializes a room family's friend invite into the
// SocialInbox notice list after the room transaction has committed.
package roominvite

import (
	"context"
	"errors"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrUnresolved = errors.New("room invite materialize unresolved")

// NoticeListRoute wakes the realtime friend-notice reload for one recipient.
const NoticeListRoute = "social.room-invite.notice-list.v1"

type NoticeListNotifier interface {
	NoticeListChanged(context.Context, identity.PlayerID)
}

type Store interface {
	NextNoticeIDTx(context.Context, tx.Queryer) (socialinbox.NoticeID, error)
	LockNoticeSourceTx(context.Context, tx.Tx, identity.PlayerID, socialinbox.SourceKey) (socialinbox.Notice, bool, error)
	InsertRoomInviteNoticeTx(context.Context, tx.Tx, socialinbox.Notice) (socialinbox.Notice, error)
	UpdateRoomInviteNoticeTx(context.Context, tx.Tx, socialinbox.Notice, time.Time) (socialinbox.Notice, error)
	DeleteAgedRoomInviteNoticesTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (int64, error)
}

type Materializer interface {
	Materialize(context.Context, identity.ActorContext, socialinbox.RoomInvite, operation.Context) error
}

type Service struct {
	Timed   gen.TimedRunner
	Players playerroot.RecipientLocker
	Roots   socialrelation.RootService
	Store   Store
	Notices NoticeListNotifier
}

func MaterializeProfile() tx.Profile {
	return tx.Profile{Name: "I9_8_ROOM_INVITE_MATERIALIZE", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func (s Service) valid() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Players != nil && s.Roots.Store != nil && s.Store != nil
}

func childOperation(parent operation.Context, source socialinbox.SourceKey) (operation.Context, error) {
	id, err := ids.NewUUID()
	if err != nil {
		return operation.Context{}, err
	}
	return operation.Context{ID: id, StartedAt: parent.StartedAt, EntropySeed: parent.Derive("social-room-invite:"+source.Key, 0), Policies: parent.Policies}, nil
}

func (s Service) Materialize(c context.Context, actor identity.ActorContext, invite socialinbox.RoomInvite, op operation.Context) error {
	if !s.valid() || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || actor.PlayerID == invite.Recipient {
		return socialinbox.ErrInvalidNotice
	}
	source, err := invite.SourceKey()
	if err != nil {
		return err
	}
	child, err := childOperation(op, source)
	if err != nil {
		return err
	}
	c, cancel := context.WithTimeout(c, MaterializeProfile().OperationTimeout)
	defer cancel()
	changed := false
	_, result, err := s.Timed.Run(c, child, MaterializeProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, scope gen.TimedScope) error {
		changed = false
		at := scope.Operation.DecisionAt()
		root, err := s.Players.LockBoundRecipientTx(c, scope.Tx, actor.LogicalServerID, invite.Recipient)
		if err != nil {
			return err
		}
		if root.NonReusedAbsent {
			return nil
		}
		plan, err := s.Roots.PrepareTx(c, scope.Tx, root.Root)
		if err != nil {
			return err
		}
		// Aged rows are removed before the source lock so a stale row of this
		// same room cannot be revived past its retention window.
		if _, err = s.Store.DeleteAgedRoomInviteNoticesTx(c, scope.Tx, invite.Recipient, at); err != nil {
			return err
		}
		existing, found, err := s.Store.LockNoticeSourceTx(c, scope.Tx, invite.Recipient, source)
		if err != nil {
			return err
		}
		// The recipient root is the notice's foreign key, so it is written before
		// the row; guildinvitetarget/materialize.go orders it the same way.
		if _, err = s.Roots.ApplyChangeTx(c, scope.Tx, plan, at); err != nil {
			return err
		}
		if found {
			if socialinbox.ValidateRoomInviteLifecycle(existing) != nil || existing.Source != source || existing.NoticeType != invite.NoticeType {
				return socialinbox.ErrInvalidNotice
			}
			existing.RelatedPlayerID = actor.PlayerID
			existing.RelatedPlayerDeleted = false
			if _, err = s.Store.UpdateRoomInviteNoticeTx(c, scope.Tx, existing, at); err != nil {
				return err
			}
		} else {
			noticeID, err := s.Store.NextNoticeIDTx(c, scope.Tx)
			if err != nil {
				return err
			}
			notice := socialinbox.Notice{RecipientPlayerID: invite.Recipient, NoticeID: noticeID, NoticeType: invite.NoticeType,
				Source: source, RelatedPlayerID: actor.PlayerID, Active: true, NoticeTime: at, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
			if socialinbox.ValidateRoomInviteLifecycle(notice) != nil {
				return socialinbox.ErrInvalidNotice
			}
			if _, err = s.Store.InsertRoomInviteNoticeTx(c, scope.Tx, notice); err != nil {
				return err
			}
		}
		changed = true
		return nil
	})
	if err != nil {
		return err
	}
	if result.Outcome != tx.DefiniteCommit {
		return ErrUnresolved
	}
	if changed && !result.Reconciled && s.Notices != nil {
		s.Notices.NoticeListChanged(c, invite.Recipient)
	}
	return nil
}
