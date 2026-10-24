# Publication PUBLICATION_V1

Owning specification: normal Pass658 selected I7A9 contract index. Source: locked current src_64 publication consumers and CP171/CP172; V1/historical only corroborate. I7A9 is one phase, no children.

Apply migration39 before startup. An empty database catalog safely returns MID7 contents as a JSON string encoding {"contents":[]}, MID1537 contents[], and MID8193 has_read1/contents[]. MID8194 accepts no gameplay arguments and creates no marker for empty/inactive selection. Authenticated routes derive server/player from canonical gameplay authority; MID7 is public.

Optional GXB_PUBLICATION_FILE is one typed JSON object with sets[]. Each set: UUID id, family announcement/board/picture, server_id (0 global or canonical server ID), starts_at, optional ends_at, items[]. Each item has exactly one family member: announcement {title,contents:[strings],url?}, board {id,title,start_date,content,img_url?}, picture {weight,pic,small_pic}. Image fields may be empty stock defaults. Nonempty images require http:// URLs; changed bytes must use fresh basename because the inspected client caches by basename. Hosting and operator qualification remain I11; no external image-rendering proof is claimed here.

Published input is validated and installed atomically. Same UUID with canonical identical input is idempotent; changed data requires a new UUID and fresh board IDs. Dates normalize to UTC PostgreSQL microsecond precision. Database revisions/items/markers are durable authority after install; restart without the file works. No overwritten/deleted historical sets, automatic reset, fabricated V1/client read markers, board server markers, reward settlement, activity eligibility or additional worker exists.

At authoritative DecisionAt, choose matching effective (start inclusive) revision: server scope ahead of global, then newest start and install sequence. Check expiry (end exclusive) and nonempty items after choosing. An expired/empty replacement suppresses predecessors and fallback; future revisions leave current untouched until start. This precedence is declared compatibility policy, not recovered original-server behavior.

Picture READ locks actor liveness, typed I4 PlayerRoot315, then exact Marker390. Its natural key is canonical player/set UUID; root covers absent-row creation. Internal retries retain selected identity and DecisionAt. Lost COMMIT reply reconciles that exact marker; absence stays UNKNOWN and cannot trigger blind replay. The source command has no displayed-set identifier: a later stock request can mark a replacement, and old displayed intent cannot be recovered. Manual8193 continues returning content after read; the marker only suppresses automatic popup.

Joint backup/restore must retain catalog and marker references together. Migration is forward-only. Disable by installing a new empty revision, not deleting history. Native/process evidence and exact candidate qualification remain separate from this document.
