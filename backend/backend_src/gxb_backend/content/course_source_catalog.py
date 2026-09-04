"""Immutable effective-src_64 authority for P1 Electives/Courses."""
from __future__ import annotations
from pathlib import Path
from typing import Any, Mapping
from .p1_source_common import freeze_rows, load_source_json


class CourseSourceCatalog:
    EXPECTED_SUBJECTS = 4
    EXPECTED_CLASSES = 12
    EXPECTED_COURSES = 48
    EXPECTED_COLORS = 6
    EXPECTED_PROFICIENCY_ITEMS = 4

    def __init__(self, data_dir: Path):
        raw = load_source_json(data_dir, "p1_course_source_catalog.json")
        tables = raw.get("tables") or {}
        self.subjects = freeze_rows(tables.get("subjects"))
        self.classes = freeze_rows(tables.get("classes"))
        self.books = freeze_rows(tables.get("books"))
        self.book_colors = freeze_rows(tables.get("book_colors"))
        self.study_seconds = int(raw.get("fixed_study_seconds", 0) or 0)
        misc = raw.get("misc") or {}
        self.forget_crystal = int(misc.get("forget_crystal", 0) or 0)
        self.study_knowledge_coefficient = float(misc.get("study_knowledge_coefficient", 0) or 0)
        self.speed_money = int(misc.get("speed_money", 0) or 0)
        self.study_log_limit = int(misc.get("study_log_limit", 0) or 0)
        prof_rows = raw.get("proficiency_items") or []
        self.proficiency_items = {
            int(row.get("item_id", 0)): int(row.get("proficiency", 0))
            for row in prof_rows if int(row.get("item_id", 0) or 0) > 0
        }
        if (len(self.subjects), len(self.classes), len(self.books), len(self.book_colors)) != (4, 12, 48, 6):
            raise ValueError("Course source census drift")
        if len(self.proficiency_items) != self.EXPECTED_PROFICIENCY_ITEMS:
            raise ValueError("Course proficiency item census drift")
        if self.study_seconds != 28800:
            raise ValueError("Course study duration drift")
        if self.forget_crystal != 200 or self.speed_money != 30 or self.study_log_limit != 30:
            raise ValueError("Course misc source constants drift")
        if abs(self.study_knowledge_coefficient - 0.2) > 1e-9:
            raise ValueError("Course knowledge coefficient drift")
        for row in self.classes.values():
            if int(row.get("application", 0) or 0) <= 0:
                raise ValueError("Course application item missing")
        if max(int(r.get("total_proficiency", 0) or 0) for r in self.book_colors.values()) != 1680:
            raise ValueError("Course proficiency cap drift")

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @staticmethod
    def _split_ints(value: Any) -> tuple[int, ...]:
        if isinstance(value, (list, tuple)):
            raw = value
        else:
            raw = str(value or "").split("|")
        out = []
        for entry in raw:
            try:
                number = int(entry)
            except (TypeError, ValueError):
                continue
            if number > 0:
                out.append(number)
        return tuple(out)

    def course(self, course_id: Any) -> Mapping[str, Any] | None:
        try:
            return self.books.get(int(course_id))
        except (TypeError, ValueError):
            return None

    def class_row(self, class_id: Any) -> Mapping[str, Any] | None:
        try:
            return self.classes.get(int(class_id))
        except (TypeError, ValueError):
            return None

    def color(self, quality: Any) -> Mapping[str, Any] | None:
        try:
            return self.book_colors.get(int(quality))
        except (TypeError, ValueError):
            return None

    def application_item_for_course(self, course_id: Any) -> int:
        row = self.course(course_id)
        if row is None:
            return 0
        cls = self.class_row(row.get("class_type"))
        return int(cls.get("application", 0) or 0) if cls else 0

    def proficiency_for_item(self, item_id: Any) -> int:
        return max(0, int(self.proficiency_items.get(self._int(item_id), 0)))

    def max_total_proficiency(self) -> int:
        return max(self._int(row.get("total_proficiency"), 0) for row in self.book_colors.values())

    def quality_for_exp(self, exp: Any) -> int:
        value = max(0, min(self.max_total_proficiency(), self._int(exp)))
        for quality in sorted(self.book_colors):
            threshold = self._int(self.book_colors[quality].get("total_proficiency"), 0)
            if value < threshold:
                return max(1, int(quality) - 1)
        return max(int(q) for q in self.book_colors)

    def forget_returns(self, quality: Any) -> tuple[tuple[int, int], ...]:
        row = self.color(quality)
        if row is None:
            return ()
        items = self._split_ints(row.get("book_return"))
        counts = self._split_ints(row.get("book_numb"))
        return tuple((item_id, count) for item_id, count in zip(items, counts) if item_id > 0 and count > 0)

    def speed_cost(self, remaining_seconds: Any) -> int:
        remaining = max(0, self._int(remaining_seconds))
        if remaining <= 0:
            return 0
        # Effective Course windows use objectClassRoomMoney * ceil(remaining / 1800) / 2.
        slots = (remaining + 1799) // 1800
        return int(self.speed_money * slots // 2)
