--!nocheck

local Signal = require(script.Parent.Signal)

export type ReactiveTable<T> = {
	Changed:Signal.Signal<any>,
	GetChangedSignal:(self:ReactiveTable,key:any) -> Signal.Signal<>,
	Values:T
}

local ReactiveTable = {}
ReactiveTable.ClassName = "ReactiveTable"

function ReactiveTable.new<T>(defs:T,locked:boolean?,parent:ReactiveTable?,self_name:string?):ReactiveTable<T>
	locked = if locked == nil then false else locked
	if parent ~= nil then
		if self_name == nil then
			error("self_name is required for ReactiveTables with a parent",2)
		end
	end
	local changed_signals = {}
	for name, _ in defs do
		changed_signals[name] = Signal.new()
	end
	local handler = {
		ClassName = "ReactiveTable",
		Values = defs,
		_changed_signals = changed_signals,
		_parent = parent,
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
			if tbl.Values[key] == nil and locked then
				error(`Attempted to get "{key}" (not a key)`,2)
			end
			return tbl.Values[key]
		end,
		__newindex = function(tbl,key,value)
			if tbl.Values[key] == nil and locked then
				error(`Attempted to set "{key}" (not a key)`,2)
			end
			local old_val = tbl.Values[key]
			if value ~= old_val then
				tbl.Values[key] = value
				handler.Changed:Fire(key)
				if changed_signals[key] ~= nil then
					handler:GetChangedSignal(key):Fire()
				end
				if parent ~= nil then
					parent.Changed:Fire(self_name)
					if parent._changed_signals[self_name] ~= nil then
						parent:GetChangedSignal(self_name):Fire()
					end
				end
			end
		end,
		__iter = function(tbl)
			return pairs(tbl.Values)
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
