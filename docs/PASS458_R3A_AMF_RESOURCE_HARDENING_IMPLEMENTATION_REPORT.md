# Pass458 R3A AMF Resource Hardening Implementation Report

## Scope
R3A repairs RF-008 only. It preserves the recovered Xinyoudi/stock wire profile while bounding decode allocation and encode output/recursion/reference work.

## Implemented
- trait sealed-count validation before allocation/read; unsupported sealed/non-dynamic traits fail before sealed-name allocation.
- finite encode output/depth/node/property/array/string/reference budgets.
- deterministic cycle rejection for supported Go containers.
- symmetric exact IEEE-754 integer policy for signed/unsigned inputs.
- native frame encode path accepts explicit limits and cannot exceed NativeFramePayloadMax.
- existing default Encode/EncodeFrame APIs remain stock-safe wrappers.

## Local evidence
Disposable Go 1.23 clone only: repository-wide tests/vet, targeted race, existing golden/differential tests, and short fuzz campaigns for Decode/Encode/StreamDecoder. Canonical go.mod remains go 1.26.0 / toolchain go1.27.1.

## Deferred live evidence
R7 retains load/resource-pressure and final stock-wire/live regression gates. R3A does not claim client acceptance.
