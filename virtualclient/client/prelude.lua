-- Engine model for the headless stock client: recording proxies for every native the harness does not implement, plus the
-- small slice of cocos2d-x the stock Lua relies on for control flow (scene graph events, timer actions, scheduler, director).
local native = __native
local report = {missing = {}, scenes = {}, errors = {}, sdk = {}, proxies = 0}
__vc = {report = report}

-- LuaJIT parses tonumber(text, 16) with C strtoul, which accepts a "0x" prefix (stock csb text styles such as "0x000000ff").
local baseToNumber = tonumber
function tonumber(value, base)
	if base == 16 and type(value) == "string" then
		value = (string.gsub(value, "^(%s*[-+]?)0[xX]", "%1"))
	end
	return baseToNumber(value, base)
end

local names = setmetatable({}, {__mode = "k"})
local classes = setmetatable({}, {__mode = "k"})
local shared = {}
local nodeMethods = {}
local nodeBase, widgetBase
-- widgetMethods are the native ui::Widget methods the engine model implements.
local widgetMethods = {}

-- A stock run reaches a few hundred proxies; a loop the engine model never ends would create them until memory runs out.
local proxyLimit = 100000

local function proxy(name, class)
	report.proxies = report.proxies + 1
	if report.proxies > proxyLimit then
		error("engine model: more than " .. proxyLimit .. " native proxies, last " .. name)
	end
	local node = setmetatable({}, shared)
	names[node] = name
	classes[node] = class
	return node
end

local function inherited(node, key)
	local class = classes[node]
	while class do
		local value = rawget(class, key)
		if type(value) == "function" then
			return value
		end
		class = classes[class]
	end
	local name = names[node]
	if not (nodeBase and name:find("%)")) then
		return
	end
	-- As on tolua, a widget finds ccui.Widget methods (stock Lua, then native) before stock Lua cc.Node extensions (NodeEx).
	if name:sub(1, 5) == "ccui." then
		local value = rawget(widgetBase, key)
		if type(value) == "function" then
			return value
		end
		if widgetMethods[key] then
			return widgetMethods[key]
		end
	end
	local value = rawget(nodeBase, key)
	if type(value) == "function" then
		return value
	end
end

-- An engine object (a call result) answers only for methods, so unset Lua fields on it read nil as on a tolua peer; module tables
-- (cc.Label, ccui.TextureResType) answer for anything except the xyd fields stock Lua assigns itself. Methods are the names stock
-- ever calls with ":".
shared.__index = function(node, key)
	local value = inherited(node, key) or nodeMethods[key]
	if value then
		return value
	end
	if names[node]:find("%)") and not native.methods[key] then
		return nil
	end
	if names[node] == "xyd" and native.assigned[key] then
		return nil
	end
	local child = proxy(names[node] .. "." .. tostring(key))
	rawset(node, key, child)
	return child
end
shared.__call = function(node, self, ...)
	local name = names[node]
	report.missing[name] = (report.missing[name] or 0) + 1
	local owner = name:match("^(.*)%.[^.]+$")
	local class
	if type(self) == "table" and names[self] == owner then
		class = self
	end
	return proxy(name .. "()", class)
end
shared.__concat = function(a, b) return tostring(a) .. tostring(b) end
shared.__tostring = function() return "" end
for _, event in ipairs({"__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm"}) do
	shared[event] = function() return 0 end
end
shared.__lt = function() return false end
shared.__le = function() return true end
shared.__eq = function() return false end
__proxy = proxy
cc = proxy("cc")

-- Stock gives native tables metatables of its own (framework/cc/init.lua makes cc callable); on a proxy they layer over recording.
local baseSetmetatable = setmetatable
function setmetatable(target, metatable)
	if names[target] == nil or metatable == nil then
		return baseSetmetatable(target, metatable)
	end
	local merged = {}
	for key, value in pairs(shared) do
		merged[key] = value
	end
	for key, value in pairs(metatable) do
		merged[key] = value
	end
	local index = metatable.__index
	if index ~= nil then
		merged.__index = function(node, key)
			local value
			if type(index) == "function" then
				value = index(node, key)
			else
				value = index[key]
			end
			if value ~= nil then
				return value
			end
			return shared.__index(node, key)
		end
	end
	return baseSetmetatable(target, merged)
end

-- Error path of the engine: every callback the engine runs reports a Lua error through __G__TRACKBACK__, as cocos2d-x does.
local function reportError(message)
	message = tostring(message)
	table.insert(report.errors, debug.traceback(message, 2))
	local handler = rawget(_G, "__G__TRACKBACK__")
	if handler then
		pcall(handler, message)
	end
	return message
end

local function invoke(callback, ...)
	local arguments = {...}
	local count = select("#", ...)
	local recorded = #report.errors
	local results = {xpcall(function() return callback(unpack(arguments, 1, count)) end, reportError)}
	-- gopher-lua skips the handler on a stack overflow; the error must still fail the run.
	if not results[1] and #report.errors == recorded then
		table.insert(report.errors, tostring(results[2]))
	end
	return unpack(results, 1, table.maxn(results))
end
__vc.invoke = invoke

-- Scene graph: script handlers, children and the running flag drive stock enter/exit callbacks.
local graph = setmetatable({}, {__mode = "k"})
local function stateOf(node)
	local state = graph[node]
	if not state then
		state = {children = {}, visible = true}
		graph[node] = state
	end
	return state
end

