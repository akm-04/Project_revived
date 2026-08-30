"""Recovered Xinyoudi TCP frame and bounded AMF3 Params codec.

Wire authority (Pass259):
    u32_be payload_length | u16_be MID | u32_be sequence | AMF3 Params payload

Only the recovered AMF3 subset is accepted. Unsupported markers fail closed.
"""

from __future__ import annotations

from dataclasses import dataclass
import math
import struct
from typing import Any


MAX_PAYLOAD_LENGTH = 65_536
FRAME_HEADER_LENGTH = 10


class RealtimeCodecError(ValueError):
    pass


class FrameTooLarge(RealtimeCodecError):
    pass


class MalformedFrame(RealtimeCodecError):
    pass


class MalformedAmf3(RealtimeCodecError):
    pass


class UnsupportedAmf3(RealtimeCodecError):
    pass


@dataclass(frozen=True, slots=True)
class RealtimeFrame:
    mid: int
    sequence: int
    params: Any


class _Undefined:
    __slots__ = ()

    def __repr__(self) -> str:  # pragma: no cover - diagnostic only
        return "AMF3_UNDEFINED"


AMF3_UNDEFINED = _Undefined()


def _read_u29(data: bytes, offset: int) -> tuple[int, int]:
    value = 0
    for index in range(4):
        if offset >= len(data):
            raise MalformedAmf3("truncated U29")
        byte = data[offset]
        offset += 1
        if index < 3:
            value = (value << 7) | (byte & 0x7F)
            if (byte & 0x80) == 0:
                return value, offset
        else:
            value = (value << 8) | byte
            return value, offset
    raise MalformedAmf3("invalid U29")


def _write_u29(value: int) -> bytes:
    if not 0 <= value <= 0x1FFFFFFF:
        raise MalformedAmf3(f"U29 out of range: {value}")
    if value < 0x80:
        return bytes((value,))
    if value < 0x4000:
        return bytes(((value >> 7) | 0x80, value & 0x7F))
    if value < 0x200000:
        return bytes(((value >> 14) | 0x80, ((value >> 7) & 0x7F) | 0x80, value & 0x7F))
    return bytes(
        (
            ((value >> 22) & 0x7F) | 0x80,
            ((value >> 15) & 0x7F) | 0x80,
            ((value >> 8) & 0x7F) | 0x80,
            value & 0xFF,
        )
    )


class _Amf3Decoder:
    def __init__(self, data: bytes) -> None:
        self.data = data
        self.offset = 0
        self.strings: list[str] = []
        self.objects: list[Any] = []
        self.traits: list[tuple[str, tuple[str, ...], bool]] = []

    def _take(self, length: int) -> bytes:
        end = self.offset + length
        if length < 0 or end > len(self.data):
            raise MalformedAmf3("truncated AMF3 payload")
        out = self.data[self.offset:end]
        self.offset = end
        return out

    def _u29(self) -> int:
        value, self.offset = _read_u29(self.data, self.offset)
        return value

    def _string_no_marker(self) -> str:
        header = self._u29()
        if (header & 1) == 0:
            index = header >> 1
            try:
                return self.strings[index]
            except IndexError as exc:
                raise MalformedAmf3("invalid string reference") from exc
        length = header >> 1
        if length == 0:
            return ""
        raw = self._take(length)
        try:
            value = raw.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise MalformedAmf3("invalid UTF-8 string") from exc
        self.strings.append(value)
        return value

    def value(self) -> Any:
        if self.offset >= len(self.data):
            raise MalformedAmf3("missing AMF3 marker")
        marker = self.data[self.offset]
        self.offset += 1
        if marker == 0x00:
            return AMF3_UNDEFINED
        if marker == 0x01:
            return None
        if marker == 0x02:
            return False
        if marker == 0x03:
            return True
        if marker == 0x04:
            raw = self._u29()
            return raw - 0x20000000 if raw & 0x10000000 else raw
        if marker == 0x05:
            return struct.unpack(">d", self._take(8))[0]
        if marker == 0x06:
            return self._string_no_marker()
        if marker == 0x09:
            return self._array()
        if marker == 0x0A:
            return self._object()
        raise UnsupportedAmf3(f"unsupported AMF3 marker 0x{marker:02x}")

    def _array(self) -> Any:
        header = self._u29()
        if (header & 1) == 0:
            index = header >> 1
            try:
                return self.objects[index]
            except IndexError as exc:
                raise MalformedAmf3("invalid array reference") from exc
        dense_count = header >> 1
        # Recovered Xinyoudi Params arrays are modeled as ordered dense arrays.
        # Do not invent a Python representation for AMF3 associative arrays.
        holder: list[Any] = []
        self.objects.append(holder)
        first_key = self._string_no_marker()
        if first_key != "":
            raise UnsupportedAmf3("associative AMF3 arrays are outside the recovered subset")
        holder.extend(self.value() for _ in range(dense_count))
        return holder

    def _object(self) -> Any:
        header = self._u29()
        if (header & 1) == 0:
            index = header >> 1
            try:
                return self.objects[index]
            except IndexError as exc:
                raise MalformedAmf3("invalid object reference") from exc

        trait_info = header >> 1
        if (trait_info & 1) == 0:
            trait_index = trait_info >> 1
            try:
                class_name, sealed_names, dynamic = self.traits[trait_index]
            except IndexError as exc:
                raise MalformedAmf3("invalid trait reference") from exc
        else:
            externalizable = bool(trait_info & 0x02)
            dynamic = bool(trait_info & 0x04)
            sealed_count = trait_info >> 3
            if externalizable:
                raise UnsupportedAmf3("externalizable AMF3 objects are unsupported")
            class_name = self._string_no_marker()
            sealed_names = tuple(self._string_no_marker() for _ in range(sealed_count))
            if class_name or sealed_names or not dynamic:
                raise UnsupportedAmf3("only recovered dynamic anonymous AMF3 objects are supported")
            self.traits.append((class_name, sealed_names, dynamic))

        if class_name or sealed_names or not dynamic:
            raise UnsupportedAmf3("only recovered dynamic anonymous AMF3 objects are supported")
        obj: dict[str, Any] = {}
        self.objects.append(obj)
        for name in sealed_names:
            obj[name] = self.value()
        if dynamic:
            while True:
                key = self._string_no_marker()
                if key == "":
                    break
                obj[key] = self.value()
        return obj


