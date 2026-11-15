package guildcampaign

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/guild"
	domain "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestAuditA059MembershipAndCampaignShareSnapshot(t *testing.T) {
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	state := &auditCampaignState{}
	mode := Mode{
		Service: Service{
			Runner: tx.Runner{DB: auditCampaignDatabase{state}},
			Guilds: auditCampaignGuilds{state: state},
			Fence:  struct{ Fence }{}, Players: struct{ playerroot.TxLocker }{},
		},
		ModeStore: auditCampaignStore{}, Content: struct{ Content }{},
		Combat: struct{ ModeCombat }{}, Grants: struct{ Grants }{},
		Facts: struct{ Facts }{}, Directory: struct{ Directory }{}, Mail: struct{ Mailer }{},
		Tables: map[int64]ChapterInfo{7: {ChapterID: 7}},
	}
	result, err := mode.GuildMap(context.Background(), identity.ActorContext{PlayerID: 100001},
		operation.Context{ID: identifier, StartedAt: time.Now().UTC()})
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Chapters) != 0 {
		t.Fatalf("departed player received post-departure campaign state: %+v", result)
	}
}

type auditCampaignState struct{ departed bool }

type auditCampaignGuilds struct {
	Guilds
	state *auditCampaignState
}

func (owner auditCampaignGuilds) ReadMembership(context.Context, identity.PlayerID) (guild.Membership, bool, error) {
	return guild.Membership{GuildID: 1, PlayerID: 100001}, !owner.state.departed, nil
}

func (owner auditCampaignGuilds) ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error) {
	return guild.Membership{GuildID: 1, PlayerID: 100001}, !owner.state.departed, nil
}

type auditCampaignDatabase struct{ state *auditCampaignState }

func (database auditCampaignDatabase) Begin(context.Context, tx.Options) (tx.Tx, error) {
	// The leave and the later campaign update commit before this snapshot starts.
	database.state.departed = true
	return auditCampaignTransaction{}, nil
}

type auditCampaignTransaction struct{ tx.Tx }

func (auditCampaignTransaction) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, nil
}

func (auditCampaignTransaction) Commit(context.Context) error   { return nil }
func (auditCampaignTransaction) Rollback(context.Context) error { return nil }

type auditCampaignStore struct{ ModeStore }

func (auditCampaignStore) ReadChapterTx(context.Context, tx.Queryer, int64, int64) (domain.Chapter, bool, error) {
	return domain.Chapter{GuildID: 1, ChapterID: 7, Percent: 0.42}, true, nil
}

func (auditCampaignStore) MemberClearsTx(context.Context, tx.Queryer, identity.PlayerID, int64, int64) (int64, error) {
	return 0, nil
}

func (auditCampaignStore) ListCopiesTx(context.Context, tx.Queryer, int64, int64) ([]CopyRow, error) {
	return nil, nil
}
