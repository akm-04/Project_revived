package amf3

import (
	"encoding/binary"
	"errors"
	"fmt"
	"math"
	"sort"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/protocol/limits"
)

var (
	ErrMalformed   = errors.New("malformed xinyoudi amf3")
	ErrUnsupported = errors.New("unsupported xinyoudi amf3 shape")
	ErrBudget      = errors.New("xinyoudi amf3 budget exceeded")
)

type trait struct {
	class   string
	sealed  []string
	dynamic bool
}
type decoder struct {
	b             []byte
	off           int
	cfg           limits.Config
	strings       []string
	objects       []any
	traits        []trait
	depth         int
	nodes         int
	stringBytes   int
	properties    int
	arrayElements int
}

func Decode(data []byte, cfg limits.Config) (any, error) {
	if err := cfg.Validate(); err != nil {
		return nil, err
	}
	if len(data) > limits.NativeFramePayloadMax {
		return nil, fmt.Errorf("%w: payload", ErrBudget)
	}
	d := &decoder{b: data, cfg: cfg}
	v, err := d.value()
	if err != nil {
		return nil, err
	}
	if d.off != len(d.b) {
		return nil, fmt.Errorf("%w: trailing bytes", ErrMalformed)
	}
	return v, nil
}

func (d *decoder) enter() error {
	d.depth++
	d.nodes++
	if d.depth > d.cfg.AMFDepth || d.nodes > d.cfg.AMFNodes {
		return ErrBudget
	}
	return nil
}
func (d *decoder) leave() { d.depth-- }
func (d *decoder) take(n int) ([]byte, error) {
	if n < 0 || d.off+n > len(d.b) {
		return nil, ErrMalformed
	}
	x := d.b[d.off : d.off+n]
	d.off += n
	return x, nil
}
func (d *decoder) u29() (uint32, error) {
	var v uint32
	for i := 0; i < 4; i++ {
		if d.off >= len(d.b) {
			return 0, ErrMalformed
		}
		c := d.b[d.off]
		d.off++
		if i < 3 {
			v = (v << 7) | uint32(c&0x7f)
			if c&0x80 == 0 {
				return v, nil
			}
		} else {
			v = (v << 8) | uint32(c)
			return v, nil
		}
	}
	return 0, ErrMalformed
}
func (d *decoder) str() (string, error) {
	h, e := d.u29()
	if e != nil {
		return "", e
	}
	if h&1 == 0 {
		i := int(h >> 1)
		if i < 0 || i >= len(d.strings) {
			return "", ErrMalformed
		}
		return d.strings[i], nil
	}
	n := int(h >> 1)
	if n == 0 {
		return "", nil
	}
	raw, e := d.take(n)
	if e != nil {
		return "", e
	}
	d.stringBytes += n
	if d.stringBytes > d.cfg.AMFStringBytes {
		return "", ErrBudget
	}
	s := string(raw)
	if !utf8.ValidString(s) {
		return "", ErrMalformed
	}
	if len(d.strings) >= d.cfg.AMFReferences {
		return "", ErrBudget
	}
	d.strings = append(d.strings, s)
	return s, nil
}

