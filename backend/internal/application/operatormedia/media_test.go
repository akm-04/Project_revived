package operatormedia

import (
	"context"
	"encoding/binary"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func pngBytes(width, height uint32) []byte {
	data := append([]byte{}, pngMagic...)
	chunk := make([]byte, 25)
	binary.BigEndian.PutUint32(chunk[0:4], 13)
	copy(chunk[4:8], "IHDR")
	binary.BigEndian.PutUint32(chunk[8:12], width)
	binary.BigEndian.PutUint32(chunk[12:16], height)
	chunk[16] = 8
	chunk[17] = 6
	return append(data, chunk...)
}

func jpegBytes(width, height uint16) []byte {
	data := []byte{0xff, 0xd8, 0xff, 0xc0, 0x00, 0x11, 0x08, 0x00, 0x00, 0x00, 0x00}
	binary.BigEndian.PutUint16(data[7:9], height)
	binary.BigEndian.PutUint16(data[9:11], width)
	return append(data, make([]byte, 8)...)
}

func testService(t *testing.T) Service {
	t.Helper()
	return Service{MediaPath: t.TempDir(), PublicEngineURL: "https://game.example/engine"}
}

func TestStoreSniffsTypeAndIsContentAddressed(t *testing.T) {
	service := testService(t)
	picture := pngBytes(320, 200)
	first, err := service.Upload(picture)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasSuffix(first.Name, ".png") || len(first.Name) != 20 {
		t.Fatalf("name = %q, want 16 hex digits and .png", first.Name)
	}
	if first.URL != "https://game.example/media/"+first.Name {
		t.Fatalf("url = %q", first.URL)
	}
	if first.Width == nil || *first.Width != 320 || first.Height == nil || *first.Height != 200 {
		t.Fatalf("size = %v x %v", first.Width, first.Height)
	}
	second, err := service.Upload(picture)
	if err != nil {
		t.Fatal(err)
	}
	if second.Name != first.Name {
		t.Fatalf("same bytes got %q then %q", first.Name, second.Name)
	}
	info, err := os.Stat(filepath.Join(service.MediaPath, first.Name))
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o644 {
		t.Fatalf("mode = %o", info.Mode().Perm())
	}
	jpeg := jpegBytes(64, 48)
	stored, err := service.Upload(jpeg)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasSuffix(stored.Name, ".jpg") || stored.Width == nil || *stored.Width != 64 {
		t.Fatalf("jpeg store = %+v", stored)
	}
}

func TestStoreRefusesNonPicturesAndOversize(t *testing.T) {
	service := testService(t)
	if _, err := service.Upload([]byte("<html>")); !isCode(err, CodeTypeUnsupported) {
		t.Fatalf("non-picture error = %v", err)
	}
	oversize := append(append([]byte{}, pngMagic...), make([]byte, MaxPictureBytes)...)
	if _, err := service.Upload(oversize); !isCode(err, CodeTooLarge) {
		t.Fatalf("oversize error = %v", err)
	}
}

func TestStoreWithoutFolderRefuses(t *testing.T) {
	service := Service{}
	if _, err := service.Upload(pngBytes(1, 1)); !isCode(err, CodeUnavailable) {
		t.Fatalf("error = %v", err)
	}
}

func TestMediaPathPrefersEnvironmentThenConfigThenDefault(t *testing.T) {
	t.Setenv("GXB_NOTICE_MEDIA_ROOT", "")
	root := t.TempDir()
	if path := MediaPath(root, "/var/pictures"); path != "/var/pictures" {
		t.Fatalf("configured path = %q", path)
	}
	if path := MediaPath(root, ""); path != filepath.Join(root, mediaDirectory) {
		t.Fatalf("default path = %q", path)
	}
	t.Setenv("GXB_NOTICE_MEDIA_ROOT", "/from-environment")
	if path := MediaPath(root, "/var/pictures"); path != "/from-environment" {
		t.Fatalf("environment path = %q", path)
	}
}

func TestPublicAddressRefusesSharedAndThisNetwork(t *testing.T) {
	cases := []struct {
		address string
		allowed bool
	}{
		{"100.64.0.1", false},
		{"100.127.255.254", false},
		{"0.1.2.3", false},
		{"100.128.0.1", true},
	}
	for _, testCase := range cases {
		if got := publicAddress(net.ParseIP(testCase.address)); got != testCase.allowed {
			t.Fatalf("%s: publicAddress = %v, want %v", testCase.address, got, testCase.allowed)
		}
	}
}

func TestImportRefusesLoopbackLinkLocalAndPrivateAddresses(t *testing.T) {
	service := testService(t)
	service.PublicEngineURL = ""
	cases := []string{
		"http://127.0.0.1/p.png",
		"http://10.0.0.1/p.png",
		"http://192.168.1.10/p.png",
		"http://[::1]/p.png",
		"http://169.254.1.1/p.png",
		"http://0.0.0.0/p.png",
	}
	for _, target := range cases {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		_, err := service.ImportURL(ctx, target)
		cancel()
		if !isCode(err, CodeURLInvalid) {
			t.Fatalf("%s: error = %v", target, err)
		}
	}
}

func TestImportRefusesAURLThatIsNotHTTP(t *testing.T) {
	service := testService(t)
	for _, target := range []string{"ftp://example.test/p.png", "javascript:alert(1)", "https://", "file:///etc/passwd"} {
		if _, err := service.ImportURL(context.Background(), target); !isCode(err, CodeURLInvalid) {
			t.Fatalf("%s: error = %v", target, err)
		}
	}
}

func TestImportRefusesARedirectToAPrivateAddress(t *testing.T) {
	redirector := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		http.Redirect(writer, request, "http://10.0.0.1/p.png", http.StatusFound)
	}))
	defer redirector.Close()
	service := testService(t)
	service.permit = func(address net.IP) bool { return address.IsLoopback() }
	_, err := service.ImportURL(context.Background(), redirector.URL)
	if !isCode(err, CodeURLInvalid) || !strings.Contains(err.Error(), "private or local") {
		t.Fatalf("error = %v", err)
	}
}

