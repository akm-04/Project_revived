package operatoragent

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

// Log sources the operator tool can read (OPERATOR_BACKUPS_LOGS_DESIGN C1).
const (
	LogSourceTool     = "tool"
	LogSourceBackend  = "backend"
	LogSourceDatabase = "database"
	LogSourceClient   = "client"
)

const (
	ToolLogPrefix    = "tool-"
	BackendLogPrefix = "backend-"
	LogFileSuffix    = ".log"

	DefaultLogTailLimit = 100
	MaxLogTailLimit     = 1000

	// A live tail reads at most this much of the newest file; a search reads at
	// most this much per file. Both stay bounded on a large log.
	// shortcut: no cursor or search beyond these windows, upgrade when logs outgrow them.
	logTailReadBytes   = 256 << 10
	logSearchReadBytes = 4 << 20

	DefaultToolLogDays = 30
	maximumToolLogDays = 3650
)

// DatedLogWriter appends to <directory>/<prefix><UTC date>.log and rolls at UTC
// midnight, so a running agent never keeps one unbounded file.
type DatedLogWriter struct {
	directory string
	prefix    string
	now       func() time.Time

	mutex       sync.Mutex
	currentDate string
	file        *os.File
}

// NewDatedLogWriter names the directory and the file prefix.
func NewDatedLogWriter(directory, prefix string, now func() time.Time) *DatedLogWriter {
	return &DatedLogWriter{directory: directory, prefix: prefix, now: now}
}

// Write appends to the current day's file.
func (writer *DatedLogWriter) Write(data []byte) (int, error) {
	writer.mutex.Lock()
	defer writer.mutex.Unlock()
	date := writer.now().UTC().Format("2006-01-02")
	if writer.file == nil || date != writer.currentDate {
		if err := writer.open(date); err != nil {
			return 0, err
		}
	}
	return writer.file.Write(data)
}

func (writer *DatedLogWriter) open(date string) error {
	if writer.file != nil {
		_ = writer.file.Close()
		writer.file = nil
	}
	if err := os.MkdirAll(writer.directory, 0o700); err != nil {
		return err
	}
	file, err := os.OpenFile(filepath.Join(writer.directory, writer.prefix+date+LogFileSuffix), os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return err
	}
	writer.file, writer.currentDate = file, date
	return nil
}

// Close closes the current file.
func (writer *DatedLogWriter) Close() error {
	writer.mutex.Lock()
	defer writer.mutex.Unlock()
	if writer.file == nil {
		return nil
	}
	err := writer.file.Close()
	writer.file = nil
	return err
}

// RetainDatedLogs removes tool and backend files older than the retention days
// (C1: tool_log_days applies to both). It returns how many files it removed.
func RetainDatedLogs(directory string, days int, now time.Time) (int, error) {
	if days < 1 {
		days = DefaultToolLogDays
	}
	cutoff := now.UTC().AddDate(0, 0, -days).Format("2006-01-02")
	entries, err := os.ReadDir(directory)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return 0, nil
		}
		return 0, err
	}
	removed := 0
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		_, date, ok := parseDatedLogName(entry.Name())
		if !ok || date >= cutoff {
			continue
		}
		if err := os.Remove(filepath.Join(directory, entry.Name())); err != nil {
			return removed, err
		}
		removed++
	}
	return removed, nil
}

// RunLogRetention prunes old dated files now and then once per interval until
// ctx ends, so a long-running agent keeps the tool_log_days window.
func RunLogRetention(ctx context.Context, directory string, days int, now func() time.Time, interval time.Duration) {
	_, _ = RetainDatedLogs(directory, days, now())
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			_, _ = RetainDatedLogs(directory, days, now())
		}
	}
}

// parseDatedLogName accepts only a tool or backend dated file.
func parseDatedLogName(name string) (string, string, bool) {
	prefix := ""
	switch {
	case strings.HasPrefix(name, ToolLogPrefix):
		prefix = ToolLogPrefix
	case strings.HasPrefix(name, BackendLogPrefix):
		prefix = BackendLogPrefix
	default:
		return "", "", false
	}
	rest := strings.TrimSuffix(strings.TrimPrefix(name, prefix), LogFileSuffix)
	if len(rest) != len("2006-01-02") {
		return "", "", false
	}
	if _, err := time.Parse("2006-01-02", rest); err != nil {
		return "", "", false
	}
	return prefix, rest, true
}

