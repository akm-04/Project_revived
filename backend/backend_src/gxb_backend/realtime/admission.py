"""Pure room-role admission rules plus authenticated HTTP room discovery."""

from __future__ import annotations

from dataclasses import dataclass

from .contracts import AuthenticatedPlayerIdentity, RealtimeRole, RoomAdmission


SERVICE_ROOM_ID = 99_999


class RealtimeRoomAdmissionPolicy:
    def classify(self, identity: AuthenticatedPlayerIdentity, room_id: int) -> RoomAdmission | None:
        try:
            room = int(room_id)
        except (TypeError, ValueError):
            return None
        if room <= 0:
            return None
        if room == SERVICE_ROOM_ID:
            return RoomAdmission(RealtimeRole.SERVICE, room)
        if room == int(identity.region):
            return RoomAdmission(RealtimeRole.WORLD, room)
        if int(identity.guild_id) > 0 and room == int(identity.guild_id):
            return RoomAdmission(RealtimeRole.GUILD, room)
        return None


@dataclass(frozen=True, slots=True)
class RealtimeRoomDirectory:
    """Read-only HTTP discovery facade over the same TCP admission policy."""

    host: str
    port: int
    admission_policy: RealtimeRoomAdmissionPolicy

    def describe(
        self,
        identity: AuthenticatedPlayerIdentity | None,
        room_id: int,
    ) -> dict[str, object] | None:
        if identity is None:
            return None
        admission = self.admission_policy.classify(identity, room_id)
        if admission is None:
            return None
        return {
            "host": str(self.host),
            "port": int(self.port),
            "room_id": int(admission.room_id),
        }
