"""Authenticated transient realtime transport foundation."""

from .admission import RealtimeRoomAdmissionPolicy, RealtimeRoomDirectory, SERVICE_ROOM_ID
from .codec import (
    AMF3_UNDEFINED,
    FRAME_HEADER_LENGTH,
    MAX_PAYLOAD_LENGTH,
    FrameTooLarge,
    MalformedAmf3,
    MalformedFrame,
    RealtimeCodecError,
    RealtimeFrame,
    RealtimeFrameEncoder,
    RealtimeFrameStreamDecoder,
    UnsupportedAmf3,
    XinyoudiAmf3Codec,
)
from .contracts import (
    AuthenticatedPlayerIdentity,
    PlayerAudience,
    RealtimeEventIntent,
    RealtimeRole,
    RoomAdmission,
    RoomAudience,
    SessionAudience,
)
from .publisher import (
    POST_COMMIT_TOPIC,
    RealtimeEventSchemaRegistry,
    RealtimeIntentStager,
    RealtimeNoticeSchema,
    RealtimePublicationError,
    RealtimePublishReport,
    TypedRealtimeEventPublisher,
)
from .runtime import RealtimeRuntime
from .server import RealtimeServer
from .session import AuthenticatedRealtimeSessionRegistry, RealtimeSession

__all__ = [
    "AMF3_UNDEFINED",
    "FRAME_HEADER_LENGTH",
    "MAX_PAYLOAD_LENGTH",
    "POST_COMMIT_TOPIC",
    "AuthenticatedPlayerIdentity",
    "AuthenticatedRealtimeSessionRegistry",
    "FrameTooLarge",
    "MalformedAmf3",
    "MalformedFrame",
    "PlayerAudience",
    "RealtimeCodecError",
    "RealtimeEventIntent",
    "RealtimeEventSchemaRegistry",
    "RealtimeFrame",
    "RealtimeFrameEncoder",
    "RealtimeFrameStreamDecoder",
    "RealtimeIntentStager",
    "RealtimeNoticeSchema",
    "RealtimePublicationError",
    "RealtimePublishReport",
    "RealtimeRole",
    "RealtimeRoomAdmissionPolicy",
    "RealtimeRoomDirectory",
    "RealtimeRuntime",
    "RealtimeServer",
    "RealtimeSession",
    "RoomAdmission",
    "RoomAudience",
    "SERVICE_ROOM_ID",
    "SessionAudience",
    "TypedRealtimeEventPublisher",
    "UnsupportedAmf3",
    "XinyoudiAmf3Codec",
]
