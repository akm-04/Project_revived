//go:build postgres && river

package riveradapter

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/riverqueue/river/riverdriver/riverpgxv5"
	"github.com/riverqueue/river/rivermigrate"
)

// ValidateDeployment is read-only. Generic API/worker startup calls only this
// operation; schema deployment remains an explicit operator action.
func ValidateDeployment(c context.Context, p *pgxpool.Pool) error {
	if p == nil {
		return errors.New("nil River deployment pool")
	}
	m, e := rivermigrate.New(riverpgxv5.New(p), nil)
	if e != nil {
		return e
	}
	v, e := m.Validate(c, nil)
	if e != nil {
		return e
	}
	if !v.OK {
		return errors.New("pinned River schema validation failed")
	}
	return nil
}

// DeploySchema is used by the explicit Guild deployment command, never by a
// runtime constructor. It does not activate content or run backend migrations.
func DeploySchema(c context.Context, p *pgxpool.Pool) error {
	if p == nil {
		return errors.New("nil River deployment pool")
	}
	m, e := rivermigrate.New(riverpgxv5.New(p), nil)
	if e != nil {
		return e
	}
	if _, e = m.Migrate(c, rivermigrate.DirectionUp, nil); e != nil {
		return e
	}
	return ValidateDeployment(c, p)
}