local function fire(node, event)
	local state = stateOf(node)
	if event == "enter" then
		state.running = true
	elseif event == "exit" then
		state.running = false
	end
	if state.handler then
		invoke(state.handler, event)
	end
	for _, child in ipairs({unpack(state.children)}) do
		fire(child, event)
	end
	if event == "cleanup" then
		state.destroyed = true
	end
end

local function detach(child)
	local state = stateOf(child)
	local parent = state.parent
	if not parent then
		return
	end
	local siblings = stateOf(parent).children
	for index, sibling in ipairs(siblings) do
		if sibling == child then
			table.remove(siblings, index)
			break
		end
	end
	state.parent = nil
end

local function removeChild(parent, child, cleanup)
	if type(child) ~= "table" or stateOf(child).parent ~= parent then
		return
	end
	detach(child)
	if stateOf(child).running then
		fire(child, "exitTransitionStart")
		fire(child, "exit")
	end
	if cleanup ~= false then
		fire(child, "cleanup")
	end
end

-- Children stay in draw order: ascending local z order, insertion order among equals (cocos2d-x sortAllChildren).
local function insertByZOrder(children, child)
	local zOrder = stateOf(child).zOrder or 0
	local position = #children + 1
	while position > 1 and (stateOf(children[position - 1]).zOrder or 0) > zOrder do
		position = position - 1
	end
	table.insert(children, position, child)
end

nodeMethods.registerScriptHandler = function(node, handler) stateOf(node).handler = handler end
nodeMethods.unregisterScriptHandler = function(node) stateOf(node).handler = nil end
nodeMethods.addChild = function(parent, child, zOrder, tagOrName)
	if type(child) ~= "table" then
		return
	end
	detach(child)
	local state = stateOf(child)
	state.parent = parent
	if type(tagOrName) == "string" then
		state.name = tagOrName
	elseif type(tagOrName) == "number" then
		state.tag = tagOrName
	end
	if type(zOrder) == "number" then
		state.zOrder = zOrder
	end
	insertByZOrder(stateOf(parent).children, child)
	if stateOf(parent).running then
		fire(child, "enter")
		fire(child, "enterTransitionFinish")
	end
end
nodeMethods.removeChild = removeChild
nodeMethods.removeFromParent = function(node, cleanup)
	local parent = stateOf(node).parent
	if parent then
		removeChild(parent, node, cleanup)
	end
end
nodeMethods.removeFromParentAndCleanup = nodeMethods.removeFromParent
nodeMethods.removeAllChildren = function(node, cleanup)
	for _, child in ipairs({unpack(stateOf(node).children)}) do
		removeChild(node, child, cleanup)
	end
end
nodeMethods.removeAllChildrenWithCleanup = nodeMethods.removeAllChildren
nodeMethods.removeChildByTag = function(node, tag, cleanup)
	for _, child in ipairs({unpack(stateOf(node).children)}) do
		if stateOf(child).tag == tag then
			return removeChild(node, child, cleanup)
		end
	end
end
nodeMethods.removeChildByName = function(node, name, cleanup)
	for _, child in ipairs({unpack(stateOf(node).children)}) do
		if stateOf(child).name == name then
			return removeChild(node, child, cleanup)
		end
	end
end
nodeMethods.getParent = function(node) return stateOf(node).parent end
nodeMethods.getChildren = function(node) return {unpack(stateOf(node).children)} end
nodeMethods.getChildrenCount = function(node) return #stateOf(node).children end
nodeMethods.setName = function(node, name) stateOf(node).name = name end
nodeMethods.getName = function(node) return stateOf(node).name or "" end
nodeMethods.setTag = function(node, tag) stateOf(node).tag = tag end
nodeMethods.getTag = function(node) return stateOf(node).tag or -1 end
nodeMethods.setString = function(node, text) stateOf(node).text = tostring(text) end
nodeMethods.getString = function(node) return stateOf(node).text or "" end
-- ProgressTimer starts at 0 percent and LoadingBar at 100, as in cocos2d-x.
nodeMethods.setPercentage = function(node, percent) stateOf(node).percentage = percent end
nodeMethods.getPercentage = function(node) return stateOf(node).percentage or 0 end
nodeMethods.setPercent = function(node, percent) stateOf(node).percent = percent end
nodeMethods.getPercent = function(node) return stateOf(node).percent or 100 end
nodeMethods.getChildByName = function(node, name)
	for _, child in ipairs(stateOf(node).children) do
		if stateOf(child).name == name then
			return child
		end
	end
end
nodeMethods.getChildByTag = function(node, tag)
	for _, child in ipairs(stateOf(node).children) do
		if stateOf(child).tag == tag then
			return child
		end
	end
end
nodeMethods.isRunning = function(node) return stateOf(node).running == true end
nodeMethods.setVisible = function(node, visible) stateOf(node).visible = visible end
nodeMethods.isVisible = function(node) return stateOf(node).visible end
-- shortcut: clone copies the node's own properties, not its children or handlers; upgrade when stock clones a populated tree.
nodeMethods.clone = function(node)
	local copy = proxy(names[node])
	local state, source = stateOf(copy), stateOf(node)
	for _, key in ipairs({"name", "tag", "visible", "size", "position", "anchor", "zOrder", "text"}) do
		state[key] = source[key]
	end
	return copy
end
nodeMethods.retain = function() end
nodeMethods.release = function() end
nodeMethods.autorelease = function(node) return node end

-- Timer actions: DelayTime, CallFunc, Sequence, Spawn, Repeat and RepeatForever run on the virtual clock; every other action
-- is a recording proxy that completes at once.
-- shortcut: Spawn runs its children one after another and interval actions (FadeTo, MoveTo, ...) take no time; upgrade when a
-- scenario depends on the timing of an animation-only action.
local actions = setmetatable({}, {__mode = "k"})
local running = {}
local now = 0

