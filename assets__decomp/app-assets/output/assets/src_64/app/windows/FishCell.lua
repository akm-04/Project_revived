local var_0_0 = class("FishCell", function()
	return cc.Node:create()
end)
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = {}

var_0_2[1] = "skeletons/ui_effect/beach/beach_pink"
var_0_2[2] = "skeletons/ui_effect/beach/beach_blue"
var_0_2[3] = "skeletons/ui_effect/beach/beach_red"

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.fishIndex = arg_3_1.fishIndex
	arg_3_0.isConnected = arg_3_1.isConnected
	arg_3_0.explodeSoundPaths = {}
	arg_3_0.explodeSoundPaths[1] = xyd.tables.sound:getSound("beach_pink_explode")
	arg_3_0.explodeSoundPaths[2] = xyd.tables.sound:getSound("beach_blue_explode")
	arg_3_0.explodeSoundPaths[3] = xyd.tables.sound:getSound("beach_red_explode")
	arg_3_0.connectSoundPath = xyd.tables.sound:getSound("beach_connect")
	arg_3_0.connectLines = {}

	arg_3_0:update()
	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)

	arg_3_0.isReset = true
end

function var_0_0.update(arg_4_0)
	if not arg_4_0.fishIndex then
		return
	end

	local var_4_0 = arg_4_0:contentView():nodeByName("container")

	if var_4_0:getChildByName("fish_effect") then
		var_4_0:removeChildByName("fish_effect")
	end

	local var_4_1 = var_0_2[arg_4_0.fishIndex] .. ".json"
	local var_4_2 = var_0_2[arg_4_0.fishIndex] .. ".atlas"

	if arg_4_0.fish and not tolua.isnull(arg_4_0.fish) then
		arg_4_0.fish:removeSelf()

		arg_4_0.fish = nil
	end

	arg_4_0.fish = var_0_1.new(var_4_1, var_4_2, 1)

	arg_4_0.fish:addTo(var_4_0)
	arg_4_0.fish:setAnchorPoint(cc.p(0.5, 0.5))
	arg_4_0.fish:setPosition(var_4_0:getContentSize().width / 2, var_4_0:getContentSize().height / 2 - 40)
	arg_4_0.fish:setAnimation(0, "idle", true)
	arg_4_0.fish:setLocalZOrder(-1)
	arg_4_0.fish:setScale(0.2)
	arg_4_0.fish:setName("fish_effect")
	arg_4_0:initConnectLine()
end

function var_0_0.explode(arg_5_0)
	arg_5_0.isReset = false

	arg_5_0.fish:setAnimation(0, "dead", false)
	audio.playSound(arg_5_0.explodeSoundPaths[arg_5_0.fishIndex], false)
	arg_5_0:initConnectLine()
end

function var_0_0.initConnectLine(arg_6_0)
	if not arg_6_0.fishIndex then
		return
	end

	for iter_6_0 = 1, 3 do
		arg_6_0.contentView_:nodeByName("line_n" .. "_" .. iter_6_0):setVisible(false)
		arg_6_0.contentView_:nodeByName("line_s" .. "_" .. iter_6_0):setVisible(false)
		arg_6_0.contentView_:nodeByName("line_e" .. "_" .. iter_6_0):setVisible(false)
		arg_6_0.contentView_:nodeByName("line_e_n" .. "_" .. iter_6_0):setVisible(false)
		arg_6_0.contentView_:nodeByName("line_e_s" .. "_" .. iter_6_0):setVisible(false)
		arg_6_0.contentView_:nodeByName("line_w" .. "_" .. iter_6_0):setVisible(false)
		arg_6_0.contentView_:nodeByName("line_w_n" .. "_" .. iter_6_0):setVisible(false)
		arg_6_0.contentView_:nodeByName("line_w_s" .. "_" .. iter_6_0):setVisible(false)
		arg_6_0.contentView_:nodeByName("center_" .. iter_6_0):setVisible(false)
	end

	if not arg_6_0.connectLines or not next(arg_6_0.connectLines) then
		arg_6_0.connectLines = {}
		arg_6_0.connectLines["0"] = {}
		arg_6_0.connectLines["1"] = {}
		arg_6_0.connectLines["-1"] = {}
		arg_6_0.connectLines["0"]["1"] = arg_6_0.contentView_:nodeByName("line_n" .. "_" .. arg_6_0.fishIndex)
		arg_6_0.connectLines["0"]["-1"] = arg_6_0.contentView_:nodeByName("line_s" .. "_" .. arg_6_0.fishIndex)
		arg_6_0.connectLines["1"]["0"] = arg_6_0.contentView_:nodeByName("line_e" .. "_" .. arg_6_0.fishIndex)
		arg_6_0.connectLines["1"]["1"] = arg_6_0.contentView_:nodeByName("line_e_n" .. "_" .. arg_6_0.fishIndex)
		arg_6_0.connectLines["1"]["-1"] = arg_6_0.contentView_:nodeByName("line_e_s" .. "_" .. arg_6_0.fishIndex)
		arg_6_0.connectLines["-1"]["0"] = arg_6_0.contentView_:nodeByName("line_w" .. "_" .. arg_6_0.fishIndex)
		arg_6_0.connectLines["-1"]["1"] = arg_6_0.contentView_:nodeByName("line_w_n" .. "_" .. arg_6_0.fishIndex)
		arg_6_0.connectLines["-1"]["-1"] = arg_6_0.contentView_:nodeByName("line_w_s" .. "_" .. arg_6_0.fishIndex)
	end

	if not arg_6_0.connectCenter then
		arg_6_0.connectCenter = arg_6_0.contentView_:nodeByName("center_" .. arg_6_0.fishIndex)
	end
end

function var_0_0.updateByConnectStatus(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if not arg_7_0.fishIndex then
		return
	end

	arg_7_3 = arg_7_3 or 1

	if arg_7_3 == 1 then
		audio.playSound(arg_7_0.connectSoundPath, false)
	end

	if arg_7_1 and arg_7_2 then
		if arg_7_3 == 1 then
			arg_7_0.connectLines[tostring(arg_7_1)][tostring(arg_7_2)]:setVisible(true)
			arg_7_0.connectCenter:setVisible(true)
			arg_7_0.fish:setAnimation(0, "click", true)
		else
			arg_7_0.connectLines[tostring(arg_7_1)][tostring(arg_7_2)]:setVisible(false)
			arg_7_0.connectCenter:setVisible(false)
			arg_7_0.fish:setAnimation(0, "idle", true)
		end
	elseif arg_7_3 == 1 then
		arg_7_0.connectCenter:setVisible(true)
		arg_7_0.fish:setAnimation(0, "click", true)
	else
		arg_7_0.connectCenter:setVisible(false)
		arg_7_0.fish:setAnimation(0, "idle", true)
	end

	arg_7_0.isReset = false
end

function var_0_0.reset(arg_8_0)
	arg_8_0:initConnectLine()
	arg_8_0.fish:setAnimation(0, "idle", true)

	arg_8_0.isReset = true
end

function var_0_0.contentView(arg_9_0)
	if arg_9_0.contentView_ == nil then
		arg_9_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_9_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/beach_activity/main_wnd/fish_cell.csb"))
		arg_9_0.contentView_:addTo(arg_9_0)
		arg_9_0.contentView_:setTouchSwallowEnabled(false)
		arg_9_0:setContentSize(arg_9_0.contentView_:nodeByName("container"):getContentSize())
	end

	return arg_9_0.contentView_
end

return var_0_0
