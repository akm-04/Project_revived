// Package operatormedia stores operator notice pictures on this machine and
// hands out the backend's public /media/ URL for them (G41).
package operatormedia

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"errors"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

const (
	// MaxPictureBytes is the G41 cap on one stored picture.
	MaxPictureBytes = 5 << 20
	fetchTimeout    = 15 * time.Second
	maxRedirects    = 3
	mediaDirectory  = "media"
)

const (
	CodeUnavailable     = "MEDIA_UNAVAILABLE"
	CodeURLInvalid      = "MEDIA_URL_INVALID"
	CodeFetchFailed     = "MEDIA_FETCH_FAILED"
	CodeTypeUnsupported = "MEDIA_TYPE_UNSUPPORTED"
	CodeTooLarge        = "MEDIA_TOO_LARGE"
	CodeNameInvalid     = "MEDIA_NAME_INVALID"
	CodePictureNotFound = "MEDIA_PICTURE_NOT_FOUND"
)

var mediaNamePattern = regexp.MustCompile(`^[0-9a-f]{16}\.(png|jpg)$`)

// Refusal is one media refusal; the agent answers it 409 with the code.
type Refusal struct {
	Code    string
	Message string
}

func (refusal *Refusal) Error() string { return refusal.Message }

// Refuse builds a media refusal.
func Refuse(code, message string) error { return &Refusal{Code: code, Message: message} }

// Service stores pictures under MediaPath and builds their URLs from the public
// engine URL. The zero HTTPClient uses the guarded default below.
type Service struct {
	MediaPath       string
	PublicEngineURL string
	HTTPClient      *http.Client
	// permit is the address guard; tests replace it, production uses publicAddress.
	permit func(net.IP) bool
}

// Stored is the reply of media.import_url and media.upload.
type Stored struct {
	Name   string `json:"name"`
	URL    string `json:"url"`
	Bytes  int    `json:"bytes"`
	Width  *int   `json:"width,omitempty"`
	Height *int   `json:"height,omitempty"`
}

// StoredItem is one media.list entry.
type StoredItem struct {
	Name  string `json:"name"`
	URL   string `json:"url"`
	Bytes int64  `json:"bytes"`
}

// MediaPath resolves the notice picture folder: the agent process's
// GXB_NOTICE_MEDIA_ROOT, then the configured agent.json media_path, then
// <root>/media.
func MediaPath(root, configured string) string {
	if fromEnvironment := strings.TrimSpace(os.Getenv("GXB_NOTICE_MEDIA_ROOT")); fromEnvironment != "" {
		return fromEnvironment
	}
	if configured = strings.TrimSpace(configured); configured != "" {
		return configured
	}
	return filepath.Join(root, mediaDirectory)
}

// ImportURL downloads one http or https picture and stores it.
func (service Service) ImportURL(ctx context.Context, rawURL string) (Stored, error) {
	target := strings.TrimSpace(rawURL)
	parsed, err := url.Parse(target)
	if err != nil || parsed.Host == "" || parsed.User != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		return Stored{}, Refuse(CodeURLInvalid, "the picture URL must be an absolute http or https address")
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, target, nil)
	if err != nil {
		return Stored{}, Refuse(CodeURLInvalid, "the picture URL is not a valid request")
	}
	response, err := service.httpClient().Do(request)
	if err != nil {
		var refusal *Refusal
		if errors.As(err, &refusal) {
			return Stored{}, refusal
		}
		return Stored{}, Refuse(CodeFetchFailed, "the picture could not be downloaded: "+err.Error())
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode > 299 {
		return Stored{}, Refuse(CodeFetchFailed, "the picture server answered HTTP "+strconv.Itoa(response.StatusCode))
	}
	if response.ContentLength > MaxPictureBytes {
		return Stored{}, Refuse(CodeTooLarge, "the picture is larger than 5 MiB")
	}
	data, err := io.ReadAll(io.LimitReader(response.Body, MaxPictureBytes+1))
	if err != nil {
		return Stored{}, Refuse(CodeFetchFailed, "the picture could not be read: "+err.Error())
	}
	return service.store(data)
}

// Upload stores the bytes the operator chose from the file picker.
func (service Service) Upload(data []byte) (Stored, error) {
	return service.store(data)
}

