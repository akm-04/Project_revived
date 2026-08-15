local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = 3
local var_0_4 = 15

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.count = arg_1_1.idx
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0.container:getChildByName("title"):setPositionY(arg_2_0.container:getChildByName("title"):getPositionY() + 2)

	arg_2_0.awardContainer = arg_2_0.container:getChildByName("award_container")

	arg_2_0:layout()
end

function var_0_0.initListView(arg_3_0)
	local var_3_0 = arg_3_0.awardContainer:getContentSize().width
	local var_3_1 = arg_3_0.awardContainer:getContentSize().height

	arg_3_0.awardList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_0, var_3_1),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.awardContainer):onScroll(handler(arg_3_0, arg_3_0.scrollListener))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:initListView()
	arg_4_0:initAwardLayout()
end

function var_0_0.initAwardLayout(arg_5_0)
	local var_5_0 = xyd.tables.activityNewLevUp:getIDs()

	for iter_5_0 = 1, #var_5_0 do
		local var_5_1 = var_5_0[iter_5_0]
		local var_5_2 = arg_5_0.awardList:newItem()
		local var_5_3 = display.newNode()
		local var_5_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1071/award_item.csb")
		local var_5_5 = var_5_4:getChildByName("container")

		arg_5_0:rewardItemLayout(arg_5_0.activity, var_5_5, arg_5_0.count, var_5_1)
		var_5_4:addTo(var_5_3)
		var_5_4:setTouchEnabled(true)
		var_5_4:setAnchorPoint(cc.p(0, 0))
		var_5_4:setPosition(var_0_4, 0)
		var_5_4:setTouchSwallowEnabled(false)

		local var_5_6 = var_5_5:getContentSize()

		var_5_3:setContentSize(var_5_6.width + var_0_4, var_5_6.height + var_0_3)
		var_5_2:addContent(var_5_3)
		var_5_2:setItemSize(var_5_6.width + var_0_4, var_5_6.height + var_0_3)
		arg_5_0.awardList:addItem(var_5_2)
	end

	arg_5_0.awardList:reload()
end

function var_0_0.rewardItemLayout(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0 = arg_6_2:getChildByName("btn_get")
	local var_6_1 = arg_6_2:getChildByName("bg_yilingqu")
	local var_6_2 = arg_6_2:getChildByName("yilingqu_big")
	local var_6_3 = var_6_0:getChildByName("img_lingqu")
	local var_6_4 = var_6_0:getChildByName("img_lingqu_gray")

	var_6_0:getChildByName("img_lingqu"):setString(var_0_2:translation("ACTIVITY_1071_TEXT1"))
	var_6_0:getChildByName("img_lingqu_gray"):setString(var_0_2:translation("ACTIVITY_1071_TEXT1"))

	local var_6_5 = {
		btn = var_6_0,
		alreadyObtain1 = var_6_1,
		alreadyObtain2 = var_6_2,
		obtain_bright = var_6_3,
		obtain_gray = var_6_4
	}
	local var_6_6 = arg_6_2:getChildByName("detail_container")
	local var_6_7 = arg_6_2:getChildByName("lv_img")
	local var_6_8 = xyd.tables.activityNewLevUp:level(arg_6_4)

	local function var_6_9(arg_7_0)
		local var_7_0 = "windows/activities/1071/" .. arg_7_0 .. ".png"

		return xyd.AssetLoader.get():loadSprite(var_7_0)
	end

	local var_6_10 = display.newNode()
	local var_6_11 = 0
	local var_6_12 = var_6_8

	while var_6_12 > 0 do
		local var_6_13 = var_6_12 % 10

		var_6_12 = math.floor(var_6_12 / 10)

		local var_6_14 = var_6_9(var_6_13)

		var_6_11 = var_6_11 + var_6_14:getWidth() / 2
		hight = var_6_14:getHeight()

		var_6_14:addTo(var_6_10, 10)
		var_6_14:setAnchorPoint(0.5, 0)
		var_6_14:setPosition(-var_6_11, 0)
	end

	var_6_10:setAnchorPoint(0, 0)
	var_6_10:setPosition(cc.p(var_6_11 / 2, 0))
	var_6_10:addTo(var_6_7)

	local var_6_15 = xyd.ServerTime.get():getServerTime()
	local var_6_16 = xyd.splitToNumber(arg_6_1.details.is_awards, "|")
	local var_6_17 = xyd.tables.activityNewLevUp:gift(arg_6_4)

	if #var_6_17 == 1 then
		arg_6_0:rewardFormat(var_6_6, var_6_17[1])
	else
		arg_6_0:rewardMutiHeroFormat(var_6_6, var_6_17[1], arg_6_4)
	end

	if not var_6_16 then
		arg_6_0:setBtnGetState(-1, var_6_5)

		return
	end

	if var_6_16[arg_6_4] == 1 then
		arg_6_0:setBtnGetState(0, var_6_5)
	elseif var_6_16[arg_6_4] == 0 and var_6_8 <= arg_6_0.player.lev then
		arg_6_0:setBtnGetState(1, var_6_5)
	else
		arg_6_0:setBtnGetState(-1, var_6_5)
	end

	var_6_0:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			var_6_0:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.moved then
			var_6_0:setScale(1)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			var_6_0:setScale(1)

			local function var_8_0()
				arg_6_0:setBtnGetState(0, var_6_5)

				local var_9_0 = xyd.luaStringSplit(arg_6_0.activities[arg_6_3].details.is_awards, "|")

				var_9_0[arg_6_4] = "1"

				local var_9_1 = xyd.luaStringMerge(var_9_0, "|")

				arg_6_0.activities[arg_6_3].details.is_awards = var_9_1

				arg_6_0.activitiesModel:clearRedMarkState(arg_6_1.table_id, 2)

				local var_9_2 = xyd.WindowManager.get():getWindow("activities")

				if var_9_2 and var_9_2.rightItems then
					var_9_2:updateRightCell(arg_6_1.table_id)
				end
			end

			if #var_6_17 == 1 then
				arg_6_0.activitiesModel:getActivityReward2(arg_6_1.table_id, arg_6_4, 1, function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						arg_6_0.player:handleRewards(arg_10_1.awards)
						var_8_0()
					end
				end)
			elseif #var_6_17 == 3 then
				local var_8_1 = {
					id = arg_6_4,
					activityID = arg_6_1.table_id,
					callback = var_8_0,
					giftIDs = xyd.tables.activityNewLevUp:gift(arg_6_4)
				}

				xyd.WindowManager.get():openWindow("select_hero_giftbag", var_8_1)
			end
		end
	end)
