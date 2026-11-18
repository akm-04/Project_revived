package stockruntime

import (
	"bytes"
	"context"
	"errors"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"net/url"
	"strings"

	app "gxb.local/backend/v2/internal/application/clientlog"
	domain "gxb.local/backend/v2/internal/domain/clientlog"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// ClientLogIngest is the ClientLog service seen by the log URL route.
type ClientLogIngest interface {
	Ingest(context.Context, app.UploadRequest) int
}

// ClientLogHandler receives stock Backend:log posts at <base path>/<capability>
// (I85_CLIENT_LOG_INGEST_V1). Bad input is quarantined and answered 200 so the
// stock poster stops resending it (R4).
type ClientLogHandler struct {
	Ingest   ClientLogIngest
	BasePath string
	// Bound caps concurrent uploads. This route bypasses the HTTP edge on the
	// raw gameplay pool, so without it one host can take every connection (C1-9).
	Bound *httpedge.Admission
}

// ClientLogBasePath is the route path of GXB_CLIENT_LOG_URL.
func ClientLogBasePath(baseURL string) (string, error) {
	parsed, err := url.Parse(baseURL)
	if err != nil || parsed.Scheme == "" || parsed.Host == "" {
		return "", errors.New("GXB_CLIENT_LOG_URL must be an absolute URL")
	}
	path := strings.TrimRight(parsed.Path, "/")
	if path == "" {
		return "", errors.New("GXB_CLIENT_LOG_URL needs a path of its own (for example /client-log)")
	}
	return path, nil
}

func (h ClientLogHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	if h.Bound != nil && !h.Bound.TryAcquire() {
		busyReply(w, "client_log_busy")
		return
	}
	if h.Bound != nil {
		defer h.Bound.Release()
	}
	request := readUpload(r)
	request.Capability = strings.TrimPrefix(strings.TrimPrefix(r.URL.Path, h.BasePath), "/")
	w.WriteHeader(h.Ingest.Ingest(r.Context(), request))
}

func readUpload(r *http.Request) app.UploadRequest {
	body, err := io.ReadAll(io.LimitReader(r.Body, domain.MaxCrashBodyBytes+1))
	if err != nil {
		return malformedUpload(body, app.QuarantineMalformedMultipart)
	}
	if len(body) > domain.MaxCrashBodyBytes {
		return malformedUpload(body, app.QuarantineOverCap)
	}
	mediaType, parameters, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || mediaType != "multipart/form-data" || parameters["boundary"] == "" {
		return malformedUpload(body, app.QuarantineMalformedMultipart)
	}
	request := app.UploadRequest{BodyBytes: len(body)}
	if err := readParts(multipart.NewReader(bytes.NewReader(body), parameters["boundary"]), &request); err != nil {
		return malformedUpload(body, app.QuarantineMalformedMultipart)
	}
	if request.Kind == domain.KindErrorLog && len(body) > domain.MaxErrorLogBodyBytes {
		request.Malformed = app.QuarantineOverCap
	}
	return request
}

func malformedUpload(body []byte, reason string) app.UploadRequest {
	return app.UploadRequest{BodyBytes: len(body), Malformed: reason, RawBody: body}
}

var errNoParts = errors.New("multipart body has no parts")

func readParts(reader *multipart.Reader, request *app.UploadRequest) error {
	for parts := 0; ; parts++ {
		part, err := reader.NextPart()
		if errors.Is(err, io.EOF) && parts == 0 {
			return errNoParts
		}
		if errors.Is(err, io.EOF) {
			return nil
		}
		if err != nil {
			return err
		}
		data, err := io.ReadAll(part)
		if err != nil {
			return err
		}
		if part.FileName() != "" {
			request.Kind = domain.KindCrash
			request.AttachmentName = part.FileName()
			request.Attachment = data
			continue
		}
		switch part.FormName() {
		case "payload":
			request.Payload = data
		case "app_v":
			request.AppVersion = string(data)
		case "v":
			request.Version = string(data)
		case "token":
			request.Token = string(data)
		}
	}
}
