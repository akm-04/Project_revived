package publicprofile

import (
	"context"
	"encoding/hex"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strings"
)

type ContentPolicy struct {
	Revision string
	Policy   builtin.PublicProfilePolicy
}

func (p ContentPolicy) Validate() error {
	b, e := hex.DecodeString(p.Revision)
	if e != nil || len(b) != 32 || p.Revision != strings.ToLower(p.Revision) || p.Policy.Validate() != nil {
		return ErrContent
	}
	return nil
}

type ContentReader interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ReadPublicProfilePolicy(context.Context, tx.Queryer, string) (ContentPolicy, error)
}
