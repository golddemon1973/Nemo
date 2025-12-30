--!native

--\ VariableRegisterLibrary \--
local VRL = {}
VRL.__index = VRL

function VRL.new()
	return setmetatable({
		_register = {}
	}, VRL)
end

function VRL:WriteRegister(name, value)
	assert(type(name) == "string", "WriteRegister: name must be string")

	self._register[name] = {
		data = {
			name = name,
			value = value,
		}
	}
end

function VRL:GetRegisterValue(name)
	local reg = self._register[name]

	if reg then
		return reg.data.value
	end

	return nil
end

function VRL:CleanRegister(name)
	assert(self._register[name], "Attempt to clean non existent register")
	self._register[name].data.value = nil
end

--\ VariableNamingHandler \--
local VNH = {}
VNH.__index = VNH

function VNH.new()
	return setmetatable({
		_register = {},
		_counter = 0
	}, VNH)
end

function VNH:GetVariableName()
	self._counter = (self._counter or 0) + 1

	return "v" .. tostring(self._counter)
end

function VNH:BindAndGetVariableName(original)
	assert(original, "BindAndGetVariableName requires an original identifier")
	local existing = self._register[original]
	if existing then
		return existing
	end
	local name = self:GetVariableName()
	self._register[original] = name
	return name
end

function VNH:GetName(original)
	return self._register[original]
end

--\ Arrays \--

local ARITHS = {
	["ADD"] = true,
	["ADDK"] = true,

	["SUB"] = true,
	["SUBK"] = true,
	["SUBRK"] = true,

	["DIV"] = true,
	["DIVK"] = true,
	["DIVRK"] = true,

	["IDIV"] = true,
	["IDIVK"] = true,

	["MUL"] = true,
	["MULK"] = true,

	["MOD"] = true,
	["MODK"] = true,

	["POW"] = true,
	["POWK"] = true,
}

local NO_RETURNS = {
	["print"] = true,
	["warn"] = true,
	["error"] = true,
	["assert"] = true,

	["table.clear"] = true,

	["task.cancel"] = true,
}

local LIMITED_ARGS = {
	-- Globals
	["print"] = nil,              -- infinite
	["warn"] = nil,               -- infinite
	["error"] = 2,                -- message, level?
	["assert"] = 2,               -- condition, message?
	["type"] = 1,
	["typeof"] = 1,
	["tostring"] = 1,
	["tonumber"] = 2,             -- value, base?
	["pairs"] = 1,
	["ipairs"] = 1,
	["next"] = 2,
	["select"] = nil,             -- infinite
	["pcall"] = nil,              -- infinite
	["xpcall"] = 3,               -- function, errHandler, arguments...
	["unpack"] = 3,               -- table, i?, j?
	["require"] = 1,
	["rawequal"] = 2,
	["rawget"] = 2,
	["rawset"] = 3,
	["setmetatable"] = 2,
	["getmetatable"] = 1,

	-- math
	["math.abs"] = 1,
	["math.acos"] = 1,
	["math.asin"] = 1,
	["math.atan"] = 2,            -- y, x?
	["math.ceil"] = 1,
	["math.clamp"] = 3,
	["math.cos"] = 1,
	["math.cosh"] = 1,
	["math.deg"] = 1,
	["math.exp"] = 1,
	["math.floor"] = 1,
	["math.fmod"] = 2,
	["math.frexp"] = 1,
	["math.ldexp"] = 2,
	["math.log"] = 2,             -- x, base?
	["math.log10"] = 1,
	["math.max"] = nil,           -- infinite
	["math.min"] = nil,           -- infinite
	["math.modf"] = 1,
	["math.noise"] = 3,
	["math.pow"] = 2,
	["math.rad"] = 1,
	["math.random"] = 2,          -- min?, max?
	["math.randomseed"] = 1,
	["math.round"] = 1,
	["math.sign"] = 1,
	["math.sin"] = 1,
	["math.sinh"] = 1,
	["math.sqrt"] = 1,
	["math.tan"] = 1,
	["math.tanh"] = 1,

	-- string
	["string.byte"] = 3,          -- s, i?, j?
	["string.char"] = nil,        -- infinite
	["string.find"] = 4,
	["string.format"] = nil,      -- infinite
	["string.gmatch"] = 2,
	["string.gsub"] = 4,
	["string.len"] = 1,
	["string.lower"] = 1,
	["string.match"] = 3,
	["string.rep"] = 3,
	["string.reverse"] = 1,
	["string.split"] = 2,
	["string.sub"] = 3,
	["string.upper"] = 1,

	-- table
	["table.clear"] = 1,
	["table.clone"] = 1,
	["table.concat"] = 4,
	["table.create"] = 2,
	["table.find"] = 3,
	["table.freeze"] = 1,
	["table.getn"] = 1,
	["table.insert"] = 3,
	["table.isfrozen"] = 1,
	["table.maxn"] = 1,
	["table.move"] = 5,
	["table.pack"] = nil,         -- infinite
	["table.remove"] = 2,
	["table.sort"] = 2,
	["table.unpack"] = 3,

	-- coroutine
	["coroutine.create"] = 1,
	["coroutine.resume"] = nil,   -- infinite
	["coroutine.running"] = 0,
	["coroutine.status"] = 1,
	["coroutine.wrap"] = 1,
	["coroutine.yield"] = nil,    -- infinite

	-- task (Roblox)
	["task.wait"] = 1,
	["task.spawn"] = nil,         -- infinite
	["task.delay"] = nil,         -- infinite
	["task.defer"] = nil,         -- infinite

	-- os (limited in Roblox)
	["os.clock"] = 0,
	["os.date"] = 2,
	["os.difftime"] = 2,
	["os.time"] = 1,
}

