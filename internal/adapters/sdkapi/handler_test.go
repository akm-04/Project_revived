package sdkapi

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
)

type fakeService struct {
	registerResult  appidentity.SDKRegisterResult
	registerError   error
	loginIdentity   appidentity.SDKIdentity
	loginError      error
	anonymousResult appidentity.SDKIdentity
	anonymousError  error

	registerCalls  []appidentity.SDKRegisterRequest
	loginCalls     []appidentity.SDKLoginRequest
	anonymousCalls []appidentity.SDKAnonymousRequest
}

func (service *fakeService) Register(_ context.Context, request appidentity.SDKRegisterRequest) (appidentity.SDKRegisterResult, error) {
	service.registerCalls = append(service.registerCalls, request)
	return service.registerResult, service.registerError
}

func (service *fakeService) Login(_ context.Context, request appidentity.SDKLoginRequest) (appidentity.SDKIdentity, error) {
	service.loginCalls = append(service.loginCalls, request)
	return service.loginIdentity, service.loginError
}

func (service *fakeService) Anonymous(_ context.Context, request appidentity.SDKAnonymousRequest) (appidentity.SDKIdentity, error) {
	service.anonymousCalls = append(service.anonymousCalls, request)
	return service.anonymousResult, service.anonymousError
}

func serve(t *testing.T, service Service, method, path, body string, cookies map[string]string) *httptest.ResponseRecorder {
	t.Helper()
	request := httptest.NewRequest(method, path, strings.NewReader(body))
	for name, value := range cookies {
		request.AddCookie(&http.Cookie{Name: name, Value: value})
	}
	recorder := httptest.NewRecorder()
	Handler{Service: service}.ServeHTTP(recorder, request)
	return recorder
}

func decode(t *testing.T, recorder *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	var body map[string]any
	if err := json.Unmarshal(recorder.Body.Bytes(), &body); err != nil {
		t.Fatalf("body %q: %v", recorder.Body.String(), err)
	}
	return body
}

func data(t *testing.T, body map[string]any) map[string]any {
	t.Helper()
	value, ok := body["data"].(map[string]any)
	if !ok {
		t.Fatalf("data is not an object: %v", body)
	}
	return value
}

func cookieValue(t *testing.T, recorder *httptest.ResponseRecorder, name string) string {
	t.Helper()
	for _, cookie := range recorder.Result().Cookies() {
		if cookie.Name == name {
			if cookie.Path != "/" {
				t.Fatalf("cookie %s path = %q", name, cookie.Path)
			}
			return cookie.Value
		}
	}
	return ""
}

func TestRegisterRepliesWithTheIdentityInDataAndAtTheTopLevel(t *testing.T) {
	service := &fakeService{registerResult: appidentity.SDKRegisterResult{UID: "account-1", LoginEmail: "player@example.com"}}
	recorder := serve(t, service, http.MethodPost, "/server/mobile_api_new",
		`{"mid":"65282","payload":{"login_email":"player@example.com","password":"pw","repassword":"pw"}}`, nil)
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d", recorder.Code)
	}
	if got := recorder.Header().Get("Cache-Control"); got != "no-cache, no-store" {
		t.Fatalf("cache-control = %q", got)
	}
	body := decode(t, recorder)
	if body["status"] != float64(1) || body["code"] != float64(1) || body["error_code"] != float64(0) || body["msg"] != "success" {
		t.Fatalf("envelope = %v", body)
	}
	if body["uid"] != "account-1" || body["login_email"] != "player@example.com" {
		t.Fatalf("top-level identity = %v", body)
	}
	payload := data(t, body)
	if payload["uid"] != "account-1" || payload["login_email"] != "player@example.com" {
		t.Fatalf("data identity = %v", payload)
	}
	if len(recorder.Result().Cookies()) != 0 {
		t.Fatalf("register set cookies: %v", recorder.Result().Cookies())
	}
	if len(service.registerCalls) != 1 || service.registerCalls[0].Login != "player@example.com" || service.registerCalls[0].Password != "pw" || service.registerCalls[0].Repassword != "pw" {
		t.Fatalf("register calls = %+v", service.registerCalls)
	}
}

func TestFormBodyCarriesTheWholeObjectInThePayloadField(t *testing.T) {
	service := &fakeService{registerResult: appidentity.SDKRegisterResult{UID: "account-1", LoginEmail: "form@example.com"}}
	form := url.Values{"payload": []string{`{"mid":"65282.0","payload":{"login_email":"form@example.com","password":"pw","repassword":"pw"}}`}}
	recorder := serve(t, service, http.MethodPost, "/server/mobile_api_new", form.Encode(), nil)
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d", recorder.Code)
	}
	if len(service.registerCalls) != 1 || service.registerCalls[0].Login != "form@example.com" {
		t.Fatalf("form register calls = %+v", service.registerCalls)
	}
}

