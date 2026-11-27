package agentapi

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

func newTerminalHandler(t *testing.T) (Handler, string, *bytes.Buffer) {
	t.Helper()
	handler, _, session := newForwardingHandler(t)
	output := &bytes.Buffer{}
	toolLog := operatoragent.NewToolLog(output, time.Now)
	service := operatoragent.NewTerminalService(toolLog, time.Now)
	service.ShellPath = "/bin/cat"
	service.Environment = []string{"PATH=/usr/bin:/bin", "TERM=xterm-256color"}
	t.Cleanup(service.Shutdown)
	handler.Terminal = service
	handler.ToolLog = toolLog
	return handler, session, output
}

func openTerminal(t *testing.T, handler Handler, session string) operatoragent.TerminalOpen {
	t.Helper()
	recorder := serveAgent(handler, http.MethodPost, terminalOpenPath, session, `{"password":"test password"}`)
	if recorder.Code != http.StatusOK {
		t.Fatalf("open = %d %s", recorder.Code, recorder.Body)
	}
	var opened operatoragent.TerminalOpen
	if err := json.Unmarshal(recorder.Body.Bytes(), &opened); err != nil {
		t.Fatal(err)
	}
	if opened.TerminalID == "" {
		t.Fatal("open reply carried no terminal_id")
	}
	return opened
}

func TestTerminalOpenRequiresThePassword(t *testing.T) {
	handler, session, _ := newTerminalHandler(t)
	for _, body := range []string{`{}`, `{"password":""}`, `{"password":"wrong password"}`} {
		recorder := serveAgent(handler, http.MethodPost, terminalOpenPath, session, body)
		if recorder.Code != http.StatusConflict || refusalCodeOf(t, recorder) != operatoragent.CodeLoginRefused {
			t.Fatalf("%s: %d %s", body, recorder.Code, recorder.Body)
		}
	}
	if handler.Terminal.ActiveCount() != 0 {
		t.Fatalf("terminals = %d", handler.Terminal.ActiveCount())
	}
}

func TestTerminalOpenRefusesNonLoopbackListen(t *testing.T) {
	handler, session, _ := newTerminalHandler(t)
	handler.Listen = "0.0.0.0:8090"
	recorder := serveAgent(handler, http.MethodPost, terminalOpenPath, session, `{"password":"test password"}`)
	if recorder.Code != http.StatusConflict || refusalCodeOf(t, recorder) != operatoragent.CodeTerminalDisabled {
		t.Fatalf("non-loopback open = %d %s", recorder.Code, recorder.Body)
	}
}

func TestTerminalInputResizeAndIdempotentClose(t *testing.T) {
	handler, session, output := newTerminalHandler(t)
	opened := openTerminal(t, handler, session)
	terminalPath := terminalPrefix + opened.TerminalID

	hello := base64.StdEncoding.EncodeToString([]byte("hello\n"))
	recorder := serveAgent(handler, http.MethodPost, terminalPath+"/input", session, `{"data":"`+hello+`"}`)
	if recorder.Code != http.StatusOK {
		t.Fatalf("input = %d %s", recorder.Code, recorder.Body)
	}
	recorder = serveAgent(handler, http.MethodPost, terminalPath+"/resize", session, `{"cols":100,"rows":40}`)
	if recorder.Code != http.StatusOK {
		t.Fatalf("resize = %d %s", recorder.Code, recorder.Body)
	}
	for attempt := 0; attempt < 2; attempt++ {
		recorder = serveAgent(handler, http.MethodPost, terminalPath+"/close", session, `{}`)
		if recorder.Code != http.StatusOK {
			t.Fatalf("close %d = %d %s", attempt, recorder.Code, recorder.Body)
		}
	}
	if handler.Terminal.ActiveCount() != 0 {
		t.Fatalf("terminals after close = %d", handler.Terminal.ActiveCount())
	}

	log := output.String()
	for _, secret := range []string{"test password", hello} {
		if strings.Contains(log, secret) {
			t.Fatalf("the tool log leaked %q:\n%s", secret, log)
		}
	}
	for _, expected := range []string{`"op":"terminal"`, `"step":"open"`, `"step":"close"`, `"pid":`} {
		if !strings.Contains(log, expected) {
			t.Fatalf("the tool log lost %s:\n%s", expected, log)
		}
	}
}

