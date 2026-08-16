"""RETRIEVE_TOKEN and bootstrap detail hydration."""

from __future__ import annotations

import json
import time

from .context import HandlerContext


class BootstrapHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def retrieve_token(self, req: dict) -> dict:
        player = self.ctx.state.get_player()
        account = self.ctx.state.get_account()
        try:
            region = int(req.get("region", player.region))
        except Exception:
            region = player.region
        self.ctx.state.set_region(region)
        # Re-fetch after set_region(), which persists through the repository.
        player = self.ctx.state.get_player()
        self._trace_identity(req, account, player)

        detail = self.build_detail()
        return {
            "token": account.token,
            "region": player.region,
            # Source-backed cross-cutting field. Backend:extraWebResponseCheck_()
            # consumes this before dispatching the TOKEN event, which guarantees
            # xyd.ServerTime is initialized before MainSceneBottom/Top perform
            # synchronous BattlePass/activity time comparisons.
            "server_time": player.now(),
            "log_url": self.ctx.settings.client_log_url,
            "is_new": 0,
            "story_type": 0,
            "is_debug": 0,
            "is_old_top": 0,
            "uid": account.uid,
            "detail": detail,
        }


    def _trace_identity(self, req: dict, account, player) -> None:
        """Record the SDK SID / account UID / game player-ID split.

        This is backend-only observability. No diagnostic field is added to the
        client protocol response. LoadingScene sends the native SDK SID as the
        MID1 request ``sid`` while MID17 hydrates ``player_id`` separately.
        """
        row = {
            "ts": int(time.time()),
            "request_sid": str(req.get("sid", "")),
            "sdk_sid": str(account.sid),
            "account_uid": str(account.uid),
            "game_player_id": str(player.player_id),
            "game_player_name": str(player.player_name),
            "region": int(player.region),
            "region_name": str(player.region_name),
            "request_sid_matches_sdk_sid": str(req.get("sid", "")) == str(account.sid),
        }
        print(
            "[IDENTITY] "
            f"request_sid={row['request_sid']} sdk_sid={row['sdk_sid']} "
            f"account_uid={row['account_uid']} player_id={row['game_player_id']} "
            f"player_name={row['game_player_name']!r} region={row['region']} "
            f"region_name={row['region_name']!r}"
        )
        try:
            root = self.ctx.settings.runtime_log_dir
            root.mkdir(parents=True, exist_ok=True)
            with (root / "identity_trace.jsonl").open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n")
        except Exception as exc:
            print(f"[IDENTITY] trace write failed: {exc}")

    def build_detail(self) -> dict[str, object]:
        """Build the RETRIEVE_TOKEN bootstrap hydration bag.

        Stage 2 originally widened this aggressively. The live client then stopped
        after RETRIEVE_TOKEN/2784 and never reached the known-good MainScene fanout
        (1537, 192, 1344, 836, 56, etc.). The event dispatcher is not defensive, so
        a malformed optional detail entry can abort the boot listener chain without
        producing a clean backend-side unknown MID.

        Default mode therefore returns the exact Stage 1 proven-safe hydration set
        plus the two Stage 1 lobby-timer entries that already worked in the client.
        The wider set remains available only for controlled experiments by setting:

            GXB_BOOTSTRAP_DETAIL_MODE=wide
        """

        mode = getattr(self.ctx.settings, "bootstrap_detail_mode", "stage3")
        if mode == "safe":
            return self._safe_detail()
        if mode == "wide":
            return self._wide_detail()
        return self._stage3_detail()

    def _safe_detail(self) -> dict[str, object]:
        player = self.ctx.state.get_player()
        return {
            "17": player.player_info_payload(),
            "49": self.ctx.state.get_hero_repository().payload(),
            "81": self.ctx.state.get_inventory_repository().payload(),
            "836": player.library_payload(),
            "56": player.summon_payload(),
            "176": player.friends_payload(),
            # Source-backed MainScene safety hydration. SelfPlayer.loadCollectedPets
            # normally initializes collectedPets before PETS_GET; however
            # MainSceneBottomWindow can schedule GlobalTimer when pet is open, and
            # GlobalTimer iterates pairs(selfPlayer.collectedPets) without a nil
            # guard. Providing an empty PETS_GET result in boot makes collectedPets
            # a safe empty table even before the explicit PETS_GET call happens.
            "780": player.pets_payload(),
            "229": player.activities_payload(),
            "2560": player.redmark_payload(),
        }


    def _stage3_detail(self) -> dict[str, object]:
        """Corrected broad hydration for the Stage 3 established-account profile.

        Every entry here has a source-recognized RETRIEVE_TOKEN consumer and the
        structurally sensitive payloads have been corrected against those model
        consumers. `safe` remains available as an immediate rollback mode.
        """
        player = self.ctx.state.get_player()
        detail = self._safe_detail()
        detail.update({
            "112": player.world_map_payload(),
            "115": player.trial_infos_payload(),
            "289": player.arena_records_payload(),
            "336": player.march_payload(),
            "352": self._sign_info_payload(),
            "368": player.mail_payload(),
            "384": player.invite_payload(),
            "612": player.guild_payload(),
            "624": player.world_boss_payload(),
            "2416": player.adventure_payload(),
            "2485": player.peak_records_payload(),
            "2984": player.battle_pass_payload(),
        })
        return detail

    def _wide_detail(self) -> dict[str, object]:
        player = self.ctx.state.get_player()
        # Experimental only. These are source-recognized MIDs, but many have
        # non-trivial event listeners and should not be injected into boot until
        # each contract is verified by client run.
        return {
            **self._safe_detail(),
            "112": player.world_map_payload(),
            "115": player.trial_infos_payload(),
            "289": player.arena_records_payload(),
            "336": player.march_payload(),
            "352": self._sign_info_payload(),
            "384": player.invite_payload(),
            "624": player.world_boss_payload(),
            "612": player.guild_payload(),
            "780": player.pets_payload(),
            "822": player.pet_campaign_red_point_payload(),
            "1056": player.building_list_payload(),
            "1304": player.offline_payload(),
            "1808": player.tea_talk_payload(),
            "1856": player.class_info_payload(),
            "2137": player.study_payload(),
            "2139": player.gift_box_payload(),
            "2416": player.adventure_payload(),
            "2485": player.peak_records_payload(),
            "2501": player.hero_recommend_payload(),
            "2984": player.battle_pass_payload(),
            "3101": player.hunqi_start_payload(),
        }

    @staticmethod
    def _sign_info_payload() -> dict:
        return {
            "awards": [],
            "is_signed": 1,
            "partner_id": 0,
            "sign_times": 0,
            "month": 1,
            "is_skin": 0,
        }
