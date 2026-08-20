# GXB backend v0.8.29 — Pass42.7 SX counter-status gate fix

Pass42.7 is a narrow runtime-regression fix for the corrected SX/Soul Box planner introduced in Pass42.6.

The Pass42.6 data policy correctly marks the SX counter as `implemented_private_sx_policy_v2`, but `SummonCounterPolicy.transition_supported` still recognized only the older `implemented_private_sx_policy` label. As a result, every MID50 `(type=4,index=1/2)` purchase failed infrastructure validation before the SX planner ran and returned `{error_code:1,result:[]}`. Because the client treats HTTP 200 as transport success, that fail-closed body opened an empty SX EXP Juice/result popup.

v0.8.29 adds the v2 status to the explicit accepted transition-status allow-list. No SX class rates, candidate weights, costs, VIP gates, result shaping, hotspot defaults, pity semantics, duplicate conversion, Classic/Magic behavior, Campaign behavior, or Pass29 compatibility data are changed.

The corrected Pass42.6 SX content planner remains the active design: five recovered item slots plus one mixed Soul-Casket reward-class slot using current `partner.is_sx` as SX identity authority. Runtime content validation must be repeated after this gate fix.

Validation for this artifact is static only: Python AST, JSON parsing, protected-data comparison, and archive integrity. Flask/HTTP/emulator/gameplay are not executed by the assistant.
