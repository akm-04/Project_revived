package stockruntime

import (
	"net/http"

	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// conflictRefusal answers a refusal on a mode whose success callbacks index nested
// reply tables. Backend.lua hands a 200 body to the callback as OK, which crashes
// them; on any other status the callback gets ERROR and the toast still shows.
// R4 parts 1-3a route migrated dispatchers through failureReply instead.
func conflictRefusal(code int64) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusConflict, Body: map[string]any{"error_code": code}}
}

// conflictRefusalCause keeps the server-side branch visible in the request
// journal while the stock client shows the coded toast.
func conflictRefusalCause(code int64, cause error) httpedge.Response {
	response := conflictRefusal(code)
	response.Cause = cause
	return response
}
