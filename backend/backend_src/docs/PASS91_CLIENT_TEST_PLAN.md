# Pass91.0 Client Test Plan

1. Start `gxb-backend-v0.11.0-pass91.0` with the same Pass89 OTA client state.
2. Log into a fresh/recent VIP account that has reached at least VIP1. On MID1, inspect `detail[17].vip_awards`; it should be a 15-entry 0/1 array rather than `[]`.
3. Open the Recharge/VIP window. The one-time VIP gift button/red point for an eligible unclaimed tier should be visible.
4. Claim VIP1. The client should receive MID657 success, show the normal award UI, add the listed Backpack items, and increase Crystal by 5.
5. Re-open the VIP window. VIP1 should display as claimed.
6. Restart both client and backend, log in again, and confirm VIP1 remains claimed. Crystal/items must persist.
7. Attempt to claim VIP1 again (normally or through a proxy). It must grant nothing a second time.
8. On a high-VIP account, claim a representative unclaimed higher tier (VIP15 is useful): verify its full gift and +700 Crystal, then restart and confirm persistence.
9. If possible, attempt to claim a tier above the account's current VIP; the server must reject it and state must remain unchanged.
10. Preserve `server.txt`, client logs, and the resulting player JSON if the award popup, claim marker, Crystal, or item quantities diverge.

MID116 is deliberately outside this smoke.