func (d *decoder) value() (any, error) {
	if err := d.enter(); err != nil {
		return nil, err
	}
	defer d.leave()
	if d.off >= len(d.b) {
		return nil, ErrMalformed
	}
	m := d.b[d.off]
	d.off++
	switch m {
	case 0x00:
		return UndefinedValue, nil
	case 0x01:
		return nil, nil
	case 0x02:
		return false, nil
	case 0x03:
		return true, nil
	case 0x04:
		h, e := d.u29()
		if e != nil {
			return nil, e
		}
		if h&0x10000000 != 0 {
			return int32(h | 0xe0000000), nil
		}
		return int32(h), nil
	case 0x05:
		x, e := d.take(8)
		if e != nil {
			return nil, e
		}
		return math.Float64frombits(binary.BigEndian.Uint64(x)), nil
	case 0x06:
		return d.str()
	case 0x09:
		return d.array()
	case 0x0a:
		return d.object()
	default:
		return nil, fmt.Errorf("%w: marker 0x%02x", ErrUnsupported, m)
	}
}
func (d *decoder) ref(i int) (any, error) {
	if i < 0 || i >= len(d.objects) {
		return nil, ErrMalformed
	}
	return d.objects[i], nil
}
func (d *decoder) array() (any, error) {
	h, e := d.u29()
	if e != nil {
		return nil, e
	}
	if h&1 == 0 {
		return d.ref(int(h >> 1))
	}
	n := int(h >> 1)
	d.arrayElements += n
	if d.arrayElements > d.cfg.AMFArrayElements {
		return nil, ErrBudget
	}
	if len(d.objects) >= d.cfg.AMFReferences {
		return nil, ErrBudget
	}
	holder := make([]any, n)
	d.objects = append(d.objects, holder)
	key, e := d.str()
	if e != nil {
		return nil, e
	}
	if key != "" {
		return nil, fmt.Errorf("%w: associative array", ErrUnsupported)
	}
	for i := 0; i < n; i++ {
		v, e := d.value()
		if e != nil {
			return nil, e
		}
		holder[i] = v
	}
	return holder, nil
}
func (d *decoder) object() (any, error) {
	h, e := d.u29()
	if e != nil {
		return nil, e
	}
	if h&1 == 0 {
		return d.ref(int(h >> 1))
	}
	ti := h >> 1
	var tr trait
	if ti&1 == 0 {
		idx := int(ti >> 1)
		if idx < 0 || idx >= len(d.traits) {
			return nil, ErrMalformed
		}
		tr = d.traits[idx]
	} else {
		external := ti&2 != 0
		dynamic := ti&4 != 0
		sealedN := int(ti >> 3)
		if sealedN > d.cfg.AMFProperties {
			return nil, fmt.Errorf("%w: sealed properties", ErrBudget)
		}
		if external {
			return nil, fmt.Errorf("%w: externalizable", ErrUnsupported)
		}
		// The recovered Xinyoudi profile supports only dynamic anonymous objects.
		// Reject unsupported trait shapes before any sealed-name allocation/read.
		if sealedN != 0 || !dynamic {
			return nil, fmt.Errorf("%w: only dynamic anonymous object", ErrUnsupported)
		}
		class, e := d.str()
		if e != nil {
			return nil, e
		}
		if class != "" {
			return nil, fmt.Errorf("%w: named class", ErrUnsupported)
		}
		tr = trait{class: class, dynamic: true}
		if len(d.traits) >= d.cfg.AMFReferences {
			return nil, ErrBudget
		}
		d.traits = append(d.traits, tr)
	}
	if tr.class != "" || len(tr.sealed) != 0 || !tr.dynamic {
		return nil, fmt.Errorf("%w: only dynamic anonymous object", ErrUnsupported)
	}
	if len(d.objects) >= d.cfg.AMFReferences {
		return nil, ErrBudget
	}
	o := &Object{}
	d.objects = append(d.objects, o)
	for {
		k, e := d.str()
		if e != nil {
			return nil, e
		}
		if k == "" {
			break
		}
		d.properties++
		if d.properties > d.cfg.AMFProperties {
			return nil, ErrBudget
		}
		v, e := d.value()
		if e != nil {
			return nil, e
		}
		o.Properties = append(o.Properties, Property{Name: k, Value: v})
	}
	return o, nil
}

type encoder struct {
	cfg           limits.Config
	out           []byte
	strings       map[string]int
	active        map[string]struct{}
	depth         int
	nodes         int
	stringBytes   int
	properties    int
	arrayElements int
	objectRefs    int
}

// Encode preserves the frozen stock-safe API and applies the default finite AMF profile.
func Encode(v any) ([]byte, error) { return EncodeWithConfig(v, limits.Default()) }