func TestImportAllowsThreeRedirectsAndRefusesTheFourth(t *testing.T) {
	var requests int
	redirector := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		requests++
		http.Redirect(writer, request, "/again", http.StatusFound)
	}))
	defer redirector.Close()
	service := testService(t)
	service.permit = func(address net.IP) bool { return address.IsLoopback() }
	_, err := service.ImportURL(context.Background(), redirector.URL)
	if !isCode(err, CodeURLInvalid) || !strings.Contains(err.Error(), "more than 3 times") {
		t.Fatalf("error = %v after %d requests", err, requests)
	}
}

func TestImportStoresAReachablePicture(t *testing.T) {
	picture := pngBytes(16, 8)
	source := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		writer.Header().Set("Content-Type", "image/png")
		_, _ = writer.Write(picture)
	}))
	defer source.Close()
	service := testService(t)
	service.permit = publicAddressOnlyLoopbackForTest()
	stored, err := service.ImportURL(context.Background(), source.URL+"/p.png")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasSuffix(stored.Name, ".png") || stored.URL != "https://game.example/media/"+stored.Name {
		t.Fatalf("stored = %+v", stored)
	}
	if stored.Width == nil || *stored.Width != 16 {
		t.Fatalf("size = %v", stored.Width)
	}
}

func TestImportRefusesOversizeBody(t *testing.T) {
	source := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		_, _ = writer.Write(append(append([]byte{}, pngMagic...), make([]byte, MaxPictureBytes)...))
	}))
	defer source.Close()
	service := testService(t)
	service.permit = publicAddressOnlyLoopbackForTest()
	if _, err := service.ImportURL(context.Background(), source.URL); !isCode(err, CodeTooLarge) {
		t.Fatalf("error = %v", err)
	}
}

func publicAddressOnlyLoopbackForTest() func(net.IP) bool {
	return func(address net.IP) bool { return address.IsLoopback() || publicAddress(address) }
}

func TestListAndFilePathAcceptOnlyStoredNames(t *testing.T) {
	service := testService(t)
	stored, err := service.Upload(pngBytes(2, 2))
	if err != nil {
		t.Fatal(err)
	}
	items, err := service.List()
	if err != nil {
		t.Fatal(err)
	}
	if len(items) != 1 || items[0].Name != stored.Name || items[0].URL != stored.URL {
		t.Fatalf("items = %+v", items)
	}
	if _, err := service.FilePath(stored.Name); err != nil {
		t.Fatalf("stored name refused: %v", err)
	}
	for _, name := range []string{"../" + stored.Name, stored.Name + "/x", "not-a-hash.png", stored.Name + ".jpeg"} {
		if _, err := service.FilePath(name); !isCode(err, CodeNameInvalid) {
			t.Fatalf("%q: error = %v", name, err)
		}
	}
}

func isCode(err error, code string) bool {
	var refusal *Refusal
	return errors.As(err, &refusal) && refusal.Code == code
}
