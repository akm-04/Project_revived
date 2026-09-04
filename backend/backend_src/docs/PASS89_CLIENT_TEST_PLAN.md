# Pass 89.0 Client Test Plan

## OTA install

1. Start the Pass89 backend normally.
2. Confirm startup prints `LOCAL_UPDATE = enabled target=1.631.3 volumes=1 silent=True`.
3. Fully close and cold-start the game client.
4. On the first startup, server logs should show MID2 advertising resource version `1.631.3` and a request for `/updates/gxb-local-1.631.3.zip.001`.
5. The client should download, MD5-verify, unzip to its normal update path, and restart automatically. No emulator filesystem editing is required.
6. On the restarted client, MID2 should contain `v=1.631.3`; the backend should no longer advertise the same package.

## Purchase smoke — fresh account strongly recommended

1. Log into the new VIP0 account normally.
2. Open Recharge and verify MID354 still exposes the seven direct Crystal packs.
3. Tap the 100-Crystal direct pack (`80001007`) in the UI. Do **not** run cURL.
4. Server output should include `[COMMERCE AUTH]` with the new account uid/player id/region and `legacy=0`, followed by a COMMITTED purchase.
5. The client should show its normal recharge-success behavior and immediately update Crystal/VIP/charge through `SelfPlayer:onRecharge_()`.
6. On the first 100-Crystal purchase expect `+200` Crystal (100 base + 100 first-buy bonus), cumulative `charge=100`, and VIP1.
7. Tap the same pack again. Expect `+100` Crystal, `charge=200`, still VIP1.
8. Tap it a third time. Expect `+100` Crystal, `charge=300`, reaching VIP2.
9. Close/restart the client and verify Crystal/VIP/charge and MID354 `charge_count` persist.

## Token safety smoke

A copied legacy cURL containing `token=local_token` should now receive HTTP 409 `LEGACY_SANDBOX_EXPLICIT_OPT_IN_REQUIRED`; this is intentional. The OTA client does not need manual tokens: it uses the active login token automatically.

If a manual preservation test is ever intentionally run against the legacy sandbox, it must explicitly include `allow_legacy_sandbox=1` and should include `expected_player_id=12525385`.

## Capture on failure

Preserve `server.txt`, `all_requests.jsonl`, any client error upload, and note whether the client downloaded/restarted at resource version `1.631.3`. Do not advance into MID657 or MID116 until the OTA tap-to-purchase path is reconciled.
