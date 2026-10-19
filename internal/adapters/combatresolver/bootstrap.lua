-- SNAPSHOT_ONLY_ADAPTERS_V1 server-branch environment for the pinned corpus.
-- Every adapter answers only from combat_input; anything else fails closed.
local input = combat_input
local function deny(name)
	return function()
		error("COMBAT_ADAPTER_UNMATERIALIZED " .. name)
	end
end

package.path = ""
package.cpath = ""
package.loadlib = nil
dofile, loadfile, loadstring, load, debug = nil, nil, nil, nil, nil
os = combat_os
combat_os = nil
isClient = false
ngx = { ctx = { battle = {} } }
xyd = { tables = {} }
package.preload["socket"] = function()
	return { gettime = function() return input.os_time end }
end

-- framework/functions.lua installs io.* helpers while loading; combat never calls them.
io = {}
require("framework.functions")
io = nil
require("app.common.enums")
require("app.common.const")
require("app.common.utils")
isClient = false
local cocos = require("lib.battle.framework.cocos")
class = cocos.class
import = cocos.import
require("app.common.tables.tables")
require("lib.battle.battleConfig"):new()
ngx.ctx.battle.battleType = xyd.BattleType.CreateReport

package.preload["lib.battle.app.model.Item"] = function() return require("app.model.Item") end
-- Reached only when a hero lacks params.spirit_item; snapshots always carry it.
package.preload["lib.spirit.spirit_item"] = function() return { new = deny("lib.spirit.spirit_item") } end
package.preload["lib.player.backpack"] = function()
	return {
		new = function(_, player_id)
			local player = input.players[tonumber(player_id)]
			if not player then
				error("COMBAT_ADAPTER_BACKPACK_UNFROZEN_PLAYER " .. tostring(player_id))
			end
			return { get_item_num = function(_, item_id) return player.books[tonumber(item_id)] or 0 end }
		end,
	}
end
package.preload["app.common.ui.SpineEffect"] = function() return require("lib.battle.BattleBaseNode") end

local scheduled, scheduled_id = nil, 0
package.preload["framework.scheduler"] = function()
	return {
		scheduleUpdateGlobal = function(fn)
			scheduled_id = scheduled_id + 1
			scheduled = { id = scheduled_id, fn = fn }
			return scheduled_id
		end,
		unscheduleGlobal = function(id)
			if scheduled and scheduled.id == id then
				scheduled = nil
			end
		end,
		scheduleGlobal = deny("framework.scheduler.scheduleGlobal"),
		performWithDelayGlobal = deny("framework.scheduler.performWithDelayGlobal"),
	}
end
function combat_next_frame()
	assert(scheduled, "COMBAT_DRIVER_NO_SCHEDULED_FRAME")
	scheduled.fn()
end
package.preload["cjson"] = function()
	return { encode = combat_json_encode, decode = deny("cjson.decode") }
end

-- Recovered design viewport and list helper the engine reads from client globals.
local Node = require("lib.battle.BattleBaseNode")
xyd.list = require("app.common.list")
xyd.STAGE_WIDTH = xyd.tables.misc.designWidth
xyd.STAGE_HEIGHT = xyd.tables.misc.designHeight
xyd.UNLIMIT_STAGE_WIDTH = xyd.STAGE_WIDTH / 0.6
xyd.UNLIMIT_STAGE_HEIGHT = xyd.STAGE_HEIGHT / 0.6
local function node()
	local n = Node.new()
	function n:align(_, x, y)
		self:pos(x or 0, y or 0)
		return self
	end
	return n
end
display = { newNode = node, newColorLayer = function() return node() end, LEFT_BOTTOM = 0 }
cc = { c4b = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end }
tolua = { isnull = function(v) return v == nil end }
transition = { stopTarget = function() end }

local scene_player = { playerID = input.scene_player }
xyd.ModelManager = {
	get = function()
		return {
			loadModel = function(_, kind)
				if kind == xyd.ModelType.SELF_PLAYER then
					return scene_player
				end
				if kind == xyd.ModelType.REGION_ARENA then
					return {}
				end
				error("COMBAT_ADAPTER_UNMATERIALIZED_MODEL " .. tostring(kind))
			end,
		}
	end,
}

-- C5A_COMBAT_COLLECTION_ATTR_OWNER_SCOPED_V1: the server branch leaves
-- NormalHero.selfPlayer nil; each owned hero sees its own owner's album.
local Hero = require("app.model.Hero")
local Pet = require("app.model.Pet")
local function model(actor)
	if actor.kind == "PET" then
		local pet = Pet.new()
		pet:populate(actor.params)
		return pet
	end
	local hero = Hero.new()
	hero:populate(actor.params)
	if actor.player > 0 then
		hero.selfPlayer = { playerID = actor.player, albumAttr = input.players[actor.player].album }
	end
	return hero
end
function combat_models(actors)
	local out = {}
	for i, actor in ipairs(actors) do
		out[i] = model(actor)
	end
	return out
end

function combat_report_context()
	local collect, books = {}, {}
	for player, row in pairs(input.players) do
		local attrs, count = {}, 0
		for attr, value in ipairs(row.album) do
			attrs[tostring(attr)] = value
		end
		for _, quantity in pairs(row.books) do
			if quantity > 0 then
				count = count + 1
			end
		end
		collect[tostring(player)] = attrs
		books[tostring(player)] = count
	end
	return collect, books
end

function combat_evaluate_actors()
	local lists = { input.team_a, input.pets_a }
	for _, wave in ipairs(input.waves_b) do
		lists[#lists + 1] = wave
	end
	lists[#lists + 1] = input.pets_b
	local actors = {}
	for _, list in ipairs(lists) do
		for _, actor in ipairs(list) do
			actors[#actors + 1] = actor
		end
	end
	local totals = {}
	for i, m in ipairs(combat_models(actors)) do
		m:setupBattleAttrInfo()
		local row = {}
		for attr = 1, 49 do
			row[attr] = m:getBattleAttr(attr)
		end
		totals[i] = row
	end
	return totals
end
