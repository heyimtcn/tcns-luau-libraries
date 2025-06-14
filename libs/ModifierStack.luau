--!nocheck

local Signal = require(script.Parent.Signal)

export type Operator = "+" | "-" | "*" | "/"

export type Modifier<T> = {
	Operator:Operator,
	Value:T
}

export type ModifierStack<T> = {
	Changed:Signal.Signal<>,
	Calculate:(self:ModifierStack<T>,val:T) -> T,
	SetModifier:(self:ModifierStack<T>,name:string,mod:Modifier) -> ModifierStack<T>,
	RemoveModifier:(self:ModifierStack<T>,name:string) -> ModifierStack<T>,
	HasModifier:(self:ModifierStack<T>,name:string) -> boolean,
	GetModifier:(self:ModifierStack<T>,name:string) -> Modifier<T>,
	GetModifiers:(self:ModifierStack<T>) -> {Modifier<T>},
	GetOperators:(self:ModifierStack<T>) -> {[Operator|string]:(acc:T,val:T) -> T},
	GetOrder:(self:ModifierStack<T>) -> {Operator|string},
	BindTo:(self:ModifierStack<T>,obj:Instance|{[string]:any},prop:string,def:T) -> (() -> ())
}

local ModifierStack = {}
local prototype:ModifierStack<any> = {}
prototype.__index = prototype
ModifierStack.prototype = prototype
ModifierStack.ClassName = "ModifierStack"
prototype.Class = ModifierStack
prototype.ClassName = "ModifierStack"

function ModifierStack.new<T>(operators:{[Operator|string]:(num:T,val:T) -> T},order:{Operator|string}):ModifierStack
	return setmetatable({Changed = Signal.new() :: Signal.Signal<>,_modifiers = {},_operators = operators,_order = order},prototype)
end

function ModifierStack.default():ModifierStack
	return ModifierStack.new({
		["+"] = function(acc,val)
			return acc + val
		end,
		["-"] = function(acc,val)
			return acc - val
		end,
		["*"] = function(acc,val)
			return acc * val
		end,
		["/"] = function(acc,val)
			return acc / val
		end
	},{"+","-","*","/"}) :: ModifierStack<number>
end

function ModifierStack.is(obj:any):boolean
	return type(obj) == "table" and getmetatable(obj).ClassName == "ModifierStack"
end

function prototype:Calculate<T>(val:T)
	local operators_present = {}
	local operator_modifiers:{[Operator|string]:Modifier<T>} = {}
	local operator_funcs = self:GetOperators()
	for name, mod in self:GetModifiers() do
		if operator_modifiers[mod.Operator] == nil then
			operator_modifiers[mod.Operator] = {}
			table.insert(operators_present,mod.Operator)
		end
		table.insert(operator_modifiers[mod.Operator],mod)
	end
	local new_val = val
	for _, operator in self:GetOrder() do
		if table.find(operators_present,operator) then
			for _, mod:Modifier<T> in operator_modifiers[operator] do
				new_val = operator_funcs[operator](new_val,mod.Value)
			end
		end
	end
	return new_val
end

function prototype:SetModifier(name,mod)
	if self:GetModifier(name) == nil or self:GetModifier(name) ~= mod then
		self:GetModifiers()[name] = mod
		self.Changed:Fire()
	end
	return self
end

function prototype:RemoveModifier(name)
	if self:GetModifiers()[name] ~= nil then
		self:GetModifiers()[name] = nil
		self.Changed:Fire()
	end
	return self
end

function prototype:HasModifier(name)
	return self:GetModifiers()[name] ~= nil
end

function prototype:GetModifier(name)
	return self:GetModifiers()[name]
end

function prototype:GetModifiers()
	return self._modifiers
end

function prototype:GetOperators()
	return self._operators
end

function prototype:GetOrder()
	return self._order
end

function prototype:BindTo(obj:Instance|{[string]:any},prop,def)
	obj[prop] = self:Calculate(def)
	local conn = self.Changed:Connect(function()
		obj[prop] = self:Calculate(def)
	end)
	if typeof(obj) == "Instance" then
		obj.Destroying:Connect(function()
			conn:Disconnect()
		end)
	end
	return function()
		conn:Disconnect()
	end
end

function prototype:Destroy()
	table.clear(self)
	setmetatable(self,nil)
end

return ModifierStack