// LogLine is one line of a tool, backend or database log.
type LogLine struct {
	At    string `json:"at,omitempty"`
	Level string `json:"level"`
	Text  string `json:"text"`
}

// LogTail is the logs.tail reply for one source.
type LogTail struct {
	Source     string    `json:"source"`
	Lines      []LogLine `json:"lines"`
	NextCursor string    `json:"next_cursor"`
	Absent     bool      `json:"absent,omitempty"`
	Reason     string    `json:"reason,omitempty"`
}

// LogSearch is the logs.search reply for one source. Entries are LogLine values
// for a file source and the redacted journal objects for the client source.
type LogSearch struct {
	Source  string `json:"source"`
	Entries []any  `json:"entries"`
	Absent  bool   `json:"absent,omitempty"`
	Reason  string `json:"reason,omitempty"`
}

// LogService reads the agent's own log files and forwards client journal reads
// to the backend operator API.
type LogService struct {
	Directory       string
	DatabaseLogPath string
	Operator        OperatorClient
	Now             func() time.Time
}

type logFileCursor struct {
	Date   string
	Offset int64
}

func parseLogCursor(value string) (logFileCursor, bool) {
	date, offsetText, found := strings.Cut(value, "|")
	if !found {
		return logFileCursor{}, false
	}
	if _, err := time.Parse("2006-01-02", date); err != nil {
		return logFileCursor{}, false
	}
	offset, err := strconv.ParseInt(offsetText, 10, 64)
	if err != nil || offset < 0 {
		return logFileCursor{}, false
	}
	return logFileCursor{Date: date, Offset: offset}, true
}

func formatLogCursor(date string, offset int64) string {
	return date + "|" + strconv.FormatInt(offset, 10)
}

// tailFiles reads the agent's own dated files forward from afterCursor (C2).
// An empty cursor reads the newest lines of the newest file.
func (service *LogService) tailFiles(source, afterCursor, level string, limit int) (LogTail, error) {
	level, err := normalizeLogLevel(level)
	if err != nil {
		return LogTail{}, err
	}
	limit = normalizeLogLimit(limit)
	if afterCursor != "" {
		if _, valid := parseLogCursor(afterCursor); !valid {
			return LogTail{}, Refuse(CodeLogCursorInvalid, "after_cursor is not a cursor this agent issued")
		}
	}
	files, absent, reason := service.filesFor(source)
	if absent {
		return LogTail{Source: source, Lines: []LogLine{}, Absent: true, Reason: reason}, nil
	}
	if len(files) == 0 {
		return LogTail{Source: source, Lines: []LogLine{}}, nil
	}
	if afterCursor == "" {
		return tailNewestFile(source, files[len(files)-1], level, limit)
	}
	cursor, _ := parseLogCursor(afterCursor)
	return tailFromCursor(source, files, cursor, level, limit)
}

func tailNewestFile(source string, file datedLogFile, level string, limit int) (LogTail, error) {
	handle, err := os.Open(file.Path)
	if err != nil {
		return LogTail{}, err
	}
	defer handle.Close()
	info, err := handle.Stat()
	if err != nil {
		return LogTail{}, err
	}
	start := info.Size() - logTailReadBytes
	if start < 0 {
		start = 0
	}
	if _, err := handle.Seek(start, io.SeekStart); err != nil {
		return LogTail{}, err
	}
	contents, err := io.ReadAll(io.LimitReader(handle, logTailReadBytes))
	if err != nil {
		return LogTail{}, err
	}
	lines := splitLogLines(contents)
	if start > 0 && len(lines) > 0 {
		lines = lines[1:]
	}
	matched := make([]LogLine, 0, limit)
	for _, text := range lines {
		line := decodeLogLine(source, text)
		if level != "" && line.Level != level {
			continue
		}
		matched = append(matched, line)
	}
	if len(matched) > limit {
		matched = matched[len(matched)-limit:]
	}
	return LogTail{Source: source, Lines: matched, NextCursor: formatLogCursor(file.Date, info.Size())}, nil
}

