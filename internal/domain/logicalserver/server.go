package logicalserver

import (
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/domain/identity"
	"time"
)

var ErrServerFull = errors.New("server full or closed to new characters")
var ErrExistingLoginClosed = errors.New("existing character login disabled")
var ErrServerRetired = errors.New("retired logical server is terminal")

type Lifecycle uint8

const (
	Provisioned Lifecycle = iota + 1
	Open
	ExistingOnly
	Maintenance
	Retired
)

type Server struct {
	ID                   identity.LogicalServerID
	Name                 string
	FirstOpenedAt        *time.Time
	DirectoryVisible     bool
	ExistingLoginAllowed bool
	NewCharacterAllowed  bool
	NextPlayerID         identity.PlayerID
	MaxPlayerID          identity.PlayerID
	StateVersion         int64
	CreatedAt            time.Time
	RetiredAt            *time.Time
}

// stockRobotTableLimit: the stock client reads a wire table_id (player id within its region) up to 25000 as a robot team.
const stockRobotTableLimit = 25000

// BandMin is the first allocatable player id; ids below it would collide with robot team ids on the wire (D63).
func BandMin(id identity.LogicalServerID) identity.PlayerID {
	return identity.PlayerID(int64(id)*100000 + stockRobotTableLimit + 1)
}
func BandMax(id identity.LogicalServerID) identity.PlayerID {
	return identity.PlayerID((int64(id)+1)*100000 - 1)
}
func PlayerRegion(id identity.PlayerID) identity.LogicalServerID {
	return identity.LogicalServerID(int64(id) / 100000)
}
func (s Server) Validate() error {
	if !s.ID.Valid() || s.Name == "" {
		return errors.New("invalid logical server")
	}
	if s.NextPlayerID < BandMin(s.ID) || s.MaxPlayerID > BandMax(s.ID) || s.NextPlayerID > s.MaxPlayerID+1 {
		return fmt.Errorf("allocator outside server band")
	}
	if s.RetiredAt != nil {
		if s.RetiredAt.IsZero() {
			return errors.New("invalid retirement timestamp")
		}
		if s.DirectoryVisible || s.ExistingLoginAllowed || s.NewCharacterAllowed {
			return errors.New("retired logical server cannot admit or advertise")
		}
	}
	return nil
}
func (s Server) ExistingAdmission() error {
	if !s.ExistingLoginAllowed {
		return ErrExistingLoginClosed
	}
	return nil
}
func (s Server) Allocate() (Server, identity.PlayerID, error) {
	if err := s.Validate(); err != nil {
		return s, 0, err
	}
	if !s.NewCharacterAllowed || s.NextPlayerID > s.MaxPlayerID {
		return s, 0, ErrServerFull
	}
	id := s.NextPlayerID
	out := s
	out.NextPlayerID++
	out.StateVersion++
	return out, id, nil
}
