local var_0_0 = class("CGShowWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.openStoryID = arg_1_2.open_story_id
	arg_1_0.playingIndex = 0

	if arg_1_2.callback then
		arg_1_0.callback = arg_1_2.callback
	end

	arg_1_0.effectType = arg_1_2.effect_type
	arg_1_0.storyData = import("app.common.tables.CGShowDataTable").new(arg_1_0.openStoryID)
	arg_1_0.ids = arg_1_0.storyData:ids()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	if arg_2_0.effectType == 1 then
		arg_2_0.bgEffect = cc.ParticleSystemQuad:create("skeletons/ui_effect/common_effect_snow/xuehua_yuan_particle_texture.plist")

		arg_2_0.bgEffect:setPosition(cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT))
		arg_2_0.bgEffect:addTo(arg_2_0, 20001)
		arg_2_0.bgEffect:setVisible(true)
	end

	arg_2_0.middleTxt = arg_2_0:nodeByName("middle_txt")
	arg_2_0.txt = arg_2_0:nodeByName("txt")

	arg_2_0:nodeByName("skip"):setTouchEnabled(true)
	arg_2_0:nodeByName("skip"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
		if arg_3_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("cg_show")
		end

		return true
	end)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 255))
	arg_4_0:CGShow()
end

function var_0_0.didClose(arg_5_0, arg_5_1)
	if arg_5_0.txtHandle then
		var_0_1.unscheduleGlobal(arg_5_0.txtHandle)

		arg_5_0.txtHandle = nil
	end

	if arg_5_0.callback then
		arg_5_0.callback()
	end
end

