//go:build postgres && !river

package main

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/guildinvitebundle"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialprojection"
	"gxb.local/backend/v2/internal/application/socialreload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func configureGuildInvite(c context.Context, p *postgres.Pool, r tx.Runner, _ *guildcore.Service, gift *socialgift.Service, reads *socialprojection.Service, reload *socialreload.Service) error {
	rev, e := (contentstore.Store{}).ActiveRevision(c, p)
	if e != nil {
		return e
	}
	b, e := guildinvitebundle.Prepare(c, p, r, rev)
	if e != nil {
		return e
	}
	if b.Qualified {
		return errors.New("qualified Guild Invite producer requires the pinned insert-only River build")
	}
	if b.Present {
		gift.InviteConsumption = socialinboxstore.Store{}
		gift.Invites = b.Target
		reads.Invites = b.Target
		reads.PresentationAt = socialpresentation.TransactionReader{}
		reload.Invites = b.Target
	}
	return nil
}
