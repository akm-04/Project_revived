//go:build postgres

// Package guildinvitebundle binds the exact finite owner ports without opening
// transactions, changing content activation or migrating any schema.
package guildinvitebundle

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	target "gxb.local/backend/v2/internal/application/guildinvitetarget"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Bundle struct {
	Source             app.SourceReader
	Target             target.Service
	Present, Qualified bool
}

func Prepare(c context.Context, p *postgres.Pool, r tx.Runner, revision string) (Bundle, error) {
	if p == nil || r.DB == nil {
		return Bundle{}, errors.New("nil Guild Invite bundle")
	}
	content := contentstore.Store{}
	_, qualified, e := content.ReadInvitePolicy(c, p, revision)
	if e != nil {
		return Bundle{}, e
	}
	store := guildinvitestore.Store{}
	present, e := store.SchemaPresent(c, p)
	if e != nil {
		return Bundle{}, e
	}
	if qualified && !present {
		return Bundle{}, errors.New("qualified Invite content requires exact deployed schema")
	}
	if !present {
		return Bundle{Qualified: qualified}, nil
	}
	if e = store.ValidateSchema(c, p); e != nil {
		return Bundle{}, e
	}
	inbox := socialinboxstore.Store{}
	if e = inbox.ValidateInviteSchema(c, p); e != nil {
		return Bundle{}, e
	}
	source := app.SourceReader{Store: store, Bindings: guildstore.Store{Queryer: p}, Receipts: kernelstore.Store{}, Content: content}
	binder := gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}
	targetService := target.Service{Timed: gen.TimedRunner{Binder: binder, Runner: r}, Reads: r, Sources: source, Players: i4store.PlayerRootLocker{}, Roots: socialrelation.RootService{Store: socialrelationstore.Store{}}, Store: inbox, Receipts: kernelstore.Store{}, Emitter: postgres.SocialWakeupEmitter{Pool: p}}
	return Bundle{Source: source, Target: targetService, Present: true, Qualified: qualified}, nil
}
