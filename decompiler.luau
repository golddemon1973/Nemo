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
	assert(self._register[name], "Attempt to clean nonexistent register")
	self._register[name].data.value = nil
end

--\ VariableNamingHandler \--
local VNH = {}
VNH.__index = VNH

function VNH.new()
	return setmetatable({
		_register = {}, -- maps original argument/register -> user variable name
		_counter = 0
	}, VNH)
end

function VNH:GetVariableName()
	-- always produce a fresh name using a counter to avoid collisions in table length issues
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

--\ Parsing library \--
local function IsGotoLabel(line)
	-- Remove trailing comments first
	local cleaned = line:gsub("%-%-.*$", "")  
	-- check if only ::number:: blocks separated by commas
	cleaned = cleaned:match("^%s*(.-)%s*$")  -- trim spaces
	if cleaned == "" then return false end

	-- Split by comma
	for part in cleaned:gmatch("[^,]+") do
		part = part:match("^%s*(.-)%s*$")  -- trim each piece
		if not part:match("^::%d+::$") then
			return false
		end
	end
	return true
end

local function SplitArguments(str)
	local t = {}
	if not str or str == "" then
		return t
	end
	for arg in string.gmatch(str, "[^,%s]+") do
		table.insert(t, arg)
	end
	return t
end

local function ParseFunctionHeader(Raw)
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

	local index  = SafeMatch(line, "^%s*%[(%d+)%]")
	local opcode = SafeMatch(line, "%]%s*(%w+)")
	local comment = SafeMatch(line, ";%s*(.+)$")

	if opcode == "RETURN" then
		local returns = {}

		if comment then
			local ret = comment:match("^return%s+(.+)$")
			if ret then
				-- split by "->" exactly
				for part in ret:gmatch("([^>]+)") do
					part = part:match("^%s*(.-)%s*$")
					-- skip empty or just whitespace
					if part ~= "" then
						table.insert(returns, part)
					end
				end
			end
		end

		return {
			isafunction = false,
			isreturn = true,
			index = index and tonumber(index) or nil,
			opcode = opcode,
			returns = returns,
			_raw = line
		}
	end
	local argument, result, callArgs, concatArgs

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

		else
			argument, result = comment:match("(%w+)%s*=%s*(.+)")
		end
	end

	return {
		isafunction = false,
		isend = false,
		islabel = false,
		index = index and tonumber(index) or nil,
		opcode = opcode,
		argument = argument,
		result = result,
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
	return ("local %s = %s"):format(Name, Value)
end

function FormatGlobalAssign(Name, Value)
	return ("%s = %s"):format(Name, Value)
end

function IsUntreatedVar(value)
	if type(value) ~= "string" then
		return false
	end

	-- trim whitespace
	value = value:match("^%s*(.-)%s*$")

	-- exact match: var<number>
	return value:match("^var%d+$") ~= nil
end

--\ Arrays \--

local NO_RETURNS = {
	["print"] = true,
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

--\ Nemo \--
local Nemo = {}

function Nemo:Decompile(Disassembly, Debug)
	local VRL_ = VRL.new()
	local VNH_ = VNH.new()

	local Parsed = ParseDisassembly(Disassembly)

	print(Parsed)

	local Output = {}
	local StringOutput = "-- Decompiled with Nemo BETA\n"

	local function AddToOutput (String:string)
		table.insert(Output, String)
	end

	for Line, Data in pairs(Parsed) do
		--upvalues support when
		
		if Data.isend then
			AddToOutput("end") --handle function's end
			
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

		if Data.opcode == "LOADK" or Data.opcode == "LOADN" or Data.opcode == "LOADB" or Data.opcode == "LOADNIL" or Data.opcode == "GETIMPORT" or Data.opcode == "NEWTABLE" then
			local Argument = Data.argument

			local Result = Data.result

			VRL_:WriteRegister(Argument, Result)

			local VarName = VNH_:BindAndGetVariableName(Argument)
			
			AddToOutput(FormatVariableAssign(VarName, Result))

			continue
		end
		
		if Data.opcode == "SETGLOBAL" then
			print("!SETGLOBAL")
			
			print(Data)
			
			local Argument = Data.argument
			local Result = Data.result
			
			VRL_:WriteRegister(Argument, Result)
			
			local IsADisassmVar = IsUntreatedVar(Result)
			
			if IsADisassmVar then
				AddToOutput(FormatGlobalAssign(Argument, VNH_:GetName(Result)))
			else
				AddToOutput(FormatGlobalAssign(Argument, Result))
			end
			
			continue
		end
		
		if Data.opcode == "GETGLOBAL" then
			print("!GETGLOBAL")
			
			print(Data)
			
			local Argument = Data.argument
			local Result = Data.result

			VRL_:WriteRegister(Argument, Result)
			
			local VarName = VNH_:GetName(Argument)
			
			AddToOutput(FormatVariableAssign(VarName, Result))
			
			continue
		end

		if Data.opcode == "DUPCLOSURE" or Data.opcode == "NEWCLOSURE" then
			local Argument = Data.argument
			local Result = Data.result

			VRL_:WriteRegister(Argument, Result)

			local VarName = VNH_:BindAndGetVariableName(Argument)

			AddToOutput(FormatVariableAssign(VarName, Result))

			continue
		end

		if Data.opcode == "MOVE" then
			local Argument = Data.argument
			local Result = Data.result

			local ActualResult = VNH_:GetName(Result)

			VRL_:WriteRegister(Argument, ActualResult)

			local VarName = VNH_:BindAndGetVariableName(Argument)

			AddToOutput(FormatVariableAssign(VarName, ActualResult))

			continue
		end

		if Data.opcode == "CALL" then
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
					local VarName = VNH_:BindAndGetVariableName(Caller)
					
					AddToOutput(FormatVariableAssign(VarName, Outer..Inner))
				else
					AddToOutput(Outer..Inner)
				end
			end)
			
			if not sccess then
				AddToOutput("-- error:"..err.." raw: "..Data._raw)
			end

			continue
		end
		
		if Data.opcode == "RETURN" then
			print("!RETURN")
			
			print(Data)
			
			local ReturnArgs = Data.returns
			
			local TrueReturnArgs = {}
			
			for i=1, #ReturnArgs do
				TrueReturnArgs[i] = VNH_:GetName(ReturnArgs[i])
			end
			
			AddToOutput(("return %s"):format(table.concat(ReturnArgs, ", ")))
			
			continue
		end
		
		if Data.opcode then
			AddToOutput(("-- Unknown instruction: %s"):format(Data.opcode))
			
			continue
		else
			AddToOutput(("-- ABSOLUTE Unknown! Raw: %s"):format(Data._raw))
			
			continue
		end
	end

	StringOutput = StringOutput..table.concat(Output, "\n")

	if Debug then
		print(StringOutput)
	end

	return StringOutput
end

return Nemo