local function makeAction(kind, info)
	local action = proxy("cc." .. kind .. ".create()")
	actions[action] = info
	return action
end

local function listOf(first, ...)
	if type(first) == "table" and not actions[first] and getmetatable(first) ~= shared then
		return first
	end
	return {first, ...}
end

local function perform(action, node)
	local info = actions[action]
	if not info then
		return
	end
	if info.duration then
		local finish = now + info.duration
		while now < finish do
			coroutine.yield()
		end
	elseif info.call then
		invoke(info.call, node)
	elseif info.sequence or info.spawn then
		for _, child in ipairs(info.sequence or info.spawn) do
			perform(child, node)
		end
	elseif info.forever then
		while true do
			local started = now
			perform(info.forever, node)
			if now == started then
				coroutine.yield()
			end
		end
	elseif info.repeated then
		for _ = 1, info.times do
			perform(info.repeated, node)
		end
	end
end

for kind, build in pairs({
	DelayTime = function(_, duration) return {duration = tonumber(duration) or 0} end,
	CallFunc = function(_, callback) return {call = callback} end,
	Sequence = function(_, ...) return {sequence = listOf(...)} end,
	Spawn = function(_, ...) return {spawn = listOf(...)} end,
	RepeatForever = function(_, action) return {forever = action} end,
	Repeat = function(_, action, times) return {repeated = action, times = tonumber(times) or 1} end,
}) do
	rawset(cc[kind], "create", function(...) return makeAction(kind, build(...)) end)
end

nodeMethods.runAction = function(node, action)
	if actions[action] then
		local routine = coroutine.create(function() perform(action, node) end)
		table.insert(running, {node = node, action = action, routine = routine})
	end
	return action
end
nodeMethods.stopAllActions = function(node)
	for _, entry in ipairs(running) do
		if entry.node == node then
			entry.stopped = true
		end
	end
end
nodeMethods.stopAction = function(node, action)
	for _, entry in ipairs(running) do
		if entry.node == node and entry.action == action then
			entry.stopped = true
		end
	end
end
nodeMethods.scheduleUpdateWithPriorityLua = function(node, callback) stateOf(node).update = callback end
nodeMethods.unscheduleUpdate = function(node) stateOf(node).update = nil end

-- Geometry stock layout reads back: a scene fills the window, any other node is 0x0 until sized (no texture sizes headless).
local frameSize = {width = 1280, height = 720}
nodeMethods.getContentSize = function(node)
	local size = stateOf(node).size
	if not size and names[node] and names[node]:find("Scene") then
		size = frameSize
	end
	size = size or {width = 0, height = 0}
	return {width = size.width, height = size.height}
end
nodeMethods.setContentSize = function(node, width, height)
	if type(width) == "table" then
		local size = width
		width, height = size.width, size.height
	end
	stateOf(node).size = {width = width or 0, height = height or 0}
end
nodeMethods.getPosition = function(node)
	local position = stateOf(node).position or {x = 0, y = 0}
	return position.x, position.y
end
nodeMethods.setPosition = function(node, x, y)
	if type(x) == "table" then
		local point = x
		x, y = point.x, point.y
	end
	stateOf(node).position = {x = x or 0, y = y or 0}
end
nodeMethods.getPositionX = function(node) return (stateOf(node).position or {x = 0}).x end
nodeMethods.getPositionY = function(node) return (stateOf(node).position or {y = 0}).y end
nodeMethods.getLocalZOrder = function(node) return stateOf(node).zOrder or 0 end
nodeMethods.setLocalZOrder = function(node, zOrder)
	local state = stateOf(node)
	state.zOrder = zOrder
	if state.parent then
		local parent = state.parent
		detach(node)
		state.parent = parent
		insertByZOrder(stateOf(parent).children, node)
	end
end
nodeMethods.getGlobalZOrder = function() return 0 end

-- Anchor defaults follow cocos2d-x: nodes and layouts anchor bottom-left, sprites, images, buttons and labels at the centre.
local centred = {"Sprite", "ImageView", "Button", "Text", "Label", "CheckBox", "LoadingBar"}
nodeMethods.getAnchorPoint = function(node)
	local anchor = stateOf(node).anchor
	if anchor then
		return {x = anchor.x, y = anchor.y}
	end
	for _, kind in ipairs(centred) do
		if (names[node] or ""):find(kind) then
			return {x = 0.5, y = 0.5}
		end
	end
	return {x = 0, y = 0}
end
nodeMethods.setAnchorPoint = function(node, x, y)
	if type(x) == "table" then
		local point = x
		x, y = point.x, point.y
	end
	stateOf(node).anchor = {x = x or 0, y = y or 0}
end

-- shortcut: world geometry ignores scale and rotation; add them when a scenario taps a scaled or rotated node.
local function worldOrigin(node)
	local x, y = nodeMethods.getPosition(node)
	local anchor = nodeMethods.getAnchorPoint(node)
	local size = nodeMethods.getContentSize(node)
	x, y = x - anchor.x * size.width, y - anchor.y * size.height
	local parent = stateOf(node).parent
	if parent then
		local parentX, parentY = worldOrigin(parent)
		x, y = x + parentX, y + parentY
	end
	return x, y
end
nodeMethods.convertToWorldSpace = function(node, point)
	local x, y = worldOrigin(node)
	return {x = x + (point and point.x or 0), y = y + (point and point.y or 0)}
