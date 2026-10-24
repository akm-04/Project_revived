// Package profileasset defines location-independent, validated image metadata.
package profileasset

import (
	"encoding/hex"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"strings"
)

const Policy = "I7B_PROFILE_PNG_V1"
const MaxBytes int64 = 8 << 20
const MaxDimension = 2048
const MaxPixels uint64 = 4194304
const PrepareSlots = 2

var (
	ErrInvalid   = errors.New("invalid profile PNG")
	ErrIntegrity = errors.New("profile asset integrity failure")
	ErrConflict  = errors.New("profile asset reservation already protected")
	ErrBinding   = errors.New("profile asset permit binding invalid or closed")
)

type Descriptor struct {
	Policy string `json:"policy"`
	SHA256 string `json:"sha256"`
	MD5    string `json:"md5"`
	Size   int64  `json:"size"`
	Width  int    `json:"width"`
	Height int    `json:"height"`
}

func (d Descriptor) Validate() error {
	if d.Policy != Policy || d.Size <= 0 || d.Size > MaxBytes || d.Width < 1 || d.Height < 1 || d.Width > MaxDimension || d.Height > MaxDimension || uint64(d.Width)*uint64(d.Height) > MaxPixels || !digest(d.SHA256, 32) || !digest(d.MD5, 16) {
		return ErrInvalid
	}
	return nil
}
func digest(s string, n int) bool {
	if len(s) != 2*n || s != strings.ToLower(s) {
		return false
	}
	_, e := hex.DecodeString(s)
	return e == nil
}

type Reservation struct {
	Operation ids.UUID                 `json:"operation"`
	Actor     identity.PlayerID        `json:"actor"`
	Server    identity.LogicalServerID `json:"server"`
}

func (r Reservation) Validate() error {
	if r.Operation.IsZero() || !r.Actor.Valid() || !r.Server.Valid() {
		return ErrBinding
	}
	return nil
}

// Unknown is the zero/default outcome and must retain durable protection.
type Outcome uint8

const (
	Unknown Outcome = iota
	DefiniteAbort
	VerifiedCommit
)

type Pin struct {
	Reservation Reservation `json:"reservation"`
	Asset       Descriptor  `json:"asset"`
}

func (p Pin) Validate() error {
	if p.Reservation.Validate() != nil || p.Asset.Validate() != nil {
		return ErrIntegrity
	}
	return nil
}
