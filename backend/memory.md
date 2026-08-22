# Current memory — Pass89.0

Canonical implementation: `gxb-backend-v0.10.2-pass89.0`. Pass88 direct-Crystal UoW settlement remains unchanged. Pass89 adds the source-confirmed MID2 OTA deployment of a narrow purchase bridge and hardens legacy sandbox token use. The OTA bridge uses the current logged-in `xyd.Backend.get().token_` and `region_`, returns/injects the committed MID36857 completion, and falls through to original native purchase code for every unsupported SKU.

Runtime gate: start the backend, cold-start the client, observe MID2 advertising resource version 1.631.3, download/unzip/restart, then tap a direct Crystal pack on a fresh account and verify correct player/VIP progression.
