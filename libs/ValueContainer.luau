--!nocheck

local RunService = game:GetService("RunService")
local Signal = require(script.Parent.Signal)
local LerpUtils = require(script.Parent.LerpUtils)

export type Default<T> = {
	Value:T,
	Muted:boolean,
	Changed:Signal.Signal<T>,
	Kind:"Default" | "Computed" | "Animated",
	Get:(self:Default<T>) -> T,
	Set:(self:Default<T>,val:T) -> (),
	SyncToProp:(self:Default<T>,inst:Instance,name:string) -> (RBXScriptConnection,Signal.Connection<any>),
	SyncToAttr:(self:Default<T>,inst:Instance,name:string) -> (RBXScriptConnection,Signal.Connection<any>),
	Clone:(self:Default<T>) -> (),
	Destroy:(self:Default<T>) -> Default<T>,
}

export type Computed<T> = Default<T> & {
	Dependencies:{Default<T>},
	Enabled:boolean,
}

export type Animated<T> = Default<T> & {
	From:Default<T>,
	Enabled:boolean,
	Started:Signal.Signal<>,
	Finished:Signal.Signal<>
}

local ValueContainer = {
	LerpUtils = LerpUtils
}
local prototype:Default<any> = {}
local methods = {}
prototype.__index = function(tbl,key)
	if key == "Value" then
		return tbl._value
	end
	if methods[key] then
		return methods[key]
	end
	return rawget(tbl,key)
end
prototype.__newindex = function(tbl,key,val)
	if key == "Value" and val ~= tbl._value then
		tbl._value = val
		if not rawget(tbl,"Muted") then
			tbl.Changed:Fire(val)
		end
		return
	end
	if val == tbl._value then
		return
	end
	rawset(tbl,key,val)
end
ValueContainer.prototype = prototype
ValueContainer.ClassName = "ValueContainer"
prototype.Class = ValueContainer
prototype.ClassName = "ValueContainer"

function ValueContainer.new<T>(val:T?):Default<T>
	return setmetatable({
		_value = val,
		Muted = false,
		Changed = Signal.new(),
	},prototype)
end

function ValueContainer.computed<T,U>(fn:(...U) -> T,...:any):Computed<T>
	local val_cont:Computed<T> = ValueContainer.new(nil)
	local deps = {...}
	val_cont.Kind = "Computed"
	val_cont.Dependencies = deps
	val_cont.Enabled = true
	local function rerun()
		if not val_cont.Enabled then
			return
		end
		local vals = {}
		for _, dep in deps do
			table.insert(vals,dep.Value)
		end
		val_cont.Value = fn(table.unpack(vals))
	end
	for _, dep in deps do
		dep.Changed:Connect(rerun)
	end
	rerun()
	return val_cont
end

--[[function ValueContainer.memo<T,U>(fn:(...U) -> T,...:ValueContainer<U>):ValueContainer<T>
	
end]]

function ValueContainer.animated<T>(from:any,lenght:number,easing:(n:number) -> number,render_stepped:boolean?):Animated<T>
	local val_cont:Animated<T> = ValueContainer.new(from.Value)
	val_cont.Kind = "Animated"
	val_cont.From = from
	val_cont.Enabled = true
	val_cont.Started = Signal.new()
	val_cont.Finished = Signal.new()
	local prev = from.Value
	local conn
	from.Changed:Connect(function(val)
		if not val_cont.Enabled then
			return
		end
		if conn then
			prev = val_cont.Value
			conn:Disconnect()
			conn = nil
		end
		local start_time = os.clock()
		local function callback()
			local time_since_start = os.clock() - start_time
			local progress = time_since_start/lenght
			if progress >= 1 then
				val_cont.Value = val
				conn:Disconnect()
				conn = nil
				prev = val
				val_cont.Finished:Fire()
				return
			end
			val_cont.Value = LerpUtils.lerp(easing(progress),val,prev)
		end
		if RunService:IsClient() and render_stepped then
			conn = RunService.RenderStepped:Connect(callback)
		else
			conn = RunService.Heartbeat:Connect(callback)
		end
		val_cont.Started:Fire()
	end)
	return val_cont
