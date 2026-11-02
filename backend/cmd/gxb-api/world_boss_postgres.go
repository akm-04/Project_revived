//go:build postgres

package main

import (
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/worldbossstore"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/worldboss"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func canonicalWorldBoss(p *pg.Pool, r tx.Runner, content contentstore.Store, values i5store.Store, grants i5.Service, privileges i5.PrivilegeSnapshotProvider, fight combat.Service) worldboss.Mode {
	return worldboss.Mode{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: worldbossstore.Store{}, Content: content,
		Fence: values, Players: i4store.PlayerRootLocker{}, Directory: i4store.PlayerDirectoryReader{}, Population: i4store.PlayerDirectoryReader{}, Heroes: fight.Inputs.Heroes,
		Combat: fight, Privileges: privileges, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Mail: i5.SettlementMail{Store: values},
		Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}