func TestLoginRepliesWithEveryIdentityFieldAndCookies(t *testing.T) {
	service := &fakeService{loginIdentity: appidentity.SDKIdentity{UID: "account-1", SID: "sid-1", Token: "token-1", Username: "player", LoginEmail: "player@example.com"}}
	recorder := serve(t, service, http.MethodPost, "/server/mobile_api_new",
		`{"mid":"65281.0","payload":{"login_email":"player@example.com","password":"pw"}}`, nil)
	body := decode(t, recorder)
	want := map[string]any{
		"uid": "account-1", "sid": "sid-1", "access_token": "token-1", "token": "token-1",
		"username": "player", "nickname": "player", "is_new": float64(0),
		"UID": "account-1", "SID": "sid-1", "UNAME": "player", "TOKEN": "token-1",
		"login_email": "player@example.com",
	}
	for key, value := range want {
		if body[key] != value {
			t.Fatalf("top-level %s = %v, want %v", key, body[key], value)
		}
		if data(t, body)[key] != value {
			t.Fatalf("data %s = %v, want %v", key, data(t, body)[key], value)
		}
	}
	for name, value := range map[string]string{"QQWSID": "sid-1", "QQWUID": "account-1", "QQWUNAME": "player", "QQWTOKEN": "token-1"} {
		if got := cookieValue(t, recorder, name); got != value {
			t.Fatalf("cookie %s = %q, want %q", name, got, value)
		}
	}
	if len(service.loginCalls) != 1 || service.loginCalls[0].Login != "player@example.com" || service.loginCalls[0].Password != "pw" {
		t.Fatalf("login calls = %+v", service.loginCalls)
	}
}

func TestLoginRefusalsUseTheOneEnvelope(t *testing.T) {
	for name, testCase := range map[string]struct {
		err     error
		message string
	}{
		"invalid account": {appidentity.ErrSDKInvalidAccount, "Invalid account or password"},
		"account exists":  {appidentity.ErrSDKAccountExists, "Account already exists"},
		"invalid request": {appidentity.ErrSDKInvalidRegistration, "Invalid registration request"},
	} {
		t.Run(name, func(t *testing.T) {
			service := &fakeService{loginError: testCase.err}
			recorder := serve(t, service, http.MethodPost, "/server/mobile_api_new",
				`{"mid":"65281","payload":{"login_email":"a@b","password":"pw"}}`, nil)
			if recorder.Code != http.StatusOK {
				t.Fatalf("status = %d", recorder.Code)
			}
			body := decode(t, recorder)
			if body["status"] != float64(0) || body["code"] != float64(0) || body["error_code"] != float64(1) || body["error_msg"] != testCase.message || body["msg"] != testCase.message {
				t.Fatalf("envelope = %v", body)
			}
			if len(data(t, body)) != 0 {
				t.Fatalf("data = %v", data(t, body))
			}
			if len(recorder.Result().Cookies()) != 0 {
				t.Fatal("a refused login set cookies")
			}
		})
	}
}

func TestAnonymousReadsTheCookieAndDevice(t *testing.T) {
	service := &fakeService{anonymousResult: appidentity.SDKIdentity{UID: "account-1", SID: "sid-2", Token: "token-2", Username: "guest-account1"}}
	recorder := serve(t, service, http.MethodPost, "/server/mobile_api_new",
		`{"mid":"65284","payload":{"device_id":"device-1","device_type":"android","os_version":"14","sdk_version":"1.2.3"}}`,
		map[string]string{"QQWSID": "presented-sid"})
	body := decode(t, recorder)
	if body["uid"] != "account-1" || body["sid"] != "sid-2" || body["username"] != "guest-account1" {
		t.Fatalf("identity = %v", body)
	}
	if _, present := body["login_email"]; present {
		t.Fatalf("anonymous carried login_email: %v", body)
	}
	if len(service.anonymousCalls) != 1 || service.anonymousCalls[0].CookieSID != "presented-sid" || service.anonymousCalls[0].DeviceID != "device-1" {
		t.Fatalf("anonymous calls = %+v", service.anonymousCalls)
	}
	if cookieValue(t, recorder, "QQWSID") != "sid-2" {
		t.Fatal("the new session cookie was not set")
	}
}

func TestPackageInfoIsAnsweredLikeAnonymous(t *testing.T) {
	service := &fakeService{anonymousResult: appidentity.SDKIdentity{UID: "account-1", SID: "sid-3", Token: "token-3", Username: "guest-account1"}}
	serve(t, service, http.MethodPost, "/server/mobile_api_new",
		`{"mid":"65305","payload":{"device_id":"device-9"}}`, nil)
	if len(service.anonymousCalls) != 1 || service.anonymousCalls[0].DeviceID != "device-9" {
		t.Fatalf("package info calls = %+v", service.anonymousCalls)
	}
}

