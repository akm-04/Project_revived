package wire

import (
	"crypto/sha256"
	"encoding/hex"
	"time"

	"gxb.local/backend/v2/internal/foundation/operation"
)

type Transport string

const (
	TransportHTTP Transport = "HTTP"
	TransportTCP  Transport = "TCP_REALTIME"
)

type Direction string

const (
	DirectionC2S           Direction = "CLIENT_TO_SERVER"
	DirectionS2C           Direction = "SERVER_TO_CLIENT"
	DirectionBidirectional Direction = "BIDIRECTIONAL"
	DirectionUnknown       Direction = "UNCLASSIFIED"
)

type Encoding string

const (
	EncodingOrdinaryForm    Encoding = "URLENCODED_JSON_FORM"
	EncodingZlibMultipart   Encoding = "ZLIB_MULTIPART"
	EncodingUploadMultipart Encoding = "UPLOAD_MULTIPART"
	EncodingAMF3            Encoding = "AMF3"
	EncodingUnknown         Encoding = "UNCLASSIFIED"
)

type CredentialClaims struct {
	Token  string
	Region int64
}

type RequestEnvelope struct {
	Operation       operation.Context
	MID             uint16
	Transport       Transport
	Direction       Direction
	Encoding        Encoding
	ReceivedAt      time.Time
	RawBytes        int64
	RawSHA256       [32]byte
	Params          map[string]any
	Claims          CredentialClaims
	CatalogRevision string
	RemoteLabel     string
}

func HashBytes(b []byte) [32]byte { return sha256.Sum256(b) }
func HashHex(h [32]byte) string   { return hex.EncodeToString(h[:]) }
