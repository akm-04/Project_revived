package stockruntime

import (
	"io"
	"log"
	"net/http"
	"path"
	"strings"
	"time"

	appotarelease "gxb.local/backend/v2/internal/application/otarelease"
)

const (
	downloadBaseWriteDeadline = 35 * time.Second
	downloadBytesPerSecond    = 32 * 1024
)

// downloadWriteDeadline replaces the shared server's 35 s WriteTimeout: the
// body gets the base window plus one second per 32 KiB (OA-4).
func downloadWriteDeadline(now time.Time, size int64) time.Time {
	if size < 0 {
		size = 0
	}
	return now.Add(downloadBaseWriteDeadline + time.Duration(size)*time.Second/downloadBytesPerSecond)
}

func bodySize(file io.ReadSeeker) int64 {
	size, err := file.Seek(0, io.SeekEnd)
	if err != nil {
		return 0
	}
	if _, err := file.Seek(0, io.SeekStart); err != nil {
		return 0
	}
	return size
}

func setDownloadWriteDeadline(writer http.ResponseWriter, file io.ReadSeeker) {
	_ = http.NewResponseController(writer).SetWriteDeadline(downloadWriteDeadline(time.Now(), bodySize(file)))
}

// OTAUpdatesGET serves /updates/<lane>/<file> (I11A_OTA_RELEASE_V1 ruling 6).
// Only a volume named by an ACTIVE release is opened; everything else is 404.
type OTAUpdatesGET struct {
	Serving *appotarelease.Serving
}

func (h OTAUpdatesGET) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if h.Serving == nil {
		http.NotFound(writer, request)
		return
	}
	if request.Method != http.MethodGet && request.Method != http.MethodHead {
		writer.Header().Set("Allow", "GET, HEAD")
		http.Error(writer, "method_not_allowed", http.StatusMethodNotAllowed)
		return
	}
	suffix, found := strings.CutPrefix(request.URL.Path, "/updates/")
	parts := strings.Split(suffix, "/")
	if !found || suffix == "" || len(parts) != 2 || parts[0] == "" || parts[1] == "" {
		http.NotFound(writer, request)
		return
	}
	file, modified, servable, err := h.Serving.OpenVolume(request.Context(), parts[0], parts[1])
	if err != nil {
		log.Printf("ota updates %s/%s: %v", parts[0], parts[1], err)
		http.Error(writer, "ota_unavailable", http.StatusServiceUnavailable)
		return
	}
	if !servable {
		http.NotFound(writer, request)
		return
	}
	defer file.Close()
	setDownloadWriteDeadline(writer, file)
	writer.Header().Set("X-Content-Type-Options", "nosniff")
	http.ServeContent(writer, request, parts[1], modified, file)
}

// OTAResGET serves /res/<basename>.<md5> from the union res index after the md5
// check. A miss is recorded once per path in the ledger.
type OTAResGET struct {
	Serving *appotarelease.Serving
}

func (h OTAResGET) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if h.Serving == nil {
		http.NotFound(writer, request)
		return
	}
	if request.Method != http.MethodGet && request.Method != http.MethodHead {
		writer.Header().Set("Allow", "GET, HEAD")
		http.Error(writer, "method_not_allowed", http.StatusMethodNotAllowed)
		return
	}
	asset, found := strings.CutPrefix(request.URL.Path, "/res/")
	if !found || asset == "" || strings.Contains(asset, "/") {
		http.NotFound(writer, request)
		return
	}
	file, modified, resourcePath, servable, err := h.Serving.OpenResource(request.Context(), asset)
	if err != nil {
		log.Printf("ota res %s: %v", asset, err)
		http.Error(writer, "ota_unavailable", http.StatusServiceUnavailable)
		return
	}
	if !servable {
		http.NotFound(writer, request)
		return
	}
	defer file.Close()
	setDownloadWriteDeadline(writer, file)
	writer.Header().Set("X-Content-Type-Options", "nosniff")
	http.ServeContent(writer, request, path.Base(resourcePath), modified, file)
}
