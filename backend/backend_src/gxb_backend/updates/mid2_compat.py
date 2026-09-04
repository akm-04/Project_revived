"""Stock-client MID2 numeric compatibility helpers.

The current Android 1.631.0 FileDownloader reports curl progress byte counters to
Lua through a 32-bit float bridge, while UpdateScene.lua persists each completed
volume's reported total and reuses the accumulated value as the next local file
offset.  The native download offset is a signed 32-bit integer.

This module is intentionally pure and transport-focused so both the operator
publisher and runtime scheduler validate the same client contract.  Future
client profiles can be added here without contaminating gameplay/domain state.
"""
from __future__ import annotations

import struct
from typing import Any, Iterable

CURRENT_STOCK_PROFILE = "android_app_v_1.631.0_current_native_f32_progress_int32_offset"
SIGNED_INT32_MAX = 2_147_483_647
FLOAT32_ALL_INTEGER_LIMIT = 1 << 24
# A comfortably sized tail that is still in the range where every integer is
# exactly representable by IEEE-754 binary32.  Adjusting it by a few bytes lets
# us make a large non-exact remainder's companion fragment float32-exact too.
FLOAT32_TAIL_ANCHOR = 1 << 23


def float32_reported_int(value: int) -> int:
    """Return the integer byte count the current native float32 bridge reports."""
    value = int(value)
    if value < 0:
        raise ValueError("MID2 byte count cannot be negative")
    reported = struct.unpack("<f", struct.pack("<f", float(value)))[0]
    # For the supported signed-int32 byte domain binary32 spacing is >= 1, so
    # a rounded integer byte count remains integral.
    if not reported.is_integer():
        raise ValueError(f"unexpected non-integral float32 byte count: {reported!r}")
    return int(reported)


def is_float32_exact_int(value: int) -> bool:
    value = int(value)
    return value >= 0 and float32_reported_int(value) == value


def largest_float32_exact_le(value: int) -> int:
    """Largest positive integer <= value that round-trips exactly via float32."""
    candidate = int(value)
    if candidate <= 0:
        raise ValueError("MID2 volume cap must be positive")
    # Below 2^31 the widest binary32 integer spacing is only 128 bytes, so this
    # loop is bounded to a tiny number of iterations in our supported domain.
    while candidate > 0 and not is_float32_exact_int(candidate):
        candidate -= 1
    if candidate <= 0:
        raise ValueError("no positive float32-exact MID2 fragment fits the cap")
    return candidate


def _split_nonexact_remainder(remainder: int, cap: int) -> list[int]:
    """Split one <=cap non-exact remainder into exact positive fragments.

    Any non-exact integer in this transport's range is >2^24.  Keep one tail
    around 8 MiB (where every integer is exact), adjusting it by only a few
    bytes until the large companion is also exact.  This avoids pathological
    one-byte final shards while keeping the number of HTTP volumes low.
    """
    remainder = int(remainder)
    cap = int(cap)
    if remainder <= 0 or remainder > cap:
        raise ValueError("non-exact remainder must be positive and <= cap")
    if is_float32_exact_int(remainder):
        return [remainder]
    if remainder <= FLOAT32_ALL_INTEGER_LIMIT:
        raise AssertionError("integers <=2^24 must be float32-exact")

    tail0 = min(FLOAT32_TAIL_ANCHOR, remainder - 1, cap)
    # At < 2^31, at most 127 bytes of adjustment can be necessary to align the
    # large companion to binary32's integer grid.  256 leaves explicit margin.
    for delta in range(256):
        tail = tail0 + delta
        head = remainder - tail
        if tail <= 0 or head <= 0 or tail > cap or head > cap:
            continue
        if is_float32_exact_int(tail) and is_float32_exact_int(head):
            return [head, tail]

    # Defensive exact fallback. This should be unreachable for our <=99 MB
    # profile, but preserves correctness if a future smaller/larger cap is used.
    pieces: list[int] = []
    left = remainder
    exact_chunk = min(FLOAT32_ALL_INTEGER_LIMIT, cap)
    if exact_chunk <= 0:
        raise ValueError("invalid fallback fragment cap")
    while left > exact_chunk:
        pieces.append(exact_chunk)
        left -= exact_chunk
    if left:
        pieces.append(left)
    if not all(0 < x <= cap and is_float32_exact_int(x) for x in pieces):
        raise ValueError(f"unable to construct float32-exact MID2 remainder plan for {remainder}")
    return pieces


