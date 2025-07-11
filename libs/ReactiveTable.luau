--!nocheck

local Signal = require(script.Parent.Signal)

export type ReactiveTable = {
	Changed:Signal.Signal<any>,
	GetChangedSignal:(self:ReactiveTable,key:any) -> Signal.Signal<>,
}

local ReactiveTable = {}
ReactiveTable.ClassName = "ReactiveTable"

function ReactiveTable.new<T>(defs:T,locked:boolean?):ReactiveTable & T
	locked = if locked == nil then false else locked
	local changed_signals = {}
	for name, _ in defs do
		changed_signals[name] = Signal.new()
	end
	local handler = {
		ClassName = "ReactiveTable",
		_props = defs,
		_changed_signals = changed_signals,
		Changed = Signal.new() :: Signal.Signal<any>,
		GetChangedSignal = function(self,key)
			if changed_signals[key] == nil then
				changed_signals[key] = Signal.new()
			end
			return changed_signals[key]
		end,
		Destroy = function(self)
			table.clear(self)
			setmetatable(self,nil)
		end,
	}
	return setmetatable(handler,{
		__index = function(tbl,key)
			if tbl._props[key] == nil and locked then
				error(`Attempted to get "{key}" (not a key)`)
			end
			return tbl._props[key]
		end,
		__newindex = function(tbl,key,value)
			if tbl._props[key] == nil and locked then
				error(`Attempted to set "{key}" (not a key)`)
			end
			local old_val = tbl._props[key]
			if value ~= old_val then
				tbl._props[key] = value
				handler.Changed:Fire(key)
				if old_val == nil then
					changed_signals[key] = Signal.new()
				end
				handler:GetChangedSignal(key):Fire()
			end
		end,
		__iter = function(tbl)
			return pairs(tbl._props)
		end,
	})
end

function ReactiveTable.extend<A>(prototype:A)
	return function<B>(obj:B):A & B & {PropertyChanged:Signal.Signal<key>,GetPropertyChangedSignal:(self:any,key:any) -> Signal.Signal<>}
		local property_changed = Signal.new()
		local changed_signals = {}
		for key, _ in obj do
			if type(obj) ~= "function" then
				changed_signals[key] = Signal.new()
			end
		end
		local get_property_changed_signal = function(_,key)
			if not changed_signals[key] then
				changed_signals[key] = Signal.new()
			end
			return changed_signals[key]
		end
		return setmetatable({_obj = obj},{
			__index = function(tbl,key)
				if key == "PropertyChanged" then
					return property_changed
				elseif key == "GetPropertyChangedSignal" then
					return get_property_changed_signal
				elseif prototype[key] ~= nil then
					return prototype[key]
				elseif obj[key] ~= nil then
					return obj[key]
				end
				return nil
			end,
			__newindex = function(tbl,key,val)
				if val == obj[key] then
					return
				end
				obj[key] = val
				property_changed:Fire(key)
				if changed_signals[key] then
					changed_signals[key]:Fire()
				end
			end,
		})
	end
end

function ReactiveTable.is(obj:any):boolean
	if type(obj) ~= "table" then
		return false
	end
	return obj.ClassName == "ReactiveTable"
end

return ReactiveTable
