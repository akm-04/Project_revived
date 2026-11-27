package operatoragent

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"net"
	"os"
	"regexp"
	"strings"
	"sync"
	"time"
)

const (
	// DefaultTerminalIdleTimeout closes a terminal with no input and no stream
	// reader (G42).
	DefaultTerminalIdleTimeout = 15 * time.Minute
	// MaxTerminals bounds the shells one agent process may run.
	MaxTerminals = 3
	// DefaultTerminalShell is used when $SHELL is empty.
	DefaultTerminalShell = "/bin/bash"

	terminalBacklogBytes   = 64 << 10
	terminalChunkBytes     = 32 << 10
	terminalSubscriberSize = 256
)

var errTerminalUnsupported = errors.New("the terminal is not available on this platform yet")

// secretEnvironmentPattern removes the agent's credentials from the shell's
// environment: DSNs, password files, tokens, secrets and API/access keys.
var secretEnvironmentPattern = regexp.MustCompile(`(?i)(DSN|PASSWORD|PASSWD|PGPASSFILE|PGSERVICEFILE|SECRET|TOKEN|PRIVATE_KEY|ACCESS_KEY|API_KEY)`)

// shellProcess is one shell attached to a pseudo terminal.
type shellProcess interface {
	Read([]byte) (int, error)
	Write([]byte) (int, error)
	Resize(columns, rows uint16) error
	Pid() int
	Kill() error
	Wait() error
	Close() error
}

// TerminalOpen is the open reply: the id the page uses for the other routes,
// and the prompt identity the header shows.
type TerminalOpen struct {
	TerminalID string `json:"terminal_id"`
	User       string `json:"user"`
	Host       string `json:"host"`
	PID        int    `json:"pid"`
}

// TerminalService runs the operator's shells. One terminal belongs to one
// session token, at most MaxTerminals run at once, and the agent shutdown
// closes every one (G42).
type TerminalService struct {
	// ShellPath defaults to $SHELL, else /bin/bash.
	ShellPath string
	// WorkingDirectory defaults to the agent user's home.
	WorkingDirectory string
	// Environment defaults to the agent's environment without secrets.
	Environment []string
	// IdleTimeout defaults to DefaultTerminalIdleTimeout.
	IdleTimeout time.Duration
	// Now defaults to time.Now.
	Now func() time.Time
	// ToolLog records open and close, never input or output.
	ToolLog *ToolLog

	mutex     sync.Mutex
	terminals map[string]*terminal
	bySession map[string]string
	closed    bool
	sweeping  bool
	stopSweep chan struct{}
}

type terminal struct {
	id        string
	session   string
	process   shellProcess
	pid       int
	createdAt time.Time
	lastInput time.Time
	readers   int
	output    *terminalOutput
	closeOnce sync.Once
}

type terminalOutput struct {
	mutex      sync.Mutex
	subscriber *terminalSubscriber
	backlog    []byte
	exhausted  bool
}

type terminalSubscriber struct {
	chunks chan []byte
	done   chan struct{}
}

// TerminalAttachment is one live stream reader.
type TerminalAttachment struct {
	Chunks <-chan []byte

	service    *TerminalService
	item       *terminal
	subscriber *terminalSubscriber
	release    sync.Once
}

// Done closes when the terminal ends or another reader takes the stream.
func (attachment *TerminalAttachment) Done() <-chan struct{} {
	return attachment.subscriber.done
}

// Release unregisters the reader; it is safe to call twice.
func (attachment *TerminalAttachment) Release() {
	attachment.release.Do(func() {
		attachment.service.mutex.Lock()
		attachment.item.readers--
		attachment.service.mutex.Unlock()
		attachment.item.output.detach(attachment.subscriber)
	})
}

// NewTerminalService builds the service with the production defaults.
func NewTerminalService(toolLog *ToolLog, now func() time.Time) *TerminalService {
	return &TerminalService{ToolLog: toolLog, Now: now}
}

// ListenIsLoopback reports whether an agent listen address is a loopback one;
// the terminal is refused on any other configuration (G42).
func ListenIsLoopback(address string) bool {
	host, _, err := net.SplitHostPort(address)
	if err != nil {
		return false
	}
	ip := net.ParseIP(host)
	return ip != nil && ip.IsLoopback()
}