def plan_volume_sizes(total_size: int, max_volume_bytes: int) -> list[int]:
    """Plan stock-client-safe raw .001..NNN fragment sizes.

    Guarantees:
    - every fragment is positive and <= configured cap;
    - every fragment is exactly represented by the current client's float32
      progress bridge;
    - exact and client-accounted sums equal total_size;
    - total/local assembly offsets stay within signed-int32 semantics.
    """
    total_size = int(total_size)
    cap = int(max_volume_bytes)
    if total_size <= 0:
        raise ValueError("assembled MID2 package must be non-empty")
    if cap <= 0:
        raise ValueError("MID2 volume cap must be positive")
    if total_size > SIGNED_INT32_MAX:
        raise ValueError(
            f"assembled MID2 package {total_size:,} exceeds current native signed-int32 "
            f"offset limit {SIGNED_INT32_MAX:,}"
        )

    safe_full = largest_float32_exact_le(cap)
    # Quotient/remainder planning avoids work proportional to byte size when an
    # operator deliberately chooses a very small cap.  Materializing the final
    # list is still naturally proportional to the advertised volume count.
    full_count, remaining = divmod(total_size, safe_full)
    sizes: list[int] = [safe_full] * full_count
    if remaining:
        if is_float32_exact_int(remaining):
            sizes.append(remaining)
        else:
            sizes.extend(_split_nonexact_remainder(remaining, cap))

    metrics = evaluate_volume_plan(sizes, total_size)
    if not metrics["volume_size_float32_exact"] or metrics["client_accounted_size"] != total_size:
        raise AssertionError("planner produced a stock-client-incompatible MID2 volume plan")
    return sizes


def evaluate_volume_plan(volume_sizes: Iterable[int], expected_size: int) -> dict[str, Any]:
    """Validate/evaluate actual or planned fragment sizes against stock client."""
    sizes = [int(v) for v in volume_sizes]
    expected_size = int(expected_size)
    if not sizes or any(v <= 0 for v in sizes):
        raise ValueError("MID2 release must contain positive non-empty volumes")
    exact_sum = sum(sizes)
    if exact_sum != expected_size:
        raise ValueError(
            f"MID2 exact fragment sum {exact_sum} differs from assembled descriptor size {expected_size}"
        )
    if expected_size > SIGNED_INT32_MAX:
        raise ValueError(
            f"MID2 assembled size {expected_size} exceeds current native signed-int32 limit {SIGNED_INT32_MAX}"
        )

    reported = [float32_reported_int(v) for v in sizes]
    all_exact = all(a == b for a, b in zip(sizes, reported))
    client_accounted = sum(reported)
    prefix = 0
    max_prefix = 0
    for size in sizes:
        max_prefix = max(max_prefix, prefix)
        if prefix > SIGNED_INT32_MAX:
            raise ValueError(f"MID2 local assembly prefix {prefix} exceeds signed-int32 limit")
        prefix += size
    if prefix != expected_size:
        raise AssertionError("prefix accounting diverged from exact fragment sum")
    if not all_exact:
        bad = [(i + 1, sizes[i], reported[i]) for i in range(len(sizes)) if sizes[i] != reported[i]]
        raise ValueError(f"MID2 volume size is not exact through current float32 progress bridge: {bad[:8]}")
    if client_accounted != expected_size:
        raise ValueError(
            f"MID2 stock-client accounted size {client_accounted} differs from descriptor size {expected_size}"
        )

    return {
        "client_compatibility_profile": CURRENT_STOCK_PROFILE,
        "volume_size_float32_exact": True,
        "client_accounted_size": client_accounted,
        "max_prefix_offset": max_prefix,
        "assembled_size_int32_safe": True,
    }


def validate_declared_metrics(declared: dict[str, Any], metrics: dict[str, Any]) -> None:
    """If a release declares compatibility metadata, require exact agreement."""
    if not isinstance(declared, dict):
        return
    profile = declared.get("client_compatibility_profile")
    if profile is not None and str(profile) != CURRENT_STOCK_PROFILE:
        raise ValueError(f"unsupported MID2 client compatibility profile: {profile!r}")
    for field in (
        "volume_size_float32_exact",
        "client_accounted_size",
        "max_prefix_offset",
        "assembled_size_int32_safe",
    ):
        if field in declared and declared[field] != metrics[field]:
            raise ValueError(
                f"MID2 compatibility metadata mismatch for {field}: "
                f"declared={declared[field]!r} actual={metrics[field]!r}"
            )
