"""Canonical CHILD/SUBRESOURCE locks for relational mail."""
from __future__ import annotations

from sqlalchemy import select

from gxb_backend.foundation.resource_keys import ResourceClass, ResourceKey
from gxb_backend.transactions.locking import ResourceLockRegistry
from .models import MailAddress
from .schema import mail_items


def mail_resource(player_id: int | str, address: MailAddress) -> ResourceKey:
    return ResourceKey.of(
        ResourceClass.CHILD,
        "mail_item",
        int(player_id),
        1 if address.is_region else 0,
        int(address.protocol_mail_id),
    )


def register_i6_mail_lockers(registry: ResourceLockRegistry) -> ResourceLockRegistry:
    def lock_mail_item(connection, resource: ResourceKey) -> None:
        if len(resource.identity) != 3:
            raise ValueError("mail_item requires player_id,is_region,protocol_mail_id")
        player_id, is_region, protocol_mail_id = resource.identity
        connection.execute(
            select(mail_items.c.mail_row_id)
            .where(
                mail_items.c.player_id == int(player_id),
                mail_items.c.is_region == bool(int(is_region)),
                mail_items.c.protocol_mail_id == int(protocol_mail_id),
            )
            .with_for_update()
        ).first()
    registry.register(ResourceClass.CHILD, "mail_item", lock_mail_item)
    return registry
