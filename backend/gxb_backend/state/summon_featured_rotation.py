"""Featured-Girl rotation with calendar and process-frozen startup debug modes."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
import hashlib
import json
from pathlib import Path
import secrets
from typing import Any
from zoneinfo import ZoneInfo

from gxb_backend.content.summon_featured_catalog import SummonFeaturedCatalog


@dataclass(frozen=True)
class FeaturedRotationSnapshot:
    sx_week_ids: tuple[int, int]
    sx_day_ids: tuple[int, int, int]
    medium_featured_id: int
    local_date: str
    iso_week: str


class SummonFeaturedRotationPolicy:
    DATA_FILE = "summon_featured_rotation_policy.json"
    DEFAULT_SEED = "gxb-private-server-featured-v1"
    DEFAULT_TIMEZONE = "Asia/Dhaka"
    DEFAULT_SELECTION_MODE = "calendar_deterministic"
    CALENDAR_MODE = "calendar_deterministic"
    STARTUP_DEBUG_MODE = "startup_debug"
    VALID_SELECTION_MODES = frozenset({CALENDAR_MODE, STARTUP_DEBUG_MODE})

    def __init__(
        self,
        data_dir: Path | str,
        catalog: SummonFeaturedCatalog,
        *,
        emit_startup_log: bool = False,
    ) -> None:
        self.data_dir = Path(data_dir)
        self.catalog = catalog
        self._warnings: list[str] = []
        self.raw = self._load_policy()
        self.seed = str(self.raw.get("rotation_seed") or self.DEFAULT_SEED)

        mode = str(self.raw.get("selection_mode") or self.DEFAULT_SELECTION_MODE).strip()
        if mode not in self.VALID_SELECTION_MODES:
            self._warn(
                f"invalid selection_mode {mode!r}; falling back to {self.DEFAULT_SELECTION_MODE}"
            )
            mode = self.DEFAULT_SELECTION_MODE
        self.selection_mode = mode

        tz_name = str(self.raw.get("timezone") or self.DEFAULT_TIMEZONE)
        try:
            self.timezone = ZoneInfo(tz_name)
            self.timezone_name = tz_name
        except Exception:
            self._warn(f"invalid timezone {tz_name!r}; falling back to {self.DEFAULT_TIMEZONE}")
            self.timezone = ZoneInfo(self.DEFAULT_TIMEZONE)
            self.timezone_name = self.DEFAULT_TIMEZONE

        self.debug_seed: str | None = None
        self.debug_run_id: str | None = None
        self._debug_sx_week_auto: tuple[int, int] | None = None
        self._debug_sx_day_auto: tuple[int, int, int] | None = None
        self._debug_medium_auto: int | None = None
        self._debug_local_date: str | None = None
        self._debug_iso_week: str | None = None
        self._active_seed = self.seed

        if self.selection_mode == self.STARTUP_DEBUG_MODE:
            self._initialize_startup_debug()

        if emit_startup_log:
            snap = self.snapshot()
            for warning in self._warnings:
                print(f"[SUMMON ROTATION] WARNING: {warning}")
            debug_fields = ""
            if self.selection_mode == self.STARTUP_DEBUG_MODE:
                debug_fields = (
                    f" debug_seed={self.debug_seed} debug_run_id={self.debug_run_id}"
                )
            print(
                "[SUMMON ROTATION] "
                f"mode={self.selection_mode}{debug_fields} "
                f"date={snap.local_date} week={snap.iso_week} "
                f"sx_week={list(snap.sx_week_ids)} sx_day={list(snap.sx_day_ids)} "
                f"medium={snap.medium_featured_id} timezone={self.timezone_name}"
            )

    def _warn(self, message: str) -> None:
        if message not in self._warnings:
            self._warnings.append(message)

    def _load_policy(self) -> dict[str, Any]:
        path = self.data_dir / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(raw, dict):
                return raw
            self._warn(f"{path.name} root is not an object; using automatic rotation")
        except Exception as exc:
            self._warn(f"cannot parse {path.name}: {exc}; using automatic rotation")
        return {
            "schema_version": 2,
            "selection_mode": self.DEFAULT_SELECTION_MODE,
            "rotation_seed": self.DEFAULT_SEED,
            "debug_seed": 0,
            "timezone": self.DEFAULT_TIMEZONE,
            "sx": {"week_manual_ids": [0, 0], "day_manual_ids": [0, 0, 0]},
            "medium": {"manual_hero_id": 0},
        }

    @staticmethod
    def _stable_permutation(ids: set[int] | frozenset[int], seed: str, scope: str) -> list[int]:
        def key(hero_id: int) -> tuple[bytes, int]:
            digest = hashlib.sha256(f"{seed}|{scope}|{hero_id}".encode("utf-8")).digest()
            return digest, int(hero_id)

        return sorted((int(v) for v in ids), key=key)

    @staticmethod
    def _coerce_manual_list(value: Any, count: int) -> list[int]:
        if not isinstance(value, list) or len(value) != count:
            return [0] * count
        out: list[int] = []
        for item in value:
            try:
                out.append(int(item or 0))
            except (TypeError, ValueError):
                out.append(0)
        return out

    @staticmethod
    def _cycle_take(permutation: list[int], start: int, count: int, excluded: set[int]) -> list[int]:
        if not permutation:
            raise RuntimeError("featured rotation candidate list is empty")
        out: list[int] = []
        for offset in range(len(permutation) * 2):
            hero_id = permutation[(start + offset) % len(permutation)]
            if hero_id in excluded or hero_id in out:
                continue
            out.append(hero_id)
            if len(out) == count:
                return out
        raise RuntimeError("featured rotation could not fill requested slots")

    @staticmethod
    def _configured_debug_seed(value: Any) -> str | None:
        """Return an explicit seed, or None when the policy requests fresh boot entropy."""
        if value is None:
            return None
        if isinstance(value, bool):
            return str(value).lower() if value else None
        if isinstance(value, (int, float)) and value == 0:
            return None
        text = str(value).strip()
        if not text or text == "0":
            return None
        return text

    def _initialize_startup_debug(self) -> None:
        configured = self._configured_debug_seed(self.raw.get("debug_seed"))
        self.debug_seed = configured or secrets.token_hex(16)
        self.debug_run_id = hashlib.sha256(
            f"{self.seed}|startup_debug|{self.debug_seed}".encode("utf-8")
        ).hexdigest()[:12]
        self._active_seed = f"{self.seed}|startup_debug|{self.debug_seed}"

        sx_ids = self.catalog.sx_ids()
        sx_perm = self._stable_permutation(sx_ids, self._active_seed, "startup-debug-sx")
        five = self._cycle_take(sx_perm, 0, 5, set())
        self._debug_sx_week_auto = (five[0], five[1])
        self._debug_sx_day_auto = (five[2], five[3], five[4])

        medium_ids = self.catalog.medium_featured_ids()
        medium_perm = self._stable_permutation(
            medium_ids, self._active_seed, "startup-debug-medium-featured"
        )
        if not medium_perm:
            raise RuntimeError("featured rotation Medium candidate list is empty")
        self._debug_medium_auto = int(medium_perm[0])

        boot = datetime.now(self.timezone)
        iso = boot.date().isocalendar()
        self._debug_local_date = boot.date().isoformat()
        self._debug_iso_week = f"{iso.year}-W{iso.week:02d}"

    def _apply_manual(
        self,
        automatic: list[int],
        manual: list[int],
        valid_ids: frozenset[int],
        label: str,
        *,
        excluded: set[int] | None = None,
    ) -> list[int]:
        excluded = set(excluded or set())
        result = list(automatic)
        used = set(excluded)
        for index, value in enumerate(manual):
            if value <= 0:
                used.add(result[index])
                continue
            if value not in valid_ids:
                self._warn(f"{label}[{index}] Hero ID {value} is invalid/ineligible; automatic fallback used")
                used.add(result[index])
                continue
            if value in used or value in result[:index]:
                self._warn(f"{label}[{index}] Hero ID {value} duplicates another slot; automatic fallback used")
                used.add(result[index])
                continue
            result[index] = value
            used.add(value)

        # A manual replacement can collide with an automatic later slot. Repair
        # from the same active mode seed so startup_debug remains boot-specific
        # while calendar mode preserves its deterministic repair behavior.
        pool = self._stable_permutation(valid_ids, self._active_seed, f"{label}:repair")
        seen = set(excluded)
        for index, value in enumerate(result):
            if value not in seen:
                seen.add(value)
                continue
            replacement = next((candidate for candidate in pool if candidate not in seen), None)
            if replacement is None:
                raise RuntimeError(f"cannot repair duplicate {label} slot")
            result[index] = replacement
            seen.add(replacement)
        return result

    def _automatic_snapshot_inputs(
        self, at: datetime | None
    ) -> tuple[list[int], list[int] | None, int, str, str, int | None]:
        if self.selection_mode == self.STARTUP_DEBUG_MODE:
            if (
                self._debug_sx_week_auto is None
                or self._debug_sx_day_auto is None
                or self._debug_medium_auto is None
                or self._debug_local_date is None
                or self._debug_iso_week is None
            ):
                raise RuntimeError("startup_debug rotation was not initialized")
            return (
                list(self._debug_sx_week_auto),
                list(self._debug_sx_day_auto),
                int(self._debug_medium_auto),
                self._debug_local_date,
                self._debug_iso_week,
                None,
            )

        now = at.astimezone(self.timezone) if at is not None else datetime.now(self.timezone)
        today = now.date()
        monday = today - timedelta(days=today.weekday())
        week_bucket = monday.toordinal() // 7
        day_bucket = today.toordinal()
        iso = today.isocalendar()

        sx_ids = self.catalog.sx_ids()
        sx_week_perm = self._stable_permutation(sx_ids, self.seed, "sx-week")
        week_auto = self._cycle_take(
            sx_week_perm, (week_bucket * 2) % len(sx_week_perm), 2, set()
        )
        # The calendar daily baseline must be computed *after* weekly manual
        # overrides are resolved, preserving Pass42.9's exact semantics.
        day_auto = None

        medium_ids = self.catalog.medium_featured_ids()
        medium_perm = self._stable_permutation(medium_ids, self.seed, "medium-daily-featured")
        if not medium_perm:
            raise RuntimeError("featured rotation Medium candidate list is empty")
        medium_auto = int(medium_perm[day_bucket % len(medium_perm)])
        return (
            week_auto,
            day_auto,
            medium_auto,
            today.isoformat(),
            f"{iso.year}-W{iso.week:02d}",
            day_bucket,
        )

    def snapshot(self, at: datetime | None = None) -> FeaturedRotationSnapshot:
        week_auto, day_auto, medium_auto, local_date, iso_week, day_bucket = self._automatic_snapshot_inputs(at)

        sx_ids = self.catalog.sx_ids()
        sx_cfg = self.raw.get("sx") if isinstance(self.raw.get("sx"), dict) else {}
        week_manual = self._coerce_manual_list(sx_cfg.get("week_manual_ids"), 2)
        if (
            sx_cfg.get("week_manual_ids") is not None
            and week_manual == [0, 0]
            and sx_cfg.get("week_manual_ids") != [0, 0]
        ):
            self._warn("sx.week_manual_ids has invalid format; automatic fallback used")
        week_ids = self._apply_manual(week_auto, week_manual, sx_ids, "sx.week_manual_ids")

        if day_auto is None:
            if day_bucket is None:
                raise RuntimeError("calendar rotation day bucket is missing")
            sx_day_perm = self._stable_permutation(sx_ids, self.seed, "sx-day")
            day_auto = self._cycle_take(
                sx_day_perm,
                (day_bucket * 3) % len(sx_day_perm),
                3,
                set(week_ids),
            )

        day_manual = self._coerce_manual_list(sx_cfg.get("day_manual_ids"), 3)
        if (
            sx_cfg.get("day_manual_ids") is not None
            and day_manual == [0, 0, 0]
            and sx_cfg.get("day_manual_ids") != [0, 0, 0]
        ):
            self._warn("sx.day_manual_ids has invalid format; automatic fallback used")
        day_ids = self._apply_manual(
            day_auto, day_manual, sx_ids, "sx.day_manual_ids", excluded=set(week_ids)
        )

        medium_ids = self.catalog.medium_featured_ids()
        medium_cfg = self.raw.get("medium") if isinstance(self.raw.get("medium"), dict) else {}
        try:
            manual_medium = int(medium_cfg.get("manual_hero_id") or 0)
        except (TypeError, ValueError):
            manual_medium = 0
            self._warn("medium.manual_hero_id has invalid format; automatic fallback used")
        if manual_medium > 0 and manual_medium in medium_ids:
            medium_id = manual_medium
        else:
            medium_id = medium_auto
            if manual_medium > 0:
                self._warn(
                    f"medium.manual_hero_id Hero ID {manual_medium} is invalid/ineligible; automatic fallback used"
                )

        return FeaturedRotationSnapshot(
            sx_week_ids=(week_ids[0], week_ids[1]),
            sx_day_ids=(day_ids[0], day_ids[1], day_ids[2]),
            medium_featured_id=int(medium_id),
            local_date=local_date,
            iso_week=iso_week,
        )