end

function var_0_0.setBtnGetState(arg_11_0, arg_11_1, arg_11_2)
	if arg_11_1 == 1 then
		arg_11_2.btn:setVisible(true)
		arg_11_2.btn:setTouchEnabled(true)
		arg_11_2.btn:setBright(true)
		arg_11_2.alreadyObtain1:setVisible(false)
		arg_11_2.alreadyObtain2:setVisible(false)
		arg_11_2.obtain_bright:setVisible(true)
		arg_11_2.obtain_gray:setVisible(false)
	elseif arg_11_1 == -1 then
		arg_11_2.btn:setVisible(true)
		arg_11_2.btn:setTouchEnabled(false)
		arg_11_2.btn:setBright(false)
		arg_11_2.alreadyObtain1:setVisible(false)
		arg_11_2.alreadyObtain2:setVisible(false)
		arg_11_2.obtain_bright:setVisible(false)
		arg_11_2.obtain_gray:setVisible(true)
	elseif arg_11_1 == 0 then
		arg_11_2.btn:setVisible(false)
		arg_11_2.btn:setTouchEnabled(false)
		arg_11_2.btn:setBright(false)
		arg_11_2.alreadyObtain1:setVisible(true)
		arg_11_2.alreadyObtain2:setVisible(true)
		arg_11_2.obtain_bright:setVisible(false)
		arg_11_2.obtain_gray:setVisible(false)
	end
end

