"""SDK account/session identity.

The native SDK code observed in project history populates UserSession from
HTTP cookies QQWSID/QQWUID/QQWUNAME/QQWTOKEN. Keep these values deterministic
for the local Stage 1 server.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class AccountIdentity:
    uid: str = "13371337"
    sid: str = "13371337"
    token: str = "local_token"
    username: str = "AdminRoot"

    def sdk_json(self) -> dict:
        return {
            "uid": self.uid,
            "sid": self.sid,
            "access_token": self.token,
            "token": self.token,
            "username": self.username,
            "nickname": self.username,
            "is_new": 0,
            "UID": self.uid,
            "SID": self.sid,
            "UNAME": self.username,
            "TOKEN": self.token,
        }

    def cookies(self) -> dict[str, str]:
        return {
            "QQWSID": self.sid,
            "QQWUID": self.uid,
            "QQWUNAME": self.username,
            "QQWTOKEN": self.token,
        }