class _Amf3Encoder:
    def __init__(self) -> None:
        self.strings: dict[str, int] = {}

    def _string_no_marker(self, value: str) -> bytes:
        if value == "":
            return b"\x01"
        index = self.strings.get(value)
        if index is not None:
            return _write_u29(index << 1)
        encoded = value.encode("utf-8")
        self.strings[value] = len(self.strings)
        return _write_u29((len(encoded) << 1) | 1) + encoded

    def value(self, value: Any) -> bytes:
        if value is AMF3_UNDEFINED:
            return b"\x00"
        if value is None:
            return b"\x01"
        if value is False:
            return b"\x02"
        if value is True:
            return b"\x03"
        # bool is an int subclass; test it first. Compatibility policy uses
        # double for ordinary Lua-semantic numbers unless a schema explicitly
        # supplies an integer-only value via encode_integer().
        if isinstance(value, (int, float)) and not isinstance(value, bool):
            number = float(value)
            if not math.isfinite(number):
                raise MalformedAmf3("non-finite AMF3 double")
            return b"\x05" + struct.pack(">d", number)
        if isinstance(value, str):
            return b"\x06" + self._string_no_marker(value)
        if isinstance(value, (list, tuple)):
            out = bytearray(b"\x09")
            out.extend(_write_u29((len(value) << 1) | 1))
            out.extend(b"\x01")  # end associative section
            for item in value:
                out.extend(self.value(item))
            return bytes(out)
        if isinstance(value, dict):
            out = bytearray(b"\x0a\x0b\x01")  # dynamic anonymous object
            for key, item in value.items():
                if not isinstance(key, str) or not key:
                    raise MalformedAmf3("dynamic object keys must be non-empty strings")
                out.extend(self._string_no_marker(key))
                out.extend(self.value(item))
            out.extend(b"\x01")
            return bytes(out)
        raise UnsupportedAmf3(f"unsupported Python value type {type(value).__name__}")

    def encode_integer(self, value: int) -> bytes:
        if not isinstance(value, int) or isinstance(value, bool) or not -(1 << 28) <= value < (1 << 28):
            raise MalformedAmf3("AMF3 integer outside signed 29-bit range")
        raw = value & 0x1FFFFFFF
        return b"\x04" + _write_u29(raw)


class XinyoudiAmf3Codec:
    """Bounded AMF3 codec for the native Xinyoudi Params subset."""

    @staticmethod
    def decode(data: bytes) -> Any:
        decoder = _Amf3Decoder(bytes(data))
        value = decoder.value()
        if decoder.offset != len(decoder.data):
            raise MalformedAmf3("trailing bytes after top-level AMF3 value")
        return value

    @staticmethod
    def encode(value: Any) -> bytes:
        return _Amf3Encoder().value(value)


class RealtimeFrameEncoder:
    def __init__(self, amf3: XinyoudiAmf3Codec | None = None) -> None:
        self.amf3 = amf3 or XinyoudiAmf3Codec()

    def encode(self, mid: int, params: Any, *, sequence: int = 0) -> bytes:
        try:
            mid_i = int(mid)
            seq_i = int(sequence)
        except (TypeError, ValueError) as exc:
            raise MalformedFrame("MID/sequence must be integers") from exc
        if not 0 <= mid_i <= 0xFFFF:
            raise MalformedFrame("MID outside u16 range")
        if not 0 <= seq_i <= 0xFFFFFFFF:
            raise MalformedFrame("sequence outside u32 range")
        payload = self.amf3.encode(params)
        if len(payload) > MAX_PAYLOAD_LENGTH:
            raise FrameTooLarge(f"payload {len(payload)} exceeds {MAX_PAYLOAD_LENGTH}")
        return struct.pack(">IHI", len(payload), mid_i, seq_i) + payload


class RealtimeFrameStreamDecoder:
    """Incrementally decode arbitrarily fragmented/coalesced TCP chunks."""

    def __init__(self, amf3: XinyoudiAmf3Codec | None = None) -> None:
        self.amf3 = amf3 or XinyoudiAmf3Codec()
        self._buffer = bytearray()

    @property
    def buffered_bytes(self) -> int:
        return len(self._buffer)

    def feed(self, chunk: bytes) -> list[RealtimeFrame]:
        if chunk:
            self._buffer.extend(chunk)
        frames: list[RealtimeFrame] = []
        while True:
            if len(self._buffer) < 4:
                break
            payload_length = struct.unpack(">I", self._buffer[:4])[0]
            if payload_length > MAX_PAYLOAD_LENGTH:
                raise FrameTooLarge(f"payload {payload_length} exceeds {MAX_PAYLOAD_LENGTH}")
            total = FRAME_HEADER_LENGTH + payload_length
            if len(self._buffer) < total:
                break
            header = bytes(self._buffer[:FRAME_HEADER_LENGTH])
            payload = bytes(self._buffer[FRAME_HEADER_LENGTH:total])
            del self._buffer[:total]
            _length, mid, sequence = struct.unpack(">IHI", header)
            params = self.amf3.decode(payload)
            frames.append(RealtimeFrame(mid=mid, sequence=sequence, params=params))
        return frames
