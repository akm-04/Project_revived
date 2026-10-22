package main

import (
	"slices"
	"testing"
)

func TestExpandTaps(t *testing.T) {
	got := expandTaps("region_button,640x360*3,a*b")
	want := []string{"region_button", "640x360", "640x360", "640x360", "a*b"}
	if !slices.Equal(got, want) {
		t.Fatalf("expandTaps = %v, want %v", got, want)
	}
}
