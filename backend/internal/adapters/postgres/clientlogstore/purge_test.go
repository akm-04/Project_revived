package clientlogstore

import (
	"testing"
	"time"

	domain "gxb.local/backend/v2/internal/domain/clientlog"
)

func TestCappedWindow(t *testing.T) {
	for _, testCase := range []struct {
		owner    time.Duration
		days     int
		expected time.Duration
	}{
		{domain.RoutineRetention, 3, 3 * 24 * time.Hour},
		{domain.RoutineRetention, 15, domain.RoutineRetention},
		{domain.IncidentRetention, 3, 3 * 24 * time.Hour},
		{domain.IncidentRetention, 15, 15 * 24 * time.Hour},
	} {
		if got := cappedWindow(testCase.owner, testCase.days); got != testCase.expected {
			t.Fatalf("cappedWindow(%s, %d)=%s want %s", testCase.owner, testCase.days, got, testCase.expected)
		}
	}
}
