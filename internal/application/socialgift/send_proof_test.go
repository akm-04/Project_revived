package socialgift

import (
	"context"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/socialinbox"
	dg "gxb.local/backend/v2/internal/domain/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	dgift "gxb.local/backend/v2/internal/domain/socialgift"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type sendProofStore struct {
	Store
	transfer Transfer
	epochs   map[identity.PlayerID]Epoch
}

func (s sendProofStore) ReadSend(context.Context, tx.Queryer, ids.UUID) (Transfer, bool, error) {
	return s.transfer, true, nil
}
func (s sendProofStore) ReadEpoch(_ context.Context, _ tx.Queryer, player identity.PlayerID, _ string) (Epoch, bool, error) {
	epoch, found := s.epochs[player]
	return epoch, found, nil
}

type sendProofContent struct{ value Content }

func (c sendProofContent) ReadGiftContent(context.Context, tx.Queryer, string) (Content, error) {
	return c.value, nil
}
func (sendProofContent) ActiveRevision(context.Context, tx.Queryer) (string, error) { return "", nil }

type sendProofEvidence struct{ notice socialinbox.Notice }

func (e sendProofEvidence) ReadNoticeEvidenceTx(context.Context, tx.Queryer, identity.PlayerID, socialinbox.NoticeID) (socialinbox.Notice, bool, error) {
	return e.notice, true, nil
}

type sendProofClassInfo struct{ value map[string]any }

func (c sendProofClassInfo) GiftBaseInfoTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID, time.Time) (map[string]any, bool, error) {
	return c.value, true, nil
}

type sendProofTx struct{}

func (sendProofTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (sendProofTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (sendProofTx) Commit(context.Context) error                                { return nil }
func (sendProofTx) Rollback(context.Context) error                              { return nil }

// S28: an unknown-commit retry rebuilds the send reply from the stored proof,
// so it must carry the same class-pair master_info as the original answer.
func TestSendProofReplaysTheClassPairMasterInfo(t *testing.T) {
	const sender, recipient = identity.PlayerID(100001), identity.PlayerID(100002)
	revision := strings.Repeat("a", 64)
	vector := strings.Repeat("b", 64)
	fingerprint := strings.Repeat("c", 64)
	transferID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	generationUUID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	generation, err := dg.GenerationIDFrom(generationUUID)
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(2026, 11, 21, 10, 0, 0, 0, time.UTC)
	day, err := Day(at)
	if err != nil {
		t.Fatal(err)
	}
	op := operation.Context{ID: operationID, StartedAt: at}
	transfer := Transfer{
		ID: transferID, Sender: sender, Recipient: recipient, SenderDay: day,
		SenderGeneration: generation, SendOperation: operationID, RequestFingerprint: fingerprint,
		StartedAt: at, IssuedAt: at, FriendshipGeneration: 1, RewardRevision: revision,
		VectorFingerprint: vector, Amount: 5, NoticeID: 1, Version: 1,
	}
	notice, err := transfer.Descriptor().Notice()
	if err != nil {
		t.Fatal(err)
	}
	notice.NoticeID = transfer.NoticeID
	notice.Active = true
	notice.StateVersion = 1
	notice.CreatedAt, notice.UpdatedAt = at, at
	epoch := Epoch{Player: sender, Day: day, Generation: generation, Version: 1, CreatedAt: at, UpdatedAt: at}
	recipientEpoch := Epoch{Player: recipient, Day: day, Generation: generation, Version: 1, CreatedAt: at, UpdatedAt: at}
	masterInfo := map[string]any{"intimacies": []any{int64(100)}}
	service := Service{
		Store:          sendProofStore{transfer: transfer, epochs: map[identity.PlayerID]Epoch{sender: epoch, recipient: recipientEpoch}},
		Content:        sendProofContent{value: Content{Revision: revision, Catalog: dgift.SocialGiftCatalog{Amount: 5, VectorFingerprint: vector}}},
		NoticeEvidence: sendProofEvidence{notice: notice},
		ClassInfo:      sendProofClassInfo{value: masterInfo},
	}
	actor := identity.ActorContext{PlayerID: sender}
	answer, found, err := service.sendProof(context.Background(), sendProofTx{}, actor, recipient, fingerprint, op)
	if err != nil || !found {
		t.Fatalf("sendProof found=%v err=%v", found, err)
	}
	if answer.MasterInfo == nil {
		t.Fatal("replayed send omitted master_info")
	}
	if len(answer.NoticeIDs) != 1 || answer.NoticeIDs[0] != transfer.NoticeID {
		t.Fatalf("answer = %+v", answer)
	}
}
