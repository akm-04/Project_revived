package clientlog

const (
	firstServerErrorStatus = 500
	firstClientErrorStatus = 400
)

// Outcome classifies one stock request for the journal (I85_REQUEST_JOURNAL_V1 R1).
type Outcome string

const (
	OutcomeOK          Outcome = "OK"
	OutcomeClientError Outcome = "CLIENT_ERROR"
	OutcomeServerError Outcome = "SERVER_ERROR"
	OutcomeUnknownMID  Outcome = "UNKNOWN_MID"
	OutcomeUndecodable Outcome = "UNDECODABLE"
)

// OutcomeOf maps a dispatched response; a stock error_code on HTTP 200 is a
// client-visible refusal.
func OutcomeOf(httpStatus int, errorCode int64) Outcome {
	if httpStatus >= firstServerErrorStatus {
		return OutcomeServerError
	}
	if httpStatus >= firstClientErrorStatus || errorCode != 0 {
		return OutcomeClientError
	}
	return OutcomeOK
}

// Class is the retention class of a journal row (R6).
func (o Outcome) Class() RetentionClass {
	switch o {
	case OutcomeOK:
		return Routine
	case OutcomeUnknownMID, OutcomeUndecodable:
		return Anomaly
	default:
		return Error
	}
}

// KeepsRawEnvelope reports whether the redacted request body is kept (R3).
func (o Outcome) KeepsRawEnvelope() bool {
	return o == OutcomeUnknownMID || o == OutcomeUndecodable
}
