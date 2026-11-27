package operatorapi

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	appota "gxb.local/backend/v2/internal/application/otarelease"
)

func get(t *testing.T, handler Handler, token, path string) *httptest.ResponseRecorder {
	t.Helper()
	request := httptest.NewRequest(http.MethodGet, path, nil)
	request.RemoteAddr = "127.0.0.1:5000"
	if token != "" {
		request.Header.Set("Authorization", "Bearer "+token)
	}
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	return recorder
}

func TestReadRoutesRequireTheOfficeToken(t *testing.T) {
	handler := Handler{Token: "secret", Reads: map[string]Read{"ota.status": OTAStatus(fakeStatusService{})}}
	if recorder := get(t, handler, "", "/operator/v1/reads/ota.status"); recorder.Code != http.StatusUnauthorized {
		t.Fatalf("unauthorized read: %d", recorder.Code)
	}
	if recorder := get(t, handler, "secret", "/operator/v1/reads/ota.status"); recorder.Code != http.StatusOK {
		t.Fatalf("authorized read: %d %s", recorder.Code, recorder.Body)
	}
}

func TestUnknownReadIsNotFound(t *testing.T) {
	handler := Handler{Token: "secret", Reads: map[string]Read{"ota.status": OTAStatus(fakeStatusService{})}}
	recorder := get(t, handler, "secret", "/operator/v1/reads/ota.nothing")
	if recorder.Code != http.StatusNotFound || errorCode(t, recorder) != codeUnknownRead {
		t.Fatalf("unknown read: %d %s", recorder.Code, recorder.Body)
	}
}

func TestReadOfAnotherMethodIsNotFound(t *testing.T) {
	handler := Handler{Token: "secret", Reads: map[string]Read{"ota.status": OTAStatus(fakeStatusService{})}}
	request := httptest.NewRequest(http.MethodPost, "/operator/v1/reads/ota.status", nil)
	request.RemoteAddr = "127.0.0.1:5000"
	request.Header.Set("Authorization", "Bearer secret")
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusNotFound {
		t.Fatalf("POST read: %d", recorder.Code)
	}
}

func TestVersionRouteUsesTheInjectedFunction(t *testing.T) {
	handler := Handler{Token: "secret", Version: func(context.Context) (any, error) {
		return operator.VersionInfo{Migration: 184, OperatorAPIRevision: "1"}, nil
	}}
	if recorder := get(t, handler, "", "/operator/v1/version"); recorder.Code != http.StatusUnauthorized {
		t.Fatalf("unauthorized version: %d", recorder.Code)
	}
	recorder := get(t, handler, "secret", "/operator/v1/version")
	if recorder.Code != http.StatusOK {
		t.Fatalf("version: %d %s", recorder.Code, recorder.Body)
	}
	var info operator.VersionInfo
	if err := json.Unmarshal(recorder.Body.Bytes(), &info); err != nil || info.Migration != 184 || info.OperatorAPIRevision != "1" {
		t.Fatalf("version body=%s err=%v", recorder.Body, err)
	}
}

type fakeStatusService struct{}

func (fakeStatusService) Status(context.Context) (appota.Status, error) {
	code := "1.631.2"
	return appota.Status{Revision: 3, Active: appota.ActiveStatus{Code: &code}}, nil
}

type fakeAuditService struct{ filter operator.AuditFilter }

func (service *fakeAuditService) List(_ context.Context, filter operator.AuditFilter) (operator.AuditPage, error) {
	service.filter = filter
	return operator.AuditPage{Commands: []operator.Record{}}, nil
}

func TestAuditReadParsesTheBoundedQuery(t *testing.T) {
	service := &fakeAuditService{}
	handler := Handler{Token: "secret", Reads: map[string]Read{"operator.audit.list": AuditList(service)}}
	recorder := get(t, handler, "secret", "/operator/v1/reads/operator.audit.list?module=ota.publish&principal=root&limit=2&from=2026-11-22T00:00:00Z&cursor=2026-11-22T00:00:01.5Z|key-1")
	if recorder.Code != http.StatusOK {
		t.Fatalf("audit read: %d %s", recorder.Code, recorder.Body)
	}
	if service.filter.Module != "ota.publish" || service.filter.Principal != "root" || service.filter.Limit != 2 || service.filter.From == nil || service.filter.Cursor == nil || service.filter.Cursor.SemanticKey != "key-1" {
		t.Fatalf("filter=%+v", service.filter)
	}
	if got := service.filter.Cursor.String(); got != "2026-11-22T00:00:01.5Z|key-1" {
		t.Fatalf("cursor round trip=%q", got)
	}
}

func TestAuditReadRefusesAMalformedLimit(t *testing.T) {
	handler := Handler{Token: "secret", Reads: map[string]Read{"operator.audit.list": AuditList(&fakeAuditService{})}}
	recorder := get(t, handler, "secret", "/operator/v1/reads/operator.audit.list?limit=nope")
	if recorder.Code != http.StatusConflict || errorCode(t, recorder) != operator.CodeReadInvalid {
		t.Fatalf("malformed limit: %d %s", recorder.Code, recorder.Body)
	}
}

type fakeRedeemList struct {
	after string
	limit int
}

func (f *fakeRedeemList) List(_ context.Context, after string, limit int) (appi5.RedeemPage, error) {
	f.after, f.limit = after, limit
	return appi5.RedeemPage{}, nil
}

func TestRedeemListParsesTheBoundedQuery(t *testing.T) {
	service := &fakeRedeemList{}
	handler := Handler{Token: "secret", Reads: map[string]Read{"redeem.list": RedeemList(service)}}
	recorder := get(t, handler, "secret", "/operator/v1/reads/redeem.list?after=00000000-0000-4000-8000-000000000001&limit=25")
	if recorder.Code != http.StatusOK {
		t.Fatalf("redeem read: %d %s", recorder.Code, recorder.Body)
	}
	if service.after != "00000000-0000-4000-8000-000000000001" || service.limit != 25 {
		t.Fatalf("after=%q limit=%d", service.after, service.limit)
	}
	recorder = get(t, handler, "secret", "/operator/v1/reads/redeem.list?limit=201")
	if recorder.Code != http.StatusConflict || errorCode(t, recorder) != operator.CodeReadInvalid {
		t.Fatalf("limit over cap: %d %s", recorder.Code, recorder.Body)
	}
}
