"""I9-11D compatibility input compiler.

Compiles the stock message_push preference ids into one immutable catalog. The
catalog carries the ids, their source table sha256 and the compiled row count so
the runtime validates the artifact against the content revision manifest
instead of a hard-coded row count.
"""


def build_message_push(rows, source_sha256, error):
    ids = []
    for index, row in enumerate(rows, start=1):
        text = (row.get("id") or "").strip()
        if text == "":
            raise error(f"message_push[{index}].id is empty")
        try:
            value = int(text)
        except ValueError:
            raise error(f"message_push[{index}].id is not an integer: {text!r}")
        if value <= 0:
            raise error(f"message_push[{index}].id must be positive")
        if value in ids:
            raise error(f"duplicate message_push id {value}")
        ids.append(value)
    ids.sort()
    return {
        "source": "data/tables/message_push.lua",
        "source_sha256": source_sha256,
        "row_count": len(ids),
        "ids": ids,
        "schema_version": 1,
    }