function var_0_0.rewardMutiHeroFormat(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = display.newNode()

	var_12_0:setContentSize(arg_12_1:getHeight(), arg_12_1:getHeight())
	xyd.setSpriteBorder(var_12_0, xyd.tables.activityNewLevUp:giftIcon(arg_12_3), 1)
	var_12_0:addTo(arg_12_1)
	var_12_0:setPosition(0, 0)
	var_12_0:setAnchorPoint(cc.p(0, 0))

	local var_12_1 = {}

	var_12_1.id = -100000
	var_12_1.tipsType = 1
	var_12_1.desc1 = xyd.tables.activityNewLevUp:giftDesc(arg_12_3)

	arg_12_0:setAvatorFrameItemEffect(var_12_0)
	arg_12_0:addTips(var_12_0, var_12_1)

	local var_12_2 = arg_12_1:getContentSize().height
	local var_12_3 = var_12_2 / 4
	local var_12_4 = xyd.tables.gift:items(arg_12_2)

	if #var_12_4 == 1 and var_12_4[1] == 0 then
		var_12_4 = {}
	end

	local var_12_5 = xyd.tables.gift:itemNum(arg_12_2)
	local var_12_6 = #var_12_4

	for iter_12_0 = 2, #var_12_4 do
		local var_12_7 = display.newNode()

		var_12_7:setContentSize(var_12_2, var_12_2)

		if xyd.tables.item:type(var_12_4[iter_12_0]) == -1 then
			xyd.setAvatarBorder(var_12_4[iter_12_0], var_12_7, 1, xyd.tables.hero:initialStar(var_12_4[iter_12_0]))
		else
			xyd.setItemBorder(var_12_7, var_12_4[iter_12_0], false, false, var_12_5[iter_12_0])
		end

		var_12_7:addTo(arg_12_1)
		var_12_7:setAnchorPoint(cc.p(0, 0))
		var_12_7:setPosition((iter_12_0 - 1) * (var_12_2 + var_12_3), 0)

		local var_12_8 = {
			id = var_12_4[iter_12_0],
			lev = xyd.tables.item:level(var_12_4[iter_12_0])
		}

		if xyd.tables.item:type(var_12_4[iter_12_0]) == -1 then
			var_12_8.tipsType = 0
			var_12_8.desc1 = xyd.tables.hero:getDes(var_12_4[iter_12_0])
		elseif specialItem then
			var_12_8.tipsType = 1
			var_12_8.id = -3
		else
			var_12_8.tipsType = 1
			var_12_8.desc1 = xyd.tables.item:desc1(var_12_4[iter_12_0])
			var_12_8.desc2 = xyd.tables.item:desc2(var_12_4[iter_12_0])
		end

		var_12_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_12_4[iter_12_0])
		var_12_8.name = xyd.tables.item:name(var_12_4[iter_12_0])

		arg_12_0:addTips(var_12_7, var_12_8)
	end

	local var_12_9 = xyd.tables.gift:crystal(arg_12_2)

	if var_12_9 and var_12_9 > 0 then
		local var_12_10 = display.newNode()

		var_12_10:setContentSize(var_12_2, var_12_2)
		xyd.setItemBorder(var_12_10, -1, false, false, var_12_9)
		var_12_10:addTo(arg_12_1)
		var_12_10:setAnchorPoint(cc.p(0, 0))
		var_12_10:setPosition(var_12_6 * (var_12_2 + var_12_3), 0)

		local var_12_11 = {}

		var_12_11.id = -1
		var_12_11.tipsType = 1

		arg_12_0:addTips(var_12_10, var_12_11)

		var_12_6 = var_12_6 + 1
	end

	local var_12_12 = xyd.tables.gift:mana(arg_12_2)

	if var_12_12 and var_12_12 > 0 then
		local var_12_13 = display.newNode()

		var_12_13:setContentSize(var_12_2, var_12_2)
		xyd.setItemBorder(var_12_13, -2, false, false, var_12_12)
		var_12_13:addTo(arg_12_1)
		var_12_13:setAnchorPoint(cc.p(0, 0))
		var_12_13:setPosition(var_12_6 * (var_12_2 + var_12_3), 0)

		local var_12_14 = {}

		var_12_14.id = -2
		var_12_14.tipsType = 1

		arg_12_0:addTips(var_12_13, var_12_14)

		local var_12_15 = var_12_6 + 1
	end
end

function var_0_0.setAvatorFrameItemEffect(arg_13_0, arg_13_1)
	local var_13_0 = xyd.tables.activitySpringLogin:setEffect(3)
	local var_13_1 = tonumber(item)
	local var_13_2 = "skeletons/ui_effect/common_effect_summon4/common_effect_summon4"
	local var_13_3 = var_13_2 .. ".json"
	local var_13_4 = var_13_2 .. ".atlas"
	local var_13_5 = var_0_1.new(var_13_3, var_13_4, 1)

	arg_13_1:addChild(var_13_5)
	var_13_5:setLocalZOrder(-100)
	var_13_5:setPosition(arg_13_1:getWidth() / 2, arg_13_1:getHeight() / 2)
	var_13_5:setScale(0.4)
	var_13_5:play(nil, true)
end

return var_0_0
