package provision

import (
	"context"
	"testing"
)

func TestChallengeFixtureRejectsFreshTutorialBeforeDatabaseAccess(t *testing.T) {
	if _, err := Progress(context.Background(), "invalid-database", "", 0, nil, true); err == nil {
		t.Fatal("fresh tutorial admitted Challenge fixture")
	}
}
