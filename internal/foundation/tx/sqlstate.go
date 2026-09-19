package tx

import "errors"

type sqlStater interface{ SQLState() string }

func SQLState(err error) string {
	var s sqlStater
	if errors.As(err, &s) {
		return s.SQLState()
	}
	return ""
}
func IsDefiniteAbortSQLState(err error) bool { s := SQLState(err); return s == "40001" || s == "40P01" }

type definiteAbortMarker interface{ DefiniteAbort() bool }
type definiteAbortError struct{ error }

func (definiteAbortError) DefiniteAbort() bool { return true }

// MarkDefiniteAbort lets a driver adapter preserve authoritative driver evidence
// that a failed COMMIT actually rolled back (e.g. pgx.ErrTxCommitRollback).
func MarkDefiniteAbort(err error) error {
	if err == nil {
		return nil
	}
	return definiteAbortError{error: err}
}

func IsDefiniteAbortError(err error) bool {
	if IsDefiniteAbortSQLState(err) {
		return true
	}
	var m definiteAbortMarker
	return errors.As(err, &m) && m.DefiniteAbort()
}
