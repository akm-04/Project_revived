//go:build postgres && river

package riveradapter

import (
	"errors"
	gb "gxb.local/backend/v2/internal/application/guildbroadcast"
	gi "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/foundation/obligation"
)

func guildRoute(o obligation.Obligation) bool {
	return o.Kind == gb.MailKind || o.Kind == gb.ReconcileKind || o.Kind == gi.IssueKind || o.Kind == gi.MarkerKind
}
func validateGuildRoute(o obligation.Obligation) error {
	if o.Kind == gi.IssueKind || o.Kind == gi.MarkerKind {
		_, e := gi.DecodeObligation(o)
		return e
	}
	return gb.ValidateObligation(o)
}
func normalizeGuildRoute(o obligation.Obligation) (obligation.Obligation, error) {
	if o.Kind == gi.IssueKind || o.Kind == gi.MarkerKind {
		return gi.NormalizeStoredObligation(o)
	}
	if o.Kind == gb.MailKind || o.Kind == gb.ReconcileKind {
		return gb.NormalizeStoredObligation(o)
	}
	return o, errors.New("unknown finite Guild obligation route")
}