--\ Arithmetic Parsing \--

local ArithParser = {}

local ArithPatterns = {
	compound = {
		pattern = "^%s*(%w+)%s*([+%-*/%%])=(%s*.+)$",
		extract = function(var, op, right)
			right = right:match("^%s*(.-)%s*$")
			return {argument = var, result = right}
		end
	},

	power_compound = {
		pattern = "^%s*(%w+)%s*%^=%s*(.+)$",
		extract = function(var, right)
			right = right:match("^%s*(.-)%s*$")
			return {argument = var, result = right}
		end
	},

	floor_compound = {
		pattern = "^%s*(%w+)%s*//%s*=%s*(.+)$",
		extract = function(var, right)
			right = right:match("^%s*(.-)%s*$")
			return {argument = var, result = right}
		end
	},

	modulo_compound = {
		pattern = "^%s*(%w+)%s*%%%s*=%s*(.+)$",
		extract = function(var, right)
			right = right:match("^%s*(.-)%s*$")
			return {argument = var, result = right}
		end
	},

	binary = {
		pattern = "^%s*(%w+)%s*=%s*([^+%-%*/%%^]+)%s*([+%-%*/%%])%s*(.+)$",
		extract = function(var, left, op, right)
			left = left:match("^%s*(.-)%s*$")
			right = right:match("^%s*(.-)%s*$")
			return {argument = var, result1 = left, result2 = right}
		end
	},

	power_binary = {
		pattern = "^%s*(%w+)%s*=%s*([^%^]+)%s*%^%s*(.+)$",
		extract = function(var, left, right)
			left = left:match("^%s*(.-)%s*$")
			right = right:match("^%s*(.-)%s*$")
			return {argument = var, result1 = left, result2 = right}
		end
	},

	floor_binary = {
		pattern = "^%s*(%w+)%s*=%s*(.+)%s*//%s*(.+)$",
		extract = function(var, left, right)
			left = left:match("^%s*(.-)%s*$")
			right = right:match("^%s*(.-)%s*$")
			return {argument = var, result1 = left, result2 = right}
		end
	}
}

