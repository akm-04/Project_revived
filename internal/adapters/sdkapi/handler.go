// Package sdkapi is the product SDK login ingress (G51F F1/F3): the HTTP
// envelope the stock client's login SDK speaks, over the identity lifecycle
// application service. It is not the stock MID edge.
package sdkapi

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strings"

	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
)

const (
	registerMID     = "65282"
	loginMID        = "65281"
	anonymousMID    = "65284"
	packageInfoMID  = "65305"
	sessionCookie   = "QQWSID"
	maximumBodySize = 64 << 10
)

// Service is the SDK application port.
type Service interface {
	Register(context.Context, appidentity.SDKRegisterRequest) (appidentity.SDKRegisterResult, error)
	Login(context.Context, appidentity.SDKLoginRequest) (appidentity.SDKIdentity, error)
	Anonymous(context.Context, appidentity.SDKAnonymousRequest) (appidentity.SDKIdentity, error)
}

type Handler struct {
	Service Service
}

func (handler Handler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	// The stock client posts to "server/mobile_api_new/" with a trailing slash.
	switch strings.TrimRight(request.URL.Path, "/") {
	case "/server/mobile_api_new":
		handler.serve(writer, request)
	case "/home_api/upload_sdk_logs":
		writer.Header().Set("Cache-Control", "no-cache, no-store")
		writeJSON(writer, map[string]any{"error_code": 0})
	default:
		writer.WriteHeader(http.StatusNotFound)
	}
}

func (handler Handler) serve(writer http.ResponseWriter, request *http.Request) {
	body, ok := requestBody(request)
	mid := "malformed"
	payload := map[string]any{}
	if ok {
		mid = fmt.Sprint(body["mid"])
		payload, _ = body["payload"].(map[string]any)
	}
	logRequest(mid, request, payload)
	if !ok {
		writeSuccess(writer, nil)
		return
	}
	switch strings.TrimSuffix(mid, ".0") {
	case registerMID:
		handler.register(writer, request, payload)
	case loginMID:
		handler.login(writer, request, payload)
	case anonymousMID, packageInfoMID:
		handler.anonymous(writer, request, payload)
	default:
		writeSuccess(writer, nil)
	}
}

func (handler Handler) register(writer http.ResponseWriter, request *http.Request, payload map[string]any) {
	if handler.Service == nil {
		writeUnavailable(writer, errors.New("sdk service not composed"))
		return
	}
	result, err := handler.Service.Register(request.Context(), appidentity.SDKRegisterRequest{
		Login:      stringField(payload, "login_email"),
		Password:   stringField(payload, "password"),
		Repassword: stringField(payload, "repassword"),
	})
	if err != nil {
		handler.failure(writer, err)
		return
	}
	writeSuccess(writer, map[string]any{"uid": result.UID, "login_email": result.LoginEmail})
}

func (handler Handler) login(writer http.ResponseWriter, request *http.Request, payload map[string]any) {
	if handler.Service == nil {
		writeUnavailable(writer, errors.New("sdk service not composed"))
		return
	}
	identity, err := handler.Service.Login(request.Context(), appidentity.SDKLoginRequest{
		Login:    stringField(payload, "login_email"),
		Password: stringField(payload, "password"),
	})
	if err != nil {
		handler.failure(writer, err)
		return
	}
	writeIdentity(writer, identity, true)
}

func (handler Handler) anonymous(writer http.ResponseWriter, request *http.Request, payload map[string]any) {
	if handler.Service == nil {
		writeUnavailable(writer, errors.New("sdk service not composed"))
		return
	}
	cookie := ""
	if presented, err := request.Cookie(sessionCookie); err == nil {
		cookie = presented.Value
	}
	identity, err := handler.Service.Anonymous(request.Context(), appidentity.SDKAnonymousRequest{
		CookieSID: cookie,
		DeviceID:  stringField(payload, "device_id"),
	})
	if err != nil {
		handler.failure(writer, err)
		return
	}
	writeIdentity(writer, identity, false)
}

func (handler Handler) failure(writer http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, appidentity.ErrSDKInvalidRegistration):
		writeFailure(writer, "Invalid registration request")
	case errors.Is(err, appidentity.ErrSDKAccountExists):
		writeFailure(writer, "Account already exists")
	case errors.Is(err, appidentity.ErrSDKInvalidAccount):
		writeFailure(writer, "Invalid account or password")
	default:
		writeUnavailable(writer, err)
	}
}