// List answers media.list for the picker.
func (service Service) List() ([]StoredItem, error) {
	if service.MediaPath == "" {
		return nil, Refuse(CodeUnavailable, "the media folder is not configured")
	}
	entries, err := os.ReadDir(service.MediaPath)
	if errors.Is(err, os.ErrNotExist) {
		return []StoredItem{}, nil
	}
	if err != nil {
		return nil, err
	}
	items := make([]StoredItem, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() || !mediaNamePattern.MatchString(entry.Name()) {
			continue
		}
		info, err := entry.Info()
		if err != nil {
			continue
		}
		items = append(items, StoredItem{Name: entry.Name(), URL: service.mediaURL(entry.Name()), Bytes: info.Size()})
	}
	sort.Slice(items, func(left, right int) bool { return items[left].Name < items[right].Name })
	return items, nil
}

// FilePath resolves one stored picture for the agent preview route.
func (service Service) FilePath(name string) (string, error) {
	if service.MediaPath == "" {
		return "", Refuse(CodeUnavailable, "the media folder is not configured")
	}
	if !mediaNamePattern.MatchString(name) {
		return "", Refuse(CodeNameInvalid, "the picture name is not a stored picture name")
	}
	path := filepath.Join(service.MediaPath, name)
	info, err := os.Stat(path)
	if err != nil || !info.Mode().IsRegular() {
		return "", Refuse(CodePictureNotFound, "no such stored picture")
	}
	return path, nil
}

func (service Service) store(data []byte) (Stored, error) {
	if len(data) == 0 {
		return Stored{}, Refuse(CodeTypeUnsupported, "the picture is empty")
	}
	if len(data) > MaxPictureBytes {
		return Stored{}, Refuse(CodeTooLarge, "the picture is larger than 5 MiB")
	}
	extension := pictureExtension(data)
	if extension == "" {
		return Stored{}, Refuse(CodeTypeUnsupported, "only PNG and JPEG pictures are accepted")
	}
	if service.MediaPath == "" {
		return Stored{}, Refuse(CodeUnavailable, "the media folder is not configured")
	}
	digest := sha256.Sum256(data)
	name := hex.EncodeToString(digest[:])[:16] + extension
	if err := os.MkdirAll(service.MediaPath, 0o700); err != nil {
		return Stored{}, err
	}
	target := filepath.Join(service.MediaPath, name)
	if _, err := os.Stat(target); err != nil {
		if err := writeAtomic(service.MediaPath, target, data); err != nil {
			return Stored{}, err
		}
	}
	stored := Stored{Name: name, URL: service.mediaURL(name), Bytes: len(data)}
	if width, height := pictureSize(data); width > 0 && height > 0 {
		stored.Width, stored.Height = &width, &height
	}
	return stored, nil
}

func writeAtomic(directory, target string, data []byte) error {
	temporary, err := os.CreateTemp(directory, ".media-*")
	if err != nil {
		return err
	}
	temporaryName := temporary.Name()
	remove := func() { _ = os.Remove(temporaryName) }
	if _, err := temporary.Write(data); err != nil {
		_ = temporary.Close()
		remove()
		return err
	}
	if err := temporary.Chmod(0o644); err != nil {
		_ = temporary.Close()
		remove()
		return err
	}
	if err := temporary.Close(); err != nil {
		remove()
		return err
	}
	if err := os.Rename(temporaryName, target); err != nil {
		// Windows refuses a rename onto an existing name; a concurrent writer
		// that landed the same content is the idempotent outcome.
		if _, statErr := os.Stat(target); statErr == nil {
			remove()
			return nil
		}
		remove()
		return err
	}
	return nil
}

func (service Service) mediaURL(name string) string {
	origin := publicOrigin(service.PublicEngineURL)
	if origin == "" {
		return ""
	}
	return origin + "/media/" + name
}

// publicOrigin is the scheme and host the backend serves /media/ from; the
// engine path in GXB_PUBLIC_ENGINE_URL is not part of the media route.
func publicOrigin(raw string) string {
	parsed, err := url.Parse(strings.TrimSpace(raw))
	if err != nil || parsed.Host == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		return ""
	}
	return parsed.Scheme + "://" + parsed.Host
}

func (service Service) httpClient() *http.Client {
	if service.HTTPClient != nil {
		return service.HTTPClient
	}
	return &http.Client{
		Timeout: fetchTimeout,
		Transport: &http.Transport{
			Proxy:                 nil,
			DialContext:           service.dialContext,
			TLSHandshakeTimeout:   10 * time.Second,
			ResponseHeaderTimeout: 10 * time.Second,
		},
		CheckRedirect: checkRedirect,
	}
}

