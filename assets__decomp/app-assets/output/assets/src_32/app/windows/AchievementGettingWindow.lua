local var_0_0 = class("AchievementGettingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = "skeletons/ui_effect/effect_redpacket/effect_redpacket3"
local var_0_4 = "skeletons/ui_effect/achievement/achievement_cup_gold_star"
local var_0_5 = "skeletons/ui_effect/achievement/achievement_cup_silver_circle"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.achievement = xyd.ModelManager.get():loadModel(xyd.ModelType.ACHIEVEMENT)
	arg_1_0.ids = {}

	if arg_1_2 then
		arg_1_0.ids = arg_1_2.ids or {}
	end

	arg_1_0.index = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:updateToNextPiece()
	arg_3_0:setTouchEnabled(true)
	arg_3_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			arg_3_0:updateToNextPiece()
		end
	end)
end

function var_0_0.updateToNextPiece(arg_5_0)
	arg_5_0.index = arg_5_0.index + 1

	if arg_5_0.index > #arg_5_0.ids then
		if arg_5_0.selfPlayer.newAchievementIds and next(arg_5_0.selfPlayer.newAchievementIds) then
			arg_5_0.ids = clone(arg_5_0.selfPlayer.newAchievementIds)
			arg_5_0.selfPlayer.newAchievementIds = {}
			arg_5_0.index = 1
		else
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_5_0)

			return
		end
	end

	local var_5_1 = xyd.tables.achievement:name(arg_5_0.ids[arg_5_0.index])

	arg_5_0:nodeByName("desc_txt"):setString(string.format(var_0_2:translation("GET_NEW_ACHIEVEMENT"), var_5_1))
	arg_5_0:nodeByName("desc_txt"):enableShadow(cc.c4b(11, 11, 11, 250), cc.size(1, -1), 1)
	arg_5_0:nodeByName("graph_pos"):removeAllChildren()

	local var_5_2 = arg_5_0.achievement:getLatestIndexById(arg_5_0.ids[arg_5_0.index])
	local var_5_3 = xyd.tables.achievement:icon(arg_5_0.ids[arg_5_0.index]) .. var_5_2 .. ".png"

	sprite = xyd.SpriteLoader.new(var_5_3, nil, nil, xyd.DefaultImageType.ACHIEVEMENT_ICON)

	sprite:addTo(arg_5_0:nodeByName("graph_pos"))
	sprite:setScale(0.5)
	sprite:runAction(cc.ScaleTo:create(1, 1))
	arg_5_0:nodeByName("effect_pos"):removeAllChildren()

	local var_5_4 = var_0_3 .. ".json"
	local var_5_5 = var_0_3 .. ".atlas"

	arg_5_0.clickEffect = var_0_1.new(var_5_4, var_5_5, 1)

	arg_5_0.clickEffect:addTo(arg_5_0:nodeByName("effect_pos"))
	arg_5_0.clickEffect:play(nil, false)
	arg_5_0.clickEffect:runAction(cc.ScaleTo:create(0.5, 2))

	if var_5_2 == 3 then
		arg_5_0.achievement:addEffect(var_0_4, arg_5_0:nodeByName("graph_pos"), cc.p(0, 40), 2)
	elseif var_5_2 == 2 then
		arg_5_0.achievement:addEffect(var_0_5, arg_5_0:nodeByName("graph_pos"), cc.p(0, 40), 2)
	end
end

function var_0_0.addBlockLayer(arg_6_0)
	if color == nil then
		color = cc.c4b(0, 0, 0, 200)
	end

	arg_6_0.blockLayer_ = display.newColorLayer(color)

	local var_6_0 = arg_6_0:convertToWorldSpace(cc.p(0, 0))

	arg_6_0.blockLayer_:pos(-var_6_0.x, -var_6_0.y):addTo(arg_6_0, -1)

	local function var_6_1(arg_7_0, arg_7_1)
		return true
	end

	local function var_6_2(arg_8_0, arg_8_1)
		arg_6_0:updateToNextPiece()
	end

	arg_6_0.layerListener = cc.EventListenerTouchOneByOne:create()

	arg_6_0.layerListener:setSwallowTouches(true)
	arg_6_0.layerListener:registerScriptHandler(var_6_1, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_6_0.layerListener:registerScriptHandler(var_6_2, cc.Handler.EVENT_TOUCH_ENDED)
	arg_6_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_6_0.layerListener, arg_6_0.contentView_)
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
	arg_9_0:addBlockLayer()
end

return var_0_0
