package otabuild

import (
	"fmt"
	"regexp"
	"sort"
)

// The stock client reads the server origin from `web_api_url` in misc.lua:10
// and misc1.lua:9 (Backend.lua:651). Those tables are ordinary data a code
// release could overwrite, so the configured origins are the guard's
// population: every configured origin must appear with its configured value in
// each packaged carrier. UpdateScene's center/api literals cannot be packaged
// at all (ruling 9).

var miscRowPattern = regexp.MustCompile(`(?s)\{\s*"((?:\\.|[^"\\])*)"\s*,\s*"((?:\\.|[^"\\])*)"`)

// checkOriginGuard refuses a package whose origin carrier differs from the
// configured server origins (ruling 10): an update must never cut a phone off.
func checkOriginGuard(files map[string][]byte, origins map[string]string) error {
	for clientPath, content := range files {
		if !isOriginCarrier(clientPath) {
			continue
		}
		if len(origins) == 0 {
			return fmt.Errorf("%w: %s", ErrOriginsMissing, clientPath)
		}
		if err := checkOriginsInFile(clientPath, content, origins); err != nil {
			return err
		}
	}
	return nil
}

func isOriginCarrier(clientPath string) bool {
	return clientPath == "data/tables/misc.lua" || clientPath == "data/tables/misc1.lua"
}

func checkOriginsInFile(clientPath string, content []byte, origins map[string]string) error {
	rows := make(map[string]string)
	for _, match := range miscRowPattern.FindAllSubmatch(content, -1) {
		if _, seen := rows[string(match[1])]; !seen {
			rows[string(match[1])] = string(match[2])
		}
	}
	keys := make([]string, 0, len(origins))
	for key := range origins {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		if value, ok := rows[key]; !ok || value != origins[key] {
			return fmt.Errorf("%w: %s %s", ErrOriginMismatch, clientPath, key)
		}
	}
	return nil
}