func TestUnknownMidAndMalformedBodyReturnAnEmptySuccess(t *testing.T) {
	for name, body := range map[string]string{
		"unknown mid":    `{"mid":"12345","payload":{"x":1}}`,
		"malformed":      `not json`,
		"empty":          ``,
		"null body":      `null`,
		"numeric mid":    `{"mid":99999}`,
		"truncated json": `{"mid":"65281","payload":{`,
	} {
		t.Run(name, func(t *testing.T) {
			service := &fakeService{}
			recorder := serve(t, service, http.MethodPost, "/server/mobile_api_new", body, nil)
			if recorder.Code != http.StatusOK {
				t.Fatalf("status = %d", recorder.Code)
			}
			reply := decode(t, recorder)
			if reply["status"] != float64(1) || reply["msg"] != "success" || len(data(t, reply)) != 0 {
				t.Fatalf("reply = %v", reply)
			}
			if len(service.registerCalls)+len(service.loginCalls)+len(service.anonymousCalls) != 0 {
				t.Fatal("a malformed or unknown request reached the service")
			}
		})
	}
}

func TestUploadSDKLogsAndUnknownPaths(t *testing.T) {
	service := &fakeService{}
	upload := serve(t, service, http.MethodPost, "/home_api/upload_sdk_logs", "body", nil)
	if upload.Code != http.StatusOK || !strings.Contains(upload.Body.String(), `"error_code":0`) {
		t.Fatalf("upload reply = %d %s", upload.Code, upload.Body.String())
	}
	stockPath := serve(t, service, http.MethodPost, "/server/mobile_api_new/", `{"mid":"65305","payload":{}}`, nil)
	if stockPath.Code != http.StatusOK {
		t.Fatalf("stock client trailing-slash path = %d", stockPath.Code)
	}
	missing := serve(t, service, http.MethodPost, "/somewhere/else", "", nil)
	if missing.Code != http.StatusNotFound || missing.Body.Len() != 0 {
		t.Fatalf("unknown path = %d %q", missing.Code, missing.Body.String())
	}
}

func TestSessionUnavailableIsThe503Text(t *testing.T) {
	service := &fakeService{loginError: errors.New("database is down")}
	recorder := serve(t, service, http.MethodPost, "/server/mobile_api_new",
		`{"mid":"65281","payload":{"login_email":"a@b","password":"pw"}}`, nil)
	if recorder.Code != http.StatusServiceUnavailable || recorder.Body.String() != "session unavailable\n" {
		t.Fatalf("unavailable = %d %q", recorder.Code, recorder.Body.String())
	}
	if got := recorder.Header().Get("Cache-Control"); got != "no-cache, no-store" {
		t.Fatalf("cache-control = %q", got)
	}
}

func TestBodyIsCappedAt64KiB(t *testing.T) {
	service := &fakeService{loginIdentity: appidentity.SDKIdentity{UID: "account-1", SID: "sid", Token: "token", Username: "player"}}
	body := `{"mid":"65281","payload":{"login_email":"` + strings.Repeat("a", 70000) + `","password":"pw"}}`
	recorder := serve(t, service, http.MethodPost, "/server/mobile_api_new", body, nil)
	if recorder.Code != http.StatusOK || len(data(t, decode(t, recorder))) != 0 {
		t.Fatalf("oversized body = %d", recorder.Code)
	}
	if len(service.loginCalls) != 0 {
		t.Fatal("the oversized body reached the service")
	}
}

func TestTelemetryLogsTheAllowListedFieldsOnly(t *testing.T) {
	var captured bytes.Buffer
	previous := log.Writer()
	log.SetOutput(&captured)
	t.Cleanup(func() { log.SetOutput(previous) })
	service := &fakeService{loginIdentity: appidentity.SDKIdentity{UID: "account-1", SID: "sid-secret", Token: "token-secret", Username: "player"}}
	request := httptest.NewRequest(http.MethodPost, "/server/mobile_api_new",
		strings.NewReader(`{"mid":"65281","payload":{"login_email":"player@example.com","password":"secret-password","uid":"request-uid","device_id":"device-1","device_type":"android","os_version":"14","sdk_version":"1.2.3"}}`))
	request.Header.Set("User-Agent", "SDK-Agent/1.0")
	request.Header.Set("X-Forwarded-For", "203.0.113.7")
	recorder := httptest.NewRecorder()
	Handler{Service: service}.ServeHTTP(recorder, request)
	line := captured.String()
	for _, expected := range []string{"mid=65281", "SDK-Agent/1.0", "203.0.113.7", "player@example.com", "device-1", "android", "14", "1.2.3", "request-uid"} {
		if !strings.Contains(line, expected) {
			t.Fatalf("log line %q lacks %q", line, expected)
		}
	}
	for _, forbidden := range []string{"secret-password", "sid-secret", "token-secret"} {
		if strings.Contains(line, forbidden) {
			t.Fatalf("log line %q carries %q", line, forbidden)
		}
	}
}
