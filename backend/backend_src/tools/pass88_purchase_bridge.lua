-- Pass88 preservation purchase bridge helper.
-- PRIVATE-SERVER TEST SHIM; not recovered historical client code.
--
-- Manual call:
--     xyd.pass88Purchase(80001007)
--
-- Optional Recharge-window interception (direct Crystal SKUs only):
--     xyd.installPass88PurchaseBridge()
-- After installation, VipRechargeWindow's normal direct-pack clicks are routed
-- to /preservation/v1/purchase-intents instead of the missing native SDK.

local pass88Direct = {
    [80001002] = true,
    [80001003] = true,
    [80001004] = true,
    [80001005] = true,
    [80001006] = true,
    [80001007] = true,
    [80001030] = true
}

local function pass88Endpoint()
    local url = xyd.Backend.get():getWebAPIURL_()
    url = string.gsub(url, "/api/v1/$", "")
    url = string.gsub(url, "/api/v1$", "")
    return url .. "/preservation/v1/purchase-intents"
end

local pass88Sequence = 0

function xyd.pass88Purchase(chargeID, intentID)
    chargeID = tonumber(chargeID)
    if not chargeID or not pass88Direct[chargeID] then
        print("[PASS88] refusing unsupported direct chargeID=" .. tostring(chargeID))
        return nil
    end

    pass88Sequence = pass88Sequence + 1
    intentID = intentID or ("lua-" .. tostring(xyd.ServerTime.get():getServerTime()) .. "-" .. tostring(pass88Sequence))

    local function completed(evt)
        if evt.name ~= "completed" and evt.name ~= "failed" then
            return
        end
        if evt.name ~= "completed" then
            print("[PASS88] purchase bridge HTTP failure intent=" .. tostring(intentID))
            return
        end
        local code = evt.request:getResponseStatusCode()
        local raw = evt.request:getResponseString()
        print("[PASS88] purchase bridge code=" .. tostring(code) .. " body=" .. tostring(raw))
        if code ~= 200 then
            return
        end
        local body = json.decode(raw)
        if not body or body.ok ~= 1 or not body.recharge_event then
            return
        end
        -- Effective Backend.lua maps MID36857 -> xyd.event.RECHARGE and
        -- SelfPlayer:onRecharge_ reads event.params.params. Dispatching the
        -- returned {mid=36857, params={...}} as Event.params preserves that shape.
        xyd.EventDispatcher.get():dispatchEvent({
            name = xyd.event.RECHARGE,
            params = body.recharge_event
        })
    end

    local req = network.createHTTPRequest(completed, pass88Endpoint(), "POST")
    req:addFormContents("intent_id", tostring(intentID), 0)
    req:addFormContents("charge_id", tostring(chargeID), 0)
    req:addFormContents("platform", "lua_preservation", 0)
    req:addFormContents("token", tostring(xyd.Backend.get().token_), 0)
    req:addFormContents("region", tostring(xyd.Backend.get().region_), 0)
    req:start()
    return intentID
end

local pass88Installed = false
local pass88OriginalAndroidPurchase = nil
local pass88OriginalSdkPurchase = nil

function xyd.installPass88PurchaseBridge()
    if pass88Installed then
        return true
    end
    pass88Installed = true
    pass88OriginalAndroidPurchase = xyd.androidPurchase
    pass88OriginalSdkPurchase = xyd.sdkPurchase

    -- Effective VipRechargeWindow.lua passes charge_id as androidPurchase arg3.
    xyd.androidPurchase = function(arg1, arg2, chargeID, arg4, arg5, arg6, arg7)
        local id = tonumber(chargeID)
        if id and pass88Direct[id] then
            return xyd.pass88Purchase(id)
        end
        return pass88OriginalAndroidPurchase(arg1, arg2, chargeID, arg4, arg5, arg6, arg7)
    end

    -- Effective VipRechargeWindow.lua passes charge_id as sdkPurchase arg3.
    xyd.sdkPurchase = function(productID, canBuy, chargeID, arg4, arg5, arg6)
        local id = tonumber(chargeID)
        if id and pass88Direct[id] then
            return xyd.pass88Purchase(id)
        end
        return pass88OriginalSdkPurchase(productID, canBuy, chargeID, arg4, arg5, arg6)
    end

    print("[PASS88] direct Crystal purchase bridge installed")
    return true
end

function xyd.uninstallPass88PurchaseBridge()
    if not pass88Installed then
        return true
    end
    if pass88OriginalAndroidPurchase then
        xyd.androidPurchase = pass88OriginalAndroidPurchase
    end
    if pass88OriginalSdkPurchase then
        xyd.sdkPurchase = pass88OriginalSdkPurchase
    end
    pass88Installed = false
    print("[PASS88] direct Crystal purchase bridge removed")
    return true
end
