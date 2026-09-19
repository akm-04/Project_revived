package httpedge

import (
	"bytes"
	"compress/zlib"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"

	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type Upload struct {
	FieldName   string
	Filename    string
	ContentType string
	TempPath    string
	Size        int64
	SHA256      [32]byte
}

type Decoded struct {
	MID       uint16
	Params    map[string]any
	Encoding  wire.Encoding
	RawBytes  int64
	RawSHA256 [32]byte
	Upload    *Upload
}

func (d *Decoded) Cleanup() {
	if d != nil && d.Upload != nil && d.Upload.TempPath != "" {
		_ = os.Remove(d.Upload.TempPath)
	}
}

func Decode(r *http.Request, cfg limits.Config) (*Decoded, *wire.EdgeError) {
	if err := cfg.Validate(); err != nil {
		return nil, wire.NewError(wire.ErrInternal, http.StatusInternalServerError, "bad_config", err.Error())
	}
	mediaType, params, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil {
		return nil, bad("invalid content-type")
	}
	switch strings.ToLower(mediaType) {
	case "", "application/x-www-form-urlencoded":
		return decodeOrdinary(r, cfg)
	case "multipart/form-data":
		boundary := params["boundary"]
		if boundary == "" {
			return nil, bad("missing multipart boundary")
		}
		return decodeMultipart(r, boundary, cfg)
	default:
		return nil, bad("unsupported content-type")
	}
}

func readBounded(r io.Reader, max int64) ([]byte, bool, error) {
	lr := &io.LimitedReader{R: r, N: max + 1}
	b, err := io.ReadAll(lr)
	return b, int64(len(b)) > max, err
}

func decodeOrdinary(r *http.Request, cfg limits.Config) (*Decoded, *wire.EdgeError) {
	b, over, err := readBounded(r.Body, cfg.OrdinaryBodyBytes)
	if err != nil {
		return nil, bad("body read failed")
	}
	if over {
		return nil, tooLarge("request_too_large", "ordinary body limit")
	}
	vals, err := url.ParseQuery(string(b))
	if err != nil {
		return nil, bad("invalid form encoding")
	}
	payloads := vals["payload"]
	if len(payloads) != 1 || len(vals) != 1 {
		return nil, bad("exactly one payload field required")
	}
	obj, err := decodeJSONObject([]byte(payloads[0]), cfg.JSONDepth, cfg.JSONNodes)
	if err != nil {
		return nil, bad("invalid JSON payload")
	}
	mid, ok := numericMID(obj["mid"])
	if !ok {
		return nil, bad("numeric mid required")
	}
	if d, known := mids.Lookup(mid); known && (d.Transport != mids.HTTP || d.Encoding != mids.Ordinary) {
		return nil, bad("MID illegal for ordinary encoding")
	}
	return &Decoded{MID: mid, Params: obj, Encoding: wire.EncodingOrdinaryForm, RawBytes: int64(len(b)), RawSHA256: sha256.Sum256(b)}, nil
}

type multipartCapture struct {
	fields    map[string][]string
	file      *Upload
	zlibBytes []byte
	partCount int
	rawBytes  int64
	rawSHA256 [32]byte
}

func decodeMultipart(r *http.Request, boundary string, cfg limits.Config) (*Decoded, *wire.EdgeError) {
	// Total upload cap is the largest multipart family cap. Family-specific caps
	// are then applied before any decoded payload can reach dispatch.
	lr := &io.LimitedReader{R: r.Body, N: cfg.UploadBodyBytes + 1}
	h := sha256.New()
	tee := io.TeeReader(lr, h)
	mr := multipart.NewReader(tee, boundary)
	cap := multipartCapture{fields: make(map[string][]string)}

	for {
		p, err := mr.NextPart()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			cleanupCapture(&cap)
			return nil, bad("malformed multipart")
		}
		cap.partCount++
		if cap.partCount > cfg.MultipartParts {
			_ = p.Close()
			cleanupCapture(&cap)
			return nil, tooLarge("too_many_parts", "multipart part limit")
		}
		name := p.FormName()
		if name == "" {
			_ = p.Close()
			cleanupCapture(&cap)
			return nil, bad("multipart part missing name")
		}
		if p.FileName() != "" {
			if cap.file != nil {
				_ = p.Close()
				cleanupCapture(&cap)
				return nil, bad("exactly one upload file allowed")
			}
			u, ee := spoolUploadPart(p, name, cfg.UploadFileBytes)
			_ = p.Close()
			if ee != nil {
				cleanupCapture(&cap)
				return nil, ee
			}
			cap.file = u
			continue
		}
		if name == "payload" && cap.file == nil && len(cap.fields) == 0 && cap.zlibBytes == nil {
			b, over, e := readBounded(p, cfg.CompressedBytes)
			_ = p.Close()
			if e != nil {
				cleanupCapture(&cap)
				return nil, bad("multipart payload read failed")
			}
			if over {
				cleanupCapture(&cap)
				return nil, tooLarge("compressed_too_large", "compressed payload limit")
			}
			cap.zlibBytes = b
			continue
		}
		b, over, e := readBounded(p, cfg.FieldBytes)
		_ = p.Close()
		if e != nil {
			cleanupCapture(&cap)
			return nil, bad("multipart field read failed")
		}
		if over {
			cleanupCapture(&cap)
			return nil, tooLarge("field_too_large", "multipart field limit")
		}
		cap.fields[name] = append(cap.fields[name], string(b))
	}

	// Drain any epilogue so the hard total-body cap is actually enforced.
	_, _ = io.Copy(io.Discard, tee)
	if lr.N <= 0 {
		cleanupCapture(&cap)
		return nil, tooLarge("request_too_large", "multipart total body limit")
	}
	cap.rawBytes = cfg.UploadBodyBytes + 1 - lr.N
	copy(cap.rawSHA256[:], h.Sum(nil))

	if cap.zlibBytes != nil {
		if cap.file != nil || len(cap.fields) != 0 || cap.partCount != 1 {
			cleanupCapture(&cap)
			return nil, bad("zlib family requires exactly one payload part")
		}
		return decodeZlibCapture(&cap, cfg)
	}
	return decodeUploadCapture(&cap)
}

