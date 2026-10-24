# sqlc generation policy

Pass430 freezes sqlc-generated Go as a **build-time artifact**; project-owned migrations and owner-scoped SQL remain canonical.

Pass438 W1 exposed that generating into `internal/adapters/postgres/{kerneldb,i3db}` silently changed the sealed source tree even though I4 does not import those packages. Pass440 therefore makes the build-time boundary explicit:

- root `sqlc.yaml` generates only into sibling scratch directory `../gxb-v2-sqlc-generated/`;
- `sqlc generate` must leave every byte inside the candidate tree unchanged;
- W1 must remove the sibling scratch directory before generation, run sqlc v1.31.1, retain its generated artifact/hash inventory, and then remove it after evidence capture;
- generated code is validation/build evidence, not PostgreSQL canonical truth and not a source of domain ownership;
- when an implementation stage begins importing sqlc output, that stage must deliberately promote the required generated package into the build pipeline and add a compile-equivalence gate. Silent source-tree generation is forbidden.

This is an intentional resolution of W1 audit finding A5, not an attempt to hide generated diffs.
