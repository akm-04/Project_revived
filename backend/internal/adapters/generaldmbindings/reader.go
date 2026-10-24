package generaldmbindings

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Reader struct{}

func (Reader) ReadBindings(c context.Context, q tx.Queryer, id identity.PlayerID, at time.Time) ([]dm.Binding, error) {
	leases, e := (presencestore.Store{}).ReadGeneralWorldLeases(c, q, id, at)
	if e != nil {
		return nil, e
	}
	out := []dm.Binding{}
	for _, b := range leases {
		v, ok, e := i4store.ReadGeneralBinding(c, q, id, b, at)
		if e != nil {
			return nil, e
		}
		if ok {
			out = append(out, v)
		}
	}
	return out, nil
}
