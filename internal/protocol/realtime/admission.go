package realtime

import (
	"errors"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
)

type Role string

const (
	World   Role = "WORLD"
	Guild   Role = "GUILD"
	Service Role = "SERVICE"
)

func (r Role) Valid() bool { return r == World || r == Guild || r == Service }

var ErrPreauthMID = errors.New("preauth frame must be TCP_LOGIN")
var ErrWrongDirection = errors.New("client sent server-only MID")

type Gate struct {
	authenticated bool
	Role          Role
}

func NewGate(role Role) (*Gate, error) {
	if !role.Valid() {
		return nil, errors.New("invalid physical realtime role")
	}
	return &Gate{Role: role}, nil
}
func (g *Gate) ObserveClientFrame(f Frame) error {
	if !g.authenticated {
		if f.MID != mids.MIDTCPLogin {
			return ErrPreauthMID
		}
		if _, ok := f.Params.(*amf3.Object); !ok {
			return ErrPreauthMID
		}
		return nil
	}
	if d, ok := mids.Lookup(f.MID); ok && d.Direction == mids.S2C {
		return ErrWrongDirection
	}
	return nil
}

// MarkAuthenticated is called only after an adapter has bound TCP_LOGIN claims
// to live I3 gameplay authority. Parsing a syntactically valid login is not auth.
func (g *Gate) MarkAuthenticated()  { g.authenticated = true }
func (g *Gate) Authenticated() bool { return g.authenticated }
