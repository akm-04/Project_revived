local var_0_0 = class("ExchangeCodeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layOut()
end

function var_0_0.inputboxEventHandler(arg_3_0, arg_3_1)
	if arg_3_1 == "began" then
		arg_3_0.nameEditbox_:setText(arg_3_0:nodeByName("name_txt"):getString())
		arg_3_0:nodeByName("place_holder"):setString("")
		arg_3_0:nodeByName("name_txt"):setString("")
	end

	if arg_3_1 == "return" then
		local var_3_0 = arg_3_0.nameEditbox_:getText()

		arg_3_0:nodeByName("name_txt"):setString(var_3_0)
		arg_3_0.nameEditbox_:setText("")

		if arg_3_0:nodeByName("name_txt"):getString() == "" then
			arg_3_0:nodeByName("place_holder"):setString(var_0_1:translation("INPUT_EXCHANGE_CODE"))
		else
			arg_3_0:nodeByName("place_holder"):setString("")
		end
	end
end

function var_0_0.layOut(arg_4_0)
	arg_4_0:nodeByName("Text_1"):setString(var_0_1:translation("INPUT_EXCHANGE_CODE") .. var_0_1:translation("COLON"))
	arg_4_0:nodeByName("name_txt"):setString("")

	local var_4_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_4_0, cc.rect(28, 28, 1, 1))

	arg_4_0.nameEditbox_ = ccui.EditBox:create(cc.size(375, 40), var_4_0)

	arg_4_0:nodeByName("edit_name_node"):addChild(arg_4_0.nameEditbox_)
	arg_4_0.nameEditbox_:setAnchorPoint(cc.p(0, 0))
	arg_4_0.nameEditbox_:setPosition(0, 0)

	if arg_4_0:nodeByName("name_txt"):getString() == "" then
		arg_4_0:nodeByName("place_holder"):setString(var_0_1:translation("INPUT_EXCHANGE_CODE"))
	else
		arg_4_0:nodeByName("place_holder"):setString("")
	end

	arg_4_0.nameEditbox_:registerScriptEditBoxHandler(handler(arg_4_0, arg_4_0.inputboxEventHandler))
	arg_4_0.nameEditbox_:setInputFlag(3)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = {
				code = arg_5_0:nodeByName("name_txt"):getString(),
				platform = cc.Application:getInstance():getTargetPlatform()
			}

			xyd.Backend.get():request(xyd.mid.REDEEM_CODE, var_6_0, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					arg_5_0:handleRewards(arg_7_1.awards)
					xyd.WindowManager.get():closeWindow("exchange_code")
				else
					local var_7_0 = var_0_1:translation("INVALID_CODE")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_7_0
					})
				end
			end)
		end
	end)
	arg_5_0:addBlockLayer()
end

function var_0_0.handleRewards(arg_8_0, arg_8_1)
	local var_8_0 = {}
	local var_8_1 = {}
	local var_8_2

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		if iter_8_1.is_partner == true then
			var_8_2 = iter_8_1
			iter_8_1.item_num = 1

			table.insert(var_8_0, iter_8_1)
		elseif iter_8_1.to_stone == true then
			var_8_2 = iter_8_1

			table.insert(var_8_0, iter_8_1)
			table.insert(var_8_1, iter_8_1)
		else
			table.insert(var_8_0, iter_8_1)
			table.insert(var_8_1, iter_8_1)
		end
	end

	for iter_8_2, iter_8_3 in ipairs(var_8_1) do
		arg_8_0.player:getBackpack():addItemsByID(tonumber(iter_8_3.table_id), tonumber(iter_8_3.item_num))
	end

	if var_8_2 then
		local var_8_3 = {}

		if var_8_2.is_partner then
			local var_8_4 = var_0_2.new()

			var_8_4:populate(var_8_2)
			arg_8_0.player:addHero(var_8_4)

			local var_8_5 = {
				toStone = false,
				partnerID = var_8_2.table_id
			}
			local var_8_6 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_8_5)

			cc.EventProxy.new(var_8_6, var_8_6):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
				xyd.WindowManager.get():openWindow("alert_award", {
					awards = var_8_0
				})
			end)
		elseif var_8_2.to_stone then
			local var_8_7 = {
				partnerID = xyd.tables.item:heroID(var_8_2.table_id),
				toStone = tonumber(var_8_2.item_num)
			}
			local var_8_8 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_8_7)

			cc.EventProxy.new(var_8_8, var_8_8):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
				xyd.WindowManager.get():openWindow("alert_award", {
					awards = var_8_0
				})
			end)
		end
	else
		xyd.WindowManager.get():openWindow("alert_award", {
			awards = var_8_0
		})
	end
end

function var_0_0.showRewards(arg_11_0, arg_11_1)
	if arg_11_1 and #arg_11_1 > 0 then
		-- block empty
	end
end

return var_0_0
