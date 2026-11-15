// Package payload encodes and decodes stored JSON payloads by the payload_version column beside them (R8 6A, A-037).
// The version lives in the column, never inside the payload, so bytes, digests and fingerprints do not change.
package payload

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"reflect"
	"sort"
	"strings"
)

// Current is the version every writer stores.
// shortcut: one version for every table, until a table changes its payload shape and needs its own current version and an upgrade.
const Current int16 = 1

// Encode returns the payload bytes and the version to store beside them.
func Encode(value any) ([]byte, int16, error) {
	raw, err := json.Marshal(value)
	return raw, Current, err
}

// Decode reads a stored payload into out. Version 1 and later are strict: an unknown key, trailing data or a version
// newer than this build is an error. Version 0 rows predate the column; they decode leniently and every key the struct
// cannot hold is logged with its table, so the lead's sweep can list them before version 0 turns strict.
func Decode[T any](table string, version int16, raw []byte, out *T) error {
	if version < 0 || version > Current {
		return fmt.Errorf("%s payload version %d is outside 0..%d", table, version, Current)
	}
	if version == 0 {
		if err := json.Unmarshal(raw, out); err != nil {
			return fmt.Errorf("%s payload: %w", table, err)
		}
		for _, key := range UnknownKeys(raw, reflect.TypeOf(out).Elem()) {
			log.Printf("payload v0 unknown key: table=%s key=%s", table, key)
		}
		return nil
	}
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(out); err != nil {
		return fmt.Errorf("%s payload: %w", table, err)
	}
	if _, err := decoder.Token(); !errors.Is(err, io.EOF) {
		return fmt.Errorf("%s payload: trailing data after the value", table)
	}
	return nil
}

var unmarshalerType = reflect.TypeOf((*json.Unmarshaler)(nil)).Elem()

// UnknownKeys lists, as dotted paths, the object keys in raw that decoding into target would drop.
func UnknownKeys(raw []byte, target reflect.Type) []string {
	found := map[string]bool{}
	collectUnknown(raw, target, "", found)
	keys := make([]string, 0, len(found))
	for key := range found {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func collectUnknown(raw []byte, target reflect.Type, path string, found map[string]bool) {
	for target.Kind() == reflect.Pointer {
		target = target.Elem()
	}
	if reflect.PointerTo(target).Implements(unmarshalerType) {
		return
	}
	switch target.Kind() {
	case reflect.Struct:
		var object map[string]json.RawMessage
		if json.Unmarshal(raw, &object) != nil {
			return
		}
		fields := jsonFields(target)
		for key, value := range object {
			field, known := fields[key]
			if !known {
				field, known = foldedField(fields, key)
			}
			if !known {
				found[path+key] = true
				continue
			}
			collectUnknown(value, field, path+key+".", found)
		}
	case reflect.Slice, reflect.Array:
		if target.Elem().Kind() == reflect.Uint8 {
			return
		}
		var items []json.RawMessage
		if json.Unmarshal(raw, &items) != nil {
			return
		}
		for _, item := range items {
			collectUnknown(item, target.Elem(), path+"[].", found)
		}
	case reflect.Map:
		var object map[string]json.RawMessage
		if json.Unmarshal(raw, &object) != nil {
			return
		}
		for _, value := range object {
			collectUnknown(value, target.Elem(), path+"*.", found)
		}
	}
}

// foldedField matches a key case-insensitively, as encoding/json does when no exact name matches.
func foldedField(fields map[string]reflect.Type, key string) (reflect.Type, bool) {
	for name, field := range fields {
		if strings.EqualFold(name, key) {
			return field, true
		}
	}
	return nil, false
}

func jsonFields(target reflect.Type) map[string]reflect.Type {
	fields := map[string]reflect.Type{}
	for index := 0; index < target.NumField(); index++ {
		field := target.Field(index)
		tag := field.Tag.Get("json")
		if tag == "-" || (!field.IsExported() && !field.Anonymous) {
			continue
		}
		name, _, _ := strings.Cut(tag, ",")
		embedded := field.Type
		if embedded.Kind() == reflect.Pointer {
			embedded = embedded.Elem()
		}
		if field.Anonymous && name == "" && embedded.Kind() == reflect.Struct {
			for inner, innerType := range jsonFields(embedded) {
				if _, shadowed := fields[inner]; !shadowed {
					fields[inner] = innerType
				}
			}
			continue
		}
		if name == "" {
			name = field.Name
		}
		fields[name] = field.Type
	}
	return fields
}
