--!nocheck

local LerpUtils = {}

function LerpUtils.cubic_bezier(p1x:number,p1y:number,p2x:number,p2y:number):(n:number) -> number
	local function a(aA1, aA2)
		return 1.0 - 3.0 * aA2 + 3.0 * aA1
	end
	local function b(aA1, aA2)
		return 3.0 * aA2 - 6.0 * aA1
	end
	local function c(aA1)
		return 3.0 * aA1
	end
	-- Returns x(t) given t, x1, and x2, or y(t) given t, y1, and y2.
	local function calculateBezier(aT, aA1, aA2)
		return ((a(aA1, aA2)*aT + b(aA1, aA2))*aT + c(aA1))*aT
	end
	-- Returns dx/dt given t, x1, and x2, or dy/dt given t, y1, and y2.
	local function getSlope(aT, aA1, aA2)
		return 3.0 * a(aA1, aA2)*aT*aT + 2.0 * b(aA1, aA2) * aT + c(aA1)
	end
	-- Newton raphson iteration
	local function getTForX(aX)
		local aGuessT = aX
		for _ = 1, 4 do
			local currentSlope = getSlope(aGuessT, p1x, p2x)
			if currentSlope == 0 then
				return aGuessT
			end
			local currentX = calculateBezier(aGuessT, p1x, p2x) - aX
			aGuessT = aGuessT - currentX / currentSlope
		end
		return aGuessT
	end
	return function(aX)
		-- aX is from [0, 1], it's the original time
		return calculateBezier(getTForX(aX), p1y, p2y)
	end
end

function LerpUtils.enum_ease(style:Enum.EasingStyle,direction:Enum.EasingDirection):(n:number) -> number
	return function(n:number):number
		return game.TweenService:GetValue(n,style,direction)
	end
end

function LerpUtils.lerp<T>(alpha:number,to:T,from:T):T
	--TODO Rect, UDim, Vector2int16, EnumItem
	if type(to) ~= type(from) then
		error('"to" and "from" types do not match')
	end
	local typ = typeof(to)
	if typ == "number" then
		return from + (to - from) * alpha
	elseif typ == "boolean" then
		return if alpha < .5 then from else to
	elseif typ == "CFrame" then
		return from:Lerp(to,alpha)
	elseif typ == "Color3" then
		return from:Lerp(to,alpha)
	elseif typ == "UDim2" then
		return from:Lerp(to,alpha)
	elseif typ == "Vector2" then
		return from:Lerp(to,alpha)
	elseif typ == "Vector3" then
		return from:Lerp(to,alpha)
	end
end

LerpUtils.basic_linear = LerpUtils.enum_ease(Enum.EasingStyle.Linear,Enum.EasingDirection.InOut)

return LerpUtils