func tailFromCursor(source string, files []datedLogFile, cursor logFileCursor, level string, limit int) (LogTail, error) {
	lines := make([]LogLine, 0, limit)
	next := cursor
	for _, file := range files {
		if file.Date < cursor.Date {
			continue
		}
		offset := int64(0)
		if file.Date == cursor.Date {
			offset = cursor.Offset
		}
		read, consumed, err := readLogFileForward(file, offset, level, limit-len(lines))
		if err != nil {
			return LogTail{}, err
		}
		lines = append(lines, read...)
		next = logFileCursor{Date: file.Date, Offset: consumed}
		if len(lines) >= limit {
			break
		}
	}
	return LogTail{Source: source, Lines: lines, NextCursor: formatLogCursor(next.Date, next.Offset)}, nil
}

// readLogFileForward reads forward from offset and stops after limit matches.
// The returned offset is after the last line read, matching or not, so a level
// filter never replays the same lines.
func readLogFileForward(file datedLogFile, offset int64, level string, limit int) ([]LogLine, int64, error) {
	if limit <= 0 {
		return nil, offset, nil
	}
	handle, err := os.Open(file.Path)
	if err != nil {
		return nil, offset, err
	}
	defer handle.Close()
	if _, err := handle.Seek(offset, io.SeekStart); err != nil {
		return nil, offset, err
	}
	reader := bufio.NewReader(handle)
	consumed := offset
	lines := make([]LogLine, 0, limit)
	for {
		text, readErr := reader.ReadString('\n')
		consumed += int64(len(text))
		trimmed := strings.TrimRight(text, "\r\n")
		if trimmed != "" {
			line := decodeLogLine(sourceOfPrefix(file), trimmed)
			if level == "" || line.Level == level {
				lines = append(lines, line)
			}
		}
		if len(lines) >= limit || errors.Is(readErr, io.EOF) {
			break
		}
		if readErr != nil {
			return nil, consumed, readErr
		}
	}
	return lines, consumed, nil
}

// searchFiles answers newest-first matching lines (C2-C3). from and to bound
// the file dates, because each file is one UTC day.
func (service *LogService) searchFiles(source, fromText, toText, level string, limit int) (LogSearch, error) {
	level, err := normalizeLogLevel(level)
	if err != nil {
		return LogSearch{}, err
	}
	limit = normalizeLogLimit(limit)
	from, to, err := parseLogDateRange(fromText, toText)
	if err != nil {
		return LogSearch{}, err
	}
	files, absent, reason := service.filesFor(source)
	if absent {
		return LogSearch{Source: source, Entries: []any{}, Absent: true, Reason: reason}, nil
	}
	entries := make([]any, 0, limit)
	for index := len(files) - 1; index >= 0 && len(entries) < limit; index-- {
		file := files[index]
		if from != "" && file.Date < from {
			break
		}
		if to != "" && file.Date > to {
			continue
		}
		read, readErr := searchFileBackward(file, level, limit-len(entries))
		if readErr != nil {
			return LogSearch{}, readErr
		}
		for _, line := range read {
			entries = append(entries, line)
		}
	}
	return LogSearch{Source: source, Entries: entries}, nil
}

func searchFileBackward(file datedLogFile, level string, limit int) ([]LogLine, error) {
	handle, err := os.Open(file.Path)
	if err != nil {
		return nil, err
	}
	defer handle.Close()
	info, err := handle.Stat()
	if err != nil {
		return nil, err
	}
	start := info.Size() - logSearchReadBytes
	if start < 0 {
		start = 0
	}
	if _, err := handle.Seek(start, io.SeekStart); err != nil {
		return nil, err
	}
	contents, err := io.ReadAll(io.LimitReader(handle, logSearchReadBytes))
	if err != nil {
		return nil, err
	}
	lines := splitLogLines(contents)
	if start > 0 && len(lines) > 0 {
		lines = lines[1:]
	}
	matched := make([]LogLine, 0, limit)
	for index := len(lines) - 1; index >= 0 && len(matched) < limit; index-- {
		line := decodeLogLine(sourceOfPrefix(file), lines[index])
		if level != "" && line.Level != level {
			continue
		}
		matched = append(matched, line)
	}
	return matched, nil
}

