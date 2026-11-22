package otabuild

import (
	"bytes"
	"fmt"
	"regexp"
	"sort"
	"strings"
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
	folded := strings.ToLower(clientPath)
	return folded == "data/tables/misc.lua" || folded == "data/tables/misc1.lua"
}

func checkOriginsInFile(clientPath string, content []byte, origins map[string]string) error {
	code := stripLuaComments(content)
	counts := make(map[string]int)
	values := make(map[string]string)
	for _, match := range miscRowPattern.FindAllSubmatch(code, -1) {
		key := string(match[1])
		counts[key]++
		values[key] = string(match[2])
	}
	keys := make([]string, 0, len(origins))
	for key := range origins {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		// A key twice lets a second row shadow the first, so exactly one row is
		// required even when both values agree.
		if counts[key] != 1 || values[key] != origins[key] {
			return fmt.Errorf("%w: %s %s", ErrOriginMismatch, clientPath, key)
		}
	}
	return nil
}

// stripLuaComments removes line and long-bracket comments so a commented-out
// row cannot shadow the live one. Bytes inside quoted strings are kept: a `--`
// there is data, not a comment.
func stripLuaComments(content []byte) []byte {
	code := make([]byte, 0, len(content))
	for index := 0; index < len(content); {
		character := content[index]
		if character == '"' || character == '\'' {
			end := quotedStringEnd(content, index)
			code = append(code, content[index:end]...)
			index = end
			continue
		}
		if character == '-' && index+1 < len(content) && content[index+1] == '-' {
			if end, ok := longBracketEnd(content, index+2); ok {
				index = end
				continue
			}
			index = lineCommentEnd(content, index+2)
			continue
		}
		code = append(code, character)
		index++
	}
	return code
}

// quotedStringEnd returns the index just past the closing quote. A backslash
// escapes the next byte; an unterminated string stops at the newline.
func quotedStringEnd(content []byte, start int) int {
	quote := content[start]
	for index := start + 1; index < len(content); index++ {
		switch content[index] {
		case '\\':
			index++
		case quote:
			return index + 1
		case '\n':
			return index
		}
	}
	return len(content)
}

// longBracketEnd matches a Lua long bracket opener (`[[`, `[=[`, ...) at start
// and returns the index just past its matching closer.
func longBracketEnd(content []byte, start int) (int, bool) {
	if start >= len(content) || content[start] != '[' {
		return 0, false
	}
	cursor := start + 1
	level := 0
	for cursor < len(content) && content[cursor] == '=' {
		level++
		cursor++
	}
	if cursor >= len(content) || content[cursor] != '[' {
		return 0, false
	}
	closing := "]" + strings.Repeat("=", level) + "]"
	body := content[cursor+1:]
	offset := bytes.Index(body, []byte(closing))
	if offset < 0 {
		return len(content), true
	}
	return cursor + 1 + offset + len(closing), true
}

func lineCommentEnd(content []byte, start int) int {
	for start < len(content) && content[start] != '\n' {
		start++
	}
	return start
}
