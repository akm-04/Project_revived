// Package profileasset supplies physical storage ports; it owns no gameplay SQL.
package profileasset

import (
	"context"
	"gxb.local/backend/v2/internal/domain/profileasset"
	"io"
)

type PreparedAsset interface {
	Descriptor() (profileasset.Descriptor, error)
	ValidateBinding(Store, profileasset.Reservation) error
	// Close must run after database scopes end. VerifiedCommit requires the caller
	// to have verified canonical reference/history/receipt commit, not client ACK.
	Close(profileasset.Outcome) error
}
type Reader interface{ io.ReadSeekCloser }
type Maintenance interface {
	// Inventory is streaming. A corrupt pin stops the operation before any delete.
	Inventory(func(profileasset.Descriptor) error, func(profileasset.Pin) error) error
	OpenValidated(profileasset.Descriptor) (io.ReadSeekCloser, error)
	// Delete is physical control only; caller must first prove typed-owner
	// current/history/receipt unreachability. Pins are checked independently.
	Delete(profileasset.Descriptor) error
	// ResolvePin requires an exact inventory record and a qualified definite
	// terminal outcome from 5B after its database scope ends. Unknown is refused.
	ResolvePin(profileasset.Pin, profileasset.Outcome) error
	CleanStaging() error
}
type Store interface {
	Prepare(context.Context, io.Reader, profileasset.Reservation) (PreparedAsset, error)
	OpenValidated(context.Context, profileasset.Descriptor) (Reader, error)
	WithMaintenance(context.Context, func(Maintenance) error) error
}
