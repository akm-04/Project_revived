-- Table-shaped monsters have no partner id (-1), so they are keyed by table id.
local function actorKey(hero)
 local identity = hero:getHeroID()
 if identity <= 0 then
  identity = hero:getTableID()
 end
 return tostring(identity)
end

-- Partner ids repeat across players, so a team's members need the player too.
local function memberKey(hero)
 return tostring(hero:getPlayerID()) .. ":" .. tostring(hero:getHeroID())
end

local function carry(fighters, statuses, keyOf)
 for _, fighter in ipairs(fighters) do
  if fighter:getSummonType() == xyd.summonMonsterType.None then
   local status = statuses[keyOf(fighter.hero_)]
   if status then
    fighter:updateHp(status.hp)
    fighter:updateEnergyTo(status.mp)
    if status.is_reborn > 0 and fighter:canReborn() then
     fighter.hasReborn_ = true
    end
    fighter.healthStatus = { health = 1, hp = status.hp, mp = status.mp, is_reborn = status.is_reborn }
   end
  end
 end
end

return function(_, input)
 local parameters = input.parameters
 local Report = require("app.scenes.BattleCreateReport")
 local originalNew = Report.new
 -- Restore the per-attempt VM's constructor before creating the decorated instance.
 Report.new = function(...)
  Report.new = originalNew
  local battle = originalNew(...)
  local originalUpdate = battle.updateFighters
  battle.updateFighters = function(self)
   originalUpdate(self)
   -- The server source omits Memoir here; mirror BattleCreate's HP/MP/rebirth initialization.
   carry(ngx.ctx.battle.teamA, parameters.heroes_status or {}, actorKey)
   carry(ngx.ctx.battle.teamA, parameters.member_status or {}, memberKey)
   carry(ngx.ctx.battle.teamB, parameters.enemy_status or {}, actorKey)
  end
  return battle
 end
 local originalFactory = ngx.ctx.battle.requireFighter
 ngx.ctx.battle.requireFighter = function(name)
  local fighterClass = originalFactory(name)
  return { new = function(...)
   local fighter = fighterClass.new(...)
   local originalReport = fighter.writeReport
   fighter.writeReport = function(self)
    local report = originalReport(self)
    report.memoir_final_status = { hp = self:getHp(), mp = self:getEnergy(), is_reborn = self:hasReborned() and 1 or 0 }
    return report
   end
   return fighter
  end }
 end
end
