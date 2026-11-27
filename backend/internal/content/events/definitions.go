package eventscontent

import (
	"embed"
	"fmt"
)

//go:embed definitions/*.json
var definitionFiles embed.FS

// DefinitionFile is one shipped event definition file (EA-13).
type DefinitionFile struct {
	Name string
	Body []byte
}

// Definitions returns the shipped definition files in file-name order.
func Definitions() ([]DefinitionFile, error) {
	entries, err := definitionFiles.ReadDir("definitions")
	if err != nil {
		return nil, fmt.Errorf("events content: read definitions: %w", err)
	}
	files := make([]DefinitionFile, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		body, err := definitionFiles.ReadFile("definitions/" + entry.Name())
		if err != nil {
			return nil, fmt.Errorf("events content: read %s: %w", entry.Name(), err)
		}
		files = append(files, DefinitionFile{Name: entry.Name(), Body: body})
	}
	return files, nil
}