function ArithParser.parse(expr, debug)
	if debug then
		print("Parsing: '" .. expr .. "'")
		print("Testing power_compound pattern: " .. ArithPatterns.power_compound.pattern)
	end

	local var, right = expr:match(ArithPatterns.floor_compound.pattern)
	if var then
		if debug then print("Matched: floor_compound") end
		return ArithPatterns.floor_compound.extract(var, right)
	end

	var, right = expr:match(ArithPatterns.modulo_compound.pattern)
	if var then
		if debug then print("Matched: modulo_compound") end
		return ArithPatterns.modulo_compound.extract(var, right)
	end

	var, right = expr:match(ArithPatterns.power_compound.pattern)
	if var then
		if debug then print("Matched: power_compound") end
		return ArithPatterns.power_compound.extract(var, right)
	end

	var, left, right = expr:match(ArithPatterns.floor_binary.pattern)
	if var then
		if debug then print("Matched: floor_binary") end
		return ArithPatterns.floor_binary.extract(var, left, right)
	end

	var, left, right = expr:match(ArithPatterns.power_binary.pattern)
	if var then
		if debug then print("Matched: power_binary") end
		return ArithPatterns.power_binary.extract(var, left, right)
	end

	var, left, op, right = expr:match(ArithPatterns.binary.pattern)
	if var then
		if debug then print("Matched: binary") end
		return ArithPatterns.binary.extract(var, left, op, right)
	end

	var, op, right = expr:match(ArithPatterns.compound.pattern)
	if var then
		if debug then print("Matched: compound") end
		return ArithPatterns.compound.extract(var, op, right)
	end

	if debug then print("No match found!") end
	return nil
end

--\ Parsing library \--

function EscapePattern(s)
	return s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")
end

function IsGotoLabel(line)
	local cleaned = line:gsub("%-%-.*$", "")  

	cleaned = cleaned:match("^%s*(.-)%s*$")
	if cleaned == "" then return false end

	for part in cleaned:gmatch("[^,]+") do
		part = part:match("^%s*(.-)%s*$")
		if not part:match("^::%d+::$") then
			return false
		end
	end

	return true
end

function SplitArguments(str)
	local t = {}
	if not str or str == "" then
		return t
	end
	for arg in string.gmatch(str, "[^,%s]+") do
		table.insert(t, arg)
	end
	return t
end

function ParseReturnList(ret)
	local results = {}

	for part in string.gmatch(ret, "[^%-]+") do
		part = part:gsub("^%s*", ""):gsub("%s*$", "")
		part = part:gsub("^>", "") -- remove any leading >
		if part ~= "" then
			table.insert(results, part)
		end
	end

	return results
end

function ParseFunctionHeader(Raw)
	local Name, Line = Raw:match("^%s*function%s+(%w+)%s*%(%s*%)%s*%-%-%s*Line%s*(%d+)") or Raw:match("^%s*local%s+function%s+(%w+)%s*%(%s*%)%s*%-%-%s*Line%s*(%d+)")

	if Name then
		local indent = Raw:match("^(%s*)")
		local nested = indent ~= "" and indent ~= nil

		return {
			isafunction = true,
			name = Name,
			line = tonumber(Line),
			isnested = nested
		}
	end

	return nil
end

function ParseAssignment(comment)
	local lhs, rhs = comment:match("^%s*(.-)%s*=%s*(.+)$")
	if not lhs then return nil end
	return lhs, rhs
end

function SplitAssignment(comment)
	return comment:match("^%s*(.-)%s*=%s*(.+)$")
end

function ParseTableAccess(expr)
	local base, key = expr:match("^(%w+)%.([%w_]+)$")
	if base then

		return base, key
	end

	base, key = expr:match("^(%w+)%[(.-)%]$")
	if base then
		return base, key
	end

	return nil
end

function ParseLogical(opcode, comment)
	local dest, expr = comment:match("^(%w+)%s*=%s*(.+)$")

	if not dest then return nil end

	local a, b

	if opcode == "AND" or opcode == "ANDK" then
		a, b = expr:match("^(.-)%s+and%s+(.+)$")
	elseif opcode == "OR" or opcode == "ORK" then
		a, b = expr:match("^(.-)%s+or%s+(.+)$")
	end

	if not a or not b then
		return nil
	end

	return {
		argument = dest,
		logicalOp = (opcode == "AND" or opcode == "ANDK") and "and" or "or",
		operands = {
			a:match("^%s*(.-)%s*$"),
			b:match("^%s*(.-)%s*$")
		}
	}
end

function SafeMatch(str, pattern)
	if not str then
		return nil
	end

	return string.match(str, pattern)
