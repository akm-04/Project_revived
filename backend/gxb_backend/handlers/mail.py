"""Mailbox handlers for lobby/common windows."""

from __future__ import annotations

from .context import HandlerContext


class MailHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_mail_list(self, req: dict) -> dict:
        return self.ctx.state.get_player().mail_payload()

    def set_mail_read(self, req: dict) -> dict:
        mail_id = req.get("mail_id") or req.get("mail_ids")
        player = self.ctx.state.get_player()
        ids = set(mail_id if isinstance(mail_id, list) else [mail_id])
        for mail in player.mails:
            if not ids or mail.get("mail_id") in ids or str(mail.get("mail_id")) in {str(x) for x in ids}:
                mail["is_read"] = 1
        self.ctx.state.save()
        return {}

    def mail_onekey(self, req: dict) -> dict:
        # The client generally expects success plus optional awards. Keep all mail
        # but mark as read/claimed to avoid mutating away data during exploration.
        for mail in self.ctx.state.get_player().mails:
            mail["is_read"] = 1
            mail["is_awarded"] = 1
        self.ctx.state.save()
        return {"awards": []}
