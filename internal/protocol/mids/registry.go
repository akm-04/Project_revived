package mids

import "sort"

type Transport string
type Direction string
type Encoding string
type Status string

const (
	HTTP                  Transport = "HTTP_API"
	TCP                   Transport = "TCP_REALTIME"
	GM                    Transport = "GM_OTHER"
	UnclassifiedTransport Transport = "UNCLASSIFIED"

	C2S              Direction = "CLIENT_TO_SERVER"
	S2C              Direction = "SERVER_TO_CLIENT"
	UnknownDirection Direction = "UNCLASSIFIED"

	Ordinary        Encoding = "URLENCODED_JSON_FORM"
	ZlibMultipart   Encoding = "ZLIB_MULTIPART"
	UploadMultipart Encoding = "UPLOAD_MULTIPART"
	AMF3            Encoding = "AMF3"
	UnknownEncoding Encoding = "UNCLASSIFIED"

	KnownUnresearched       Status = "KNOWN_SYMBOL_UNRESEARCHED"
	ResearchedUnimplemented Status = "RESEARCHED_UNIMPLEMENTED"
	ProtocolImplemented     Status = "PROTOCOL_IMPLEMENTED_DOMAIN_UNBOUND"
)

const (
	MIDTCPLogin          uint16 = 32771
	MIDChatRoomEntered   uint16 = 32779
	MIDSocketHeartbeat   uint16 = 32797
	MIDUploadSpaceAvatar uint16 = 1844
	// MID2 and MID20480 are source-proven UpdateScene HTTP-plane numbers.
	// They intentionally do not appear in app/common/network/mid.lua.
	MIDVersionCheck    uint16 = 2
	MIDCenterDiscovery uint16 = 20480
)

var sourcePlaneAliases = map[uint16][]string{
	MIDVersionCheck:    {"UPDATE_VERSION_CHECK"},
	MIDCenterDiscovery: {"CENTER_DISCOVERY"},
}

var zlibMIDs = map[uint16]struct{}{279: {}, 2484: {}, 535: {}, 774: {}, 1412: {}, 1570: {}, 2515: {}}

type Descriptor struct {
	MID       uint16
	Aliases   []string
	Transport Transport
	Direction Direction
	Encoding  Encoding
	Status    Status
}

func IsRealtimeNumber(mid uint16) bool { return (mid & 0x9000) == 0x8000 }
func IsGMNumber(mid uint16) bool       { return (mid & 0x9000) == 0x9000 }
func IsZlibMID(mid uint16) bool        { _, ok := zlibMIDs[mid]; return ok }

func Lookup(mid uint16) (Descriptor, bool) {
	aliases, ok := sourceAliases[mid]
	if !ok {
		aliases, ok = sourcePlaneAliases[mid]
	}
	if !ok {
		return Descriptor{}, false
	}
	d := Descriptor{MID: mid, Aliases: append([]string(nil), aliases...), Status: KnownUnresearched, Direction: C2S}
	switch {
	case IsGMNumber(mid):
		d.Transport = GM
		d.Encoding = UnknownEncoding
	case IsRealtimeNumber(mid):
		d.Transport = TCP
		d.Encoding = AMF3
		d.Status = ResearchedUnimplemented
	case mid == MIDUploadSpaceAvatar:
		d.Transport = HTTP
		d.Encoding = UploadMultipart
		d.Status = ResearchedUnimplemented
	case IsZlibMID(mid):
		d.Transport = HTTP
		d.Encoding = ZlibMultipart
		d.Status = ResearchedUnimplemented
	default:
		d.Transport = HTTP
		d.Encoding = Ordinary
	}
	switch mid {
	case MIDTCPLogin, MIDSocketHeartbeat:
		d.Direction = C2S
		d.Status = ProtocolImplemented
	case MIDChatRoomEntered:
		d.Direction = S2C
		d.Status = ProtocolImplemented
	}
	return d, true
}

func Known(mid uint16) bool { _, ok := Lookup(mid); return ok }
func Aliases(mid uint16) []string {
	d, ok := Lookup(mid)
	if !ok {
		return nil
	}
	return append([]string(nil), d.Aliases...)
}
func Numbers() []uint16 {
	out := make([]uint16, 0, len(sourceAliases)+len(sourcePlaneAliases))
	for n := range sourceAliases {
		out = append(out, n)
	}
	for n := range sourcePlaneAliases {
		out = append(out, n)
	}
	sort.Slice(out, func(i, j int) bool { return out[i] < out[j] })
	return out
}
func CatalogRevision() string { return "src64-midlua-sha256:" + CurrentSourceSHA256 }
