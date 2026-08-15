local var_0_0 = {}

var_0_0.BaseFighter = "lib.battle.BaseFighter"
var_0_0.BasePet = "lib.battle.BasePet"
var_0_0.Buff = "lib.battle.Buff"
var_0_0.Skill = "lib.battle.Skill"
var_0_0.Hero = "app.model.Hero"
var_0_0.MoveUnit = "lib.battle.MoveUnit"
var_0_0.AttackUnit = "lib.battle.AttackUnit"
var_0_0.SkillEffect = "app.modules.battle.SkillEffect"
var_0_0.SkillEffectByPath = "app.modules.battle.SkillEffectByPath"
var_0_0.FighterModel = "app.modules.battle.FighterModel"
var_0_0.SpineEffect = "app.common.ui.SpineEffect"
var_0_0.GetTarget = "lib.battle.GetTarget"
var_0_0.BattleBaseNode = "lib.battle.BattleBaseNode"
var_0_0.SkillNode = "app.modules.battle.SkillNode"
var_0_0.HeroAnimation = "app.common.ui.HeroAnimation"
var_0_0.ActivityFighter = "lib.battle.fighters.ActivityFighter"

local var_0_1 = "lib.battle.fighters."

return {
	new = function(arg_1_0)
		local var_1_0 = require("lib.battle.framework.cocos")
		local var_1_1 = ngx
		local var_1_2 = var_1_0.getXinyoudi(var_1_1)

		var_1_1.ctx.battle = var_1_1.ctx.battle or {}
		var_1_1.ctx.battle.requireClient = var_0_0
		var_1_1.ctx.battle.clientPath = var_0_1
	end
}
