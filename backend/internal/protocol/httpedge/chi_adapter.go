//go:build chi

package httpedge

import (
	"net/http"

	"github.com/go-chi/chi/v5"
)

// ChiRouter is a thin infrastructure adapter. All GXB decode/dispatch truth
// remains in Handler; chi owns routing mechanics only.
func ChiRouter(path string, h Handler) http.Handler {
	r := chi.NewRouter()
	r.Post(path, h.ServeHTTP)
	return r
}
