# External oracles

Large source/client/V1 archives are intentionally **not copied into the V2 repository**. `oracles.lock.json` pins their transport hashes and roles. Run `tools/verify_oracles.py --root <attachment-dir>` before each implementation wave that consumes them. Treat them read-only.