// dialContext resolves the host itself, refuses every non-public address and
// dials the checked address. The http client calls it for every connection,
// redirects included, so a redirect cannot reach the LAN.
func (service Service) dialContext(ctx context.Context, network, address string) (net.Conn, error) {
	host, port, err := net.SplitHostPort(address)
	if err != nil {
		return nil, err
	}
	addresses, err := net.DefaultResolver.LookupIPAddr(ctx, host)
	if err != nil {
		return nil, err
	}
	if len(addresses) == 0 {
		return nil, Refuse(CodeURLInvalid, "the picture host has no address")
	}
	permit := service.permit
	if permit == nil {
		permit = publicAddress
	}
	for _, candidate := range addresses {
		if !permit(candidate.IP) {
			return nil, Refuse(CodeURLInvalid, "the picture URL points to a private or local address")
		}
	}
	dialer := &net.Dialer{Timeout: 10 * time.Second}
	var dialErr error
	for _, candidate := range addresses {
		connection, err := dialer.DialContext(ctx, network, net.JoinHostPort(candidate.IP.String(), port))
		if err == nil {
			return connection, nil
		}
		dialErr = err
	}
	return nil, dialErr
}

func checkRedirect(request *http.Request, via []*http.Request) error {
	if len(via) > maxRedirects {
		return Refuse(CodeURLInvalid, "the picture URL redirected more than 3 times")
	}
	if request.URL.Scheme != "http" && request.URL.Scheme != "https" {
		return Refuse(CodeURLInvalid, "the picture URL redirected to a non-http address")
	}
	return nil
}

// nonPublicAddressRanges holds ranges net.IP's Is* helpers do not cover:
// 100.64.0.0/10 is the shared address space (Tailscale and carrier NAT) and
// 0.0.0.0/8 is this network.
var nonPublicAddressRanges = []*net.IPNet{
	mustParseCIDR("100.64.0.0/10"),
	mustParseCIDR("0.0.0.0/8"),
}

func mustParseCIDR(raw string) *net.IPNet {
	_, network, err := net.ParseCIDR(raw)
	if err != nil {
		panic("invalid address range " + raw)
	}
	return network
}

// publicAddress is false for every address an operator must not be steered to.
func publicAddress(address net.IP) bool {
	if address == nil {
		return false
	}
	for _, network := range nonPublicAddressRanges {
		if network.Contains(address) {
			return false
		}
	}
	return !address.IsLoopback() &&
		!address.IsPrivate() &&
		!address.IsLinkLocalUnicast() &&
		!address.IsLinkLocalMulticast() &&
		!address.IsUnspecified() &&
		!address.IsMulticast()
}

var pngMagic = []byte{0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a}

func pictureExtension(data []byte) string {
	if bytes.HasPrefix(data, pngMagic) {
		return ".png"
	}
	if len(data) >= 3 && data[0] == 0xff && data[1] == 0xd8 && data[2] == 0xff {
		return ".jpg"
	}
	return ""
}

func pictureSize(data []byte) (int, int) {
	if bytes.HasPrefix(data, pngMagic) {
		if len(data) < 24 || string(data[12:16]) != "IHDR" {
			return 0, 0
		}
		width := int(binary.BigEndian.Uint32(data[16:20]))
		height := int(binary.BigEndian.Uint32(data[20:24]))
		if width <= 0 || height <= 0 {
			return 0, 0
		}
		return width, height
	}
	return jpegSize(data)
}

// jpegSize walks the JPEG markers to the first start-of-frame segment.
func jpegSize(data []byte) (int, int) {
	if len(data) < 4 {
		return 0, 0
	}
	index := 2
	for index+3 < len(data) {
		if data[index] != 0xff {
			index++
			continue
		}
		marker := data[index+1]
		if marker == 0xd8 || marker == 0xd9 || (marker >= 0xd0 && marker <= 0xd7) {
			index += 2
			continue
		}
		length := int(binary.BigEndian.Uint16(data[index+2 : index+4]))
		if length < 2 {
			return 0, 0
		}
		startOfFrame := marker >= 0xc0 && marker <= 0xcf && marker != 0xc4 && marker != 0xc8 && marker != 0xcc
		if startOfFrame && index+9 <= len(data) {
			height := int(binary.BigEndian.Uint16(data[index+5 : index+7]))
			width := int(binary.BigEndian.Uint16(data[index+7 : index+9]))
			return width, height
		}
		index += 2 + length
	}
	return 0, 0
}
