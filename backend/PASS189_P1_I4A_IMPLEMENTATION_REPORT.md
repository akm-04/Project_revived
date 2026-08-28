# Pass189 P1-I4A Implementation Report

Status: IMPLEMENTED / STATIC-REGRESSION ACCEPTED.

Scope is deliberately bounded to generic Event Centre building lifecycle plus Bookshelf projection. Cabinet research is NOT implemented in this pass. Effective src_64 cross-checks: `app/model/EventCentre.lua`, `app/windows/EventCentreUpgradeWindow.lua`, `app/windows/BookShelfWindow.lua`, `app/common/tables/EventCentreBookShelfTable.lua`, Cabinet source tables.

Compatibility policy retained from Pass185 planning: building cancellation refunds `floor(original_cost * remaining_time / total_time)` from a durable start-cost snapshot because original server refund math is absent.