// requestBody reads the JSON body, else the form field "payload" that holds
// the same JSON object; anything else is malformed.
func requestBody(request *http.Request) (map[string]any, bool) {
	raw, err := io.ReadAll(io.LimitReader(request.Body, maximumBodySize))
	if err != nil {
		return nil, false
	}
	var body map[string]any
	if json.Unmarshal(raw, &body) == nil && body != nil {
		return body, true
	}
	form, err := url.ParseQuery(string(raw))
	if err != nil {
		return nil, false
	}
	if json.Unmarshal([]byte(form.Get("payload")), &body) == nil && body != nil {
		return body, true
	}
	return nil, false
}

var identityCookieNames = []struct{ name, key string }{
	{sessionCookie, "sid"},
	{"QQWUID", "uid"},
	{"QQWUNAME", "username"},
	{"QQWTOKEN", "token"},
}

func writeIdentity(writer http.ResponseWriter, identity appidentity.SDKIdentity, loginEmail bool) {
	fields := map[string]any{
		"uid": identity.UID, "sid": identity.SID, "access_token": identity.Token, "token": identity.Token,
		"username": identity.Username, "nickname": identity.Username, "is_new": 0,
		"UID": identity.UID, "SID": identity.SID, "UNAME": identity.Username, "TOKEN": identity.Token,
	}
	if loginEmail && identity.LoginEmail != "" {
		fields["login_email"] = identity.LoginEmail
	}
	values := map[string]string{"sid": identity.SID, "uid": identity.UID, "username": identity.Username, "token": identity.Token}
	for _, cookie := range identityCookieNames {
		http.SetCookie(writer, &http.Cookie{Name: cookie.name, Value: values[cookie.key], Path: "/"})
	}
	writeSuccess(writer, fields)
}

func writeSuccess(writer http.ResponseWriter, identity map[string]any) {
	data := map[string]any{}
	body := map[string]any{"status": 1, "code": 1, "error_code": 0, "msg": "success", "data": data, "package_info": map[string]any{}}
	for key, value := range identity {
		body[key] = value
		data[key] = value
	}
	writeJSON(writer, body)
}

func writeFailure(writer http.ResponseWriter, message string) {
	writeJSON(writer, map[string]any{
		"status": 0, "code": 0, "error_code": 1, "error_msg": message, "msg": message,
		"data": map[string]any{}, "package_info": map[string]any{},
	})
}

func writeUnavailable(writer http.ResponseWriter, err error) {
	log.Printf("sdk session unavailable: %v", err)
	writer.Header().Set("Cache-Control", "no-cache, no-store")
	http.Error(writer, "session unavailable", http.StatusServiceUnavailable)
}

func writeJSON(writer http.ResponseWriter, value any) {
	writer.Header().Set("Content-Type", "application/json; charset=utf-8")
	writer.Header().Set("Cache-Control", "no-cache, no-store")
	if err := json.NewEncoder(writer).Encode(value); err != nil {
		log.Printf("sdk reply encode: %v", err)
	}
}

func stringField(payload map[string]any, key string) string {
	value, _ := payload[key].(string)
	return value
}

// logRequest is the SDK telemetry event: mid, user agent and proxy address plus
// the allow-listed identity fields. Passwords, cookies and tokens never enter it.
func logRequest(mid string, request *http.Request, payload map[string]any) {
	fields := []string{"sdk", "mid=" + mid}
	add := func(name, value string) {
		if value != "" {
			fields = append(fields, name+"="+fmt.Sprintf("%q", value))
		}
	}
	add("user_agent", request.UserAgent())
	add("x_forwarded_for", request.Header.Get("X-Forwarded-For"))
	add("login_email", stringField(payload, "login_email"))
	add("uid", stringField(payload, "uid"))
	add("device_id", stringField(payload, "device_id"))
	add("device_type", stringField(payload, "device_type"))
	add("os_version", stringField(payload, "os_version"))
	add("sdk_version", stringField(payload, "sdk_version"))
	log.Print(strings.Join(fields, " "))
}
