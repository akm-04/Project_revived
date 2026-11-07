# I9-10H H2: structured chat kinds (D506)

Client source: `tmp/virtualclient/src_64`. Server kind names: `internal/application/channelchat/structured.go`.

Sends are `SEND_CHAT_MESSAGE` (32782) with `message` holding the JSON room/report payload and outer `type`
equal to the discriminator. Receives are `CHAT_MESSAGE` (32783).

| Wire type | Kind | Client sender (file:line) | Channels | Owner |
|---|---|---|---|---|
| 1 | `ArenaReference` | `ArenaRecordWindow.lua:306,490` default `type_=1` (`RecordShareMenuWindow.lua:9`); payload `player_id,player_name,enemy_name,time,is_attack,id` | 0, 2, 4 (`RecordShareMenuWindow.lua:23-28,48-53,71-76`) | **Missing.** `channelchat.Owners.Arena` is nil. Owning system: Arena record/terminal (`internal/application/arena`). Follow-up. |
| 2 | `ScratchShare` | `ScratchCardRecordWindow.lua:98-101` `type_=2`; payload `player_id,player_name,share_gua,rand_card_group,card_group,scratch_status` | 0, 2, 4 (same menu) | **Missing.** `Owners.Scratch` is nil; no scratch-card system/room store in the tree. Follow-up (activities/scratch card owner). |
| 3 | `IllusionInvitation` | `IllusionInviteWindow.lua:62-72,80-94`; payload `room_id,type,boss_name,room_lev` | 4, 2 | **Present and wired** (`channelchatread.IllusionRoomReader`). |
| 4 | `OccultInvitation` | `OccultInviteWindow.lua:61-71,81-95`; payload `room_id,type,chapter_id,force` | 4, 2 | **Present and wired** (`channelchatread.OccultRoomReader`). |
| 5 | `AdventureIllusionInvitation` | `AdventureIllusionInviteWindow.lua:70-80,89-103`; payload `room_id,type,boss_name,room_lev` | 4, 2 | **Present and wired** (`channelchatread.AdventureIllusionRoomReader`). |
| 6 | `DefenseInvitation` | `AdventureDefenseInviteWindow.lua:69-78,87-100`; payload `room_id,type,room_lev` | 4, 2 | **Wired by H2** (`channelchatread.DefenseRoomReader`, Adventure family slot 1). |
| 7 | `CampMessage` | `GroupChatWnd.lua:196-210`, `GroupChatNewWnd.lua:196-210`; payload `type,message,msgType,selectType,roomID,camp` | 4 only | **Missing.** `Owners.Camp` is nil; no war-camp room store found. Owning system: guild war camp (`myCamp`/`selectType` state lives in `GroupChatWnd`). Follow-up. |
| 8 | `RagnarokInvitation` | `RagnarokInviteWindow.lua:60-70,78-92`; payload `room_id,type,boss_name,room_lev` | 4, 2 | **Missing.** `Owners.Ragnarok` is nil; no Ragnarok room system exists yet. Follow-up (Ragnarok boss mode). |
| 0 | ordinary | `Backend.lua:247-253`, `ChatWindow.lua` | 0, 2, 4 | Existing ordinary chat, unchanged. |

## Client receive routing

- Guild socket: 32783 -> `LEAGUE_CHAT_ROOM_MESSAGE` -> `GUILD_CHANNEL` for every type
  (`MessageManager.lua:1549-1558`); `genChatMessage` parses card types into the clickable card
  (`MessageManager.lua:1264-1324`) and the card click joins by `room_id` (`:272-455`).
- Service socket: 32783 -> `SERVICE_CHAT_ROOM_MESSAGE`; types 3/4/5/6/8 go to `TEAM_CHANNEL`
  (`MessageManager.lua:1560-1574`); type 7 is deliberately ignored there (`:1566`).
- `TEAM_CHANNEL` card rendering reads `np_info, player_id, player_name, message, player_type, type, avatar_id,
  avatar_frame_id, lev` from the outer envelope and `room_id/type/boss_name/room_lev` (or
  `chapter_id/force`) from the decoded `message`.

## Wire check

`internal/protocol/realtime/channel_structured.go:329-411` projects exactly the fields the client decodes:
Illusion/Adventure/Ragnarok `{room_id,type,boss_name,room_lev}`, Occult `{room_id,type,chapter_id,force}`,
Defense `{room_id,type,room_lev}`. No mismatch found; no projection change was needed.

## Activation rule (D506)

`ChannelChatDispatcher` publishes a structured message when the semantic selector parsed and the production
`channelchat.Owners` wiring has a reader for its kind; otherwise it keeps today's silent no-publication and
logs the refusal (`channel_chat.go`). Owner readers publish only when the room exists on the sender's logical
server, is open with a free seat, and the sender is seated (`channelchatread.shareableRoom`).
