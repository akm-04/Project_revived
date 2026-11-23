package agentapi

import (
	"encoding/base64"
	"errors"
	"net/http"
	"os"
	"strings"

	"gxb.local/backend/v2/internal/application/operatoragent"
	"gxb.local/backend/v2/internal/application/operatormedia"
)

const (
	mediaPrefix     = "/agent/v1/media/"
	mediaImportPath = "/agent/v1/media/import_url"
	mediaUploadPath = "/agent/v1/media/upload"
	mediaListPath   = "/agent/v1/media/list"
	mediaFilePrefix = "/agent/v1/media/file/"

	// A 5 MiB picture is about 7 MiB in base64 plus the JSON envelope.
	maxMediaBodyBytes = 8 << 20
)

type mediaImportRequest struct {
	URL string `json:"url"`
}

type mediaUploadRequest struct {
	DataBase64 string `json:"data_base64"`
}

// serveMedia dispatches the G41 picture routes; the stored picture file route
// is the GUI preview and needs no external host.
func (handler Handler) serveMedia(writer http.ResponseWriter, request *http.Request) {
	switch {
	case request.URL.Path == mediaImportPath && request.Method == http.MethodPost:
		handler.serveMediaImport(writer, request)
	case request.URL.Path == mediaUploadPath && request.Method == http.MethodPost:
		handler.serveMediaUpload(writer, request)
	case request.URL.Path == mediaListPath && request.Method == http.MethodGet:
		handler.serveMediaList(writer)
	case strings.HasPrefix(request.URL.Path, mediaFilePrefix) && (request.Method == http.MethodGet || request.Method == http.MethodHead):
		handler.serveMediaFile(writer, request)
	default:
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such media route")
	}
}

func (handler Handler) mediaStore(writer http.ResponseWriter) (*operatormedia.Service, bool) {
	if handler.Media == nil || handler.Media.MediaPath == "" {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the media folder is not configured")
		return nil, false
	}
	return handler.Media, true
}

func (handler Handler) serveMediaImport(writer http.ResponseWriter, request *http.Request) {
	service, ok := handler.mediaStore(writer)
	if !ok {
		return
	}
	var body mediaImportRequest
	if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
		handler.writeBodyError(writer, err)
		return
	}
	stored, err := service.ImportURL(request.Context(), body.URL)
	if err != nil {
		handler.writeMediaError(writer, "media.import_url", err)
		return
	}
	handler.record("media.import_url", "import", "ok", map[string]any{"name": stored.Name, "bytes": stored.Bytes})
	writeJSON(writer, http.StatusOK, stored)
}

func (handler Handler) serveMediaUpload(writer http.ResponseWriter, request *http.Request) {
	service, ok := handler.mediaStore(writer)
	if !ok {
		return
	}
	var body mediaUploadRequest
	if err := decodeBody(writer, request, maxMediaBodyBytes, &body); err != nil {
		handler.writeBodyError(writer, err)
		return
	}
	encoded := body.DataBase64
	if strings.HasPrefix(encoded, "data:") {
		_, payload, found := strings.Cut(encoded, ",")
		if !found {
			writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "the picture data is not a base64 data URL")
			return
		}
		encoded = payload
	}
	data, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "the picture data is not base64")
		return
	}
	stored, err := service.Upload(data)
	if err != nil {
		handler.writeMediaError(writer, "media.upload", err)
		return
	}
	handler.record("media.upload", "upload", "ok", map[string]any{"name": stored.Name, "bytes": stored.Bytes})
	writeJSON(writer, http.StatusOK, stored)
}

func (handler Handler) serveMediaList(writer http.ResponseWriter) {
	service, ok := handler.mediaStore(writer)
	if !ok {
		return
	}
	items, err := service.List()
	if err != nil {
		handler.writeMediaError(writer, "media.list", err)
		return
	}
	handler.record("media.list", "list", "ok", map[string]any{"pictures": len(items)})
	writeJSON(writer, http.StatusOK, map[string]any{"items": items})
}

func (handler Handler) serveMediaFile(writer http.ResponseWriter, request *http.Request) {
	service, ok := handler.mediaStore(writer)
	if !ok {
		return
	}
	name := strings.TrimPrefix(request.URL.Path, mediaFilePrefix)
	path, err := service.FilePath(name)
	if err != nil {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such stored picture")
		return
	}
	file, err := os.Open(path)
	if err != nil {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such stored picture")
		return
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such stored picture")
		return
	}
	contentType := "image/jpeg"
	if strings.HasSuffix(name, ".png") {
		contentType = "image/png"
	}
	writer.Header().Set("Content-Type", contentType)
	writer.Header().Set("X-Content-Type-Options", "nosniff")
	writer.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
	http.ServeContent(writer, request, info.Name(), info.ModTime(), file)
}

// writeMediaError maps a media refusal to 409 with its code; a transient
// download failure is a refusal too, because the operator can retry.
func (handler Handler) writeMediaError(writer http.ResponseWriter, action string, err error) {
	var refusal *operatormedia.Refusal
	if errors.As(err, &refusal) {
		handler.record(action, "error", "refused", map[string]any{"error_code": refusal.Code})
		writeRefusal(writer, http.StatusConflict, refusal.Code, refusal.Message)
		return
	}
	handler.record(action, "error", "failed", map[string]any{"error": err.Error()})
	writeRefusal(writer, http.StatusInternalServerError, operatoragent.CodeFailed, "the media action failed")
}