func spoolUploadPart(p *multipart.Part, field string, max int64) (*Upload, *wire.EdgeError) {
	f, err := os.CreateTemp("", "gxb-upload-*")
	if err != nil {
		return nil, wire.NewError(wire.ErrInternal, http.StatusInternalServerError, "upload_spool", "cannot create bounded upload spool")
	}
	path := f.Name()
	h := sha256.New()
	lr := &io.LimitedReader{R: p, N: max + 1}
	n, copyErr := io.Copy(io.MultiWriter(f, h), lr)
	closeErr := f.Close()
	if copyErr != nil || closeErr != nil {
		_ = os.Remove(path)
		return nil, wire.NewError(wire.ErrInternal, http.StatusInternalServerError, "upload_spool", "cannot write upload spool")
	}
	if n > max {
		_ = os.Remove(path)
		return nil, tooLarge("upload_too_large", "upload file limit")
	}
	var sum [32]byte
	copy(sum[:], h.Sum(nil))
	return &Upload{FieldName: field, Filename: p.FileName(), ContentType: p.Header.Get("Content-Type"), TempPath: path, Size: n, SHA256: sum}, nil
}

func decodeZlibCapture(cap *multipartCapture, cfg limits.Config) (*Decoded, *wire.EdgeError) {
	if cap.rawBytes > cfg.MultipartBodyBytes {
		return nil, tooLarge("request_too_large", "zlib multipart total body limit")
	}
	zr, err := zlib.NewReader(bytes.NewReader(cap.zlibBytes))
	if err != nil {
		return nil, bad("invalid zlib payload")
	}
	inflated, over, readErr := readBounded(zr, cfg.InflatedBytes)
	closeErr := zr.Close()
	if readErr != nil || closeErr != nil {
		return nil, bad("zlib inflate failed")
	}
	if over {
		return nil, tooLarge("inflated_too_large", "inflated payload limit")
	}
	if len(cap.zlibBytes) > 0 && int64(len(inflated)) > int64(len(cap.zlibBytes))*cfg.MaxInflateRatio {
		return nil, tooLarge("inflate_ratio", "inflate ratio limit")
	}
	obj, err := decodeJSONObject(inflated, cfg.JSONDepth, cfg.JSONNodes)
	if err != nil {
		return nil, bad("invalid inflated JSON")
	}
	mid, ok := numericMID(obj["mid"])
	if !ok {
		return nil, bad("numeric mid required")
	}
	if !mids.IsZlibMID(mid) {
		return nil, bad("MID illegal for zlib encoding")
	}
	return &Decoded{MID: mid, Params: obj, Encoding: wire.EncodingZlibMultipart, RawBytes: cap.rawBytes, RawSHA256: cap.rawSHA256}, nil
}

func decodeUploadCapture(cap *multipartCapture) (*Decoded, *wire.EdgeError) {
	if cap.file == nil {
		return nil, bad("multipart request is neither zlib payload nor upload")
	}
	defer func() {
		// Ownership transfers only on successful return; caller cleans it then.
	}()
	for k, vs := range cap.fields {
		if len(vs) <= 1 {
			continue
		}
		switch k {
		case "mid", "token", "region", "v_":
			for _, v := range vs[1:] {
				if v != vs[0] {
					cleanupCapture(cap)
					return nil, bad("conflicting source-shaped duplicate field " + k)
				}
			}
		default:
			cleanupCapture(cap)
			return nil, bad("duplicate upload field " + k)
		}
	}
	one := func(k string) (string, bool) {
		vs := cap.fields[k]
		if len(vs) == 0 {
			return "", false
		}
		return vs[0], true
	}
	midText, ok := one("mid")
	if !ok {
		cleanupCapture(cap)
		return nil, bad("upload mid required")
	}
	n, err := strconv.ParseUint(midText, 10, 16)
	if err != nil || uint16(n) != mids.MIDUploadSpaceAvatar {
		cleanupCapture(cap)
		return nil, bad("upload route requires MID1844")
	}
	formName, ok := one("form_name")
	if !ok || formName == "" || formName != cap.file.FieldName {
		cleanupCapture(cap)
		return nil, bad("upload form_name must match file part name")
	}
	params := make(map[string]any, len(cap.fields))
	for k, vs := range cap.fields {
		if len(vs) != 0 {
			params[k] = vs[0]
		}
	}
	params["mid"] = json.Number(midText)
	return &Decoded{MID: mids.MIDUploadSpaceAvatar, Params: params, Encoding: wire.EncodingUploadMultipart, RawBytes: cap.rawBytes, RawSHA256: cap.rawSHA256, Upload: cap.file}, nil
}

func cleanupCapture(cap *multipartCapture) {
	if cap.file != nil && cap.file.TempPath != "" {
		_ = os.Remove(cap.file.TempPath)
	}
}

func bad(detail string) *wire.EdgeError {
	return wire.NewError(wire.ErrMalformed, http.StatusBadRequest, "bad_request", detail)
}
func tooLarge(code, detail string) *wire.EdgeError {
	return wire.NewError(wire.ErrTooLarge, http.StatusRequestEntityTooLarge, code, detail)
}

func uploadDigestString(u *Upload) string {
	if u == nil {
		return ""
	}
	return fmt.Sprintf("%s:%d", hex.EncodeToString(u.SHA256[:]), u.Size)
}
