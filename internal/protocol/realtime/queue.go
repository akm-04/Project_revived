package realtime

import "errors"

var ErrQueueFull = errors.New("realtime writer queue full")

type WriteQueue struct {
	maxFrames, maxBytes, bytes int
	frames                     [][]byte
}

func NewWriteQueue(maxFrames, maxBytes int) (*WriteQueue, error) {
	if maxFrames <= 0 || maxBytes <= 0 {
		return nil, errors.New("invalid queue limits")
	}
	return &WriteQueue{maxFrames: maxFrames, maxBytes: maxBytes}, nil
}
func (q *WriteQueue) Push(frame []byte) error {
	if len(frame) > q.maxBytes || len(q.frames) >= q.maxFrames || q.bytes+len(frame) > q.maxBytes {
		return ErrQueueFull
	}
	cpy := append([]byte(nil), frame...)
	q.frames = append(q.frames, cpy)
	q.bytes += len(cpy)
	return nil
}
func (q *WriteQueue) Pop() ([]byte, bool) {
	if len(q.frames) == 0 {
		return nil, false
	}
	x := q.frames[0]
	q.frames = q.frames[1:]
	q.bytes -= len(x)
	return x, true
}
func (q *WriteQueue) Len() int   { return len(q.frames) }
func (q *WriteQueue) Bytes() int { return q.bytes }