end

function ValueContainer.from_signal<T>(signal:Signal.Signal<T>,def:T?):Default<any>
	local val_cont = ValueContainer.new(def)
	signal:Connect(function(val)
		val_cont.Value = val
	end)
	return val_cont
end

--ROBLOX SIGNALS MAY BE DEFFERED
function ValueContainer.synced_to_prop(inst:Instance,name:string):(Default<any>,RBXScriptConnection,Signal.Connection<any>)
	local val_cont = ValueContainer.new(inst[name])
	local inst_changed, val_cont_changed = false, false
	local inst_conn = inst:GetPropertyChangedSignal(name):Connect(function()
		if val_cont_changed then
			val_cont_changed = false
			return
		end
		val_cont.Value = inst[name]
		inst_changed = true
	end)
	local self_conn = val_cont.Changed:Connect(function(val)
		if inst_changed then
			inst_changed = false
			return
		end
		inst[name] = val_cont.Value
		val_cont_changed = true 
	end)
	return val_cont, inst_conn, self_conn
end

--ROBLOX SIGNALS MAY BE DEFFERED
function ValueContainer.synced_to_attr(inst:Instance,name:string):(Default<any>,RBXScriptConnection,Signal.Connection<any>)
	local val_cont = ValueContainer.new(inst:GetAttribute(name))
	local inst_changed, val_cont_changed = false, false
	local inst_conn = inst:GetAttributeChangedSignal(name):Connect(function()
		if val_cont_changed then
			val_cont_changed = false
			return
		end
		val_cont.Value = inst:GetAttribute(name)
		inst_changed = true
	end)
	local self_conn = val_cont.Changed:Connect(function(val)
		if inst_changed then
			inst_changed = false
			return
		end
		inst:SetAttribute(name,val_cont.Value)
		val_cont_changed = true
	end)
	return val_cont, inst_conn, self_conn
end

function ValueContainer.is(obj:any):boolean
	return type(obj) == "table" and getmetatable(obj).ClassName == "ValueContainer"
end

function methods:Get()
	return self.Value
end

function methods:Set(val)
	self.Value = val
end

--ROBLOX SIGNALS MAY BE DEFFERED
function methods:SyncToProp(inst,name)
	inst[name] = self.Value
	local inst_changed, val_cont_changed = false, false
	local inst_conn = inst:GetPropertyChangedSignal(name):Connect(function()
		if val_cont_changed then
			val_cont_changed = false
			return
		end
		self.Value = inst[name]
		inst_changed = true
	end)
	local self_conn = self.Changed:Connect(function(val)
		if inst_changed then
			inst_changed = false
			return
		end
		inst[name] = self.Value
		val_cont_changed = true 
	end)
	return inst_conn, self_conn
end

--ROBLOX SIGNALS MAY BE DEFFERED
function methods:SyncToAttr(inst,name)
	inst:SetAttribute(name,self.Value)
	local inst_changed, val_cont_changed = false, false
	local inst_conn = inst:GetAttributeChangedSignal(name):Connect(function()
		if val_cont_changed then
			val_cont_changed = false
			return
		end
		self.Value = inst:GetAttribute(name)
		inst_changed = true
	end)
	local self_conn = self.Changed:Connect(function(val)
		if inst_changed then
			inst_changed = false
			return
		end
		inst:SetAttribute(name,self.Value)
		val_cont_changed = true
	end)
	return inst_conn, self_conn
end

function methods:Clone()
	return ValueContainer.new(self.Value)
end

function methods:Destroy()
	self.Changed:Destroy()
	setmetatable(self,nil)
	table.clear(self)
end

return ValueContainer
