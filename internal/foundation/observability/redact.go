package observability

import (
	"regexp"
	"strings"
)

const Redacted = "[REDACTED]"

// secretText matches key=value, key: value and "key":"value" pairs whose key
// carries a secret fragment, in free text such as error chains and raw bodies.
var secretText = regexp.MustCompile(`(?i)("?[a-z_]*(?:authorization|password|passwd|secret|token|sid|cookie|credential|database_url|dsn)[a-z_]*"?\s*[:=]\s*"?)([^"&\s,}]+)`)

// RedactText masks secret values in free text.
func RedactText(text string) string {
	return secretText.ReplaceAllString(text, "${1}"+Redacted)
}

var secretFragments = []string{"authorization", "password", "passwd", "secret", "token", "sid", "cookie", "credential", "database_url", "dsn", "provider_receipt", "raw_receipt"}
var contentFragments = []string{"chat_content", "mail_content", "message_body", "user_content"}

func RedactFields(in map[string]any) map[string]any {
	out := make(map[string]any, len(in))
	for k, v := range in {
		n := strings.ToLower(strings.TrimSpace(k))
		if sensitiveKey(n) {
			out[k] = Redacted
		} else {
			out[k] = v
		}
	}
	return out
}
func sensitiveKey(k string) bool {
	for _, x := range secretFragments {
		if k == x || strings.Contains(k, x) {
			return true
		}
	}
	for _, x := range contentFragments {
		if k == x || strings.Contains(k, x) {
			return true
		}
	}
	return false
}
