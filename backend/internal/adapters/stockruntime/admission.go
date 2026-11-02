package stockruntime

import (
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	appillusion "gxb.local/backend/v2/internal/application/illusion"
	appoccult "gxb.local/backend/v2/internal/application/occult"
	appsharedroom "gxb.local/backend/v2/internal/application/sharedroom"
)

// NewAdmissionRouter is the one production Combat room admission table. Every
// room-start locator domain kind must have a binding here; the native proof
// builds the router through this function so the wiring cannot drift.
func NewAdmissionRouter() appsharedroom.AdmissionRouter {
	return appsharedroom.AdmissionRouter{
		"ILLUSION":           {Store: sharedroomstore.Store{}, Family: appillusion.RoomFamily, Slot: appillusion.RoomSlot},
		"OCCULT":             {Store: sharedroomstore.Store{}, Family: appoccult.RoomFamily, Slot: appoccult.RoomSlot, ConvenerFirst: true},
		"ADVENTURE_ILLUSION": {Store: sharedroomstore.Store{}, Family: appadventure.RoomFamily, Slot: appadventure.IllusionSlot, ConvenerFirst: true},
	}
}
