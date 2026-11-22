package stockruntime

import "net/http"

const boundedRetryAfterSeconds = "1"

// busyReply refuses a request the handler cannot serve now: its concurrency
// bound is full, or the request context ended. The bound's holder finishes
// within a request budget, so one second is a useful retry hint.
func busyReply(w http.ResponseWriter, message string) {
	w.Header().Set("Retry-After", boundedRetryAfterSeconds)
	http.Error(w, message, http.StatusServiceUnavailable)
}
