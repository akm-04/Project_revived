local function survivors(team)
 local count = 0
 for _, fighter in ipairs(team) do
  if fighter:getSummonType() == xyd.summonMonsterType.None and (not fighter:isDeath() or fighter:canReborn()) then
   count = count + 1
  end
 end
 return count
end

local function damage(team)
 local total = 0
 for _, fighter in ipairs(team) do
  if fighter:getSummonType() == xyd.summonMonsterType.None then total = total + fighter.harms end
 end
 return total
end

local function initialize(heroes, actors, buffs, leader, leaderBuff)
 local foundLeader = leader == 0
 for index, hero in ipairs(heroes) do
  local initial = {}
  for _, buff in ipairs(hero.buffs_ or {}) do table.insert(initial, buff) end
  for _, buff in ipairs(buffs) do table.insert(initial, buff) end
  if leader > 0 and actors[index].params.partner_id == leader then
   foundLeader = true
   assert(leaderBuff and leaderBuff > 0, "TASK_MODE_LEADER_BUFF")
   table.insert(initial, leaderBuff)
  end
  hero.buffs_ = initial
 end
 assert(foundLeader, "TASK_MODE_LEADER_NOT_FROZEN")
end

local function phantom(heroes)
 assert(#heroes == 1, "TASK_MODE_PHANTOM_FORMATION")
 return { heroes[1], heroes[1], heroes[1], heroes[1], heroes[1] }
end

return function(fight, input)
 local parameters = input.parameters
 local mode = parameters.mode
 assert(mode >= 1 and mode <= 6, "TASK_MODE_UNKNOWN_RULE")
 local leaderA, leaderB = parameters.leader_a or 0, parameters.leader_b or 0
 assert((mode == 3 and leaderA > 0 and leaderB > 0) or (mode ~= 3 and leaderA == 0 and leaderB == 0), "TASK_MODE_LEADER_RULE")
 initialize(fight.herosA, input.team_a, parameters.buffs_a, leaderA, parameters.leader_buff_a)
 initialize(fight.herosB[1], input.waves_b[1], parameters.buffs_b, leaderB, parameters.leader_buff_b)
 if mode == 5 then
  fight.herosA = phantom(fight.herosA)
  fight.herosB[1] = phantom(fight.herosB[1])
 end
 local Report = require("app.scenes.BattleCreateReport")
 local originalNew = Report.new
 Report.new = function(...)
  Report.new = originalNew
  local battle = originalNew(...)
  local originalUpdate = battle.updateFighters
  battle.updateFighters = function(self)
   originalUpdate(self)
   -- BattleCreate calls addInitBuffs here; its server wrapper omits the call.
   for _, fighter in ipairs(ngx.ctx.battle.teamA) do fighter:addInitBuffs() end
   for _, fighter in ipairs(ngx.ctx.battle.teamB) do fighter:addInitBuffs() end
  end
  local originalStar = battle.getBattleStar
  battle.getBattleStar = function(self)
   if not self.timeOut_ then return originalStar(self) end
   local teamA, teamB = ngx.ctx.battle.teamA, ngx.ctx.battle.teamB
   if mode ~= 1 then
    local aliveA, aliveB = survivors(teamA), survivors(teamB)
    if aliveA ~= aliveB then return aliveA > aliveB and 1 or 0 end
   end
   -- D353: exact timeout ties favour the defender.
   return damage(teamA) > damage(teamB) and 1 or 0
  end
  return battle
 end
end
