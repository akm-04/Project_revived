package realtime

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"strconv"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
)

// WebSocket frames carry the same MID and value tree as the TCP codec in a
// JSON envelope: {"mid": <number>, "data": <value>}.
var ErrMalformedJSONFrame = errors.New("malformed realtime JSON frame")

type jsonBudget struct {
	cfg    limits.Config
	depth  int
	nodes  int
	string int
}

const exactJSONInteger int64 = 1 << 53

func exactWireInteger(v int64) any {
	if v >= -exactJSONInteger && v <= exactJSONInteger {
		return v
	}
	return strconv.FormatInt(v, 10)
}

func jsonNumberValue(n json.Number) (any, error) {
	text := n.String()
	if !bytes.ContainsAny([]byte(text), ".eE") {
		i, err := strconv.ParseInt(text, 10, 64)
		if err != nil {
			return nil, fmt.Errorf("%w: number", ErrMalformedJSONFrame)
		}
		if i >= math.MinInt32 && i <= math.MaxInt32 {
			return int32(i), nil
		}
		if i >= -exactJSONInteger && i <= exactJSONInteger {
			return float64(i), nil
		}
		return i, nil
	}
	f, err := strconv.ParseFloat(text, 64)
	if err != nil || math.IsInf(f, 0) || math.IsNaN(f) {
		return nil, fmt.Errorf("%w: number", ErrMalformedJSONFrame)
	}
	return f, nil
}

func (b *jsonBudget) enter() error {
	b.depth++
	b.nodes++
	if b.depth > b.cfg.AMFDepth || b.nodes > b.cfg.AMFNodes {
		return fmt.Errorf("%w: budget", ErrMalformedJSONFrame)
	}
	return nil
}

func decodeJSONValue(d *json.Decoder, b *jsonBudget) (any, error) {
	if err := b.enter(); err != nil {
		return nil, err
	}
	defer func() { b.depth-- }()
	token, err := d.Token()
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrMalformedJSONFrame, err)
	}
	switch v := token.(type) {
	case nil, bool:
		return v, nil
	case string:
		b.string += len(v)
		if b.string > b.cfg.AMFStringBytes || !utf8.ValidString(v) {
			return nil, fmt.Errorf("%w: string", ErrMalformedJSONFrame)
		}
		return v, nil
	case json.Number:
		return jsonNumberValue(v)
	case json.Delim:
		switch v {
		case '{':
			object := &amf3.Object{}
			seen := make(map[string]struct{})
			for d.More() {
				keyToken, err := d.Token()
				if err != nil {
					return nil, fmt.Errorf("%w: %v", ErrMalformedJSONFrame, err)
				}
				key, ok := keyToken.(string)
				if !ok {
					return nil, fmt.Errorf("%w: object key", ErrMalformedJSONFrame)
				}
				if _, exists := seen[key]; exists {
					return nil, fmt.Errorf("%w: duplicate property", ErrMalformedJSONFrame)
				}
				seen[key] = struct{}{}
				value, err := decodeJSONValue(d, b)
				if err != nil {
					return nil, err
				}
				object.Properties = append(object.Properties, amf3.Property{Name: key, Value: value})
			}
			if _, err := d.Token(); err != nil {
				return nil, fmt.Errorf("%w: %v", ErrMalformedJSONFrame, err)
			}
			return object, nil
		case '[':
			array := []any{}
			for d.More() {
				if len(array) >= b.cfg.AMFArrayElements {
					return nil, fmt.Errorf("%w: array", ErrMalformedJSONFrame)
				}
				value, err := decodeJSONValue(d, b)
				if err != nil {
					return nil, err
				}
				array = append(array, value)
			}
			if _, err := d.Token(); err != nil {
				return nil, fmt.Errorf("%w: %v", ErrMalformedJSONFrame, err)
			}
			return array, nil
		}
	}
	return nil, fmt.Errorf("%w: token", ErrMalformedJSONFrame)
}

