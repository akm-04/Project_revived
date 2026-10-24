# I7A-8A implementation candidate

The source owner saves one immutable Guild broadcast occurrence, its complete roster and one pending binding/job per recipient in one transaction. A separate I5 command resolves only the fixed source reference, creates normal Mail and its semantic receipt atomically, and preserves their identity on replay. Guild acknowledgement validates the complete typed target proof in a separate transaction.

The finite worker executes only Guild broadcast Mail and bounded reconciliation routes. It uses the existing River runtime and reconciliation kernel with a distinct PostgreSQL session-owner key. Pending bindings remain authoritative when jobs are missing or discarded. Generic API/worker startup neither migrates River nor switches an existing content pointer.

The implementation retains the six selected source contracts and registers six explicit supplements: conservative directory name timestamp; exact operation start plus UTC snapshot fingerprint encoding; physical/logical queue mapping; PostgreSQL NUL admission boundary; stored JSONB reference representation; allocator-backed typed recipient absence. These are reconstruction decisions, not additional original-server facts.

All prior migrations1..36, dependency/tool pins and nineteen prior builtin payloads remain unchanged. Only the new Guild broadcast content artifact and manifest are added. Source artifacts and selected contract identity are bound by IMPLEMENTATION_SELECTION.json.

Creation status is unaccepted. Scoped working-copy results are supplemental evidence. Acceptance requires fresh extraction of this exact frozen identity, every selected matrix requirement plus supplemental cases, independent source/contract/reality review, and the owning normal PassMap seal. Parent8 and8B remain unaccepted.
