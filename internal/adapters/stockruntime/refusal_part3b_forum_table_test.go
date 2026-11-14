package stockruntime

import (
	"errors"
	"net/http"
	"testing"

	libraryapp "gxb.local/backend/v2/internal/application/libraryforum"
)

func TestPart3BForumFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"rejected", failForum(libraryapp.ErrRejected), http.StatusConflict, unprovenRefusalCode, ""},
		{"request", failForum(libraryapp.ErrRequest), http.StatusBadRequest, 0, "invalid_library_forum_request"},
		{"unavailable", failForum(libraryapp.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"dependency", failForum(errors.New("database unavailable")), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"malformed params", badForum("invalid_library_forum_page"), http.StatusBadRequest, 0, "invalid_library_forum_page"},
	})
}
