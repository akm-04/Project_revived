//go:build postgres

package main

import (
	"context"

	"gxb.local/backend/v2/internal/adapters/guildcampaigncontent"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildcampaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/guildcampaign"
	"gxb.local/backend/v2/internal/application/i5"
	appwakeup "gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/content/guildcampaignpolicy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// canonicalGuildCampaign builds the one Guild Campaign owner of I9-9C.
func canonicalGuildCampaign(p *pg.Pool, runner tx.Runner, guildDB guildstore.Store, i5db i5store.Store, i5svc i5.Service,
	catalog guildcampaigncontent.Catalog, policy guildcampaignpolicy.Policy, combatService combat.Service) (app.Mode, app.Payout) {
	settings := guildcampaigncontent.Settings(policy, catalog.Installed.Settings)
	tables := catalog.ChapterInfos()
	store := guildcampaignstore.Store{}
	payout := app.Payout{Store: store, Mail: i5.SettlementMail{Store: i5db}, Settings: settings, Tables: tables}
	mode := app.Mode{
		Service: app.Service{
			Runner: runner, Store: store, Guilds: guildDB, Catalog: catalog, Payout: payout,
			Mail: i5.SettlementMail{Store: i5db}, Fence: i5db, Players: i4store.PlayerRootLocker{},
			Notice: app.NoticeMail{Enabled: policy.NoticeMail.Enabled, OpenTitle: policy.NoticeMail.OpenTitle, OpenBody: policy.NoticeMail.OpenBody,
				ResetTitle: policy.NoticeMail.ResetTitle, ResetBody: policy.NoticeMail.ResetBody, Sender: "Guild"},
		},
		ModeStore: store, Content: catalog, Tables: tables, Settings: settings,
		Combat: combatService, Grants: i5svc, Facts: i5.ObjectiveFacts{Owner: i5svc, Open: i5db},
		Directory: i4store.PlayerDirectoryReader{}, Mail: i5.SettlementMail{Store: i5db}, NoticeMail: i5.SettlementMail{Store: i5db},
		Notifier: guildCampaignNotifier{Execer: pg.AutocommitExecer(p)},
		Fence:    i5db, Players: i4store.PlayerRootLocker{},
		Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner},
		Fresh: p,
	}
	return mode, payout
}

// guildCampaignNotifier emits C16's reference wakeup after the settle commits.
type guildCampaignNotifier struct{ Execer tx.Execer }

func (n guildCampaignNotifier) Notify(c context.Context, guildID, chapterID, copyID int64, player identity.PlayerID) error {
	if n.Execer == nil || guildID <= 0 {
		return nil
	}
	return pg.EmitRealtimeWakeup(c, n.Execer, appwakeup.Envelope{Version: 1, Route: stockruntime.GuildCampaignNoticeRoute,
		Ref: stockruntime.GuildCampaignNoticeRef(guildID, chapterID, copyID, player)})
}
