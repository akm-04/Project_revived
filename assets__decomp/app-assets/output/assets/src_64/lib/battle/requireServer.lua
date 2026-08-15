local var_0_0 = {}

var_0_0.BaseFighter = "lib.battle.BaseFighter"
var_0_0.BasePet = "lib.battle.BasePet"
var_0_0.Buff = "lib.battle.Buff"
var_0_0.Skill = "lib.battle.Skill"
var_0_0.Hero = "app.model.Hero"
var_0_0.MoveUnit = "lib.battle.MoveUnit"
var_0_0.AttackUnit = "lib.battle.AttackUnit"
var_0_0.SkillEffect = "lib.battle.BattleBaseNode"
var_0_0.FighterModel = "lib.battle.FighterModel"
var_0_0.SpineEffect = "lib.battle.BattleBaseNode"
var_0_0.GetTarget = "lib.battle.GetTarget"
var_0_0.BattleBaseNode = "lib.battle.BattleBaseNode"
var_0_0.SkillNode = "lib.battle.BattleBaseNode"
var_0_0.HeroAnimation = "lib.battle.HeroAnimation"
var_0_0.ActivityFighter = "lib.battle.fighters.ActivityFighter"

local var_0_1 = "lib.battle.fighters."

return {
	new = function(arg_1_0)
		local var_1_0 = require("lib.battle.framework.cocos")
		local var_1_1 = ngx
		local var_1_2 = var_1_0.getXinyoudi(var_1_1)

		var_1_1.ctx.battle = var_1_1.ctx.battle or {}
		var_1_1.ctx.battle.requireServer = var_0_0
		var_1_1.ctx.battle.serverPath = var_0_1
	end
}