end

function ParseInstruction(line)
	local trimmed = line:match("^%s*(.-)%s*$")

	if IsGotoLabel(trimmed) then
		return nil
	end

	if trimmed == "end" or trimmed:match("^end%s*%-%-") then
		return {
			isend = true,
			_raw = line
		}
	end

	local fh = ParseFunctionHeader(line)
	if fh then
		return fh
	end

	local instrIndex = SafeMatch(line, "^%s*%[(%d+)%]")
	local opcode = SafeMatch(line, "%]%s*(%w+)")
	local comment = SafeMatch(line, ";%s*(.+)$")

	local argument, result, callArgs, concatArgs, tblIndex

	if comment then
		comment = comment:match("^%s*(.-)%s*$")

		if opcode == "SETGLOBAL" then
			local name, value = comment:match("^([%w_]+)%s*=%s*(.+)$")

			if name then
				argument = name
				result = value
			end
		elseif opcode == "CALL" then
			local func, inside = comment:match("(%w+)%s*%(([^)]*)%)")

			if func then
				argument = func
				result = comment
				callArgs = SplitArguments(inside)
			end
		elseif opcode == "CONCAT" then
			local lhs, rhs = comment:match("(%w+)%s*=%s*(.+)")

			if lhs then
				argument = lhs
				result = rhs
				concatArgs = {}
				for part in rhs:gmatch("[^%.]+") do
					part = part:gsub("^%.*", ""):gsub("%.*$", "")
					table.insert(concatArgs, part)
				end
			end
		elseif opcode == "RETURN" then
			local returns = {}

			if comment then
				local ret = comment:match("^return%s+(.+)$")
				if ret then
					returns = ParseReturnList(ret)
				end
			end

			return {
				isafunction = false,
				isreturn = true,
				index = instrIndex and tonumber(instrIndex) or nil,
				opcode = opcode,
				returns = returns,
				_raw = line
			}
		elseif opcode == "AND" or opcode == "OR"or opcode == "ANDK" or opcode == "ORK" then
			local logical = ParseLogical(opcode, comment)

			if logical then
				return {
					isafunction = false,
					isreturn = false,
					isend = false,
					index = instrIndex and tonumber(instrIndex) or nil,
					opcode = opcode,
					argument = logical.argument,
					operands = logical.operands,
					_raw = line
				}
			end
		elseif ARITHS[opcode] then
			local Arith = ArithParser.parse(comment)

			if Arith then
				if Arith.result1 then
					return {
						isafunction = false,
						isreturn = false,
						isend = false,
						index = instrIndex,
						opcode = opcode,
						argument = Arith.argument,
						result1 = Arith.result1,
						result2 = Arith.result2,
						_raw = line
					}
				else
					return {
						isafunction = false,
						isreturn = false,
						isend = false,
						index = instrIndex,
						opcode = opcode,
						argument = Arith.argument,
						result = Arith.result,
						_raw = line
					}
				end
			end
		else
			local lhs, rhs = ParseAssignment(comment)

			if lhs then
				if opcode and opcode:match("^SETTABLE") then
					local base, key = ParseTableAccess(lhs)

					if base then
						argument = base
						tblIndex = key
						result = rhs
					end
				elseif opcode and opcode:match("^GETTABLE") then
					local base, key = ParseTableAccess(rhs)

					if base then
						argument = lhs
						tblIndex = key
						result = base
					end
				else
					argument = lhs
					result = rhs
				end
			end
		end
	end

	return {
		isafunction = false,
		isend = false,
		index = instrIndex and tonumber(instrIndex) or nil,
		opcode = opcode,
		argument = argument,
		result = result,
		tblIndex = tblIndex,
		callArgs = callArgs,
		concatArgs = concatArgs,
		_raw = line
	}
end

function ParseDisassembly(Disassembly)
	local Lines = {}

	for Line in Disassembly:gmatch("[^\n]+") do
		local Data = ParseInstruction(Line)

		table.insert(Lines, Data)
	end

	return Lines
end

--\ General helpers \--