func TestTerminalRouteNeedsASession(t *testing.T) {
	handler, session, _ := newTerminalHandler(t)
	opened := openTerminal(t, handler, session)
	terminalPath := terminalPrefix + opened.TerminalID
	if recorder := serveAgent(handler, http.MethodPost, terminalOpenPath, "", `{"password":"test password"}`); recorder.Code != http.StatusUnauthorized {
		t.Fatalf("open without a session = %d", recorder.Code)
	}
	if recorder := serveAgent(handler, http.MethodPost, terminalPath+"/input", "", `{"data":"aGk="}`); recorder.Code != http.StatusUnauthorized {
		t.Fatalf("input without a session = %d", recorder.Code)
	}
	if err := handler.Terminal.Close(session, opened.TerminalID); err != nil {
		t.Fatal(err)
	}
}

func startTerminalStream(t *testing.T, handler Handler, session, id string) <-chan struct{} {
	t.Helper()
	request := httptest.NewRequest(http.MethodGet, terminalPrefix+id+"/stream", nil)
	request.Host = handler.Listen
	request.RemoteAddr = "127.0.0.1:5000"
	request.Header.Set("Authorization", "Bearer "+session)
	recorder := httptest.NewRecorder()
	done := make(chan struct{})
	go func() {
		handler.serveTerminalStream(recorder, request, id)
		close(done)
	}()
	return done
}

func waitForTerminal(t *testing.T, condition func() bool) bool {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		if condition() {
			return true
		}
		time.Sleep(10 * time.Millisecond)
	}
	return condition()
}

func shortenTerminalHeartbeat(t *testing.T) {
	t.Helper()
	previous := terminalHeartbeat
	terminalHeartbeat = 20 * time.Millisecond
	t.Cleanup(func() { terminalHeartbeat = previous })
}

func TestTerminalStreamEndsWhenItsSessionIsRevoked(t *testing.T) {
	handler, session, _ := newTerminalHandler(t)
	opened := openTerminal(t, handler, session)
	shortenTerminalHeartbeat(t)
	done := startTerminalStream(t, handler, session, opened.TerminalID)
	if !waitForTerminal(t, func() bool { return handler.Terminal.ActiveCount() == 1 }) {
		t.Fatal("the terminal was not opened")
	}
	handler.Sessions.Logout(session)
	if !waitForTerminal(t, func() bool { return handler.Terminal.ActiveCount() == 0 }) {
		t.Fatal("the terminal outlived its session")
	}
	select {
	case <-done:
	case <-time.After(5 * time.Second):
		t.Fatal("the stream did not end")
	}
}

func TestTerminalStreamEndsAfterAnOfflineReset(t *testing.T) {
	handler, session, _ := newTerminalHandler(t)
	opened := openTerminal(t, handler, session)
	shortenTerminalHeartbeat(t)
	done := startTerminalStream(t, handler, session, opened.TerminalID)
	if err := handler.Credentials.ResetPassword("offline-reset-password"); err != nil {
		t.Fatal(err)
	}
	if !waitForTerminal(t, func() bool { return handler.Terminal.ActiveCount() == 0 }) {
		t.Fatal("the terminal outlived an offline reset")
	}
	select {
	case <-done:
	case <-time.After(5 * time.Second):
		t.Fatal("the stream did not end")
	}
}

func TestLogoutClosesTheCallersTerminals(t *testing.T) {
	handler, session, _ := newTerminalHandler(t)
	opened := openTerminal(t, handler, session)
	recorder := serveAgent(handler, http.MethodPost, logoutPath, session, `{}`)
	if recorder.Code != http.StatusOK {
		t.Fatalf("logout = %d %s", recorder.Code, recorder.Body)
	}
	if handler.Terminal.ActiveCount() != 0 {
		t.Fatalf("terminals after logout = %d", handler.Terminal.ActiveCount())
	}
	if _, err := handler.Terminal.Attach(session, opened.TerminalID); err == nil {
		t.Fatal("the terminal survived logout")
	}
}

func TestPasswordChangeClosesEveryTerminal(t *testing.T) {
	handler, session, _ := newTerminalHandler(t)
	openTerminal(t, handler, session)
	if _, err := handler.Terminal.Open("another-session", testListen); err != nil {
		t.Fatal(err)
	}
	recorder := serveAgent(handler, http.MethodPost, passwordPath, session, `{"current":"test password","new":"replacement password"}`)
	if recorder.Code != http.StatusOK {
		t.Fatalf("password change = %d %s", recorder.Code, recorder.Body)
	}
	if handler.Terminal.ActiveCount() != 0 {
		t.Fatalf("terminals after the password change = %d", handler.Terminal.ActiveCount())
	}
}
