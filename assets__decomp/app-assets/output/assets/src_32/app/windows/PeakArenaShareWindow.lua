local var_0_0 = class("PeakArenaShareWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena_share/share_item.csb")
	local var_4_1 = var_4_0:getChildByName("background")

	var_4_0:setContentSize(var_4_1:getContentSize())
	var_4_0:addTo(arg_4_0:nodeByName("list"))
	var_4_0:setAnchorPoint(cc.p(0, 0))
	var_4_0:setPosition(0, 0)
	var_4_1:getChildByName("battle_num"):setVisible(false)
	var_4_1:getChildByName("left_name_txt"):setString(arg_4_0.attackerName)
	var_4_1:getChildByName("right_name_txt"):setString(arg_4_0.defenderName)
	var_4_1:getChildByName("left_lev"):setString(arg_4_0.attackerLev)
	var_4_1:getChildByName("right_lev"):setString(arg_4_0.defenderLev)

	if arg_4_0.isAttackWin then
		var_4_1:getChildByName("piaodai_green_left"):setVisible(true)
		var_4_1:getChildByName("piaodai_red_left"):setVisible(false)
		var_4_1:getChildByName("piaodai_red_right"):setVisible(true)
		var_4_1:getChildByName("piaodai_green_right"):setVisible(false)
	else
		var_4_1:getChildByName("piaodai_green_left"):setVisible(false)
		var_4_1:getChildByName("piaodai_red_left"):setVisible(true)
		var_4_1:getChildByName("piaodai_red_right"):setVisible(false)
		var_4_1:getChildByName("piaodai_green_right"):setVisible(true)
	end

	local var_4_2 = xyd.setAvatarClip(var_4_1:getChildByName("left_avatar"), arg_4_0.attackerAvatar, 1)
	local var_4_3 = xyd.setAvatarClip(var_4_1:getChildByName("right_avatar"), arg_4_0.defenderAvatar, 1)
	local var_4_4 = xyd.AssetLoader.get():loadSprite("images/avatar_frames/1.png")
	local var_4_5 = xyd.AssetLoader.get():loadSprite("images/avatar_frames/1.png")
	local var_4_6 = var_4_4:getContentSize().height
	local var_4_7 = var_4_2:getContentSize().height
	local var_4_8 = var_4_2:getContentSize().width
	local var_4_9 = var_4_7 / var_4_6

	var_4_4:setScale(var_4_9)
	var_4_5:setScale(var_4_9)
	var_4_4:addTo(var_4_2)
	var_4_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_4:setPosition(var_4_8 / 2, var_4_7 / 2)
	var_4_5:addTo(var_4_3)
	var_4_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_5:setPosition(var_4_8 / 2, var_4_7 / 2)

	for iter_4_0 = 1, #arg_4_0.herosA do
		local var_4_10 = var_4_1:getChildByName("icon" .. iter_4_0)
		local var_4_11 = arg_4_0.herosA[iter_4_0]
		local var_4_12 = var_4_11:getColor()
		local var_4_13 = var_4_11:getStar()
		local var_4_14 = var_4_11:getLevel()
		local var_4_15 = xyd.setAvatarBorderWithLevelAndHp(var_4_11, var_4_10, var_4_12, var_4_13, var_4_14)
		local var_4_16 = var_4_8 / 90
		local var_4_17 = {
			size = 12
		}
	end

	for iter_4_1 = 1, #arg_4_0.herosB do
		local var_4_18 = var_4_1:getChildByName("icon" .. iter_4_1 + 5)
		local var_4_19 = arg_4_0.herosB[iter_4_1]
		local var_4_20 = var_4_19:getColor()
		local var_4_21 = var_4_19:getStar()
		local var_4_22 = var_4_19:getLevel()
		local var_4_23 = xyd.setAvatarBorderWithLevelAndHp(var_4_19, var_4_18, var_4_20, var_4_21, var_4_22)
		local var_4_24 = var_4_8 / 90
		local var_4_25 = {
			size = 12
		}
	end

	var_4_1:getChildByName("replay_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0:replayRecord(arg_4_0.report)
		end
	end)
end

function var_0_0.initHeros(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1

	arg_6_0.jsonData_ = json.decode(var_6_0)

	local var_6_1 = arg_6_0.jsonData_.formationA
	local var_6_2 = arg_6_0.jsonData_.formationB

	for iter_6_0, iter_6_1 in ipairs(var_6_1) do
		local var_6_3 = var_0_1.new()

		var_6_3:populate(iter_6_1)
		table.insert(arg_6_0.herosA, var_6_3)
	end

	for iter_6_2, iter_6_3 in ipairs(var_6_2) do
		local var_6_4 = var_0_1.new()

		var_6_4:populate(iter_6_3)
		table.insert(arg_6_0.herosB, var_6_4)
	end
end

function var_0_0.replayRecord(arg_7_0, arg_7_1)
	local var_7_0 = {
		campaignType = xyd.CampaignType.ARENA,
		campaignID = arg_7_0.campaignID,
		jsonData = arg_7_1[1].content
	}

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = xyd.WindowName.arenaRecordWnd
		}
	})
	xyd.WindowManager.get():retainHistory()
	cc.Director:getInstance():pushScene(xyd.ReportScene.new(var_7_0))
end

return var_0_0