function var_0_0.CGShow(arg_6_0)
	if arg_6_0.playingIndex >= #arg_6_0.ids then
		arg_6_0:onEnd()

		return
	end

	arg_6_0.playingIndex = arg_6_0.playingIndex + 1

	local var_6_0 = arg_6_0.ids[arg_6_0.playingIndex]
	local var_6_1 = arg_6_0.storyData:funcType(var_6_0)
	local var_6_2 = arg_6_0.storyData:dialog(var_6_0)
	local var_6_3 = arg_6_0.storyData:scale(var_6_0)
	local var_6_4 = arg_6_0.storyData:pos(var_6_0)
	local var_6_5 = arg_6_0.storyData:params(var_6_0)
	local var_6_6 = arg_6_0.storyData:time(var_6_0)

	if var_6_6 <= 0 then
		var_6_6 = 0.1
	end

	local var_6_7 = {}

	arg_6_0.middleTxt:setVisible(false)
	arg_6_0:nodeByName("bottom_layer"):setVisible(false)
	arg_6_0:nodeByName("bottom_layer"):setLocalZOrder(100)

	if arg_6_0.txtHandle then
		var_0_1.unscheduleGlobal(arg_6_0.txtHandle)

		arg_6_0.txtHandle = nil
	end

	if var_6_2 and var_6_2 ~= "" then
		if var_6_1 == 1 then
			arg_6_0.middleTxt:setVisible(true)
			arg_6_0.middleTxt:setString(var_6_2)
		else
			arg_6_0:nodeByName("bottom_layer"):setVisible(true)

			arg_6_0.leftTxt = string.sub(var_6_2, 1, #var_6_2)
			arg_6_0.showTxt = ""

			arg_6_0.txt:setString(arg_6_0.showTxt)

			arg_6_0.txtHandle = var_0_1.scheduleGlobal(function()
				if #arg_6_0.leftTxt > 0 then
					local var_7_0 = string.byte(arg_6_0.leftTxt, 1)
					local var_7_1 = var_7_0 > -127 and var_7_0 < 0 and 3 or 1

					if var_7_1 > #arg_6_0.leftTxt then
						arg_6_0.leftTxt = ""
					elseif var_7_1 == #arg_6_0.leftTxt then
						arg_6_0.showTxt = arg_6_0.showTxt .. arg_6_0.leftTxt
						arg_6_0.leftTxt = ""
					else
						arg_6_0.showTxt = arg_6_0.showTxt .. string.sub(arg_6_0.leftTxt, 1, 3)
						arg_6_0.leftTxt = string.sub(arg_6_0.leftTxt, 4, #arg_6_0.leftTxt)
					end

					arg_6_0.txt:setString(arg_6_0.showTxt)
				elseif not tolua.isnull(arg_6_0) then
					var_0_1.unscheduleGlobal(arg_6_0.txtHandle)
				end
			end, 0.06)
		end
	end

	if var_6_1 == 0 then
		if arg_6_0.img and not tolua.isnull(arg_6_0.img) then
			arg_6_0.img:removeSelf()

			arg_6_0.img = nil
		end

		arg_6_0.img = xyd.AssetLoader.get():loadSprite(var_6_5)

		arg_6_0.img:setAnchorPoint(0.5, 0.5)
		arg_6_0.img:setPosition(var_6_4[1], var_6_4[2])
		arg_6_0.img:addTo(arg_6_0:nodeByName("img_pos"))
		arg_6_0.img:setScale(var_6_3)
		arg_6_0.img:runAction(cc.Sequence:create({
			cc.DelayTime:create(var_6_6),
			cc.CallFunc:create(function()
				arg_6_0:CGShow()
			end)
		}))
	end

	if var_6_1 == 1 then
		arg_6_0.middleTxt:setOpacity(0)

		arg_6_0.upLayer = display.newColorLayer(cc.c4b(0, 0, 0, 255))

		arg_6_0.upLayer:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT / 2)
		arg_6_0.upLayer:setPosition(0, xyd.STAGE_HEIGHT)
		arg_6_0.upLayer:setAnchorPoint(0, 0)
		arg_6_0.upLayer:addTo(arg_6_0)
		arg_6_0.upLayer:setLocalZOrder(99)

		arg_6_0.downLayer = display.newColorLayer(cc.c4b(0, 0, 0, 255))

		arg_6_0.downLayer:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT / 2)
		arg_6_0.downLayer:setPosition(0, -xyd.STAGE_HEIGHT / 2)
		arg_6_0.downLayer:setAnchorPoint(0, 1)
		arg_6_0.downLayer:addTo(arg_6_0)
		arg_6_0.downLayer:setLocalZOrder(98)
		arg_6_0.upLayer:runAction(cc.Sequence:create({
			cc.MoveBy:create(0.1, cc.p(0, -xyd.STAGE_HEIGHT / 2)),
			cc.CallFunc:create(function()
				arg_6_0.img:removeSelf()

				arg_6_0.img = nil

				arg_6_0.upLayer:removeSelf()

				arg_6_0.upLayer = nil

				arg_6_0.middleTxt:runAction(cc.Sequence:create({
					cc.FadeIn:create(2),
					cc.DelayTime:create(var_6_6),
					cc.FadeOut:create(1),
					cc.CallFunc:create(function()
						arg_6_0:CGShow()
					end)
				}))
			end)
		}))
		arg_6_0.downLayer:runAction(cc.Sequence:create({
			cc.MoveBy:create(0.1, cc.p(0, xyd.STAGE_HEIGHT / 2)),
			cc.CallFunc:create(function()
				arg_6_0.downLayer:removeSelf()

				arg_6_0.downLayer = nil
			end)
		}))
	end

	if var_6_1 == 2 then
		arg_6_0.img:runAction(cc.Sequence:create({
			cc.Spawn:create({
				cc.MoveTo:create(var_6_6, cc.p(var_6_4[1], var_6_4[2])),
				cc.ScaleTo:create(var_6_6, var_6_3)
			}),
			cc.CallFunc:create(function()
				arg_6_0:CGShow()
			end)
		}))
	end
end

function var_0_0.onEnd(arg_13_0)
	arg_13_0.light = xyd.AssetLoader.get():loadSprite("images/cg_show/light.png")

	arg_13_0.light:setScale(0)
	arg_13_0.light:addTo(arg_13_0)
	arg_13_0.light:setPosition(640, 360)
	arg_13_0.light:setAnchorPoint(0.5, 0.5)
	arg_13_0.light:runAction(cc.Sequence:create({
		cc.Spawn:create({
			cc.ScaleTo:create(2, 6),
			cc.RotateBy:create(2, 240)
		}),
		cc.CallFunc:create(function()
			xyd.WindowManager.get():closeWindow("cg_show")
		end)
	}))
end

return var_0_0
