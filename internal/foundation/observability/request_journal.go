package observability

import (
	"context"
	"sync"
	"time"
)

// RequestDisposition is how far the HTTP edge got with a request.
type RequestDisposition int

const (
	RequestDispatched RequestDisposition = iota
	RequestUnknownMID
	RequestUndecodable
	RequestRejectedAtEdge
)

// RequestRecord is one stock HTTP request as seen by the edge
// (I85_REQUEST_JOURNAL_V1). Raw holds the unescaped request body for
// unknown or undecodable requests only; the journal redacts and caps it.
type RequestRecord struct {
	ReceivedAt    time.Time
	Disposition   RequestDisposition
	MID           int
	HasMID        bool
	HTTPStatus    int
	ErrorCode     int64
	Latency       time.Duration
	RequestBytes  int64
	ResponseBytes int64
	RequestSHA256 []byte
	Cause         error
	Raw           []byte
	Actor         RequestActor
}

// RequestActor is the authenticated stock identity of a request, when known.
type RequestActor struct {
	AccountUID string
	PlayerID   int64
	SessionID  string
}

// RequestJournal receives edge records; implementations must not block.
type RequestJournal interface {
	Record(RequestRecord)
}

// RequestNote collects the actor of one request while dispatchers run.
type RequestNote struct {
	mutex sync.Mutex
	actor RequestActor
}

type requestNoteKey struct{}

// WithRequestNote attaches an empty note to a request context.
func WithRequestNote(ctx context.Context) (context.Context, *RequestNote) {
	note := &RequestNote{}
	return context.WithValue(ctx, requestNoteKey{}, note), note
}

// NoteActor records the authenticated actor on the request's note, if any.
func NoteActor(ctx context.Context, actor RequestActor) {
	note, _ := ctx.Value(requestNoteKey{}).(*RequestNote)
	if note == nil {
		return
	}
	note.mutex.Lock()
	defer note.mutex.Unlock()
	note.actor = actor
}

// Actor returns the noted actor (zero when the request was never authenticated).
func (n *RequestNote) Actor() RequestActor {
	n.mutex.Lock()
	defer n.mutex.Unlock()
	return n.actor
}