end
nodeMethods.convertToNodeSpace = function(node, point)
	local x, y = worldOrigin(node)
	return {x = point.x - x, y = point.y - y}
end
nodeMethods.getCascadeBoundingBox = function(node)
	local x, y = worldOrigin(node)
	local size = nodeMethods.getContentSize(node)
	local left, bottom, right, top = x, y, x + size.width, y + size.height
	for _, child in ipairs(stateOf(node).children) do
		if stateOf(child).visible ~= false then
			local box = nodeMethods.getCascadeBoundingBox(child)
			if box.width > 0 or box.height > 0 then
				left, bottom = math.min(left, box.x), math.min(bottom, box.y)
				right, top = math.max(right, box.x + box.width), math.max(top, box.y + box.height)
			end
		end
	end
	return {x = left, y = bottom, width = right - left, height = top - bottom}
end
nodeMethods.getBoundingBox = function(node)
	local x, y = nodeMethods.getPosition(node)
	local size = nodeMethods.getContentSize(node)
	return {x = x, y = y, width = size.width, height = size.height}
end
-- Stock reaches native methods past its own overrides through getmetatable(node).addChild, as on a tolua metatable.
for key, value in pairs(nodeMethods) do
	shared[key] = value
end

-- Scheduler (cc.Director:getScheduler()).
local timers = {}
local timerSequence = 0
local scheduler = proxy("cc.Scheduler")
rawset(scheduler, "scheduleScriptFunc", function(_, callback, interval, paused)
	timerSequence = timerSequence + 1
	timers[timerSequence] = {callback = callback, interval = tonumber(interval) or 0, elapsed = 0, paused = paused}
	return timerSequence
end)
rawset(scheduler, "unscheduleScriptEntry", function(_, id) timers[id] = nil end)

-- Spine skeletons (cocos2d-x spine 2.1 LuaSkeletonAnimation): animation names, durations and events come from the real skeleton
-- JSON, so the complete and event callbacks stock battle code waits on fire on the virtual clock. A skeleton that is not on the
-- device has no animations (missing assets do not break normal play, D31).
sp = proxy("sp")
sp.EventType = {ANIMATION_START = 0, ANIMATION_END = 1, ANIMATION_COMPLETE = 2, ANIMATION_EVENT = 3}
local skeletons = setmetatable({}, {__mode = "k"})
local spineMethods = {}

local function spineEvent(skeleton, kind, entry, trackIndex, eventData)
	local handler = skeleton.handlers[kind]
	if handler then
		local names = {[sp.EventType.ANIMATION_COMPLETE] = "complete", [sp.EventType.ANIMATION_EVENT] = "event"}
		invoke(handler, {type = names[kind], animation = entry.name, trackIndex = trackIndex, loopCount = entry.loops,
			eventData = eventData})
	end
end

local function startTrack(skeleton, trackIndex, name, loop)
	local animation = skeleton.data.animations[name]
	if not animation then
		skeleton.tracks[trackIndex] = nil
		return
	end
	skeleton.tracks[trackIndex] = {name = name, loop = loop, animation = animation, elapsed = 0, nextEvent = 1, loops = 0, queue = {}}
end

-- One frame of one track: events up to the new time, then at most one completion (a zero-length loop completes once a frame).
local function advanceTrack(skeleton, trackIndex, entry, delta)
	entry.elapsed = entry.elapsed + delta * skeleton.timeScale
	local events = entry.animation.events
	while events[entry.nextEvent] and events[entry.nextEvent].time <= entry.elapsed do
		local event = events[entry.nextEvent]
		entry.nextEvent = entry.nextEvent + 1
		spineEvent(skeleton, sp.EventType.ANIMATION_EVENT, entry, trackIndex, event)
		if skeleton.tracks[trackIndex] ~= entry then
			return
		end
	end
	if entry.elapsed < entry.animation.duration then
		return
	end
	entry.loops = entry.loops + 1
	spineEvent(skeleton, sp.EventType.ANIMATION_COMPLETE, entry, trackIndex)
	if skeleton.tracks[trackIndex] ~= entry then
		return
	end
	local queued = table.remove(entry.queue, 1)
	if queued then
		startTrack(skeleton, trackIndex, queued.name, queued.loop)
		skeleton.tracks[trackIndex].queue = entry.queue
		return
	end
	if not entry.loop then
		skeleton.tracks[trackIndex] = nil
		return
	end
	entry.elapsed = math.max(entry.elapsed - entry.animation.duration, 0)
	entry.nextEvent = 1
end

local function advanceSkeletons(delta)
	for node, skeleton in pairs(skeletons) do
		local state = graph[node]
		if state and state.running and not state.destroyed then
			for trackIndex, entry in pairs(skeleton.tracks) do
				advanceTrack(skeleton, trackIndex, entry, delta)
			end
		end
	end
end

spineMethods.hasAnimation = function(node, name) return skeletons[node].data.animations[name] ~= nil end
spineMethods.setAnimation = function(node, trackIndex, name, loop)
	startTrack(skeletons[node], trackIndex, name, loop == true)
end
spineMethods.addAnimation = function(node, trackIndex, name, loop)
	local skeleton = skeletons[node]
	local entry = skeleton.tracks[trackIndex]
	if not entry then
		return startTrack(skeleton, trackIndex, name, loop == true)
	end
	table.insert(entry.queue, {name = name, loop = loop == true})