function FormatVariableAssign(Name, Value)
	if Name and Value then
		return ("local %s = %s"):format(Name, Value)
	else
		return ("-- Failed to process variable assign with name %s and value %s"):format(Name or "null", Value or "null")
	end
end

function FormatGlobalAssign(Name, Value)
	if Name and Value then
		return ("%s = %s"):format(Name, Value)
	else
		return ("-- Failed to process variable assign with name %s and value %s"):format(Name or "null", Value or "null")
	end
end

function FormatArithAssign(Operator, Name, Value)
	if Operator and Name and Value then
		return ("%s %s %s"):format(Name, Operator, Value)
	else
		return ("-- Failed to process variable assign with name %s, operator %s and value %s"):format(Name or "null", Operator or "null", Value or "null")
	end
end

function IsUntreatedVar(value)
	if type(value) ~= "string" then
		return false
	end

	value = value:match("^%s*(.-)%s*$")

	return value:match("^var%d+$") ~= nil
end

--\ Nemo \--
local Nemo = {}

function Nemo:Decompile(Disassembly, Debug)
	local StartTick = tick()

	local VRL_ = VRL.new()
	local VNH_ = VNH.new()

	local Parsed = ParseDisassembly(Disassembly)

	print(Parsed)

	local Output = {}
	local StringOutput = "-- Decompiled with Nemo v0.3.1\n"

	local function AddToOutput (String:string, Opcode:string)
		if Opcode then
			table.insert(Output, String)
		else
			table.insert(Output, String)
		end
	end

	local function SmartBindAndGetVarName(Argument:string)
		if VNH_:GetName(Argument) then
			return VNH_:GetName(Argument)
		else
			return VNH_:BindAndGetVariableName(Argument)
		end
	end

	for Line, Data in pairs(Parsed) do
		--upvalues support when

		if not Data.opcode then
			continue
		end

		if Data.isend --[[or ProcessedOpcode == "FORNLOOP" or ProcessedOpcode == "FORGLOOP"]] then --loops coming soon :D
			AddToOutput("end") --handle function's or loop's end

			continue
		end

		if Data.isafunction and not Data.isnested then
			AddToOutput(("function %s ()"):format(Data.name))

			continue
		elseif Data.isafunction and Data.isnested then
			AddToOutput(("local function %s ()"):format(Data.name))

			continue
		end

		--opcodes yeehaw

		local ProcessedOpcode = string.gsub(Data.opcode, " ", "") --fix for spacing causing some opcodes to fail

		--\\ NOISE

		if ProcessedOpcode == "PREPVARARGS" or ProcessedOpcode == "CAPTURE" or ProcessedOpcode:find("FASTCALL") then
			continue
		end

		--\\ VARIABLE SETS

		if ProcessedOpcode == "LOADK" or ProcessedOpcode == "LOADN" or ProcessedOpcode == "LOADB" or ProcessedOpcode == "LOADNIL" or ProcessedOpcode == "GETIMPORT" then
			local Argument = Data.argument

			local Result = Data.result

			VRL_:WriteRegister(Argument, Result)

			local VarName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatVariableAssign(VarName, Result), ProcessedOpcode)

			continue
		end

		if ProcessedOpcode == "SETGLOBAL" then
			local Argument = Data.argument
			local Result = Data.result

			VRL_:WriteRegister(Argument, Result)

			local IsADisassmVar = IsUntreatedVar(Result)

			if IsADisassmVar then
				AddToOutput(FormatGlobalAssign(Argument, SmartBindAndGetVarName(Result)), ProcessedOpcode)
			else
				AddToOutput(FormatGlobalAssign(Argument, Result), ProcessedOpcode)
			end

			continue
		end

		if ProcessedOpcode == "GETGLOBAL" then
			local Argument = Data.argument
			local Result = Data.result

			VRL_:WriteRegister(Argument, Result)

			local VarName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatVariableAssign(VarName, Result), ProcessedOpcode)

			continue
		end

		if ProcessedOpcode == "DUPCLOSURE" or ProcessedOpcode == "NEWCLOSURE" then
			local Argument = Data.argument
			local Result = Data.result

			VRL_:WriteRegister(Argument, Result)

			local VarName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatVariableAssign(VarName, Result), ProcessedOpcode)

			continue
		end

		--\\ SPECIAL

		if ProcessedOpcode == "MOVE" then
			local Argument = Data.argument
			local Result = Data.result

			local ActualResult = VNH_:GetName(Result)

			VRL_:WriteRegister(Argument, ActualResult)

			local VarName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatVariableAssign(VarName, ActualResult), ProcessedOpcode)

			continue
		end

		if ProcessedOpcode == "CALL" then
			local sccess, err = pcall(function()
				local Caller = Data.argument
				local UsedCaller = VRL_:GetRegisterValue(Caller)

				string.gsub(Caller, "->(top)", "") --remove those shi

				local CallArgs = Data.callArgs

				for i, str in pairs(CallArgs) do
					CallArgs[i] = string.gsub(str, "->(top)", "")
				end

				local TrueCallArgs = {}
				local ExpectedArgs = LIMITED_ARGS[UsedCaller]

				if not ExpectedArgs then
					ExpectedArgs = 1
				end

				for i=1, ExpectedArgs do
					TrueCallArgs[i] = VNH_:GetName(CallArgs[i])
				end

				local Outer = ("%s"):format(VNH_:GetName(Caller))
				local Inner = ("(%s)"):format(table.concat(TrueCallArgs, ", "))

				if not NO_RETURNS[UsedCaller] then
					local VarName = SmartBindAndGetVarName(Caller)

					AddToOutput(FormatVariableAssign(VarName, Outer..Inner), ProcessedOpcode)
				else
					AddToOutput(Outer..Inner, ProcessedOpcode)
				end
			end)

			if not sccess then
				AddToOutput("-- error:"..err.." raw: "..Data._raw)
			end

			continue
		end

		if ProcessedOpcode == "RETURN" then
			local ReturnArgs = Data.returns

			local TrueReturnArgs = {}

			for i=1, #ReturnArgs do
				print(ReturnArgs[i])

				TrueReturnArgs[i] = VNH_:GetName(ReturnArgs[i])

				print(TrueReturnArgs[i])
			end

			AddToOutput(("return %s"):format(table.concat(TrueReturnArgs, ", ")))

			continue
		end

		--\\ TABLE UTILS

		if ProcessedOpcode == "NEWTABLE" or ProcessedOpcode == "DUPTABLE" then
			local Argument = Data.argument
			local Result = Data.result

			VRL_:WriteRegister(Argument, "{}")

			local VarName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatVariableAssign(VarName, "{}"), ProcessedOpcode)

			continue
		end

		if ProcessedOpcode == "SETTABLEKS" then
			local Argument = Data.argument
			local Result = Data.result
			local TableIndex = Data.tblIndex

			local TableVariable = VNH_:GetName(Argument)
			local ResultVariable = VNH_:GetName(Result)

			AddToOutput(TableVariable..'["'..TableIndex..'"]'.." = "..ResultVariable, ProcessedOpcode)

			continue
		end

		if ProcessedOpcode == "SETTABLEN" then
			local Argument = Data.argument
			local Result = Data.result
			local TableIndex = Data.tblIndex

			local TableVariable = VNH_:GetName(Argument)
			local ResultVariable = VNH_:GetName(Result)

			AddToOutput(TableVariable.."["..TableIndex.."]".." = "..ResultVariable, ProcessedOpcode)

			continue
		end

		if ProcessedOpcode == "SETTABLE" then
			local Argument = Data.argument
			local Result = Data.result
			local TableIndex = Data.tblIndex

			local TableVariable = VNH_:GetName(Argument)
			local ResultVariable = VNH_:GetName(Result)
			local IndexVariable = VNH_:GetName(TableIndex)

			AddToOutput(TableVariable.."["..IndexVariable.."]".." = "..ResultVariable, ProcessedOpcode)

			continue
		end

		if ProcessedOpcode == "GETTABLEKS" then
			local Argument = Data.argument
			local Result = Data.result
			local TableIndex = Data.tblIndex

			local ResultVariable = VNH_:GetName(Result)

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatVariableAssign(VariableName, ResultVariable..'["'..TableIndex..'"]'), ProcessedOpcode)

			VRL_:WriteRegister(Argument, ResultVariable.."["..TableIndex.."]")

			continue
		end

		if ProcessedOpcode == "GETTABLEN" then
			local Argument = Data.argument
			local Result = Data.result
			local TableIndex = Data.tblIndex

			local ResultVariable = VNH_:GetName(Result)

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatVariableAssign(VariableName, ResultVariable.."["..TableIndex.."]"), ProcessedOpcode)

			VRL_:WriteRegister(Argument, ResultVariable.."["..TableIndex.."]", ProcessedOpcode)

			continue
		end

		if ProcessedOpcode == "GETTABLE" then
			local Argument = Data.argument
			local Result = Data.result
			local TableIndex = Data.tblIndex

			local ResultVariable = VNH_:GetName(Result)
			local IndexVariable = VNH_:GetName(TableIndex)

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatVariableAssign(VariableName, ResultVariable.."["..IndexVariable.."]"), ProcessedOpcode)

			VRL_:WriteRegister(Argument, ResultVariable.."["..IndexVariable.."]", ProcessedOpcode)

			continue
		end

		if ProcessedOpcode == "LENGTH" then
			local Argument = Data.argument
			local Result = string.gsub(Data.result, "#", "") --remove length operator to get variable name

			local ResultVariable = VNH_:GetName(Result)

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatVariableAssign(VariableName, "#"..ResultVariable))

			VRL_:WriteRegister(Argument, "#"..ResultVariable)

			continue
		end

		--\\ LOGICALS

		if ProcessedOpcode == "AND" or ProcessedOpcode == "OR" or ProcessedOpcode == "ANDK" or ProcessedOpcode == "ORK" then
			local Argument = Data.argument
			local Operands = Data.operands

			local TrueOperands = {}

			for i=1, #Operands do
				local Operand = Operands[i]

				if IsUntreatedVar(Operand) then
					TrueOperands[i] = VNH_:GetName(Operand)
				else
					TrueOperands[i] = Operand -- no change since it's a correct value
				end
			end

			local VariableName = SmartBindAndGetVarName(Argument)

			local StringOperands = table.concat(TrueOperands, (" %s "):format(string.lower(string.gsub(ProcessedOpcode, "K", ""))))

			VRL_:WriteRegister(Argument, StringOperands)

			AddToOutput(FormatVariableAssign(VariableName, StringOperands))

			continue
		end

		if ProcessedOpcode == "GETVARARGS" then
			local VariableName = SmartBindAndGetVarName(Data.argument)

			AddToOutput(FormatVariableAssign(VariableName, "..."), ProcessedOpcode)

			continue
		end

		--\\ CONCAT

		if ProcessedOpcode == "CONCAT" then
			local Argument = Data.argument
			local ConcatArgs = Data.concatArgs

			local TrueConcatArgs = {}

			for i=1, #ConcatArgs do
				TrueConcatArgs[i] = VNH_:GetName(ConcatArgs[i])
			end

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatVariableAssign(VariableName, table.concat(TrueConcatArgs, "..")))

			continue
		end

		--\\ ARITHS

		if ProcessedOpcode == "MINUS" then
			local Argument = Data.Argument
			local Result = string.gsub(Data.result, "-", "")

			local VariableName = SmartBindAndGetVarName(Result)

			local ProcessedResult = Result

			if IsUntreatedVar(Result) then
				ProcessedResult = VNH_:GetName(Result) 
			end

			AddToOutput(FormatVariableAssign(VariableName, "-"..ProcessedResult))

			continue
		end

		if ProcessedOpcode == "NOT" then
			local Argument = Data.Argument
			local Result = string.gsub(Data.result, "not ", "")

			local VariableName = SmartBindAndGetVarName(Result)

			local ProcessedResult = Result

			if IsUntreatedVar(Result) then
				ProcessedResult = VNH_:GetName(Result) 
			end

			AddToOutput(FormatVariableAssign(VariableName, "not "..ProcessedResult))

			continue
		end

		if ProcessedOpcode == "ADDK" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatArithAssign("+=", VariableName, Result))

			continue
		end

		if ProcessedOpcode == "ADD" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)
			local ResultName = VNH_:GetName(Result)

			AddToOutput(FormatArithAssign("+=", VariableName, ResultName))

			continue
		end

		if ProcessedOpcode == "SUBRK" then
			local Argument = Data.argument
			local Result1 = Data.result1
			local Result2 = Data.result2

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatArithAssign("=", VariableName, Result1.." - "..VNH_:GetName(Result2)))

			continue
		end

		if ProcessedOpcode == "SUBK" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatArithAssign("-=", VariableName, Result))

			continue
		end

		if ProcessedOpcode == "SUB" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)
			local ResultName = VNH_:GetName(Result)

			AddToOutput(FormatArithAssign("-=", VariableName, ResultName))

			continue
		end

		if ProcessedOpcode == "DIVRK" then
			local Argument = Data.argument
			local Result1 = Data.result1
			local Result2 = Data.result2

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatArithAssign("=", VariableName, Result1.." / "..VNH_:GetName(Result2)))

			continue
		end

		if ProcessedOpcode == "DIVK" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatArithAssign("/=", VariableName, Result))

			continue
		end

		if ProcessedOpcode == "DIV" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)
			local ResultName = VNH_:GetName(Result)

			AddToOutput(FormatArithAssign("//=", VariableName, ResultName))

			continue
		end

		if ProcessedOpcode == "IDIVRK" then
			local Argument = Data.argument
			local Result1 = Data.result1
			local Result2 = Data.result2

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatArithAssign("=", VariableName, Result1.." // "..VNH_:GetName(Result2)))

			continue
		end

		if ProcessedOpcode == "IDIVK" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatArithAssign("/=", VariableName, Result))

			continue
		end

		if ProcessedOpcode == "IDIV" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)
			local ResultName = VNH_:GetName(Result)

			AddToOutput(FormatArithAssign("//=", VariableName, ResultName))

			continue
		end

		if ProcessedOpcode == "MULK" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatArithAssign("+=", VariableName, Result))

			continue
		end

		if ProcessedOpcode == "MUL" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)
			local ResultName = VNH_:GetName(Result)

			AddToOutput(FormatArithAssign("+=", VariableName, ResultName))

			continue
		end

		if ProcessedOpcode == "POWK" then
			local Argument = Data.argument
			local Result = Data.result

			Result = string.gsub(Result, " ^", "") --fix cause result kept capturing the " ^" and i couldn't fix it

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatArithAssign("^=", VariableName, Result))

			continue
		end

		if ProcessedOpcode == "POW" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)
			local ResultName = VNH_:GetName(Result)

			AddToOutput(FormatArithAssign("^=", VariableName, ResultName))

			continue
		end

		if ProcessedOpcode == "MODK" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)

			AddToOutput(FormatArithAssign("%=", VariableName, Result))

			continue
		end

		if ProcessedOpcode == "MOD" then
			local Argument = Data.argument
			local Result = Data.result

			local VariableName = SmartBindAndGetVarName(Argument)
			local ResultName = VNH_:GetName(Result)

			AddToOutput(FormatArithAssign("%=", VariableName, ResultName))

			continue
		end

		--\\ UNSUPPORTED

		if Debug then
			if ProcessedOpcode:find("FOR") then
				AddToOutput("-- Loop support soon")

				continue
			end

			if ProcessedOpcode:find("JUMP") then
				AddToOutput("-- Jumps support soon")

				continue
			end

			if ProcessedOpcode == "NAMECALL" then
				AddToOutput("-- Namecalls are very hard to handle, will be there an update or two after release")

				continue
			end

			if ProcessedOpcode == "SETLIST" then
				AddToOutput("-- SETLIST is not supported yet.")
			end

			if ProcessedOpcode:find("UPVAL") then
				AddToOutput("-- Upvalues support on release")

				continue
			end
		end

		print("-- "..ProcessedOpcode.."?")
	end

	local EndTick = tick()

	StringOutput = StringOutput..("-- Decompiling took %.3f seconds.\n"):format(EndTick - StartTick)
	StringOutput = StringOutput..table.concat(Output, "\n")

	if Debug then
		print(StringOutput)
	end

	return StringOutput
end

return Nemo
