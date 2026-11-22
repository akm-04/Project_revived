package eventscontent

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/events"
)

func TestShippedDefinitionsParse(t *testing.T) {
	files, err := Definitions()
	if err != nil {
		t.Fatal(err)
	}
	if len(files) == 0 {
		t.Fatal("no shipped event definition file")
	}
	for _, file := range files {
		definition, err := events.ParseDefinition(file.Body)
		if err != nil {
			t.Fatalf("%s: %v", file.Name, err)
		}
		if definition.ActivityID <= 0 || definition.Revision <= 0 {
			t.Fatalf("%s: activity=%d revision=%d", file.Name, definition.ActivityID, definition.Revision)
		}
	}
}
