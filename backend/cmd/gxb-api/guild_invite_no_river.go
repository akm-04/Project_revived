//go:build postgres && !river

package main

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/guildinvitebundle"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
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
	if b.Qualified {
		return nil, errors.New("qualified Guild Invite producer requires the pinned insert-only River build")
	}
	if b.Present {
		gift.InviteConsumption = socialinboxstore.Store{}
		gift.Invites = b.Target
		reads.Invites = b.Target
		reload.Invites = b.Target
	}
	return nil, nil
}
