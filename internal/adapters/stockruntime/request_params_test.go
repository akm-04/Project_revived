package stockruntime

import "testing"

func TestInt64ListAcceptsStockEmptyArrayObject(t *testing.T) {
	value, err := int64List(map[string]any{"partners": map[string]any{}}, "partners")
	if err != nil || len(value) != 0 {
		t.Fatalf("empty stock array: %+v %v", value, err)
	}
	value, err = int64List(map[string]any{"partners": []any{int64(2), int64(3)}}, "partners")
	if err != nil || len(value) != 2 || value[0] != 2 || value[1] != 3 {
		t.Fatalf("stock array: %+v %v", value, err)
	}
	if _, err = int64List(map[string]any{"partners": map[string]any{"1": int64(2)}}, "partners"); err == nil {
		t.Fatal("non-empty object accepted as a list")
	}
}
