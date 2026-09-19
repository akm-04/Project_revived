package realtime

import (
	"encoding/binary"
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
)

const HeaderBytes = 10

var ErrFrameTooLarge = errors.New("realtime frame payload too large")
var ErrMalformedFrame = errors.New("malformed realtime frame")

type Frame struct {
	MID      uint16
	Sequence uint32
	Params   any
}

func EncodeFrame(f Frame) ([]byte, error) { return EncodeFrameWithConfig(f, limits.Default()) }

func EncodeFrameWithConfig(f Frame, cfg limits.Config) ([]byte, error) {
	p, err := amf3.EncodeWithConfig(f.Params, cfg)
	if err != nil {
		return nil, err
	}
	if len(p) > limits.NativeFramePayloadMax {
		return nil, ErrFrameTooLarge
	}
	out := make([]byte, HeaderBytes+len(p))
	binary.BigEndian.PutUint32(out[:4], uint32(len(p)))
	binary.BigEndian.PutUint16(out[4:6], f.MID)
	binary.BigEndian.PutUint32(out[6:10], f.Sequence)
	copy(out[10:], p)
	return out, nil
}

type StreamDecoder struct {
	cfg limits.Config
	buf []byte
}

func NewStreamDecoder(cfg limits.Config) (*StreamDecoder, error) {
	if err := cfg.Validate(); err != nil {
		return nil, err
	}
	return &StreamDecoder{cfg: cfg}, nil
}
func (d *StreamDecoder) BufferedBytes() int { return len(d.buf) }
func (d *StreamDecoder) Feed(chunk []byte) ([]Frame, error) {
	if len(d.buf)+len(chunk) > d.cfg.RealtimeBufferedBytes {
		return nil, ErrFrameTooLarge
	}
	d.buf = append(d.buf, chunk...)
	var out []Frame
	for {
		if len(d.buf) < 4 {
			break
		}
		n := int(binary.BigEndian.Uint32(d.buf[:4]))
		if n > limits.NativeFramePayloadMax {
			return nil, ErrFrameTooLarge
		}
		total := HeaderBytes + n
		if len(d.buf) < total {
			break
		}
		mid := binary.BigEndian.Uint16(d.buf[4:6])
		seq := binary.BigEndian.Uint32(d.buf[6:10])
		v, err := amf3.Decode(d.buf[10:total], d.cfg)
		if err != nil {
			return nil, fmt.Errorf("%w: %v", ErrMalformedFrame, err)
		}
		out = append(out, Frame{MID: mid, Sequence: seq, Params: v})
		copy(d.buf, d.buf[total:])
		d.buf = d.buf[:len(d.buf)-total]
	}
	return out, nil
}
