package wire

import "fmt"

type ErrorClass string

const (
	ErrMalformed     ErrorClass = "MALFORMED"
	ErrTooLarge      ErrorClass = "TOO_LARGE"
	ErrUnknownMID    ErrorClass = "UNKNOWN_MID"
	ErrUnimplemented ErrorClass = "UNIMPLEMENTED_MID"
	ErrForbidden     ErrorClass = "FORBIDDEN"
	ErrSaturated     ErrorClass = "SATURATED"
	ErrInternal      ErrorClass = "INTERNAL"
)

type EdgeError struct {
	Class      ErrorClass
	HTTPStatus int
	PublicCode string
	Detail     string
}

func (e *EdgeError) Error() string { return fmt.Sprintf("%s: %s", e.Class, e.Detail) }
func NewError(class ErrorClass, status int, code, detail string) *EdgeError {
	return &EdgeError{Class: class, HTTPStatus: status, PublicCode: code, Detail: detail}
}