// filesFor resolves a source to dated files. absent is true when the source is
// configured but unreadable or not configured at all.
func (service *LogService) filesFor(source string) ([]datedLogFile, bool, string) {
	switch source {
	case LogSourceTool:
		return datedLogFiles(service.Directory, ToolLogPrefix), false, ""
	case LogSourceBackend:
		return datedLogFiles(service.Directory, BackendLogPrefix), false, ""
	case LogSourceDatabase:
		if service.DatabaseLogPath == "" {
			return nil, true, "the agent config does not name a database log file"
		}
		info, err := os.Stat(service.DatabaseLogPath)
		if err != nil || !info.Mode().IsRegular() {
			return nil, true, "the configured database log file is not readable"
		}
		return []datedLogFile{{Path: service.DatabaseLogPath, Date: service.Now().UTC().Format("2006-01-02")}}, false, ""
	default:
		return nil, false, ""
	}
}

func datedLogFiles(directory, prefix string) []datedLogFile {
	entries, err := os.ReadDir(directory)
	if err != nil {
		return nil
	}
	files := make([]datedLogFile, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		foundPrefix, date, ok := parseDatedLogName(entry.Name())
		if !ok || foundPrefix != prefix {
			continue
		}
		files = append(files, datedLogFile{Path: filepath.Join(directory, entry.Name()), Date: date})
	}
	sort.Slice(files, func(left, right int) bool { return files[left].Date < files[right].Date })
	return files
}

type datedLogFile struct {
	Path string
	Date string
}

func sourceOfPrefix(file datedLogFile) string {
	if strings.Contains(filepath.Base(file.Path), BackendLogPrefix) {
		return LogSourceBackend
	}
	return LogSourceTool
}

func splitLogLines(contents []byte) []string {
	text := strings.TrimRight(string(contents), "\n")
	if text == "" {
		return nil
	}
	return strings.Split(text, "\n")
}

// decodeLogLine masks secrets in the text before the operator sees it and
// derives the level (C3: a line without a level counts as info).
func decodeLogLine(source, text string) LogLine {
	line := LogLine{Text: MaskString(strings.TrimRight(text, "\r")), Level: "info"}
	if source == LogSourceTool {
		var entry struct {
			At      time.Time `json:"at"`
			Level   string    `json:"level"`
			Outcome string    `json:"outcome"`
		}
		if json.Unmarshal([]byte(text), &entry) == nil {
			if !entry.At.IsZero() {
				line.At = entry.At.UTC().Format(time.RFC3339Nano)
			}
			if entry.Level != "" {
				line.Level = entry.Level
			}
		}
		return line
	}
	upper := strings.ToUpper(text)
	switch {
	case strings.Contains(upper, "ERROR"), strings.Contains(upper, "FATAL"), strings.Contains(upper, "PANIC"):
		line.Level = "error"
	case strings.Contains(upper, "WARN"):
		line.Level = "warn"
	}
	line.At = leadingLogTime(text)
	return line
}

// leadingLogTime reads the two stock server log prefixes: Go's
// "2006/01/02 15:04:05" and PostgreSQL's "2006-01-02 15:04:05".
func leadingLogTime(text string) string {
	if len(text) < len("2006-01-02 15:04:05") {
		return ""
	}
	layouts := []string{"2006/01/02 15:04:05", "2006-01-02 15:04:05"}
	for _, layout := range layouts {
		if parsed, err := time.ParseInLocation(layout, text[:len(layout)], time.UTC); err == nil {
			return parsed.Format(time.RFC3339)
		}
	}
	return ""
}

func normalizeLogLevel(level string) (string, error) {
	switch level {
	case "", "info", "warn", "error":
		return level, nil
	default:
		return "", Refuse(CodeLogLevelInvalid, "level is one of info, warn or error")
	}
}

func normalizeLogLimit(limit int) int {
	if limit <= 0 {
		return DefaultLogTailLimit
	}
	if limit > MaxLogTailLimit {
		return MaxLogTailLimit
	}
	return limit
}

func parseLogDateRange(fromText, toText string) (string, string, error) {
	parse := func(name, text string) (string, error) {
		if text == "" {
			return "", nil
		}
		parsed, err := time.Parse(time.RFC3339, text)
		if err != nil {
			return "", Refuse(CodeLogQueryInvalid, name+" must be RFC3339")
		}
		return parsed.UTC().Format("2006-01-02"), nil
	}
	from, err := parse("from", fromText)
	if err != nil {
		return "", "", err
	}
	to, err := parse("to", toText)
	if err != nil {
		return "", "", err
	}
	return from, to, nil
}