// Open starts one shell for the session. A session may hold one terminal.
func (service *TerminalService) Open(sessionToken, listenAddress string) (TerminalOpen, error) {
	if !ListenIsLoopback(listenAddress) {
		return TerminalOpen{}, Refuse(CodeTerminalDisabled, "the terminal is available only when the agent listens on a loopback address")
	}
	if sessionToken == "" {
		return TerminalOpen{}, Refuse(CodeUnauthorized, "an agent session is required")
	}
	shellPath := service.shellPath()
	environment := service.environment()
	workingDirectory := service.workingDirectory()

	service.mutex.Lock()
	defer service.mutex.Unlock()
	if service.closed {
		return TerminalOpen{}, Refuse(CodeTerminalDisabled, "the agent is shutting down")
	}
	if _, exists := service.bySession[sessionToken]; exists {
		return TerminalOpen{}, Refuse(CodeTerminalExists, "this session already has an open terminal; close it first")
	}
	if len(service.terminals) >= MaxTerminals {
		return TerminalOpen{}, Refuse(CodeTerminalLimit, "at most three terminals may be open at once")
	}
	process, err := openShellProcess(shellPath, workingDirectory, environment)
	if err != nil {
		if errors.Is(err, errTerminalUnsupported) {
			return TerminalOpen{}, Refuse(CodeTerminalUnsupported, terminalUnsupportedMessage)
		}
		return TerminalOpen{}, Refuse(CodeTerminalStartFailed, "the shell could not start")
	}
	id, err := NewToken()
	if err != nil {
		_ = process.Kill()
		_ = process.Close()
		return TerminalOpen{}, err
	}
	now := service.now()
	item := &terminal{
		id:        id,
		session:   sessionToken,
		process:   process,
		pid:       process.Pid(),
		createdAt: now,
		lastInput: now,
		output:    &terminalOutput{},
	}
	// The banner reaches the backlog before the pump copies the shell's prompt,
	// so the page always sees it first.
	item.output.push([]byte(TerminalBanner()))
	if service.terminals == nil {
		service.terminals = map[string]*terminal{}
	}
	if service.bySession == nil {
		service.bySession = map[string]string{}
	}
	service.terminals[id] = item
	service.bySession[sessionToken] = id
	service.startSweeper()
	go service.pump(item)
	go func() {
		_ = item.process.Wait()
		item.output.exhaust()
		service.finalize(item, "exited")
	}()
	service.log("open", item, nil)
	user, host := terminalIdentity()
	return TerminalOpen{TerminalID: id, User: user, Host: host, PID: item.pid}, nil
}

// WriteInput sends bytes to the terminal and marks it active.
func (service *TerminalService) WriteInput(sessionToken, id string, data []byte) error {
	item, err := service.owned(sessionToken, id)
	if err != nil {
		return err
	}
	if len(data) == 0 {
		return nil
	}
	service.mutex.Lock()
	item.lastInput = service.now()
	service.mutex.Unlock()
	if _, err := item.process.Write(data); err != nil {
		return Refuse(CodeTerminalUnknown, "the terminal has ended")
	}
	return nil
}

// Resize sets the terminal window size.
func (service *TerminalService) Resize(sessionToken, id string, columns, rows uint16) error {
	item, err := service.owned(sessionToken, id)
	if err != nil {
		return err
	}
	if err := item.process.Resize(columns, rows); err != nil {
		return Refuse(CodeTerminalUnknown, "the terminal has ended")
	}
	return nil
}

// Close ends the terminal and its process group. Closing an unknown terminal
// succeeds, so a page may retry (G42).
func (service *TerminalService) Close(sessionToken, id string) error {
	item, err := service.owned(sessionToken, id)
	if err != nil {
		var refusal *Refusal
		if errors.As(err, &refusal) && refusal.Code == CodeTerminalUnknown {
			return nil
		}
		return err
	}
	service.mutex.Lock()
	if service.terminals[item.id] == item {
		delete(service.terminals, item.id)
	}
	if service.bySession[item.session] == item.id {
		delete(service.bySession, item.session)
	}
	service.mutex.Unlock()
	service.finalize(item, "closed")
	return nil
}

// CloseSession ends every terminal the session owns, so a logout cannot leave
// an attached shell running.
func (service *TerminalService) CloseSession(sessionToken, reason string) {
	service.mutex.Lock()
	items := make([]*terminal, 0, 1)
	for _, item := range service.terminals {
		if item.session == sessionToken {
			items = append(items, item)
		}
	}
	service.mutex.Unlock()
	for _, item := range items {
		service.finalize(item, reason)
	}
}