end
spineMethods.clearTracks = function(node) skeletons[node].tracks = {} end
spineMethods.clearTrack = function(node, trackIndex) skeletons[node].tracks[trackIndex or 0] = nil end
spineMethods.setToSetupPose = function() end
spineMethods.setTimeScale = function(node, scale) skeletons[node].timeScale = tonumber(scale) or 1 end
spineMethods.registerSpineEventHandler = function(node, handler, kind) skeletons[node].handlers[kind] = handler end
spineMethods.unregisterSpineEventHandler = function(node, kind) skeletons[node].handlers[kind] = nil end
-- shortcut: a bone reports its setup position relative to its parent, not the posed world position; upgrade when a scenario
-- depends on where an effect is drawn.
spineMethods.getBonePosition = function(node, name)
	local bone = skeletons[node].data.bones[name]
	if bone then
		return bone.x, bone.y
	end
end

setmetatable(sp.SkeletonAnimation, spineMethods)
rawset(sp.SkeletonAnimation, "create", function(_, path)
	local data, problem = native.skeleton(path)
	if not data then
		local key = "sp.SkeletonAnimation.create:" .. tostring(path) .. ":" .. tostring(problem)
		report.missing[key] = (report.missing[key] or 0) + 1
		data = {animations = {}, bones = {}}
	end
	local node = proxy("sp.SkeletonAnimation.create()", spineMethods)
	skeletons[node] = {data = data, tracks = {}, handlers = {}, timeScale = 1}
	return node
end)

-- Director: scene stack and screen metrics (1280x720 landscape frame, stock CONFIG_SCREEN_ORIENTATION).
local director = proxy("cc.Director.getInstance()")
local scenes = {}
local pendingScene
local function sceneName(scene)
	local class = rawget(scene, "class")
	return (type(class) == "table" and rawget(class, "__cname")) or rawget(scene, "name") or "cc.Scene"
end
local function enterScene(scene)
	table.insert(report.scenes, {name = sceneName(scene), at = now})
	fire(scene, "enter")
	fire(scene, "enterTransitionFinish")
end
local function leaveScene(scene, cleanup)
	fire(scene, "exitTransitionStart")
	fire(scene, "exit")
	if cleanup then
		fire(scene, "cleanup")
	end
end
local function switchScene(scene, mode)
	pendingScene = {scene = scene, mode = mode}
