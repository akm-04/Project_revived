//go:build postgres

package main

import (
	"testing"

	appachievement "gxb.local/backend/v2/internal/application/achievement"
)

func TestObservingPanicsOnUnknownFamily(t *testing.T) {
	defer func() {
		if recover() == nil {
			t.Fatal("an unknown observation family must panic at startup")
		}
	}()
	observing(nil, appachievement.Service{}, "EventCentre", nil)
}
