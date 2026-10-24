// Command gxb-sdk-harness stands in for the Xinyd login SDK server when the rebuilt stock APK runs on an emulator (I8.5-7, D68):
// every login the Java SDK asks for is a provision.Account session (one per guest device), answered in the envelope V1 proved
// against the same SDK.
// It is harness-side like provision (I85_HARNESS_BOUNDARY_V1 R3); product SDK ingress belongs to I11.
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"sync"

	"gxb.local/backend/v2/virtualclient/provision"
)

const (
	loginMID       = "65281"
	registerMID    = "65282"
	anonymousMID   = "65284"
	packageInfoMID = "65305"
	sessionCookie  = "QQWSID"
)

func main() {
	address := flag.String("listen", "0.0.0.0:18855", "listen address (the emulator reaches the host at 10.0.2.2)")
	database := flag.String("database", "", "backend database URL")
	flag.Parse()
	secret := os.Getenv("GXB_CREDENTIAL_DIGEST_SECRET")
	if *database == "" || secret == "" {
		fmt.Fprintln(os.Stderr, "gxb-sdk-harness: -database and GXB_CREDENTIAL_DIGEST_SECRET are required")
		os.Exit(2)
	}
	issue := func() (provision.Session, error) {
		return provision.Account(context.Background(), *database, []byte(secret))
	}
	log.Fatal(http.ListenAndServe(*address, newHandler(issue)))
}

type handler struct {
	issue    func() (provision.Session, error)
	mutex    sync.Mutex
	sessions map[string]provision.Session
	// shortcut: guests are remembered only while this process runs; persist them if restarts must keep a device's guest.
	devices map[string]provision.Session
}

func newHandler(issue func() (provision.Session, error)) http.Handler {
	sdk := &handler{issue: issue, sessions: map[string]provision.Session{}, devices: map[string]provision.Session{}}
	mux := http.NewServeMux()
	mux.HandleFunc("/server/mobile_api_new", sdk.serve)
	mux.HandleFunc("/server/mobile_api_new/", sdk.serve)
	mux.HandleFunc("/home_api/upload_sdk_logs", acknowledge)
	mux.HandleFunc("/home_api/upload_sdk_logs/", acknowledge)
	return mux
}

func acknowledge(writer http.ResponseWriter, _ *http.Request) {
	log.Print("sdk upload_sdk_logs")
	writeJSON(writer, map[string]any{"error_code": 0})
}

// requestBody reads the SDK call the way V1 did: a JSON body, else a form field "payload" holding the JSON.
func requestBody(request *http.Request) map[string]any {
	raw, err := io.ReadAll(io.LimitReader(request.Body, 1<<20))
	if err != nil {
		return nil
	}
	body := map[string]any{}
	if json.Unmarshal(raw, &body) == nil {
		return body
	}
	form, err := url.ParseQuery(string(raw))
	if err != nil {
		return nil
	}
	if json.Unmarshal([]byte(form.Get("payload")), &body) == nil {
		return body
	}
	return nil
}

func (sdk *handler) serve(writer http.ResponseWriter, request *http.Request) {
	body := requestBody(request)
	mid := fmt.Sprint(body["mid"])
	if body == nil {
		mid = "malformed"
	}
	log.Printf("sdk mid=%s", mid)
	switch mid {
	case loginMID, registerMID, loginMID + ".0", registerMID + ".0":
		sdk.login(writer, request, "")
	case anonymousMID, packageInfoMID, anonymousMID + ".0", packageInfoMID + ".0":
		sdk.login(writer, request, deviceID(body))
	default:
		writeJSON(writer, success(nil))
	}
}

func deviceID(body map[string]any) string {
	payload, _ := body["payload"].(map[string]any)
	device, _ := payload["device_id"].(string)
	return device
}

// login answers every login-producing MID with a session; package info keeps the session its cookie names, as V1 did at startup,
// and a guest device (non-empty device) gets its earlier guest back, as the Xinyd SDK does after an app restart.
func (sdk *handler) login(writer http.ResponseWriter, request *http.Request, device string) {
	sdk.mutex.Lock()
	defer sdk.mutex.Unlock()
	session, known := provision.Session{}, false
	if cookie, err := request.Cookie(sessionCookie); err == nil {
		session, known = sdk.sessions[cookie.Value]
	}
	if !known && device != "" {
		session, known = sdk.devices[device]
	}
	if !known {
		issued, err := sdk.issue()
		if err != nil {
			log.Printf("sdk session: %v", err)
			http.Error(writer, "session unavailable", http.StatusServiceUnavailable)
			return
		}
		session = issued
		sdk.sessions[session.SID] = session
		log.Printf("sdk session issued uid=%s", session.AccountID)
	}
	if device != "" {
		sdk.devices[device] = session
	}
	username := "guest-" + session.AccountID[:8]
	for name, value := range map[string]string{sessionCookie: session.SID, "QQWUID": session.AccountID, "QQWUNAME": username, "QQWTOKEN": session.LoginToken} {
		http.SetCookie(writer, &http.Cookie{Name: name, Value: value, Path: "/"})
	}
	writeJSON(writer, success(map[string]any{
		"uid": session.AccountID, "sid": session.SID, "access_token": session.LoginToken, "token": session.LoginToken,
		"username": username, "nickname": username, "is_new": 0,
		"UID": session.AccountID, "SID": session.SID, "UNAME": username, "TOKEN": session.LoginToken,
	}))
}

// success is V1's SDK success envelope: identity fields sit both at the top level and inside data.
func success(identity map[string]any) map[string]any {
	data := map[string]any{}
	body := map[string]any{"status": 1, "code": 1, "error_code": 0, "msg": "success", "data": data, "package_info": map[string]any{}}
	for key, value := range identity {
		body[key] = value
		data[key] = value
	}
	return body
}

func writeJSON(writer http.ResponseWriter, value any) {
	writer.Header().Set("Content-Type", "application/json; charset=utf-8")
	writer.Header().Set("Cache-Control", "no-cache, no-store")
	json.NewEncoder(writer).Encode(value)
}
