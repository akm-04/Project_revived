"""Atomic relational mail claim orchestration for I6."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Protocol, Sequence

from gxb_backend.foundation.contracts import TransactionRequest
from gxb_backend.persistence.locking import player_state_resource
from gxb_backend.transactions.coordinator import ResourceTransactionCoordinator, SqlAlchemyResourceTransaction
from gxb_backend.transactions.errors import ReceiptReplayConflict
from gxb_backend.transactions.models import ReceiptKey
from gxb_backend.transactions.receipts import ReceiptRepository, canonical_request_fingerprint

from .locking import mail_resource
from .models import MailAddress, MailRecord
from .repository import MailRepository


class MailAttachmentSettlement(Protocol):
    """Adapter implemented with existing RewardTransactionService/player sub-UoW.

    I6 intentionally does not guess the protocol attachment encoding.  The
    adapter owns conversion to typed RewardPlan and returns wire award rows.
    """
    def settle(self, transaction: SqlAlchemyResourceTransaction, mail: MailRecord) -> Sequence[dict[str, Any]]: ...


class MailNotFound(LookupError): pass
class MailAlreadyClaimed(RuntimeError): pass
class MailExpired(RuntimeError): pass


@dataclass(frozen=True)
class MailClaimResult:
    claimed: tuple[MailAddress, ...]
    awards: tuple[dict[str, Any], ...]


class MailClaimService:
    def __init__(
        self,
        coordinator: ResourceTransactionCoordinator,
        repository: MailRepository,
        settlement: MailAttachmentSettlement,
        receipts: ReceiptRepository | None = None,
    ) -> None:
        self.coordinator = coordinator
        self.repository = repository
        self.settlement = settlement
        self.receipts = receipts or ReceiptRepository()

    def claim_one(self, *, player_id: int, address: MailAddress, request_id: str, client_operation_id: str | None = None) -> MailClaimResult:
        return self.claim_many(
            player_id=player_id,
            addresses=(address,),
            request_id=request_id,
            client_operation_id=client_operation_id,
        )

    def claim_many(self, *, player_id: int, addresses: Sequence[MailAddress], request_id: str, client_operation_id: str | None = None) -> MailClaimResult:
        ordered = tuple(sorted(set(addresses)))
        resources = (player_state_resource(player_id), *(mail_resource(player_id, x) for x in ordered))
        request = TransactionRequest(
            request_id=str(request_id),
            operation_name="mail.claim",
            resources=resources,
            client_operation_id=client_operation_id,
            retry_safe=True,
        )

        receipt_key = ReceiptKey(
            resource_kind="player",
            resource_key=str(int(player_id)),
            domain="mail",
            operation="claim",
            idempotency_key=str(client_operation_id or request_id),
        )
        fingerprint = canonical_request_fingerprint(
            {
                "player_id": int(player_id),
                "addresses": [
                    {"is_region": bool(address.is_region), "id": int(address.protocol_mail_id)}
                    for address in ordered
                ],
            }
        )

        def result_from_receipt(value: dict[str, Any]) -> MailClaimResult:
            claimed = tuple(
                MailAddress(bool(item["is_region"]), int(item["id"]))
                for item in value.get("claimed", ())
            )
            awards = tuple(dict(item) for item in value.get("awards", ()))
            return MailClaimResult(claimed, awards)

        def operation(tx: SqlAlchemyResourceTransaction) -> MailClaimResult:
            existing = self.receipts.get(tx.connection, receipt_key)
            if existing is not None:
                if existing.request_fingerprint != fingerprint.hex():
                    raise ReceiptReplayConflict(receipt_key.scope)
                return result_from_receipt(dict(existing.result))

            awards: list[dict[str, Any]] = []
            claimed: list[MailAddress] = []
            for address in ordered:
                row, db_now = self.repository.load_locked(tx.connection, int(player_id), address)
                if row is None:
                    raise MailNotFound(f"{int(address.is_region)}:{address.protocol_mail_id}")
                if row.claimed_at is not None:
                    raise MailAlreadyClaimed(f"{int(address.is_region)}:{address.protocol_mail_id}")
                if row.expires_at is not None and db_now is not None and row.expires_at <= db_now:
                    raise MailExpired(f"{int(address.is_region)}:{address.protocol_mail_id}")
                awards.extend(dict(x) for x in self.settlement.settle(tx, row))
                if not self.repository.mark_claimed(tx.connection, row.mail_row_id):
                    raise MailAlreadyClaimed(f"{int(address.is_region)}:{address.protocol_mail_id}")
                claimed.append(address)

            semantic_result = {
                "claimed": [
                    {"is_region": bool(address.is_region), "id": int(address.protocol_mail_id)}
                    for address in claimed
                ],
                "awards": [dict(item) for item in awards],
            }
            receipt, replayed = self.receipts.record_or_replay(
                tx.connection,
                key=receipt_key,
                request_fingerprint=fingerprint,
                result=semantic_result,
                retention_policy="MAIL_CLAIM",
            )
            if replayed:
                # Same-player/mail resources are already locked by the outer
                # ResourceTransaction, so this can only be an idempotent
                # convergence path. Return the committed semantic receipt.
                return result_from_receipt(dict(receipt.result))
            return MailClaimResult(tuple(claimed), tuple(awards))

        return self.coordinator.run(request, operation)

class MailDeliveryService:
    """Create canonical mail first; optional notification is staged only on first insert."""
    def __init__(self, repository: MailRepository) -> None:
        self.repository = repository

    def deliver(self, transaction: SqlAlchemyResourceTransaction, intent, *, notification=None):
        record, duplicate = self.repository.deliver(transaction.connection, intent)
        if notification is not None and not duplicate:
            transaction.stage_outbox(notification)
        return record, duplicate
