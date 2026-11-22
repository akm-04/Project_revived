//go:build postgres

package main

import "testing"

func TestParseGameListener(t *testing.T) {
	cases := []struct {
		value string
		open  bool
		fails bool
	}{
		{"", true, false},
		{"open", true, false},
		{"closed", false, false},
		{"CLOSED", false, true},
		{"shut", false, true},
	}
	for _, testCase := range cases {
		t.Run(testCase.value, func(t *testing.T) {
			open, err := parseGameListener(testCase.value)
			if (err != nil) != testCase.fails {
				t.Fatalf("fails = %v, err = %v", testCase.fails, err)
			}
			if err == nil && open != testCase.open {
				t.Fatalf("open = %v, want %v", open, testCase.open)
			}
		})
	}
}
