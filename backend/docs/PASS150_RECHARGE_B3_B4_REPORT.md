# Pass150 — Recharge Phase B3/B4/B5

## B3 source-native random Pack
Activated the sole recovered random page-2 Recharge Pack: `90002112 -> 90011123 -> dropbox 600002`.

Architecture:
- `RechargeGiftbagRandomOutcomeAdapter` binds the request-scoped `RandomOutcomeService` to namespace `recharge.giftbag`.
- Recharge owns source pool, ordered candidate rows, relative-weight semantics, validation, settlement and product history.
- All five possible reward plans are validated through canonical RewardTransaction owners before entropy.
- Settlement remains the existing permanent `commerce_purchase` receipt/outbox and one PlayerUnitOfWork.
- Replay outranks current availability and consumes no second entropy draw.

## B4 synthetic EOL catalog hooks
Added typed metadata/hooks for:
- 262 permanent-skin products: charge IDs `97000001..97000262`, gift IDs `97100001..97100262`, page 3.
- 10 elemental products: charge IDs `97002001..97002010`, gift IDs `97102001..97102010`, page 2.

These are intentionally NOT advertised by MID354 and NOT accepted by purchase authorization under OTA 1.631.8. Phase C will add matching client giftbag/gift rows and activate the server-side product settlement/visibility policy.

No OTA files were modified in Pass150.

## Phase-B gate
B1/B2/B3/B4 are static/regression accepted. Phase B backend architecture is closed. Next: Phase C OTA 1.631.9 and bounded activation of the synthetic EOL catalog; then Phase D client runtime closure.
