package mentorstore

import (
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
)

func isNoRows(err error) bool { return errors.Is(err, kernelstore.ErrNoRows) }
