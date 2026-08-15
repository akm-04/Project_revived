local var_0_0 = class("StoryScene", import("app.common.ui.BaseScene"))
local var_0_1 = 4
local var_0_2 = 0.15
local var_0_3 = 3
local var_0_4 = 3
local var_0_5 = 2.7
local var_0_6 = 2
local var_0_7 = 5
local var_0_8 = 2
local var_0_9 = 100
local var_0_10 = 400
local var_0_11 = 30
local var_0_12 = "xuehe0"
local var_0_13 = 4
local var_0_14 = "huo0"
local var_0_15 = {
	cc.p(271, 562),
	cc.p(1047, 357),
	cc.p(140, 267),
	cc.p(747, 579),
	cc.p(277, 364),
	cc.p(554, 500),
	cc.p(808, 193)
}
local var_0_16 = 2
local var_0_17 = {
	0.45,
	0.5,
	0.4,
	0.3,
	0.3,
	0.7,
	0.3
}
local var_0_18 = {
	cc.p(74, 389),
	cc.p(225, 276),
	cc.p(617, 202),
	cc.p(909, 194)
}
local var_0_19 = cc.p(1056, 547)
local var_0_20 = "moguang0"
local var_0_21 = 32 * var_0_2
local var_0_22 = cc.p(407, 470)
local var_0_23 = {
	"yanT0",
	"yanRR0",
	"yanBL0",
	"yanr0"
}
local var_0_24 = {
	cc.p(445, 495),
	cc.p(875, 151),
	cc.p(301, 200),
	cc.p(978, 402)
}
local var_0_25 = 4
local var_0_26 = {
	"L010",
	"L020",
	"L030",
	"wu0"
}
local var_0_27 = {
	cc.p(242, 442),
	cc.p(671, 477),
	cc.p(1103, 546),
	cc.p(525, 606)
}
local var_0_28 = cc.p(756, 500)
local var_0_29 = "040"
local var_0_30 = 4
local var_0_31 = "sound/start.ogg"

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onEnterTransitionFinish(arg_2_0)
	var_0_0.super.onEnterTransitionFinish(arg_2_0)
	audio.playMusic(var_0_31, false)
	arg_2_0:display()
end

function var_0_0.onExit(arg_3_0)
	var_0_0.super.onExit(arg_3_0)
	audio.stopMusic()
end

function var_0_0.initLabel(arg_4_0, arg_4_1)
	local var_4_0 = xyd.tables.translation:translation(string.format("BEGIN_STORY_%d", arg_4_0.idx_))

	if arg_4_0.label_ then
		arg_4_0.label_:removeFromParent()

		arg_4_0.label_ = nil
	end

	arg_4_0.label_ = xyd.AssetLoader.get():loadLabel({
		text = var_4_0,
		size = var_0_11
	}):pos(var_0_9, var_0_10):addTo(arg_4_0, 100)

	arg_4_0.label_:setAnchorPoint(cc.p(0, 1))
	arg_4_0.label_:enableShadow()
	arg_4_0.label_:setWidth(xyd.STAGE_WIDTH - var_0_9 * 2)
	arg_4_0.label_:setLineBreakWithoutSpace(true)

	local var_4_1 = string.utf8len(var_4_0) + arg_4_0.label_:getStringNumLines()

	arg_4_0.label_:setString("")

	local var_4_2 = {}

	for iter_4_0 = 1, var_4_1 do
		local var_4_3 = cc.DelayTime:create(var_0_2)
		local var_4_4 = cc.CallFunc:create(function()
			arg_4_0.label_:setString(xyd.utf8str(var_4_0, 1, iter_4_0))
		end)
		local var_4_5

		if iter_4_0 == var_4_1 - 1 then
			local var_4_6 = cc.DelayTime:create(var_0_2)

			table.insert(var_4_2, var_4_3)
			table.insert(var_4_2, var_4_4)
			table.insert(var_4_2, var_4_6)
			table.insert(var_4_2, var_4_3)
			table.insert(var_4_2, arg_4_1)
		else
			table.insert(var_4_2, var_4_3)
			table.insert(var_4_2, var_4_4)
		end
	end

	local var_4_7 = cc.Sequence:create(var_4_2)

	arg_4_0.label_:runAction(var_4_7)
end