// CloseAll ends every terminal; a password change or an offline reset revokes
// every session, so no shell may outlive them.
func (service *TerminalService) CloseAll(reason string) {
	service.mutex.Lock()
	items := make([]*terminal, 0, len(service.terminals))
	for _, item := range service.terminals {
		items = append(items, item)
	}
	service.mutex.Unlock()
	for _, item := range items {
		service.finalize(item, reason)
	}
}

// Attach registers a stream reader. The reader keeps the terminal alive even
// without input; only one reader is served at a time.
func (service *TerminalService) Attach(sessionToken, id string) (*TerminalAttachment, error) {
	item, err := service.owned(sessionToken, id)
	if err != nil {
		return nil, err
	}
	service.mutex.Lock()
	item.readers++
	service.mutex.Unlock()
	subscriber := item.output.attach()
	if subscriber == nil {
		service.mutex.Lock()
		item.readers--
		service.mutex.Unlock()
		return nil, Refuse(CodeTerminalUnknown, "the terminal has ended")
	}
	return &TerminalAttachment{Chunks: subscriber.chunks, service: service, item: item, subscriber: subscriber}, nil
}

// Shutdown closes every terminal; the agent calls it when it stops.
func (service *TerminalService) Shutdown() {
	service.mutex.Lock()
	if service.closed {
		service.mutex.Unlock()
		return
	}
	service.closed = true
	items := make([]*terminal, 0, len(service.terminals))
	for _, item := range service.terminals {
		items = append(items, item)
	}
	if service.stopSweep != nil {
		close(service.stopSweep)
		service.stopSweep = nil
	}
	service.mutex.Unlock()
	for _, item := range items {
		service.finalize(item, "shutdown")
	}
}

// ActiveCount is the number of open terminals.
func (service *TerminalService) ActiveCount() int {
	service.mutex.Lock()
	defer service.mutex.Unlock()
	return len(service.terminals)
}

func (service *TerminalService) owned(sessionToken, id string) (*terminal, error) {
	service.mutex.Lock()
	defer service.mutex.Unlock()
	item, found := service.terminals[id]
	if !found || item.session != sessionToken {
		return nil, Refuse(CodeTerminalUnknown, "no such terminal")
	}
	return item, nil
}

func (service *TerminalService) pump(item *terminal) {
	buffer := make([]byte, terminalChunkBytes)
	for {
		read, err := item.process.Read(buffer)
		if read > 0 {
			chunk := make([]byte, read)
			copy(chunk, buffer[:read])
			item.output.push(chunk)
		}
		if err != nil {
			return
		}
	}
}

func (service *TerminalService) finalize(item *terminal, reason string) {
	item.closeOnce.Do(func() {
		item.output.exhaust()
		_ = item.process.Kill()
		_ = item.process.Close()
		service.mutex.Lock()
		if service.terminals[item.id] == item {
			delete(service.terminals, item.id)
		}
		if service.bySession[item.session] == item.id {
			delete(service.bySession, item.session)
		}
		service.mutex.Unlock()
		service.log("close", item, map[string]any{"reason": reason})
	})
}

func (service *TerminalService) startSweeper() {
	if service.sweeping {
		return
	}
	service.sweeping = true
	service.stopSweep = make(chan struct{})
	stop := service.stopSweep
	go func() {
		ticker := time.NewTicker(service.sweepInterval())
		defer ticker.Stop()
		for {
			select {
			case <-stop:
				return
			case <-ticker.C:
				service.sweepIdle()
			}
		}
	}()
}

func (service *TerminalService) sweepIdle() {
	now := service.now()
	idle := service.idleTimeout()
	var expired []*terminal
	service.mutex.Lock()
	for _, item := range service.terminals {
		if item.readers == 0 && now.Sub(item.lastInput) >= idle {
			expired = append(expired, item)
		}
	}
	service.mutex.Unlock()
	for _, item := range expired {
		service.finalize(item, "idle")
	}
}

func (service *TerminalService) idleTimeout() time.Duration {
	if service.IdleTimeout <= 0 {
		return DefaultTerminalIdleTimeout
	}
	return service.IdleTimeout
}

func (service *TerminalService) sweepInterval() time.Duration {
	interval := service.idleTimeout() / 4
	if interval < 50*time.Millisecond {
		return 50 * time.Millisecond
	}
	if interval > 30*time.Second {
		return 30 * time.Second
	}
	return interval
}

func (service *TerminalService) now() time.Time {
	if service.Now == nil {
		return time.Now()
	}
	return service.Now()
}

func (service *TerminalService) shellPath() string {
	if service.ShellPath != "" {
		return service.ShellPath
	}
	if shell := os.Getenv("SHELL"); shell != "" {
		return shell
	}
	return DefaultTerminalShell
}

