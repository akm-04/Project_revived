//go:build postgres

package main

import "testing"

func TestHandlerConcurrencyClampsToHalfThePool(t *testing.T) {
	for _, test := range []struct {
		name     string
		fallback int
		pool     int
		want     int
	}{
		{"default below half", 4, 16, 4},
		{"default above half", 8, 8, 4},
		{"smallest pool", 8, 1, 1},
	} {
		t.Run(test.name, func(t *testing.T) {
			t.Setenv("GXB_HANDLER_BOUND_UNSET", "")
			if got := handlerConcurrency("GXB_HANDLER_BOUND_UNSET", test.fallback, test.pool); got != test.want {
				t.Fatalf("handlerConcurrency = %d, want %d", got, test.want)
			}
		})
	}
}
