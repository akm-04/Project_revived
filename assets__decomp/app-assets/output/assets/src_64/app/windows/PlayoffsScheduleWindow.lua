local var_0_0 = class("PlayoffsScheduleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.guildBattleTable
local var_0_4 = xyd.tables.playoffTimeTable
local var_0_5 = 0
local var_0_6 = 6
local var_0_7 = 1
local var_0_8 = 2
local var_0_9 = 3
local var_0_10 = 1
local var_0_11 = 2
local var_0_12 = 3
local var_0_13 = 4
local var_0_14 = 5
local var_0_15 = 6
local var_0_16 = 7
local var_0_17 = 8
local var_0_18 = 8

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.PlayoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.arena = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)

	arg_1_0:setTouchSwallowEnabled(true)
end

function var_0_0.updateListData(arg_2_0)
	arg_2_0.step = arg_2_0.PlayoffsModel.playoff_info.stage
	arg_2_0.listData = {}

	local var_2_0
	local var_2_1 = arg_2_0.step

	arg_2_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)

	local var_2_2 = arg_2_0.regionArena:getSeasonCount()
	local var_2_3 = 1

	if var_2_1 >= 8 then
		var_2_2 = var_2_2 - 1
	end

	if var_2_2 <= 10 then
		var_2_0 = var_0_2:translation("NUM_" .. var_2_2)
	else
		var_2_0 = tostring(var_2_2)
	end

	arg_2_0:nodeByName("title_text"):setString(string.format(var_0_2:translation("SCHEDULE_TITLE"), var_2_0))

	local function var_2_4(arg_3_0, arg_3_1)
		local var_3_0 = {
			type = arg_3_0
		}

		var_3_0.lines = 2

		if var_2_1 == arg_3_0 then
			var_3_0.selected = true
			var_3_0.state = var_0_8
		elseif arg_3_0 > var_2_1 then
			var_3_0.selected = false
			var_3_0.state = var_0_7
		else
			var_3_0.selected = false
			var_3_0.state = var_0_9
		end

		table.insert(arg_2_0.listData, var_3_0)
	end

	for iter_2_0 = 1, var_0_18 do
		var_2_4(iter_2_0, iter_2_0)
	end
end

function var_0_0.updateList(arg_4_0)
	arg_4_0.timeStr = nil

	arg_4_0.listView:removeAllItems()

	local var_4_0 = 0
	local var_4_1 = 0

	for iter_4_0, iter_4_1 in pairs(arg_4_0.listData) do
		local var_4_2 = arg_4_0.listView:newItem()
		local var_4_3 = display.newNode()

		arg_4_0:initCell(var_4_3, iter_4_1)

		local var_4_4 = display.newNode()

		var_4_4:addChild(var_4_3)
		var_4_3:setPosition(0, 0)
		var_4_4:setContentSize(var_4_3:getContentSize())
		var_4_2:setItemSize(var_4_3:getContentSize().width, var_4_3:getContentSize().height)
		var_4_2:addContent(var_4_4)
		arg_4_0.listView:addItem(var_4_2)

		if iter_4_1.selected == true then
			var_4_1 = var_4_0
		end

		var_4_0 = var_4_0 + var_4_3:getContentSize().height
	end

	arg_4_0.listView:reload()
	arg_4_0.listView:scrollTo(0, -var_4_0 + var_4_1 + arg_4_0:nodeByName("list"):getHeight())
	arg_4_0.listView:scrollAuto()
end

