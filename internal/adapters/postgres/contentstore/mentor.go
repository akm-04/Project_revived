package contentstore

import "gxb.local/backend/v2/internal/content/builtin"

// MentorCatalog exposes the compiled source catalog. Mentor rules are immutable
// source facts, not a revision-scoped deployment artifact.
func (Store) MentorCatalog() (builtin.MentorInputCatalog, error) {
	return builtin.MentorCatalog()
}
