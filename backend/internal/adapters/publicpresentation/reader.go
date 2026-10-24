// Package publicpresentation binds existing typed Player/I4 owners without SQL
// or a transaction opener. The consumer pins revision/time once per snapshot.
package publicpresentation

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func Display() playerdisplay.Service {
	c := contentstore.Store{}
	return playerdisplay.Service{Store: i5store.Store{}, Content: c, Characters: characterstore.DisplayReader{Store: characterstore.Store{}, Content: c}}
}

type Reader struct {
	Queryer    tx.Queryer
	Revision   string
	ObservedAt time.Time
	Display    i5.TxEffectivePlayerDisplayReader
}

func (r Reader) Minimal(c context.Context, pid identity.PlayerID) (playerpresentation.Minimal, bool, error) {
	d := r.Display
	if d == nil {
		d = Display()
	}
	return (playerpresentation.CanonicalReader{Directory: i4store.PlayerDirectoryReader{Queryer: r.Queryer}, Basis: i5store.Store{}, Display: d}).ReadAtTx(c, r.Queryer, pid, r.Revision, r.ObservedAt)
}
func (r Reader) Profile(c context.Context, pid identity.PlayerID) (playerdirectory.Profile, bool, error) {
	m, ok, e := r.Minimal(c, pid)
	if e != nil || !ok {
		return playerdirectory.Profile{}, ok, e
	}
	return playerdirectory.Profile{PlayerID: pid, Name: m.Name, Level: m.Level, AvatarID: m.AvatarID, AvatarFrameID: m.AvatarFrameID, ConquerLevel: m.ConquerLevel, ConquerLoopID: m.ConquerLoopID}, true, nil
}

var _ playerdirectory.Reader = Reader{}