// EncodeWithConfig serializes the recovered Xinyoudi AMF3 subset under explicit
// finite budgets. It never permits output larger than the native frame payload.
func EncodeWithConfig(v any, cfg limits.Config) ([]byte, error) {
	if err := cfg.Validate(); err != nil {
		return nil, err
	}
	e := &encoder{cfg: cfg, strings: map[string]int{}, active: map[string]struct{}{}, out: make([]byte, 0, minInt(cfg.AMFOutputBytes, 256))}
	if err := e.value(v); err != nil {
		return nil, err
	}
	return e.out, nil
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func (e *encoder) enter() error {
	e.depth++
	e.nodes++
	if e.depth > e.cfg.AMFDepth || e.nodes > e.cfg.AMFNodes {
		e.depth--
		return ErrBudget
	}
	return nil
}
func (e *encoder) leave() { e.depth-- }

func (e *encoder) ensure(n int) error {
	if n < 0 || n > e.cfg.AMFOutputBytes-len(e.out) {
		return fmt.Errorf("%w: output", ErrBudget)
	}
	return nil
}
func (e *encoder) byte(v byte) error {
	if err := e.ensure(1); err != nil {
		return err
	}
	e.out = append(e.out, v)
	return nil
}
func (e *encoder) bytes(v []byte) error {
	if err := e.ensure(len(v)); err != nil {
		return err
	}
	e.out = append(e.out, v...)
	return nil
}
func (e *encoder) text(v string) error {
	if err := e.ensure(len(v)); err != nil {
		return err
	}
	e.out = append(e.out, v...)
	return nil
}
func (e *encoder) u29(v uint32) error {
	b, err := writeU29(v)
	if err != nil {
		return err
	}
	return e.bytes(b)
}

func (e *encoder) str(s string) error {
	if s == "" {
		return e.byte(1)
	}
	if i, ok := e.strings[s]; ok {
		return e.u29(uint32(i << 1))
	}
	if !utf8.ValidString(s) {
		return ErrMalformed
	}
	if len(s) > 0x0fffffff {
		return fmt.Errorf("%w: string", ErrBudget)
	}
	if e.stringBytes > e.cfg.AMFStringBytes-len(s) {
		return fmt.Errorf("%w: string bytes", ErrBudget)
	}
	if len(e.strings) >= e.cfg.AMFReferences {
		return fmt.Errorf("%w: string references", ErrBudget)
	}
	h, err := writeU29(uint32(len(s)<<1 | 1))
	if err != nil {
		return err
	}
	if err := e.ensure(len(h) + len(s)); err != nil {
		return err
	}
	e.strings[s] = len(e.strings)
	e.stringBytes += len(s)
	e.out = append(e.out, h...)
	e.out = append(e.out, s...)
	return nil
}

func writeU29(v uint32) ([]byte, error) {
	if v > 0x1fffffff {
		return nil, ErrMalformed
	}
	switch {
	case v < 0x80:
		return []byte{byte(v)}, nil
	case v < 0x4000:
		return []byte{byte(v>>7) | 0x80, byte(v & 0x7f)}, nil
	case v < 0x200000:
		return []byte{byte(v>>14) | 0x80, byte(v>>7)&0x7f | 0x80, byte(v & 0x7f)}, nil
	default:
		return []byte{byte(v>>22)&0x7f | 0x80, byte(v>>15)&0x7f | 0x80, byte(v>>8)&0x7f | 0x80, byte(v)}, nil
	}
}

const maxExactInteger = int64(1 << 53)

func (e *encoder) double(v float64) error {
	if math.IsInf(v, 0) || math.IsNaN(v) {
		return ErrMalformed
	}
	if err := e.ensure(9); err != nil {
		return err
	}
	e.out = append(e.out, 0x05, 0, 0, 0, 0, 0, 0, 0, 0)
	binary.BigEndian.PutUint64(e.out[len(e.out)-8:], math.Float64bits(v))
	return nil
}
func (e *encoder) signed(v int64) error {
	if v < -maxExactInteger || v > maxExactInteger {
		return fmt.Errorf("%w: signed integer outside exact double range", ErrMalformed)
	}
	return e.double(float64(v))
}
func (e *encoder) unsigned(v uint64) error {
	if v > uint64(maxExactInteger) {
		return fmt.Errorf("%w: unsigned integer outside exact double range", ErrMalformed)
	}
	return e.double(float64(v))
}

func (e *encoder) beginContainer(key string) error {
	if key != "" {
		if _, exists := e.active[key]; exists {
			return fmt.Errorf("%w: cyclic input", ErrUnsupported)
		}
		e.active[key] = struct{}{}
	}
	if e.objectRefs >= e.cfg.AMFReferences {
		if key != "" {
			delete(e.active, key)
		}
		return fmt.Errorf("%w: object references", ErrBudget)
	}
	e.objectRefs++
	return nil
}
func (e *encoder) endContainer(key string) {
	if key != "" {
		delete(e.active, key)
	}
}

func (e *encoder) value(v any) error {
	if err := e.enter(); err != nil {
		return err
	}
	defer e.leave()
	switch x := v.(type) {
	case Undefined:
		return e.byte(0)
	case nil:
		return e.byte(1)
	case bool:
		if x {
			return e.byte(3)
		}
		return e.byte(2)
	case float64:
		return e.double(x)
	case float32:
		return e.double(float64(x))
	case int:
		return e.signed(int64(x))
	case int8:
		return e.signed(int64(x))
	case int16:
		return e.signed(int64(x))
	case int32:
		return e.signed(int64(x))
	case int64:
		return e.signed(x)
	case uint:
		return e.unsigned(uint64(x))
	case uint8:
		return e.unsigned(uint64(x))
	case uint16:
		return e.unsigned(uint64(x))
	case uint32:
		return e.unsigned(uint64(x))
	case uint64:
		return e.unsigned(x)
	case string:
		if err := e.byte(0x06); err != nil {
			return err
		}
		return e.str(x)
	case []any:
		return e.array(x)
	case Object:
		return e.object(&x, "")
	case *Object:
		if x == nil {
			return ErrMalformed
		}
		return e.object(x, fmt.Sprintf("object:%p", x))
	case map[string]any:
		return e.mapObject(x)
	default:
		return fmt.Errorf("%w: %T", ErrUnsupported, v)
	}
}

func (e *encoder) array(x []any) error {
	if len(x) > e.cfg.AMFArrayElements-e.arrayElements {
		return fmt.Errorf("%w: array elements", ErrBudget)
	}
	if len(x) > 0x0fffffff {
		return fmt.Errorf("%w: array elements", ErrBudget)
	}
	key := ""
	if len(x) != 0 {
		key = fmt.Sprintf("slice:%p", &x[0])
	}
	if err := e.beginContainer(key); err != nil {
		return err
	}
	defer e.endContainer(key)
	e.arrayElements += len(x)
	if err := e.byte(0x09); err != nil {
		return err
	}
	if err := e.u29(uint32(len(x)<<1 | 1)); err != nil {
		return err
	}
	if err := e.byte(1); err != nil { // empty associative-name terminator
		return err
	}
	for _, v := range x {
		if err := e.value(v); err != nil {
			return err
		}
	}
	return nil
}

func (e *encoder) object(o *Object, key string) error {
	if o == nil {
		return ErrMalformed
	}
	if len(o.Properties) > e.cfg.AMFProperties-e.properties {
		return fmt.Errorf("%w: properties", ErrBudget)
	}
	if err := e.beginContainer(key); err != nil {
		return err
	}
	defer e.endContainer(key)
	e.properties += len(o.Properties)
	if err := e.bytes([]byte{0x0a, 0x0b, 0x01}); err != nil {
		return err
	}
	for _, p := range o.Properties {
		if p.Name == "" {
			return ErrMalformed
		}
		if err := e.str(p.Name); err != nil {
			return err
		}
		if err := e.value(p.Value); err != nil {
			return err
		}
	}
	return e.byte(1)
}

func (e *encoder) mapObject(x map[string]any) error {
	if x == nil {
		return ErrMalformed
	}
	if len(x) > e.cfg.AMFProperties-e.properties {
		return fmt.Errorf("%w: properties", ErrBudget)
	}
	key := fmt.Sprintf("map:%p", x)
	if err := e.beginContainer(key); err != nil {
		return err
	}
	defer e.endContainer(key)
	e.properties += len(x)
	if err := e.bytes([]byte{0x0a, 0x0b, 0x01}); err != nil {
		return err
	}
	keys := make([]string, 0, len(x))
	for k := range x {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		if k == "" {
			return ErrMalformed
		}
		if err := e.str(k); err != nil {
			return err
		}
		if err := e.value(x[k]); err != nil {
			return err
		}
	}
	return e.byte(1)
}

func EncodeInteger(v int32) ([]byte, error) {
	if v < -268435456 || v > 268435455 {
		return nil, ErrMalformed
	}
	raw := uint32(v) & 0x1fffffff
	u, er := writeU29(raw)
	return append([]byte{4}, u...), er
}
