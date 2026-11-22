package bookskill

import (
	"context"
	"errors"
	"testing"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type auditSnapshotTransaction struct{ tx.Tx }

func (auditSnapshotTransaction) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, nil
}
func (auditSnapshotTransaction) Commit(context.Context) error   { return nil }
func (auditSnapshotTransaction) Rollback(context.Context) error { return nil }

type auditSnapshotDatabase struct{}

func (auditSnapshotDatabase) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return auditSnapshotTransaction{}, nil
}

type auditSnapshotClock struct{ at time.Time }

func (c auditSnapshotClock) Now(context.Context) (time.Time, error) { return c.at, nil }

type auditSnapshotContent struct{ *a44Content }

func (auditSnapshotContent) BookInputsActive(context.Context) (string, bool, error) {
	return a44Revision, true, nil
}

type auditSnapshotFence struct {
	err   error
	calls int
}

func (f *auditSnapshotFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	f.calls++
	return f.err
}

func TestAuditA075IdleBookReadsRecheckActorInSnapshot(t *testing.T) {
	for _, mid := range []uint16{1056, 1059} {
		for _, revoked := range []bool{false, true} {
			service, _, at := readSnapshotService(t)
			content := service.Content.(*a44Content)
			fence := &auditSnapshotFence{}
			if revoked {
				fence.err = errors.New("actor liveness fence rejected")
			}
			service.Fence = fence
			service.Content = auditSnapshotContent{content}
			service.Timed = gen.TimedRunner{Binder: gen.Binder{Time: auditSnapshotClock{at}}, Runner: tx.Runner{DB: auditSnapshotDatabase{}}}
			service.Reads = service.Timed.Runner
			service.Heroes = struct{ HeroPort }{}
			service.Players = struct{ playerroot.TxLocker }{}
			service.Costs = struct{ CostPort }{}
			service.Grants = struct{ GrantPort }{}
			service.Exchange = struct{ i5.TxMaterialExchange }{}
			service.Receipts = struct{ receipt.Store }{}
			currentOperation := operation.Context{ID: ids.UUID{1}, StartedAt: at, EntropySeed: [32]byte{9}}
			body, err := service.Read(context.Background(), identity.ActorContext{PlayerID: 1}, mid, currentOperation)
			if revoked {
				if err == nil || body != nil {
					t.Errorf("MID%d succeeded after snapshot actor was revoked", mid)
				}
			} else if err != nil || body == nil {
				t.Errorf("MID%d live control failed: %v", mid, err)
			}
			if fence.calls != 1 {
				t.Errorf("MID%d revoked=%v: snapshot fence calls=%d, want1", mid, revoked, fence.calls)
			}
		}
	}
}