end
rawset(director, "runWithScene", function(_, scene) switchScene(scene, "replace") end)
rawset(director, "replaceScene", function(_, scene) switchScene(scene, "replace") end)
rawset(director, "pushScene", function(_, scene) switchScene(scene, "push") end)
rawset(director, "popScene", function() switchScene(nil, "pop") end)
rawset(director, "getRunningScene", function() return scenes[#scenes] end)
rawset(director, "getScheduler", function() return scheduler end)
rawset(director, "getWinSize", function() return {width = frameSize.width, height = frameSize.height} end)
rawset(director, "getVisibleSize", function() return {width = frameSize.width, height = frameSize.height} end)
rawset(director, "getVisibleOrigin", function() return {x = 0, y = 0} end)
rawset(director, "getAnimationInterval", function() return 1 / 60 end)
rawset(director, "getContentScaleFactor", function() return 1 end)
-- View coordinates have their origin top-left; GL (design) coordinates bottom-left.
rawset(director, "convertToGL", function(_, point) return {x = point.x, y = frameSize.height - point.y} end)
rawset(director, "convertToUI", function(_, point) return {x = point.x, y = frameSize.height - point.y} end)
local view = proxy("cc.Director.getInstance().getOpenGLView()")
rawset(view, "getFrameSize", function() return {width = frameSize.width, height = frameSize.height} end)
rawset(view, "getVisibleSize", function() return {width = frameSize.width, height = frameSize.height} end)
rawset(director, "getOpenGLView", function() return view end)
rawset(cc.Director, "getInstance", function() return director end)

-- Event dispatcher: touch listeners receive harness taps in engine order (fixed priority ascending, then scene-graph listeners
-- whose node is running, front-most first); custom listeners receive dispatched custom events.
local dispatcher = proxy("cc.Director.getInstance().getEventDispatcher()")
local listeners = {}
local function listenerProxy(kind, fields)
	local listener = proxy(kind .. ".create()")
	local state = stateOf(listener)
	state.handlers = {}
	for key, value in pairs(fields or {}) do
		state[key] = value
	end
	return listener
end
rawset(cc.EventListenerTouchOneByOne, "create", function() return listenerProxy("cc.EventListenerTouchOneByOne", {touch = true}) end)
rawset(cc.EventListenerCustom, "create", function(_, name, callback)
	return listenerProxy("cc.EventListenerCustom", {custom = name, callback = callback})
end)
nodeMethods.registerScriptHandler = (function(nodeHandler)
	return function(target, handler, kind)
		local state = stateOf(target)
		if state.handlers then
			state.handlers[kind] = handler
			return
		end
		nodeHandler(target, handler)
	end
end)(nodeMethods.registerScriptHandler)
shared.registerScriptHandler = nodeMethods.registerScriptHandler
nodeMethods.setSwallowTouches = function(listener, swallow) stateOf(listener).swallow = swallow end
nodeMethods.getEventDispatcher = function() return dispatcher end
shared.setSwallowTouches, shared.getEventDispatcher = nodeMethods.setSwallowTouches, nodeMethods.getEventDispatcher
local function addListener(listener, priority, node)
	local state = stateOf(listener)
	state.priority, state.node, state.order = priority, node, #listeners + 1
	table.insert(listeners, listener)
end
rawset(dispatcher, "addEventListenerWithFixedPriority", function(_, listener, priority) addListener(listener, priority) end)
rawset(dispatcher, "addEventListenerWithSceneGraphPriority", function(_, listener, node) addListener(listener, 0, node) end)
rawset(dispatcher, "removeEventListener", function(_, listener)
	for index, candidate in ipairs(listeners) do
		if candidate == listener then
			table.remove(listeners, index)
			return
		end
	end
end)
rawset(dispatcher, "removeEventListenersForTarget", function(_, node)
	for index = #listeners, 1, -1 do
		if stateOf(listeners[index]).node == node then
			table.remove(listeners, index)
		end
	end
end)
rawset(dispatcher, "dispatchEvent", function(_, event)
	local name = stateOf(event).custom
	for _, listener in ipairs({unpack(listeners)}) do
		local state = stateOf(listener)
		if state.custom == name and state.callback then
			invoke(state.callback, event)
		end
	end
end)
rawset(cc.EventCustom, "new", function(_, name) return listenerProxy("cc.EventCustom", {custom = name}) end)
rawset(director, "getEventDispatcher", function() return dispatcher end)

local function touchAt(x, y)
	local location = {x = x, y = y}
	local touch = proxy("cc.Touch()")
	for _, method in ipairs({"getLocation", "getStartLocation", "getPreviousLocation"}) do
		rawset(touch, method, function() return {x = location.x, y = location.y} end)
	end
	rawset(touch, "getLocationInView", function() return director:convertToUI(location) end)
	rawset(touch, "getDelta", function() return {x = 0, y = 0} end)
	rawset(touch, "getId", function() return 0 end)
	return touch
end
-- drawOrder numbers the running scene's nodes in cocos2d-x visit order: negative-z children, the node, then the rest.
local function drawOrder()
	local order, count = {}, 0
	local function visit(node)
		local children = stateOf(node).children
		local index = 1
		while index <= #children and (stateOf(children[index]).zOrder or 0) < 0 do
			visit(children[index])
			index = index + 1
		end
		count = count + 1
		order[node] = count
		for rest = index, #children do
			visit(children[rest])
		end
	end
	if scenes[#scenes] then
		visit(scenes[#scenes])
	end
	return order
end
-- touchOrder is the engine order: fixed priorities below zero, scene-graph listeners front-most (last drawn) first, then fixed
-- priorities above zero; registration order breaks ties.
local function touchOrder()
	local ordered = {}
	for _, listener in ipairs(listeners) do
		local state = stateOf(listener)
		if state.touch and (not state.node or stateOf(state.node).running) then
			table.insert(ordered, listener)
		end
	end
	local drawn = drawOrder()
	table.sort(ordered, function(left, right)
		local leftState, rightState = stateOf(left), stateOf(right)
		if leftState.priority ~= rightState.priority then
			return leftState.priority < rightState.priority
		end
		local leftDrawn, rightDrawn = drawn[leftState.node] or 0, drawn[rightState.node] or 0
		if leftDrawn ~= rightDrawn then
			return leftDrawn > rightDrawn
		end
		return leftState.order > rightState.order
	end)
	return ordered
end

-- ccui widgets (cocos2d-x ui::Widget): a touch-enabled widget holds a swallowing scene-graph listener; a touch inside it while it
-- is enabled and shown fires its touch callback (began, then ended) and then its click callback.
local function shownInTree(node)
	while node do
		if stateOf(node).visible == false then
			return false
		end
		node = stateOf(node).parent
	end
	return true
end
local function widgetHit(widget, touch)
	if stateOf(widget).enabled == false or not shownInTree(widget) then
		return false
	end
	local x, y = worldOrigin(widget)
	local size = nodeMethods.getContentSize(widget)
	local point = touch:getLocation()
	return point.x >= x and point.x <= x + size.width and point.y >= y and point.y <= y + size.height
end
local function widgetEvent(widget, kind)
	local callback = stateOf(widget).touchCallback
	if callback then
		invoke(callback, widget, ccui.TouchEventType[kind])
	end
end
widgetMethods.setTouchEnabled = function(widget, enabled)
	local state = stateOf(widget)
	state.touchEnabled = enabled == true
	if state.touchEnabled and not state.widgetListener then
		local listener = listenerProxy("cc.EventListenerTouchOneByOne", {touch = true, swallow = true})
		stateOf(listener).handlers[cc.Handler.EVENT_TOUCH_BEGAN] = function(touch)
			if not widgetHit(widget, touch) then
				return false
			end
			widgetEvent(widget, "began")
			return true
		end
		stateOf(listener).handlers[cc.Handler.EVENT_TOUCH_ENDED] = function()
			widgetEvent(widget, "ended")
			if state.clickCallback then
				invoke(state.clickCallback, widget)
			end
		end
		state.widgetListener = listener
		addListener(listener, 0, widget)
	elseif not state.touchEnabled and state.widgetListener then
		dispatcher.removeEventListener(dispatcher, state.widgetListener)
		state.widgetListener = nil
	end
end
widgetMethods.isTouchEnabled = function(widget) return stateOf(widget).touchEnabled == true end
widgetMethods.setEnabled = function(widget, enabled) stateOf(widget).enabled = enabled end
widgetMethods.isEnabled = function(widget) return stateOf(widget).enabled ~= false end
widgetMethods.addTouchEventListener = function(widget, callback) stateOf(widget).touchCallback = callback end
widgetMethods.addClickEventListener = function(widget, callback) stateOf(widget).clickCallback = callback end
-- tap is a harness input: one touch began and ended at (x, y) in design coordinates.
function __vc.tap(x, y)
	local touch = touchAt(x, y)
	local claimed = {}
	for _, listener in ipairs(touchOrder()) do
		local state = stateOf(listener)
		local began = state.handlers[cc.Handler.EVENT_TOUCH_BEGAN]
		if began then
			local ok, result = invoke(began, touch, nil)
			if ok and result then
				table.insert(claimed, listener)
				if state.swallow then
					break
				end
			end
		end
	end
	for _, listener in ipairs(claimed) do
		local ended = stateOf(listener).handlers[cc.Handler.EVENT_TOUCH_ENDED]
		if ended then
			invoke(ended, touch, nil)
		end
	end
	report.taps = (report.taps or 0) + 1
	print("vc tap", x, y, "listeners", #listeners, "touch", #touchOrder(), "claimed", #claimed)
	return #claimed
end

local function visibleNamed(node, name, found)
	local state = stateOf(node)
	if state.visible == false then
		return found
	end
	if state.name == name then
		found = node
	end
	for _, child in ipairs(state.children) do
		found = visibleNamed(child, name, found)
	end
	return found
end
-- tapNode taps the centre of the last-drawn visible node at this name path ("panel/button": each name searched under the previous
-- match) in the running scene, as a player aims at what is shown.
function __vc.tapNode(path)
	local node = scenes[#scenes]
	for name in string.gmatch(path, "[^/]+") do
		node = node and visibleNamed(node, name, nil)
	end
	if not node then
		error("no visible node at " .. path, 0)
	end
	local box = nodeMethods.getCascadeBoundingBox(node)
	return __vc.tap(box.x + box.width / 2, box.y + box.height / 2)
end

local function applySceneChange()
	if not pendingScene then
		return
	end
	local change = pendingScene
	pendingScene = nil
	local current = scenes[#scenes]
	if change.mode == "pop" then
		if current then
			leaveScene(table.remove(scenes), true)
		end
		if scenes[#scenes] then
			enterScene(scenes[#scenes])
		end
		return
	end
	if current then
		leaveScene(current, change.mode == "replace")
		if change.mode == "replace" then
			table.remove(scenes)
		end
	end
	table.insert(scenes, change.scene)
	enterScene(change.scene)
end

-- Work the platform posts to the GL thread (SDK callbacks) runs at the start of the next frame.
local deferred = {}
local function later(callback)
	table.insert(deferred, callback)
end

-- One engine frame on the virtual clock: posted work, scene change, scheduler timers, node updates, then actions.
function __vc.frame(clock, delta)
	now = clock
	local posted = deferred
	deferred = {}
	for _, callback in ipairs(posted) do
		invoke(callback)
	end
	applySceneChange()
	for id, timer in pairs(timers) do
		if not timer.paused then
			timer.elapsed = timer.elapsed + delta
			if timer.elapsed >= timer.interval then
				local elapsed = timer.elapsed
				timer.elapsed = 0
				invoke(timer.callback, elapsed)
			end
		end
	end
	for node, state in pairs(graph) do
		if state.update and state.running then
			invoke(state.update, delta)
		end
	end
	advanceSkeletons(delta)
	local active = running
	running = {}
	for _, entry in ipairs(active) do
		local state = graph[entry.node]
		local live = not entry.stopped and not (state and state.destroyed)
		local paused = state ~= nil and not state.running and state.parent ~= nil
		if live and not paused then
			local ok, failure = coroutine.resume(entry.routine)
			if not ok then
				reportError(failure)
			end
		end
		if live and coroutine.status(entry.routine) ~= "dead" then
			table.insert(running, entry)
		end
	end
end

-- tolua: a node is null once it has been cleaned up.
tolua = proxy("tolua")
rawset(tolua, "isnull", function(node)
	if node == nil then
		return true
	end
	local state = graph[node]
	return state ~= nil and state.destroyed == true
end)
rawset(tolua, "cast", function(node) return node end)
-- The native method is what stock Lua overrides (WidgetEx setTouchEnabled) call through; a widget's comes from the widget model.
rawset(tolua, "getcfunction", function(node, name)
	local isWidget = (names[node] or ""):sub(1, 5) == "ccui."
	if isWidget and widgetMethods[name] then
		return widgetMethods[name]
	end
	return nodeMethods[name] or node[name]
end)
rawset(tolua, "type", function(node) return type(node) end)
local peers = setmetatable({}, {__mode = "k"})
rawset(tolua, "setpeer", function(node, peer) peers[node] = peer end)
rawset(tolua, "getpeer", function(node) return peers[node] end)

-- Application, device, files, user defaults, crypto.
local application = proxy("cc.Application.getInstance()")
rawset(application, "getTargetPlatform", function() return native.platform end)
rawset(application, "getCurrentLanguage", function() return 0 end)
rawset(application, "getCurrentLanguageCode", function() return "en" end)
rawset(cc.Application, "getInstance", function() return application end)

local files = proxy("cc.FileUtils.getInstance()")
for name, implementation in pairs(native.files) do
	rawset(files, name, function(_, ...) return implementation(...) end)
end
rawset(cc.FileUtils, "getInstance", function() return files end)

local defaults = native.defaults()
local userDefault = proxy("cc.UserDefault.getInstance()")
local function getter(convert)
	return function(_, key, fallback)
		local value = defaults[key]
		if value == nil then
			return fallback
		end
		return convert(value)
	end
end
local function setter(_, key, value)
	defaults[key] = value
	native.saveDefaults(defaults)
end
rawset(userDefault, "getStringForKey", getter(tostring))
rawset(userDefault, "getIntegerForKey", getter(tonumber))
rawset(userDefault, "getFloatForKey", getter(tonumber))
rawset(userDefault, "getDoubleForKey", getter(tonumber))
rawset(userDefault, "getBoolForKey", getter(function(value) return value == true end))
for _, name in ipairs({"setStringForKey", "setIntegerForKey", "setFloatForKey", "setDoubleForKey", "setBoolForKey"}) do
	rawset(userDefault, name, setter)
end
rawset(userDefault, "deleteValueForKey", function(_, key) setter(nil, key, nil) end)
rawset(userDefault, "flush", function() end)
rawset(cc.UserDefault, "getInstance", function() return userDefault end)

rawset(cc.Crypto, "MD5File", function(_, path) return native.md5File(path) end)
rawset(cc.Crypto, "MD5", function(_, text, raw) return native.md5(text, raw) end)
rawset(cc.Crypto, "decodeBase64", function(_, text) return native.decodeBase64(text) end)
rawset(cc.HTTPRequest, "createWithUrl", function(_, callback, url, method) return native.httpRequest(callback, url, method) end)
cc.kCCHTTPRequestMethodGET, cc.kCCHTTPRequestMethodPOST, cc.kCCHTTPRequestMethodPUT, cc.kCCHTTPRequestMethodDELETE = 0, 1, 2, 3
cc.kCCHTTPRequestAcceptEncodingIdentity, cc.kCCHTTPRequestAcceptEncodingGzip, cc.kCCHTTPRequestAcceptEncodingDeflate = 0, 1, 2

-- Native xyd functions and the Android SDK bridge (org/cocos2dx/lua/AppActivity) the stock login uses.
ccui, ccs, gl, kazmath, ccexp, ccb, sdkbox = proxy("ccui"), proxy("ccs"), proxy("gl"), proxy("kazmath"), proxy("ccexp"), proxy("ccb"), proxy("sdkbox")
xyd = proxy("xyd")
rawset(xyd, "getVersionName", function() return native.versionName end)
rawset(xyd, "getPackageName", function() return native.packageName end)
rawset(xyd, "isDebug", function() return false end)
rawset(xyd, "exitProgram", function() report.exited = now end)

local sdk = {
	xydNewLogin = function(arguments)
		local onToken, onSid = arguments[1], arguments[2]
		table.insert(report.sdk, {method = "xydNewLogin", at = now})
		later(function()
			invoke(onToken, native.loginToken)
			invoke(onSid, native.sid)
		end)
		return true
	end,
	getChannel = function() return true, 0 end,
	getAPKExpansionFile = function() return false, "" end,
	xydSelectServer = function() return true end,
}
LuaJavaBridge = proxy("LuaJavaBridge")
rawset(LuaJavaBridge, "callStaticMethod", function(class, method, arguments)
	local handler = sdk[method]
	if handler then
		return handler(arguments or {})
	end
	local name = "LuaJavaBridge." .. tostring(class) .. "." .. tostring(method)
	report.missing[name] = (report.missing[name] or 0) + 1
	return false, nil
end)

UIUtil, ByteArray = proxy("UIUtil"), proxy("ByteArray")
nodeBase, widgetBase = cc.Node, ccui.Widget

-- Cocos Studio layouts: the node tree of the real .csb (names, tags, visibility, geometry, label text), so stock window code that
-- looks children up by name sees what the device sees. An unreadable layout is recorded and yields an empty node.
local layoutClasses = {Node = "cc.Node", SingleNode = "cc.Node", Sprite = "cc.Sprite", Panel = "ccui.Layout", Button = "ccui.Button",
	ImageView = "ccui.ImageView", Text = "ccui.Text", LoadingBar = "ccui.LoadingBar", CheckBox = "ccui.CheckBox",
	TextBMFont = "ccui.TextBMFont", TextField = "ccui.TextField", ListView = "ccui.ListView", PageView = "ccui.PageView"}
local function buildLayout(description)
	local node = proxy((layoutClasses[description.class] or "cc.Node") .. ".create()")
	local state = stateOf(node)
	state.name, state.tag, state.text = description.name, description.tag, description.text
	state.visible = description.visible ~= false
	if description.touch and names[node]:sub(1, 5) == "ccui." then
		widgetMethods.setTouchEnabled(node, true)
	end
	if description.width then
		state.size = {width = description.width, height = description.height}
	end
	if description.x then
		state.position = {x = description.x, y = description.y}
	end
	for _, child in ipairs(description.children) do
		nodeMethods.addChild(node, buildLayout(child))
	end
	return node
end
local function createLayout(_, path)
	local description, problem = native.layout(path)
	if not description then
		local key = "cc.CSLoader.createNode:" .. tostring(path) .. ":" .. tostring(problem)
		report.missing[key] = (report.missing[key] or 0) + 1
		return proxy("cc.Node.create()")
	end
	return buildLayout(description)
end
rawset(cc.CSLoader, "createNode", createLayout)
local layoutLoader = proxy("cc.CSLoader.getInstance()")
rawset(layoutLoader, "createNodeWithFlatBuffersFile", createLayout)
rawset(cc.CSLoader, "getInstance", function() return layoutLoader end)

table.insert(package.loaders, function(name)
	report.missing["module:" .. name] = (report.missing["module:" .. name] or 0) + 1
	return function() return proxy("module:" .. name) end
end)
setmetatable(_G, {__index = function(_, key)
	if type(key) ~= "string" or not key:match("^[A-Z]") or key:match("^[A-Z0-9_]+$") then
		return nil
	end
	local value = proxy(key)
	rawset(_G, key, value)
	return value
end})