func (service *TerminalService) workingDirectory() string {
	if service.WorkingDirectory != "" {
		return service.WorkingDirectory
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "."
	}
	return home
}

func (service *TerminalService) environment() []string {
	if service.Environment != nil {
		return service.Environment
	}
	return TerminalEnvironment(os.Environ())
}

// TerminalBanner is the text a new shell receives before its prompt: the CLI
// hint and the same usage text the CLI prints.
func TerminalBanner() string {
	return CLIUsageBanner + "\r\n" + strings.ReplaceAll(CLIUsageText(), "\n", "\r\n")
}

// TerminalEnvironmentWithCLI makes the operator CLI reachable from the shell:
// the running binary's folder is first on PATH and GXB_OPERATOR_ROOT names the
// agent root, so `gxb-operator <command>` works with no --root.
func TerminalEnvironmentWithCLI(source []string, binaryDirectory, root string) []string {
	environment := TerminalEnvironment(source)
	result := make([]string, 0, len(environment)+2)
	pathValue := ""
	for _, entry := range environment {
		name, value, found := strings.Cut(entry, "=")
		if found && strings.EqualFold(name, "PATH") {
			pathValue = value
			continue
		}
		result = append(result, entry)
	}
	if binaryDirectory != "" {
		pathValue = binaryDirectory + string(os.PathListSeparator) + pathValue
	}
	if pathValue != "" {
		result = append(result, "PATH="+pathValue)
	}
	if root != "" {
		result = append(result, "GXB_OPERATOR_ROOT="+root)
	}
	return result
}

// TerminalEnvironment removes the secrets the agent can name and makes the
// terminal a colour one.
func TerminalEnvironment(source []string) []string {
	environment := make([]string, 0, len(source)+1)
	for _, entry := range source {
		name, _, found := strings.Cut(entry, "=")
		if !found || secretEnvironmentPattern.MatchString(name) {
			continue
		}
		if name == "TERM" {
			continue
		}
		environment = append(environment, entry)
	}
	return append(environment, "TERM=xterm-256color")
}

func (service *TerminalService) log(step string, item *terminal, extra map[string]any) {
	if service.ToolLog == nil {
		return
	}
	detail := map[string]any{
		"terminal_id": item.id,
		"session":     terminalSessionLabel(item.session),
		"pid":         item.pid,
	}
	for key, value := range extra {
		detail[key] = value
	}
	service.ToolLog.Write("terminal", step, "ok", detail)
}

func terminalSessionLabel(token string) string {
	digest := sha256.Sum256([]byte(token))
	return hex.EncodeToString(digest[:6])
}

func terminalIdentity() (string, string) {
	user := os.Getenv("USER")
	if user == "" {
		user = os.Getenv("LOGNAME")
	}
	if user == "" {
		user = "operator"
	}
	host, err := os.Hostname()
	if err != nil || host == "" {
		host = "agent"
	}
	return user, host
}

func (output *terminalOutput) push(chunk []byte) {
	output.mutex.Lock()
	subscriber := output.subscriber
	if subscriber == nil {
		output.backlog = append(output.backlog, chunk...)
		if len(output.backlog) > terminalBacklogBytes {
			output.backlog = output.backlog[len(output.backlog)-terminalBacklogBytes:]
		}
		output.mutex.Unlock()
		return
	}
	output.mutex.Unlock()
	select {
	case subscriber.chunks <- chunk:
	case <-subscriber.done:
	}
}

func (output *terminalOutput) attach() *terminalSubscriber {
	output.mutex.Lock()
	defer output.mutex.Unlock()
	if output.exhausted {
		return nil
	}
	subscriber := &terminalSubscriber{chunks: make(chan []byte, terminalSubscriberSize), done: make(chan struct{})}
	if len(output.backlog) > 0 {
		subscriber.chunks <- output.backlog
		output.backlog = nil
	}
	if output.subscriber != nil {
		close(output.subscriber.done)
	}
	output.subscriber = subscriber
	return subscriber
}

func (output *terminalOutput) detach(subscriber *terminalSubscriber) {
	output.mutex.Lock()
	if output.subscriber == subscriber {
		output.subscriber = nil
		close(subscriber.done)
	}
	output.mutex.Unlock()
}

func (output *terminalOutput) exhaust() {
	output.mutex.Lock()
	output.exhausted = true
	if output.subscriber != nil {
		close(output.subscriber.done)
		output.subscriber = nil
	}
	output.mutex.Unlock()
}
