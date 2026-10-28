//go:build postgres

package main

import (
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dodgeballstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/dodgeball"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func canonicalDodgeball(pool *postgres.Pool, runner tx.Runner, content contentstore.Store, values i5store.Store, grants i5.Service, fight combat.Service, display playerdisplay.Service) dodgeball.Mode {
	relations := socialrelationstore.Store{}
	return dodgeball.Mode{Timed: generation.TimedRunner{Binder: generation.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner}, Fresh: pool, Store: dodgeballstore.Store{}, Content: content, Fence: values, Functions: values, Players: i4store.PlayerRootLocker{}, Privacy: socialrelation.FriendDMPrivacyProvider{Store: relations}, Friends: relations, Presentation: socialpresentation.TransactionReader{Display: display}, Combat: fight, Values: grants, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Mail: values, Delivery: i5.SettlementMail{Store: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: pool}}
}