// DecodeJSONFrame converts one JSON text frame into the same internal frame
// values the AMF3 decoder produces: objects are *amf3.Object, arrays are []any,
// JSON null is nil and integral numbers use the exact AMF3 integer/double split.
func DecodeJSONFrame(data []byte, cfg limits.Config) (Frame, error) {
	if err := cfg.Validate(); err != nil {
		return Frame{}, err
	}
	if len(data) > limits.NativeFramePayloadMax {
		return Frame{}, ErrFrameTooLarge
	}
	if len(data) == 0 || !utf8.Valid(data) {
		return Frame{}, ErrMalformedJSONFrame
	}
	d := json.NewDecoder(bytes.NewReader(data))
	d.UseNumber()
	token, err := d.Token()
	if err != nil || token != json.Delim('{') {
		return Frame{}, ErrMalformedJSONFrame
	}
	budget := &jsonBudget{cfg: cfg}
	var frame Frame
	haveMID := false
	for d.More() {
		keyToken, err := d.Token()
		if err != nil {
			return Frame{}, ErrMalformedJSONFrame
		}
		key, ok := keyToken.(string)
		if !ok {
			return Frame{}, ErrMalformedJSONFrame
		}
		switch key {
		case "mid":
			if haveMID {
				return Frame{}, ErrMalformedJSONFrame
			}
			value, err := d.Token()
			if err != nil {
				return Frame{}, ErrMalformedJSONFrame
			}
			number, ok := value.(json.Number)
			if !ok {
				return Frame{}, ErrMalformedJSONFrame
			}
			mid, err := strconv.ParseInt(number.String(), 10, 64)
			if err != nil || mid < 0 || mid > math.MaxUint16 {
				return Frame{}, ErrMalformedJSONFrame
			}
			frame.MID = uint16(mid)
			haveMID = true
		case "data":
			value, err := decodeJSONValue(d, budget)
			if err != nil {
				return Frame{}, err
			}
			frame.Params = value
		default:
			return Frame{}, ErrMalformedJSONFrame
		}
	}
	if _, err := d.Token(); err != nil {
		return Frame{}, ErrMalformedJSONFrame
	}
	if _, err := d.Token(); !errors.Is(err, io.EOF) {
		return Frame{}, ErrMalformedJSONFrame
	}
	if !haveMID {
		return Frame{}, ErrMalformedJSONFrame
	}
	return frame, nil
}

func jsonWireValue(v any, depth int) (any, error) {
	if depth > 64 {
		return nil, ErrMalformedJSONFrame
	}
	switch x := v.(type) {
	case nil:
		return nil, nil
	case amf3.Undefined:
		return nil, nil
	case bool, string:
		return x, nil
	case fmt.Stringer:
		return x.String(), nil
	case float32:
		if math.IsInf(float64(x), 0) || math.IsNaN(float64(x)) {
			return nil, ErrMalformedJSONFrame
		}
		return float64(x), nil
	case float64:
		if math.IsInf(x, 0) || math.IsNaN(x) {
			return nil, ErrMalformedJSONFrame
		}
		return x, nil
	case int:
		return exactWireInteger(int64(x)), nil
	case int8:
		return exactWireInteger(int64(x)), nil
	case int16:
		return exactWireInteger(int64(x)), nil
	case int32:
		return exactWireInteger(int64(x)), nil
	case int64:
		return exactWireInteger(x), nil
	case uint:
		return exactWireInteger(int64(x)), nil
	case uint8:
		return exactWireInteger(int64(x)), nil
	case uint16:
		return exactWireInteger(int64(x)), nil
	case uint32:
		return exactWireInteger(int64(x)), nil
	case uint64:
		if x > math.MaxInt64 {
			return strconv.FormatUint(x, 10), nil
		}
		return exactWireInteger(int64(x)), nil
	case []any:
		out := make([]any, len(x))
		for i, item := range x {
			converted, err := jsonWireValue(item, depth+1)
			if err != nil {
				return nil, err
			}
			out[i] = converted
		}
		return out, nil
	case amf3.Object:
		return jsonWireObject(&x, depth)
	case *amf3.Object:
		if x == nil {
			return nil, nil
		}
		return jsonWireObject(x, depth)
	case map[string]any:
		out := make(map[string]any, len(x))
		for key, item := range x {
			converted, err := jsonWireValue(item, depth+1)
			if err != nil {
				return nil, err
			}
			out[key] = converted
		}
		return out, nil
	default:
		return nil, fmt.Errorf("%w: unsupported value %T", ErrMalformedJSONFrame, v)
	}
}

func jsonWireObject(o *amf3.Object, depth int) (any, error) {
	out := make(map[string]any, len(o.Properties))
	for _, property := range o.Properties {
		if _, exists := out[property.Name]; exists {
			return nil, ErrMalformedJSONFrame
		}
		converted, err := jsonWireValue(property.Value, depth+1)
		if err != nil {
			return nil, err
		}
		out[property.Name] = converted
	}
	return out, nil
}

// EncodeJSONFrame converts one internal frame into the JSON text envelope.
// Integers that a double cannot hold exactly are sent as decimal strings so the
// Lua side never receives a silently rounded identifier.
func EncodeJSONFrame(f Frame, cfg limits.Config) ([]byte, error) {
	if err := cfg.Validate(); err != nil {
		return nil, err
	}
	data, err := jsonWireValue(f.Params, 0)
	if err != nil {
		return nil, err
	}
	body, err := json.Marshal(struct {
		MID  uint16 `json:"mid"`
		Data any    `json:"data"`
	}{MID: f.MID, Data: data})
	if err != nil {
		return nil, err
	}
	if len(body) > limits.NativeFramePayloadMax {
		return nil, ErrFrameTooLarge
	}
	return body, nil
}
