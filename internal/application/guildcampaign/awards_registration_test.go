package guildcampaign

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/guild"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TestI9_9CApplyRewardRequiresRegistration covers BUGS #98: an unregistered
// member of the guild (a late joiner, or a leaver who rejoined) must not be
// able to apply for a chapter reward.
func TestI9_9CApplyRewardRequiresRegistration(t *testing.T) {
	for _, test := range []struct {
		name        string
		registered  bool
		wantRefused bool
	}{
		{name: "registered member is accepted", registered: true},
		{name: "late joiner or rejoin is refused", registered: false, wantRefused: true},
	} {
		t.Run(test.name, func(t *testing.T) {
			state := &applyRewardRegistrationState{registered: test.registered}
			mode := Mode{
				Service: Service{
					Runner:  tx.Runner{DB: applyRewardRegistrationDatabase{state: state}},
					Store:   applyRewardRegistrationServiceStore{},
					Guilds:  applyRewardRegistrationGuilds{},
					Fence:   applyRewardRegistrationFence{},
					Players: applyRewardRegistrationRoots{},
				},
				ModeStore: applyRewardRegistrationStore{state: state},
				Content:   struct{ Content }{},
				Combat:    struct{ ModeCombat }{},
				Grants:    struct{ Grants }{},
				Facts:     struct{ Facts }{},
				Directory: struct{ Directory }{},
				Mail:      struct{ Mailer }{},
				Settings:  Settings{ApplicationsPerDay: 4},
			}
			_, err := mode.ApplyReward(context.Background(),
				identity.ActorContext{PlayerID: 100001, LogicalServerID: 900}, 7, 20001091,
				operation.Context{StartedAt: time.Unix(1700000000, 0).UTC()})
			if test.wantRefused {
				if !errors.Is(err, d.ErrRefused) {
					t.Fatalf("unregistered application err=%v, want refusal", err)
				}
				if state.applied {
					t.Fatal("unregistered application was recorded")
				}
				return
			}
			if err != nil {
				t.Fatalf("registered application: %v", err)
			}
			if !state.applied {
				t.Fatal("registered application was not recorded")
			}
		})
	}
}

type applyRewardRegistrationState struct {
	registered bool
	applied    bool
}

type applyRewardRegistrationGuilds struct{ Guilds }

func (applyRewardRegistrationGuilds) ReadMembership(context.Context, identity.PlayerID) (guild.Membership, bool, error) {
	return guild.Membership{GuildID: 1, PlayerID: 100001}, true, nil
}

type applyRewardRegistrationServiceStore struct{ Store }

func (applyRewardRegistrationServiceStore) LockChapterTx(context.Context, tx.Tx, int64, int64) (d.Chapter, bool, error) {
	return d.Chapter{GuildID: 1, ChapterID: 7, Run: 1, Win: true}, true, nil
}

type applyRewardRegistrationFence struct{}

func (applyRewardRegistrationFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type applyRewardRegistrationRoots struct{}

func (applyRewardRegistrationRoots) LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error) {
	return nil, nil
}

type applyRewardRegistrationDatabase struct{ state *applyRewardRegistrationState }

func (applyRewardRegistrationDatabase) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return applyRewardRegistrationTransaction{}, nil
}

type applyRewardRegistrationTransaction struct{ tx.Tx }

func (applyRewardRegistrationTransaction) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return applyRewardRegistrationTag{}, nil
}

func (applyRewardRegistrationTransaction) Commit(context.Context) error   { return nil }
func (applyRewardRegistrationTransaction) Rollback(context.Context) error { return nil }

type applyRewardRegistrationTag struct{}

func (applyRewardRegistrationTag) RowsAffected() int64 { return 1 }

type applyRewardRegistrationStore struct {
	ModeStore
	state *applyRewardRegistrationState
}

func (store applyRewardRegistrationStore) IsRegisteredTx(context.Context, tx.Queryer, int64, int64, identity.PlayerID) (bool, error) {
	return store.state.registered, nil
}

func (applyRewardRegistrationStore) LockChapterTx(context.Context, tx.Tx, int64, int64) (d.Chapter, bool, error) {
	return d.Chapter{GuildID: 1, ChapterID: 7, Run: 1, Win: true}, true, nil
}

func (applyRewardRegistrationStore) ReadChapterTx(context.Context, tx.Queryer, int64, int64) (d.Chapter, bool, error) {
	return d.Chapter{GuildID: 1, ChapterID: 7, Run: 1, Win: true}, true, nil
}

func (applyRewardRegistrationStore) ListAwardsTx(context.Context, tx.Queryer, int64, int64, int64) ([]AwardRow, error) {
	return []AwardRow{{GuildID: 1, ChapterID: 7, Run: 1, AwardID: 20001091, Remaining: 1}}, nil
}

func (applyRewardRegistrationStore) ApplicationCountTx(context.Context, tx.Queryer, identity.PlayerID, int64) (int64, error) {
	return 0, nil
}

func (store applyRewardRegistrationStore) ApplyTx(context.Context, tx.Tx, int64, int64, int64, identity.PlayerID, int64, time.Time) error {
	store.state.applied = true
	return nil
}

func (applyRewardRegistrationStore) BumpApplicationCountTx(context.Context, tx.Tx, identity.PlayerID, int64) error {
	return nil
}

func (applyRewardRegistrationStore) ListDamageTx(context.Context, tx.Queryer, int64, int64, int64, int) ([]DamageRow, error) {
	return nil, nil
}

func (applyRewardRegistrationStore) ApplicationTx(context.Context, tx.Queryer, int64, int64, int64, identity.PlayerID) (ApplicationRow, bool, error) {
	return ApplicationRow{}, false, nil
}

func (applyRewardRegistrationStore) ApplicationsByAwardTx(context.Context, tx.Queryer, int64, int64, int64) ([]ApplicationRow, error) {
	return nil, nil
}