function var_0_0.initCell(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0
	local var_5_1

	if arg_5_2.type == var_0_10 then
		if arg_5_2.lines == 1 then
			var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/playoffs/playoffs_resource/schedule/schedule/item_1.csb")
			var_5_1 = var_5_0:getChildByName("container")

			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("ENROLLED"))
		elseif arg_5_2.lines == 2 then
			var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/playoffs/playoffs_resource/schedule/schedule/item_3.csb")
			var_5_1 = var_5_0:getChildByName("container")

			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("ENROLL"))

			arg_5_0.timeStr = var_5_1:getChildByName("item_des2")

			var_5_1:getChildByName("item_des3"):setString("")

			if arg_5_2.state == var_0_8 then
				var_5_1:getChildByName("item_des2"):setString(var_0_2:translation("PLAYOFFS_APPLYING"))

				if arg_5_0.PlayoffsModel.player_info.is_signed == 1 then
					var_5_1:getChildByName("item_des2"):setString(var_0_2:translation("PLAYOFFS_ALREADY_SIGNED"))
					var_5_1:getChildByName("sign_in_container"):getChildByName("sign_in_btn"):setVisible(false)
				end
			elseif arg_5_2.state == var_0_9 then
				var_5_1:getChildByName("item_des2"):setString(var_0_2:translation("PLAYOFFS_AFTER_APPLYING"))
				var_5_1:getChildByName("sign_in_container"):getChildByName("sign_in_btn"):setVisible(false)
			else
				var_5_1:getChildByName("item_des2"):setString(var_0_2:translation("PLAYOFFS_BEFORE_APPLYING"))
				var_5_1:getChildByName("sign_in_container"):getChildByName("sign_in_btn"):setVisible(false)
			end

			var_5_1:getChildByName("des_right"):setVisible(false)
			var_5_1:getChildByName("sign_in_container"):getChildByName("cost_words"):setVisible(false)
			var_5_1:getChildByName("sign_in_container"):getChildByName("huoyuezhi"):setVisible(false)
			var_5_1:getChildByName("sign_in_container"):getChildByName("huoyue_words"):setVisible(false)
			var_5_1:getChildByName("sign_in_container"):getChildByName("sign_in_btn"):getChildByName("text_sign_in"):setString(var_0_2:translation("PLAYOFFS_TEXT_4"))
			var_5_1:getChildByName("sign_in_container"):getChildByName("sign_in_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
				if arg_6_1 == ccui.TouchEventType.ended then
					if arg_5_0.PlayoffsModel.playoff_info.stage == 1 then
						local var_6_0 = xyd.tables.regionArenaLevel:getPlayerArenaLevel(arg_5_0.regionArena:getStar())

						if arg_5_0.PlayoffsModel.player_info.is_signed == 0 then
							xyd.WindowManager.get():openWindow("playoffs_match_time")
						else
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("PLAYOFFS_ALREADY_SIGNED")
							})
						end
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("PLAYOFFS_NOT_SIGNED")
						})
					end
				end
			end)
		else
			var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/playoffs/playoffs_resource/schedule/schedule/item_3.csb")
			var_5_1 = var_5_0:getChildByName("container")

			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("ENROLL"))
			var_5_1:getChildByName("item_des2"):setString(var_0_2:translation("PLAYOFFS_APPLYING"))

			arg_5_0.timeStr = var_5_1:getChildByName("item_des3")
			arg_5_0.tillTime = arg_5_0.guild.warNextStartTime

			var_5_1:getChildByName("sign_in_container"):setVisible(false)
			var_5_1:getChildByName("des_right"):setVisible(false)
		end
	else
		var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/playoffs/playoffs_resource/schedule/schedule/item_1.csb")
		var_5_1 = var_5_0:getChildByName("container")
	end

	var_5_1:getChildByName("item_des1"):setString(var_0_4:project(arg_5_2.type))

	local var_5_2 = var_5_1:getChildByName("time_container")

	var_5_2:getChildByName("date_text"):setString(string.format(var_0_2:translation("TEAM_DATA_DATE"), var_0_4:month(arg_5_2.type), var_0_4:day(arg_5_2.type)))

	local var_5_3 = math.floor(var_0_4:hour(arg_5_2.type))
	local var_5_4 = math.floor(var_0_4:minute(arg_5_2.type))

	var_5_2:getChildByName("time_text"):setString(string.format("%02d:%02d", var_5_3, var_5_4))

	if arg_5_2.selected == false then
		var_5_1:getChildByName("select_bg"):setVisible(false)
		var_5_1:getChildByName("arrow_bg"):setVisible(false)
	else
		var_5_1:getChildByName("item_bg"):setVisible(false)
	end

	if arg_5_2.nobg then
		var_5_1:getChildByName("time_container"):setVisible(false)
		var_5_1:getChildByName("item_bg"):setVisible(false)
		var_5_1:getChildByName("select_bg"):setVisible(false)
		var_5_1:getChildByName("arrow_bg"):setVisible(false)
	end

	local var_5_5 = var_5_1:getContentSize()

	var_5_0:setContentSize(var_5_5)
	arg_5_1:setContentSize(var_5_5)
	var_5_0:setName("layout")
	var_5_0:setPosition(cc.p(0, 0))
	arg_5_1:addChild(var_5_0)
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.startClick_ = true
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.startClick_ = false
	end
end

function var_0_0.willOpen(arg_8_0, arg_8_1)
	var_0_0.super:willOpen(arg_8_1)

	arg_8_0.listView = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_8_0:nodeByName("list"):getWidth(), arg_8_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_8_0:nodeByName("list")):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	arg_8_0.listView:setBounceable(true)
	arg_8_0:updateListData()
	arg_8_0:updateList()
	arg_8_0:addBlockLayer()
	arg_8_0:layout()
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
end

function var_0_0.layout(arg_10_0)
	arg_10_0:nodeByName("rule_btn"):setVisible(false)
	arg_10_0:nodeByName("win_times_text"):setVisible(false)
end

function var_0_0.willClose(arg_11_0, arg_11_1)
	return
end

return var_0_0
