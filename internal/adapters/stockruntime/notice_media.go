package stockruntime

import (
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// noticeMediaPrefix is the public read-only route for operator notice pictures
// (G41); the name is a content hash, so a 200 can be cached forever.
const noticeMediaPrefix = "/media/"

var noticeMediaName = regexp.MustCompile(`^[0-9a-f]{16}\.(png|jpg)$`)

// NoticeMediaGET serves one stored notice picture read-only. The exact name
// pattern admits no directory listing, traversal or other extension.
type NoticeMediaGET struct {
	Root string
}

func (handler NoticeMediaGET) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet && request.Method != http.MethodHead {
		writer.Header().Set("Allow", "GET, HEAD")
		http.Error(writer, "method_not_allowed", http.StatusMethodNotAllowed)
		return
	}
	if handler.Root == "" {
		http.NotFound(writer, request)
		return
	}
	name, found := strings.CutPrefix(request.URL.Path, noticeMediaPrefix)
	if !found || !noticeMediaName.MatchString(name) || request.URL.RawQuery != "" {
		http.NotFound(writer, request)
		return
	}
	file, err := os.Open(filepath.Join(handler.Root, name))
	if err != nil {
		http.NotFound(writer, request)
		return
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil || !info.Mode().IsRegular() {
		http.NotFound(writer, request)
		return
	}
	contentType := "image/jpeg"
	if strings.HasSuffix(name, ".png") {
		contentType = "image/png"
	}
	writer.Header().Set("Content-Type", contentType)
	writer.Header().Set("X-Content-Type-Options", "nosniff")
	writer.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
	writer.Header().Set("ETag", `"`+name+`"`)
	http.ServeContent(writer, request, name, time.Time{}, file)
}
