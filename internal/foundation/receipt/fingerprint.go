package receipt

import (
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"math"
	"reflect"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

var ErrUnsupportedFingerprintType = errors.New("unsupported request fingerprint type")

// FingerprintRequest hashes a canonical, type-tagged encoding. It deliberately
// distinguishes values such as bool(true), int64(1), uint64(1), float64(1),
// string("1"), and []byte("1"). Map keys are sorted.
func FingerprintRequest(v any) ([32]byte, error) {
	var b bytes.Buffer
	seen := map[visit]bool{}
	if err := encodeCanonical(&b, reflect.ValueOf(v), seen, 0); err != nil {
		return [32]byte{}, err
	}
	return sha256.Sum256(b.Bytes()), nil
}

type visit struct {
	typ reflect.Type
	ptr uintptr
}

func encodeCanonical(b *bytes.Buffer, v reflect.Value, seen map[visit]bool, depth int) error {
	if depth > 64 {
		return errors.New("fingerprint nesting too deep")
	}
	if !v.IsValid() {
		b.WriteByte(0)
		return nil
	}
	if v.Kind() == reflect.Interface {
		if v.IsNil() {
			b.WriteByte(0)
			return nil
		}
		return encodeCanonical(b, v.Elem(), seen, depth+1)
	}
	if v.Kind() == reflect.Pointer {
		if v.IsNil() {
			b.WriteByte(1)
			return nil
		}
		key := visit{v.Type(), v.Pointer()}
		if seen[key] {
			return errors.New("fingerprint cycle")
		}
		seen[key] = true
		defer delete(seen, key)
		b.WriteByte(2)
		return encodeCanonical(b, v.Elem(), seen, depth+1)
	}
	if v.CanInterface() {
		switch x := v.Interface().(type) {
		case time.Time:
			b.WriteByte('T')
			writeBytes(b, []byte(x.UTC().Format(time.RFC3339Nano)))
			return nil
		case ids.UUID:
			b.WriteByte('U')
			q := x.Bytes()
			writeBytes(b, q[:])
			return nil
		}
	}
	switch v.Kind() {
	case reflect.Bool:
		b.WriteByte('b')
		if v.Bool() {
			b.WriteByte(1)
		} else {
			b.WriteByte(0)
		}
	case reflect.String:
		b.WriteByte('s')
		writeBytes(b, []byte(v.String()))
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		b.WriteByte('i')
		writeU64(b, uint64(v.Int()))
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64, reflect.Uintptr:
		b.WriteByte('u')
		writeU64(b, v.Uint())
	case reflect.Float32, reflect.Float64:
		b.WriteByte('f')
		writeU64(b, math.Float64bits(v.Convert(reflect.TypeOf(float64(0))).Float()))
	case reflect.Slice:
		if v.Type().Elem().Kind() == reflect.Uint8 {
			b.WriteByte('x')
			writeBytes(b, v.Bytes())
			return nil
		}
		b.WriteByte('l')
		writeU64(b, uint64(v.Len()))
		for i := 0; i < v.Len(); i++ {
			if err := encodeCanonical(b, v.Index(i), seen, depth+1); err != nil {
				return err
			}
		}
	case reflect.Array:
		b.WriteByte('a')
		writeU64(b, uint64(v.Len()))
		for i := 0; i < v.Len(); i++ {
			if err := encodeCanonical(b, v.Index(i), seen, depth+1); err != nil {
				return err
			}
		}
	case reflect.Map:
		if v.Type().Key().Kind() != reflect.String {
			return ErrUnsupportedFingerprintType
		}
		b.WriteByte('m')
		keys := v.MapKeys()
		sort.Slice(keys, func(i, j int) bool { return keys[i].String() < keys[j].String() })
		writeU64(b, uint64(len(keys)))
		for _, k := range keys {
			writeBytes(b, []byte(k.String()))
			if err := encodeCanonical(b, v.MapIndex(k), seen, depth+1); err != nil {
				return err
			}
		}
	case reflect.Struct:
		b.WriteByte('r')
		typ := v.Type()
		type field struct {
			name string
			v    reflect.Value
		}
		fields := []field{}
		for i := 0; i < v.NumField(); i++ {
			sf := typ.Field(i)
			if sf.PkgPath != "" {
				continue
			}
			fields = append(fields, field{sf.Name, v.Field(i)})
		}
		sort.Slice(fields, func(i, j int) bool { return fields[i].name < fields[j].name })
		writeU64(b, uint64(len(fields)))
		for _, f := range fields {
			writeBytes(b, []byte(f.name))
			if err := encodeCanonical(b, f.v, seen, depth+1); err != nil {
				return err
			}
		}
	default:
		return ErrUnsupportedFingerprintType
	}
	return nil
}
func writeU64(b *bytes.Buffer, v uint64) {
	var x [8]byte
	binary.BigEndian.PutUint64(x[:], v)
	b.Write(x[:])
}
func writeBytes(b *bytes.Buffer, v []byte) { writeU64(b, uint64(len(v))); b.Write(v) }
