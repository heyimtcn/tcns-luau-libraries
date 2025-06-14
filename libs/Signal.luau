--!nocheck

export type Signal<T...> = {
	Enabled:boolean,
	Connections:{Connection<T...>},
	Fire:(self:Signal<T...>,T...) -> (),
	FireDefer:(self:Signal<T...>,T...) -> (),
	Connect:(self:Signal<T...>,fn:(T...) -> ()) -> Connection<T...>,
	Once:(self:Signal<T...>,fn:(T...) -> ()) -> Connection<T...>,
	Wait:(self:Signal<T...>) -> T...,
	WaitUntil:(self:Signal<T...>,fn:(T...) -> boolean) -> T...,
	DisconnectAll:(self:Signal<T...>) -> (),
	Map:(self:Signal<T...>,mod:(T...) -> T...) -> Signal<T...>,
	Filter:(self:Signal<T...>,fn:(T...) -> boolean) -> Signal<T...>,
	MultiMap:(self:Signal<T...>,mods:{(T...) -> T...}) -> Signal<T...>,
	MultiFilter:(self:Signal<T...>,fns:{(T...) -> boolean}) -> Signal<T...>,
	Destroy:(self:Signal<T...>) -> ()
}

export type Connection<T...> = {
	Connected:boolean,
	Signal:Signal<T...>,
	Disconnect:(self:Connection<T...>) -> ()
}

local Signal = {}
local prototype:Signal<any> = {}
prototype.__index = prototype
Signal.prototype = prototype
Signal.ClassName = "Signal"
prototype.Class = Signal
prototype.ClassName = "Signal"

local conn_prototype:Connection<any> = {}
conn_prototype.__index = conn_prototype

function new_connection<T...>(fn:(T...) -> (),signal:Signal<T...>,id:number):Connection<T...>
	return setmetatable({
		_fn = fn,
		_id = id,
		Connected = true,
		Signal = signal
	},conn_prototype)
end

function conn_prototype:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false
	self.Signal.Connections[self._id] = nil
end

function Signal.new<T...>():Signal<T...>
	local obj = setmetatable({
		Enabled = true,
		Connections = {},
		_last_conn_id = 0,
		_external_connections = {}
	},prototype)
	return obj
end

function Signal.is(obj:any):boolean
	return type(obj) == "table" and getmetatable(obj).ClassName == "Signal"
end

function Signal.wrap<T...>(signal:RBXScriptSignal|Signal<T...>)
	local sig = Signal.new()
	signal:Connect(function(...)
		sig:Fire(...)
	end)
	return sig
end

function Signal.merge(...:Signal):Signal
	local new_sig = Signal.new()
	for _, sig:Signal in pairs({...}) do
		sig:Connect(function(...)
			new_sig:Fire(...)
		end)
	end
	return new_sig
end

function prototype:Fire(...)
	if not self.Enabled then
		return
	end
	for _, conn:Connection<any> in pairs(self.Connections) do
		task.spawn(conn._fn,...)
	end
end

function prototype:FireDefer(...)
	for _, conn:Connection<any> in pairs(self.Connections) do
		task.defer(conn._fn,...)
	end
end

function prototype:Connect(fn)
	self._last_conn_id += 1
	local conn_id = self._last_conn_id
	local conn = new_connection(fn,self,conn_id)
	self.Connections[conn_id] = conn
	return conn
end

function prototype:Once(fn)
	local conn
	conn = self:Connect(function(...)
		fn(...)
		conn:Disconnect()
	end)
	return conn
end

function prototype:Wait()
	local routine = coroutine.running()
	self:Once(function(...)
		task.defer(function(...)
			coroutine.resume(routine,...)
		end,...)
	end)
	return coroutine.yield()
end

function prototype:WaitUntil(fn)
	local routine = coroutine.running()
	local conn
	conn = self:Connect(function(...)
		task.defer(function(...)
			if fn(...) then
				conn:Disconnect()
				coroutine.resume(routine,...)
			end
		end,...)
	end)
	return coroutine.yield()
end

function prototype:DisconnectAll()
	for _, conn in pairs(self.Connections) do
		conn:Disconnect()
	end
end

function prototype:Map(mod)
	local new_sig = Signal.new()
	local conn = self:Connect(function(...)
		new_sig:Fire(mod(...))
	end)
	table.insert(new_sig._external_connections,conn)
	return new_sig
end

function prototype:Filter(fn)
	local new_sig = Signal.new()
	local conn = self:Connect(function(...)
		if fn(...) then
			new_sig:Fire(...)
		end
	end)
	table.insert(new_sig._external_connections,conn)
	return new_sig
end

function prototype:MultiMap(mods)
	local new_sig = Signal.new()
	local conn = self:Connect(function(...)
		local mapped_arr = {...}
		for _, mod in ipairs(mods) do
			mapped_arr = {mod(table.unpack(mapped_arr))}
		end
		new_sig:Fire(table.unpack(mapped_arr))
	end)
	table.insert(new_sig._external_connections,conn)
	return new_sig
end

function prototype:MutliFilter(fns)
	local new_sig = Signal.new()
	local conn = self:Connect(function(...)
		for _, fn in ipairs(fns) do
			if not fn(...) then
				return
			end
		end
		new_sig:Fire(...)
	end)
	table.insert(new_sig._external_connections,conn)
	return new_sig
end

function prototype:Destroy()
	self:DisconnectAll()
	for _, conn in pairs(self._external_connections) do
		conn:Disconnect()
	end
	table.clear(self)
	setmetatable(self,nil)
end

return Signal
