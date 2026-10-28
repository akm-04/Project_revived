local function carry(fighters, statuses)
 for _, fighter in ipairs(fighters) do
  if fighter:getSummonType() == xyd.summonMonsterType.None then
   local status = statuses[tostring(fighter.hero_:getHeroID())]
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
   carry(ngx.ctx.battle.teamA, parameters.heroes_status or {})
   carry(ngx.ctx.battle.teamB, parameters.enemy_status or {})
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
