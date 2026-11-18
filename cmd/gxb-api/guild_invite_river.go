//go:build postgres && river

package main

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/guildinvitebundle"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialprojection"
	"gxb.local/backend/v2/internal/application/socialreload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func prepareGuildInvite(c context.Context, p *postgres.Pool, r tx.Runner, gift *socialgift.Service, reads *socialprojection.Service, reload *socialreload.Service) (*app.SourceService, error) {
	rev, e := (contentstore.Store{}).ActiveRevision(c, p)
	if e != nil {
		return nil, e
	}
	b, e := guildinvitebundle.Prepare(c, p, r, rev)
	if e != nil {
		return nil, e
	}
	if !b.Present {
		return nil, nil
	}
	if e = riveradapter.ValidateDeployment(c, p.Raw()); e != nil {
		return nil, e
	}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		return nil, e
	}
	projection := app.SourceService{Reads: tx.Runner{DB: p}, Store: guildinvitestore.Store{}, Bindings: guildstore.Store{Queryer: p}, History: kernelstore.Store{}, Reader: b.Source, Content: contentstore.Store{}, Queryer: p, Enqueue: queue}
	// On an older active revision Admit returns inactive; the same typed reader
	// still validates retained qualified historical notices after pointer rollback.
	gift.InviteConsumption = socialinboxstore.Store{}
	gift.Invites = b.Target
	reads.Invites = b.Target
	reload.Invites = b.Target
	return &projection, nil
}