function var_0_0.display(arg_6_0)
	arg_6_0.backgrounds_ = {}
	arg_6_0.idx_ = 1
	arg_6_0.backgrounds_[arg_6_0.idx_] = xyd.AssetLoader.get():loadSprite(string.format("images/story/%02d.png", arg_6_0.idx_))

	arg_6_0.backgrounds_[arg_6_0.idx_]:pos(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2):addTo(arg_6_0)

	arg_6_0.label_ = xyd.AssetLoader.get():loadLabel({
		text = "",
		size = var_0_11
	}):pos(var_0_9, var_0_10):addTo(arg_6_0, 100)

	local function var_6_0()
		if not arg_6_0.animationSprites_ then
			arg_6_0.animationSprites_ = {}
		end

		if arg_6_0.idx_ == 1 then
			local var_7_0 = xyd.AssetLoader.get():loadAnimation(var_0_12, true)
			local var_7_1 = display.newSprite()

			var_7_1:pos(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2):addTo(arg_6_0)

			local var_7_2 = cc.Animate:create(var_7_0)

			var_7_1:runAction(cc.RepeatForever:create(var_7_2))
			var_7_1:setScale(var_0_13)
			table.insert(arg_6_0.animationSprites_, var_7_1)

			local var_7_3 = 0.2

			for iter_7_0 = 1, #var_0_15 do
				local var_7_4 = display.newSprite():addTo(arg_6_0.backgrounds_[arg_6_0.idx_])

				var_7_4:setPosition(var_0_15[iter_7_0])
				var_7_4:setScale(var_0_16 * var_0_17[iter_7_0])
				var_7_4:setOpacity(0)

				local var_7_5 = cc.FadeIn:create(var_0_8)
				local var_7_6 = cc.DelayTime:create(var_7_3 * (iter_7_0 - 1))
				local var_7_7 = cc.CallFunc:create(function()
					local var_8_0 = xyd.AssetLoader.get():loadAnimation(var_0_14, true)

					var_7_4:playAnimationForever(var_8_0)
				end)
				local var_7_8 = cc.Spawn:create(var_7_5, var_7_7)

				var_7_4:runAction(cc.Sequence:create(var_7_6, var_7_8))
				table.insert(arg_6_0.animationSprites_, var_7_4)
			end
		elseif arg_6_0.idx_ == 2 then
			for iter_7_1 = 1, #var_0_18 do
				local var_7_9 = xyd.AssetLoader.get():loadAnimation("huo0" .. iter_7_1 .. "0", true)
				local var_7_10 = display.newSprite():addTo(arg_6_0.backgrounds_[arg_6_0.idx_])

				var_7_10:setPosition(var_0_18[iter_7_1])

				local var_7_11 = cc.Animate:create(var_7_9)

				var_7_10:runAction(cc.RepeatForever:create(var_7_11))
				table.insert(arg_6_0.animationSprites_, var_7_10)
			end

			for iter_7_2 = 1, #var_0_24 do
				local var_7_12 = xyd.AssetLoader.get():loadAnimation(var_0_23[iter_7_2], true)
				local var_7_13 = display.newSprite():addTo(arg_6_0.backgrounds_[arg_6_0.idx_])

				var_7_13:setPosition(var_0_24[iter_7_2])

				local var_7_14 = cc.Animate:create(var_7_12)

				var_7_13:runAction(cc.RepeatForever:create(var_7_14))
				var_7_13:setScale(var_0_25)
				table.insert(arg_6_0.animationSprites_, var_7_13)
			end

			local var_7_15 = xyd.AssetLoader.get():loadSprite("images/shanguang.png"):addTo(arg_6_0.backgrounds_[arg_6_0.idx_])

			var_7_15:setPosition(var_0_19)

			local var_7_16 = 1
			local var_7_17 = cc.FadeIn:create(var_7_16)
			local var_7_18 = cc.FadeOut:create(var_7_16)

			var_7_15:runAction(cc.RepeatForever:create(cc.Sequence:create(var_7_17, var_7_18)))
			table.insert(arg_6_0.animationSprites_, var_7_15)

			local var_7_19 = display.newSprite():addTo(arg_6_0.backgrounds_[arg_6_0.idx_])

			var_7_19:setPosition(var_0_22)
			var_7_19:setOpacity(0)

			local var_7_20 = cc.DelayTime:create(var_0_21)
			local var_7_21 = cc.FadeIn:create(var_0_8)
			local var_7_22 = cc.CallFunc:create(function()
				local var_9_0 = xyd.AssetLoader.get():loadAnimation(var_0_20, true)

				var_7_19:playAnimationForever(var_9_0)
			end)
			local var_7_23 = cc.Spawn:create(var_7_21, var_7_22)

			var_7_19:runAction(cc.Sequence:create(var_7_20, var_7_23))
			table.insert(arg_6_0.animationSprites_, var_7_19)

			local var_7_24 = cc.ParticleSystemQuad:create("atlases/start_story_2.plist")

			var_7_24:setTexture(cc.Director:getInstance():getTextureCache():addImage("atlases/start_story_2.png"))
			var_7_24:setAutoRemoveOnFinish(true)

			local var_7_25 = cc.ParticleBatchNode:createWithTexture(var_7_24:getTexture())

			var_7_25:addChild(var_7_24)

			local var_7_26 = display.newSprite():addTo(arg_6_0.backgrounds_[arg_6_0.idx_])

			var_7_26:setPosition(cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2))
			var_7_26:addChild(var_7_25)
			table.insert(arg_6_0.animationSprites_, var_7_26)
		elseif arg_6_0.idx_ == 3 then
			for iter_7_3 = 1, #var_0_27 do
				local var_7_27 = xyd.AssetLoader.get():loadAnimation(var_0_26[iter_7_3], true)
				local var_7_28 = display.newSprite():addTo(arg_6_0.backgrounds_[arg_6_0.idx_])

				var_7_28:setPosition(var_0_27[iter_7_3])

				local var_7_29 = cc.Animate:create(var_7_27)

				var_7_28:runAction(cc.RepeatForever:create(var_7_29))
				var_7_28:setScale(var_0_25)
				table.insert(arg_6_0.animationSprites_, var_7_28)
			end

			local var_7_30 = xyd.AssetLoader.get():loadAnimation("sd0", true)
			local var_7_31 = display.newSprite():addTo(arg_6_0.backgrounds_[arg_6_0.idx_])

			var_7_31:setPosition(var_0_28)

			local var_7_32 = cc.Animate:create(var_7_30)

			var_7_31:runAction(cc.RepeatForever:create(var_7_32))
			table.insert(arg_6_0.animationSprites_, var_7_31)

			local var_7_33 = xyd.AssetLoader.get():loadSprite("images/story/outline_03.png")

			var_7_33:pos(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2):addTo(arg_6_0)
			var_7_33:setOpacity(0)

			local var_7_34 = 1
			local var_7_35 = cc.FadeOut:create(var_7_34)
			local var_7_36 = cc.FadeIn:create(var_7_34)

			var_7_33:runAction(cc.RepeatForever:create(cc.Sequence:create(var_7_36, var_7_35)))
			table.insert(arg_6_0.animationSprites_, var_7_33)
		elseif arg_6_0.idx_ == 4 then
			local var_7_37 = xyd.AssetLoader.get():loadAnimation(var_0_29, true)
			local var_7_38 = display.newSprite():pos(0, 0):addTo(arg_6_0.backgrounds_[arg_6_0.idx_])

			var_7_38:setAnchorPoint(cc.p(0, 0))
			var_7_38:playAnimationForever(var_7_37)
			var_7_38:setScale(var_0_30)
			table.insert(arg_6_0.animationSprites_, var_7_38)
		end
	end

	local var_6_1

	local function var_6_2()
		arg_6_0:initLabel(cc.CallFunc:create(var_6_1))
	end

	function var_6_1()
		if arg_6_0.idx_ == var_0_1 then
			display.replaceScene(xyd.EditNameScene.new())

			return
		end

		arg_6_0.label_:setString("")

		if arg_6_0.label_ then
			arg_6_0.label_:removeFromParent()

			arg_6_0.label_ = nil
		end

		if arg_6_0.animationSprites_ then
			for iter_11_0, iter_11_1 in pairs(arg_6_0.animationSprites_) do
				iter_11_1:stopAllActions()
				iter_11_1:removeFromParent()
			end
		end

		arg_6_0.animationSprites_ = {}

		local var_11_0 = cc.ScaleBy:create(var_0_3, var_0_7)
		local var_11_1 = cc.FadeOut:create(var_0_4)
		local var_11_2

		if arg_6_0.idx_ == 1 then
			var_11_2 = var_0_5
		else
			var_11_2 = var_0_6
		end

		local var_11_3 = cc.DelayTime:create(var_0_4 - var_11_2)
		local var_11_4 = cc.FadeIn:create(var_11_2)
		local var_11_5 = arg_6_0.idx_
		local var_11_6 = cc.CallFunc:create(function()
			arg_6_0.backgrounds_[var_11_5]:removeFromParent()
		end)
		local var_11_7

		if arg_6_0.idx_ == 1 then
			local var_11_8 = cc.Spawn:create(var_11_0, var_11_1)

			var_11_7 = transition.sequence({
				var_11_8,
				var_11_6
			})
		else
			var_11_7 = transition.sequence({
				var_11_1,
				var_11_6
			})
		end

		arg_6_0.backgrounds_[arg_6_0.idx_]:runAction(var_11_7)

		arg_6_0.idx_ = arg_6_0.idx_ + 1

		local var_11_9 = cc.CallFunc:create(var_6_2)
		local var_11_10 = cc.CallFunc:create(var_6_0)
		local var_11_11 = cc.Spawn:create(var_11_9, var_11_10)

		arg_6_0.backgrounds_[arg_6_0.idx_] = xyd.AssetLoader.get():loadSprite(string.format("images/story/%02d.png", arg_6_0.idx_))

		arg_6_0.backgrounds_[arg_6_0.idx_]:pos(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2):addTo(arg_6_0)
		arg_6_0.backgrounds_[arg_6_0.idx_]:setOpacity(0)
		arg_6_0.backgrounds_[arg_6_0.idx_]:runAction(transition.sequence({
			var_11_3,
			var_11_4,
			var_11_11
		}))
	end

	local var_6_3 = cc.CallFunc:create(var_6_2)
	local var_6_4 = cc.CallFunc:create(var_6_0)
	local var_6_5 = cc.Spawn:create(var_6_3, var_6_4)

	arg_6_0.backgrounds_[arg_6_0.idx_]:runAction(var_6_5)
end

return var_0_0
