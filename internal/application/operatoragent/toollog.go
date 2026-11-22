package operatoragent

import (
	"encoding/json"
	"io"
	"regexp"
	"sync"
	"time"
)

// secretKeyPattern is the single masking rule (I11A_1_PLAN "Agent decisions"):
// a key containing token, password, passwd, secret, dsn or key is masked.
var secretKeyPattern = regexp.MustCompile(`(?i)(token|password|passwd|secret|dsn|key)`)

// userinfoPattern masks the credentials in a database URL.
var userinfoPattern = regexp.MustCompile(`(?i)\b(postgres(?:ql)?://)[^/@\s]+@`)

// assignmentPattern masks key=value text and a DSN's query password.
var assignmentPattern = regexp.MustCompile(`(?i)(token|password|passwd|secret|dsn|key)=[^\s&]+`)

// ToolLog writes one JSON line per agent action. Masking happens here and only
// here, so no call site has to remember it.
type ToolLog struct {
	mutex  sync.Mutex
	writer io.Writer
	now    func() time.Time
}

// NewToolLog takes the destination and the clock.
func NewToolLog(writer io.Writer, now func() time.Time) *ToolLog {
	return &ToolLog{writer: writer, now: now}
}

type toolLogLine struct {
	At      time.Time `json:"at"`
	Op      string    `json:"op"`
	Step    string    `json:"step"`
	Outcome string    `json:"outcome"`
	Detail  any       `json:"detail,omitempty"`
}

// Write appends one masked line.
func (log *ToolLog) Write(op, step, outcome string, detail any) {
	line := toolLogLine{At: log.now(), Op: op, Step: step, Outcome: outcome}
	if detail != nil {
		line.Detail = maskDetail(detail)
	}
	encoded, err := json.Marshal(line)
	if err != nil {
		return
	}
	log.mutex.Lock()
	defer log.mutex.Unlock()
	_, _ = log.writer.Write(append(encoded, '\n'))
}

func maskDetail(detail any) any {
	encoded, err := json.Marshal(detail)
	if err != nil {
		return nil
	}
	var decoded any
	if err := json.Unmarshal(encoded, &decoded); err != nil {
		return nil
	}
	return MaskValue(decoded)
}

// MaskValue masks a decoded JSON value.
func MaskValue(value any) any {
	switch typed := value.(type) {
	case map[string]any:
		masked := make(map[string]any, len(typed))
		for key, item := range typed {
			if secretKeyPattern.MatchString(key) {
				masked[key] = "***"
				continue
			}
			masked[key] = MaskValue(item)
		}
		return masked
	case []any:
		masked := make([]any, len(typed))
		for index, item := range typed {
			masked[index] = MaskValue(item)
		}
		return masked
	case string:
		return MaskString(typed)
	default:
		return value
	}
}

// MaskString masks database userinfo and key=value secrets inside free text.
func MaskString(text string) string {
	masked := userinfoPattern.ReplaceAllString(text, "${1}***@")
	return assignmentPattern.ReplaceAllString(masked, "${1}=***")
}
