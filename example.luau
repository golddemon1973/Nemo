Source:

-- LOP_BREAK, LOP_COVERAGE and LOP_NOP aren't possible without the C API
-- Vector constants are supported but need to be commented in and need the ctor renamed
-- LOADKX and JUMPX support can be commented out
---------------------------------------------------------------------------------------
-- PREPVARARGS
local a = "hello world"; -- LOADK
a,a,a,a,a,a = nil, true, false, 1, 9e9, function() --[[ RETURN ]] end; -- LOADNIL, LOADB 1, LOADB 0, LOADN 1, LOADK 9e9, DUPCLOSURE (no captures)
FUNC_GLOBAL = newproxy; -- GETIMPORT, SETGLOBAL
local t = { }; -- NEWTABLE 1 1
local function stub(...) -- NEWCLOSURE (ref, val, ref captures)
	local b = FUNC_GLOBAL(); -- GETGLOBAL, CALL
	local t = t -- GETUPVAL
	t.s = b -- SETTABLEKS
	t[1] = b -- SETTABLEN 1
	t[b] = b -- SETTABLE
	a = t[b] -- SETUPVAL, GETTABLE

	return t.s, t[1], t[b] -- GETTABLEKS, GETTABLEN, GETTABLE, RETURN 3
end
--[[ Vector constant support
local a = vector(1,2,3,4) -- LOADK
stub(a) -- CALL
--]]
local _,_,_ = stub()
local function upv()
	local function foo() -- NEWCLOSURE (upval capture)
		return upv -- GETUPVAL, RETURN 1
	end

	while FALSE_GLOBAL do end -- GETIMPORT, JUMPIFNOT, JUMPBACK

	return foo(), FUNC_GLOBAL() -- GETUPVAL, RETURN -1
end
local tm = { val = upv }; -- DUPTABLE, SETTABLEKS
local a = #tm -- LENGTH
upv = upv() -- MOVE, CALL 0 1, MOVE
local t2 = { upv(tm:val(upv())) } -- NEWTABLE 0 1, MOVE, MOVE, CALL, NAMECALL, CALL -1 -1, CALL -1 -1, SETLIST -1
local _table = {} -- NEWTABLE 0 0
local function dup() return function() --[[ RETURN ]] end --[[ DUPCLOSURE, RETURN 1 ]] end -- DUPCLOSURE
local _1, _2, _3 = dup(), dup(), dup() --[[ DUPCLOSURE x3 | CALL + MOVE x3 ]]
_table = { -- NEWTABLE 0 3
	_1, _2, _3 -- MOVE, MOVE, MOVE
}
for i = 1, 35 do -- LOADN 1, LOADN 35, LOADN 1 
	-- FORNPREP
	if i then -- JUMPIFNOT
		-- JUMP
	else  
	end
	if not i then -- JUMPIF 
		-- JUMP
	else 
	end  
	if i == i then -- JUMPIFNOTEQ
		-- JUMP
	else 
	end 
	if i ~= i then -- JUMPIFEQ
		-- JUMP
	else 
	end  
	local val
	if i >= i then -- JUMPIFNOTLE
		val = "hello " -- LOADK
		-- JUMP
	else 
	end  
	if i < i then -- JUMPIFNOTLT
		-- JUMP
	else 
	end  
	if not (i >= i) then -- JUMPIFLE
		-- JUMP
	else 
	end  
	if not (i < i) then -- JUMPIFLT
		-- JUMP
	else 
	end  
	if i == 1 then -- JUMPXEQKN  
	end
	if i == "hello" then -- JUMPXEQKS
	end 
	if i == true then -- JUMPXEQKB 1
	end 
	if i == false then -- JUMPXEQKB 0
	end 
	if i == nil then -- JUMPXEQKNIL 
	end 
	if i ~= 1 then -- JUMXEQKN  
	end 
	if i ~= "hello" then -- JUMPXEQKS
	end 
	if i ~= true then -- JUMPXEQKB 1
	end 
	if i ~= false then -- JUMPXEQKB 0
	end 
	if i == nil then -- JUMPXEQKNIL 
	end 
	local a = not i -- NOT 
	local a = -i -- MINUS
	local a = val .. "world" -- MOVE, LOADK, CONCAT
	local a = i == i -- JUMPIFEQ, LOADB C1, LOADB
	local a = i and 1 -- ANDK
	local a = i or 1 -- ORK
	local a = i and i -- AND
	local a = i or i -- ORK
	i = i + 1 -- ADDK
	i = i + i -- ADD 
	i = i - 1 -- SUBK
	i = 1 - i -- SUBRK
	i = i - i -- SUB
	i = i * 1 -- MULK
	i = i * i -- MUL
	i = i / 1 -- DIVK
	i = 1 / i -- DIVRK
	i = i / i -- DIV
	i = i // 1 -- IDIVK
	i = i // i -- IDIV
	i = i ^ 1 -- POWK
	i = i ^ i -- POW
	i = i % 1 -- MODK
	i = i % i -- MOD
	local a = ... -- GETVARARGS
	local a = math.floor(i) -- FASTCALL1, MOVE, GETIMPORT, CALL
	local a = math.floor(i, i) -- FASTCALL2, MOVE, MOVE, GETIMPORT, CALL
	local a = math.floor(i, 1) -- FASTCALL2K, MOVE, LOADK, GETIMPORT, CALL
	local a = math.floor(i, 1, 2) -- (LOP_FASTCALL3 | LOP_FASTCALL) & MOVE, LOADN, LOADN, GETIMPORT, CALL 
	local a = math.floor(i, 1, 2, 3, 4, 5) -- MOVE, LOADN, LOADN, LOADN, LOADN, LOADN, FASTCALL, GETIMPORT, CALL
	-- FORNLOOP
end 
for i,v in {} do end -- FORGPREP, FORGLOOP 
for i,v in ipairs({}) do end -- FORGPREP_INEXT, FORGLOOP
for i,v in next, {} do end -- FORGPREP_NEXT, FORGLOOP
for i = 1, 35 do  -- LOADN, LOADN, LOADN
	if i then -- JUMPXEQKB 1 
		i = i % 1;
	else -- JUMPX
	end 
	break
end 
-- CLOSEUPVALS, RETURN
print("PASSED")

Disassembly:

[0] #1 [0x00000041]          PREPVARARGS 0                     ; -- Prepare for any number (top) of variables as ...
[1] #2 [0x00000005]          LOADK 0, 0                        ; var0 = "hello world"
[2] #3 [0x00000002]          LOADNIL 0                         ; var0 = nil
[3] #4 [0x00010003]          LOADB 0, 1, 0                     ; var0 = true
[4] #5 [0x00000003]          LOADB 0, 0, 0                     ; var0 = false
[5] #6 [0x00010004]          LOADN 0, 1                        ; var0 = 1
[6] #7 [0x00010005]          LOADK 0, 1                        ; var0 = 9000000000
local function func1() -- Line 7
end
[7] #8 [0x00020040]          DUPCLOSURE 0, 2                   ; var0 = func1
[8] #9 [0x0004010C]          GETIMPORT 1, 4 [0x40300000]       ; var1 = newproxy
[10] #10 [0x6D000108]        SETGLOBAL 1, 109 [5]              ; FUNC_GLOBAL = var1
[12] #11 [0x00000135]        NEWTABLE 1, 0 [0]                 ; var1 = {}
local function stub() -- Line 10
	[0] #1 [0x00000041]          PREPVARARGS 0                     ; -- Prepare for any number (top) of variables as ...
	[1] #2 [0x6D000007]          GETGLOBAL 0, 109 [0]              ; var0 = FUNC_GLOBAL
	[3] #3 [0x02010015]          CALL 0, 1, 2                      ; var0 = var0()
	[4] #4 [0x00000109]          GETUPVAL 1, 0                     ; var1 = up0
	[5] #5 [0x92010010]          SETTABLEKS 0, 1, 146 [1]          ; var1.s = var0
	[7] #6 [0x00010012]          SETTABLEN 0, 1, 0                 ; var1[0] = var0
	[8] #7 [0x0001000E]          SETTABLE 0, 1, 0                  ; var1[var0] = var0
	[9] #8 [0x0001020D]          GETTABLE 2, 1, 0                  ; var2 = var1[var0]
	[10] #9 [0x0001020A]         SETUPVAL 2, 1                     ; up1 = var2
	[11] #10 [0x9201020F]        GETTABLEKS 2, 1, 146 [1]          ; var2 = var1.s
	[13] #11 [0x00010311]        GETTABLEN 3, 1, 0                 ; var3 = var1[0]
	[14] #12 [0x0001040D]        GETTABLE 4, 1, 0                  ; var4 = var1[var0]
	[15] #13 [0x00040216]        RETURN 2, 4                       ; return var2->var4
end
[14] #12 [0x00010213]        NEWCLOSURE 2, 1                   ; var2 = stub
[14] #12 [0x00010213]        CAPTURE 0, 1                      ; up0 = var1 -- Readable
[15] #12 [0x00010213]        CAPTURE 1, 0                      ; up1 = var0 -- Readable and writable
[17] #13 [0x00020306]        MOVE 3, 2                         ; var3 = var2
[18] #14 [0x04010315]        CALL 3, 1, 4                      ; var3, var4, var5 = var3()
local function upv() -- Line 25
	local function foo() -- Line 26
		[0] #1 [0x00000009]          GETUPVAL 0, 0                     ; var0 = up0
		[1] #2 [0x00020016]          RETURN 0, 2                       ; return var0->var0
	end
	[0] #1 [0x00000013]          NEWCLOSURE 0, 0                   ; var0 = foo
	[0] #1 [0x00000013]          CAPTURE 2, 0                      ; up0 = up0
::5::
	[2] #2 [0x0001010C]          GETIMPORT 1, 1 [0x40000000]       ; var1 = FALSE_GLOBAL
	[4] #3 [0x0001011A]          JUMPIFNOT 1, 1                    ; if not var1 then goto [6] end
	[5] #4 [0xFFFC0018]          JUMPBACK -4                       ; -- goto [2] (likely while/repeat loop)
::4::
	[6] #5 [0x00000106]          MOVE 1, 0                         ; var1 = var0
	[7] #6 [0x02010115]          CALL 1, 1, 2                      ; var1 = var1()
	[8] #7 [0x6D000207]          GETGLOBAL 2, 109 [2]              ; var2 = FUNC_GLOBAL
	[10] #8 [0x00010215]         CALL 2, 1, 0                      ; var2->(top) = var2()
	[11] #9 [0x00000116]         RETURN 1, 0                       ; return var1->(top)
end
[19] #15 [0x00020613]        NEWCLOSURE 6, 2                   ; var6 = upv
[19] #15 [0x00020613]        CAPTURE 1, 6                      ; up0 = var6 -- Readable and writable
[21] #16 [0x00070736]        DUPTABLE 7, 7                     ; var7 = {}
[22] #17 [0x3F070610]        SETTABLEKS 6, 7, 63 [6]           ; var7.val = var6
[24] #18 [0x00070834]        LENGTH 8, 7                       ; var8 = #var7
[25] #19 [0x00060906]        MOVE 9, 6                         ; var9 = var6
[26] #20 [0x02010915]        CALL 9, 1, 2                      ; var9 = var9()
[27] #21 [0x00090606]        MOVE 6, 9                         ; var6 = var9
[28] #22 [0x00000935]        NEWTABLE 9, 0 [1]                 ; var9 = table.create(1)
[30] #23 [0x00060A06]        MOVE 10, 6                        ; var10 = var6
[31] #24 [0x00060D06]        MOVE 13, 6                        ; var13 = var6
[32] #25 [0x00010D15]        CALL 13, 1, 0                     ; var13->(top) = var13()
[33] #26 [0x3F070B14]        NAMECALL 11, 7, 63 [6]            ; var12 = var7; var11 = var7.val -- Invokes __namecall
[35] #27 [0x00000B15]        CALL 11, 0, 0                     ; var11->(top) = var11(var12->(top))
[36] #28 [0x00000A15]        CALL 10, 0, 0                     ; var10->(top) = var10(var11->(top))
[37] #29 [0x000A0937]        SETLIST 9, 10, 0 [1]              ; var9[1->(top)] = var10->(top)
[39] #30 [0x00000A35]        NEWTABLE 10, 0 [0]                ; var10 = {}
local function dup() -- Line 39
	local function func2() -- Line 39
	end
	[0] #1 [0x00000040]          DUPCLOSURE 0, 0                   ; var0 = func2
	[1] #2 [0x00020016]          RETURN 0, 2                       ; return var0->var0
end
[41] #31 [0x00080B40]        DUPCLOSURE 11, 8                  ; var11 = dup
[42] #32 [0x000B0F06]        MOVE 15, 11                       ; var15 = var11
[43] #33 [0x02010F15]        CALL 15, 1, 2                     ; var15 = var15()
[44] #34 [0x000F0C06]        MOVE 12, 15                       ; var12 = var15
[45] #35 [0x000B0F06]        MOVE 15, 11                       ; var15 = var11
[46] #36 [0x02010F15]        CALL 15, 1, 2                     ; var15 = var15()
[47] #37 [0x000F0D06]        MOVE 13, 15                       ; var13 = var15
[48] #38 [0x000B0E06]        MOVE 14, 11                       ; var14 = var11
[49] #39 [0x02010E15]        CALL 14, 1, 2                     ; var14 = var14()
[50] #40 [0x00000F35]        NEWTABLE 15, 0 [3]                ; var15 = table.create(3)
[52] #41 [0x000C1006]        MOVE 16, 12                       ; var16 = var12
[53] #42 [0x000D1106]        MOVE 17, 13                       ; var17 = var13
[54] #43 [0x000E1206]        MOVE 18, 14                       ; var18 = var14
[55] #44 [0x04100F37]        SETLIST 15, 16, 4 [1]             ; var15[1->3] = var16->var18
[57] #45 [0x000F0A06]        MOVE 10, 15                       ; var10 = var15
[58] #46 [0x00011104]        LOADN 17, 1                       ; var17 = 1
[59] #47 [0x00230F04]        LOADN 15, 35                      ; var15 = 35
[60] #48 [0x00011004]        LOADN 16, 1                       ; var16 = 1
[61] #49 [0x00710F38]        FORNPREP 15, 113                  ; for var17 = var17, var15, var16 do -- If loop shouldn't start (var17 > var15) then goto [175]
::174::
[62] #50 [0x00111206]        MOVE 18, 17                       ; var18 = var17
[63] #51 [0x0001121A]        JUMPIFNOT 18, 1                   ; if not var18 then goto [65] end
[64] #52 [0x00000017]        JUMP 0                            ; -- goto [65]
::63::, ::64::
[65] #53 [0x00011219]        JUMPIF 18, 1                      ; if var18 then goto [67] end
[66] #54 [0x00000017]        JUMP 0                            ; -- goto [67]
::65::, ::66::
[67] #55 [0x0002121E]        JUMPIFNOTEQ 18, 2 [18]            ; if var18 ~= var18 then goto [70] end
[69] #56 [0x00000017]        JUMP 0                            ; -- goto [70]
::67::, ::69::
[70] #57 [0x0002121B]        JUMPIFEQ 18, 2 [18]               ; if var18 == var18 then goto [73] end
[72] #58 [0x00000017]        JUMP 0                            ; -- goto [73]
::70::, ::72::
[73] #59 [0x00001302]        LOADNIL 19                        ; var19 = nil
[74] #60 [0x0003121F]        JUMPIFNOTLE 18, 3 [18]            ; if var18 > var18 then goto [78] end
[76] #61 [0x00091305]        LOADK 19, 9                       ; var19 = "hello "
[77] #62 [0x00000017]        JUMP 0                            ; -- goto [78]
::74::, ::77::
[78] #63 [0x00021220]        JUMPIFNOTLT 18, 2 [18]            ; if var18 >= var18 then goto [81] end
[80] #64 [0x00000017]        JUMP 0                            ; -- goto [81]
::78::, ::80::
[81] #65 [0x0002121C]        JUMPIFLE 18, 2 [18]               ; if var18 <= var18 then goto [84] end
[83] #66 [0x00000017]        JUMP 0                            ; -- goto [84]
::81::, ::83::
[84] #67 [0x0002121D]        JUMPIFLT 18, 2 [18]               ; if var18 < var18 then goto [87] end
[86] #68 [0x00000017]        JUMP 0                            ; -- goto [87]
::84::, ::86::
[87] #69 [0x0001124F]        JUMPXEQKN 18, 1 [0x8000000A]      ; if var18 ~= 1 then goto [89] end
::87::
[89] #70 [0x00011250]        JUMPXEQKS 18, 1 [0x8000000B]      ; if var18 ~= "hello" then goto [91] end
::89::
[91] #71 [0x0001124E]        JUMPXEQKB 18, 1 [0x80000001]      ; if var18 ~= true then goto [93] end
::91::
[93] #72 [0x0001124E]        JUMPXEQKB 18, 1 [0x80000000]      ; if var18 ~= false then goto [95] end
::93::
[95] #73 [0x0001124D]        JUMPXEQKNIL 18, 1 [0x80000000]    ; if var18 ~= nil then goto [97] end
::95::
[97] #74 [0x0001124F]        JUMPXEQKN 18, 1 [0x0000000A]      ; if var18 == 1 then goto [99] end
::97::
[99] #75 [0x00011250]        JUMPXEQKS 18, 1 [0x0000000B]      ; if var18 == "hello" then goto [101] end
::99::
[101] #76 [0x0001124E]       JUMPXEQKB 18, 1 [0x00000001]      ; if var18 == true then goto [103] end
::101::
[103] #77 [0x0001124E]       JUMPXEQKB 18, 1 [0x00000000]      ; if var18 == false then goto [105] end
::103::
[105] #78 [0x0001124D]       JUMPXEQKNIL 18, 1 [0x80000000]    ; if var18 ~= nil then goto [107] end
::105::
[107] #79 [0x00121432]       NOT 20, 18                        ; var20 = not var18
[108] #80 [0x00121533]       MINUS 21, 18                      ; var21 = -var18
[109] #81 [0x00131706]       MOVE 23, 19                       ; var23 = var19
[110] #82 [0x000C1805]       LOADK 24, 12                      ; var24 = "world"
[111] #83 [0x18171631]       CONCAT 22, 23, 24                 ; var22 = var23..var24
[112] #84 [0x0002121B]       JUMPIFEQ 18, 2 [18]               ; if var18 == var18 then goto [115] end
[114] #85 [0x01001703]       LOADB 23, 0, 1                    ; var23 = false -- goto [116]
::112::
[115] #86 [0x00011703]       LOADB 23, 1, 0                    ; var23 = true
::114::
[116] #87 [0x0A12182F]       ANDK 24, 18, 10                   ; var24 = var18 and 1
[117] #88 [0x0A121930]       ORK 25, 18, 10                    ; var25 = var18 or 1
[118] #89 [0x12121A2D]       AND 26, 18, 18                    ; var26 = var18 and var18
[119] #90 [0x12121B2E]       OR 27, 18, 18                     ; var27 = var18 or var18
[120] #91 [0x0A121227]       ADDK 18, 18, 10                   ; var18 += 1
[121] #92 [0x12121221]       ADD 18, 18, 18                    ; var18 += var18
[122] #93 [0x0A121228]       SUBK 18, 18, 10                   ; var18 -= 1
[123] #94 [0x120A1247]       SUBRK 18, 10, 18                  ; var18 = 1 - var18
[124] #95 [0x12121222]       SUB 18, 18, 18                    ; var18 -= var18
[125] #96 [0x0A121229]       MULK 18, 18, 10                   ; var18 *= 1
[126] #97 [0x12121223]       MUL 18, 18, 18                    ; var18 *= var18
[127] #98 [0x0A12122A]       DIVK 18, 18, 10                   ; var18 /= 1
[128] #99 [0x120A1248]       DIVRK 18, 10, 18                  ; var18 = 1 // var18
[129] #100 [0x12121224]      DIV 18, 18, 18                    ; var18 /= var18
[130] #101 [0x0A121252]      IDIVK 18, 18, 10                  ; var18 //= 1
[131] #102 [0x12121251]      IDIV 18, 18, 18                   ; var18 //= var18
[132] #103 [0x0A12122C]      POWK 18, 18, 10                   ; var18 ^= 1
[133] #104 [0x12121226]      POW 18, 18, 18                    ; var18 ^= var18
[134] #105 [0x0A12122B]      MODK 18, 18, 10                   ; var18 %= 1
[135] #106 [0x12121225]      MOD 18, 18, 18                    ; var18 %= var18
[136] #107 [0x00021C3F]      GETVARARGS 28, 2                  ; var28 = ... -- Load 1 variable
[137] #108 [0x03120C49]      FASTCALL1 12, 18, 3               ; ... = math.floor(var18) -- Uses results from call at [141]. If successful, goto [142]
[138] #109 [0x00121E06]      MOVE 30, 18                       ; var30 = var18
[139] #110 [0x000F1D0C]      GETIMPORT 29, 15 [0x80D03800]     ; var29 = math.floor
[141] #111 [0x02021D15]      CALL 29, 2, 2                     ; var29 = var29(var30)
::137::
[142] #112 [0x05120C4A]      FASTCALL2 12, 18, 5               ; ... = math.floor(var18, var18) -- Uses results from call at [148]. If successful, goto [149]
[144] #113 [0x00121F06]      MOVE 31, 18                       ; var31 = var18
[145] #114 [0x00122006]      MOVE 32, 18                       ; var32 = var18
[146] #115 [0x000F1E0C]      GETIMPORT 30, 15 [0x80D03800]     ; var30 = math.floor
[148] #116 [0x02031E15]      CALL 30, 3, 2                     ; var30 = var30(var31, var32)
::143::
[149] #117 [0x05120C4B]      FASTCALL2K 12, 18, 5 [10]         ; ... = math.floor(var18, 1) -- Uses results from call at [155]. If successful, goto [156]
[151] #118 [0x00122006]      MOVE 32, 18                       ; var32 = var18
[152] #119 [0x000A2105]      LOADK 33, 10                      ; var33 = 1
[153] #120 [0x000F1F0C]      GETIMPORT 31, 15 [0x80D03800]     ; var31 = math.floor
[155] #121 [0x02031F15]      CALL 31, 3, 2                     ; var31 = var31(var32, var33)
::150::
[156] #122 [0x00012204]      LOADN 34, 1                       ; var34 = 1
[157] #123 [0x00022304]      LOADN 35, 2                       ; var35 = 2
[158] #124 [0x04120C3C]      FASTCALL3 12, 18, 4               ; ... = math.floor(var18, var34, var35) -- Uses results from call at [163]. If successful, goto [164]
[160] #125 [0x00122106]      MOVE 33, 18                       ; var33 = var18
[161] #126 [0x000F200C]      GETIMPORT 32, 15 [0x80D03800]     ; var32 = math.floor
[163] #127 [0x02042015]      CALL 32, 4, 2                     ; var32 = var32(var33, var34, var35)
::159::
[164] #128 [0x00122206]      MOVE 34, 18                       ; var34 = var18
[165] #129 [0x00012304]      LOADN 35, 1                       ; var35 = 1
[166] #130 [0x00022404]      LOADN 36, 2                       ; var36 = 2
[167] #131 [0x00032504]      LOADN 37, 3                       ; var37 = 3
[168] #132 [0x00042604]      LOADN 38, 4                       ; var38 = 4
[169] #133 [0x00052704]      LOADN 39, 5                       ; var39 = 5
[170] #134 [0x02000C44]      FASTCALL 12, 2                    ; ... = math.floor(...) -- Uses args and results from call at [173]. If successful, goto [174]
[171] #135 [0x000F210C]      GETIMPORT 33, 15 [0x80D03800]     ; var33 = math.floor
[173] #136 [0x02072115]      CALL 33, 7, 2                     ; var33 = var33(var34, var35, var36, var37, var38, var39)
::170::
[174] #137 [0xFF8F0F39]      FORNLOOP 15, -113                 ; var17 += var16; if var17 <= var15 then goto [62] end
::61::
[175] #138 [0x00000F35]      NEWTABLE 15, 0 [0]                ; var15 = {}
[177] #139 [0x00001002]      LOADNIL 16                        ; var16 = nil
[178] #140 [0x00001102]      LOADNIL 17                        ; var17 = nil
[179] #141 [0x00000F4C]      FORGPREP 15, 0                    ; for var18->... in var15, var16, var17 do -- If loop shouldn't start then goto [180]
::179::, ::180::
[180] #142 [0xFFFF0F3A]      FORGLOOP 15, -1 [0x00000002]      ; var18, var19 = var15(var16, var17); if var18 ~= nil then goto [180]
[182] #143 [0x00110F0C]      GETIMPORT 15, 17 [0x41000000]     ; var15 = ipairs
[184] #144 [0x00001035]      NEWTABLE 16, 0 [0]                ; var16 = {}
[186] #145 [0x04020F15]      CALL 15, 2, 4                     ; var15, var16, var17 = var15(var16)
[187] #146 [0x00000F3B]      FORGPREP_INEXT 15, 0              ; for var18->... in var15, var16, var17 do -- If loop shouldn't start then goto [188]
::187::, ::188::
[188] #147 [0xFFFF0F3A]      FORGLOOP 15, -1 [0x80000002]      ; var18, var19 = var15(var16, var17); if var18 ~= nil then goto [188]
[190] #148 [0x00130F0C]      GETIMPORT 15, 19 [0x41200000]     ; var15 = next
[192] #149 [0x00001035]      NEWTABLE 16, 0 [0]                ; var16 = {}
[194] #150 [0x00001102]      LOADNIL 17                        ; var17 = nil
[195] #151 [0x00000F3D]      FORGPREP_NEXT 15, 0               ; for var18->... in var15, var16, var17 do -- If loop shouldn't start then goto [196]
::195::, ::196::
[196] #152 [0xFFFF0F3A]      FORGLOOP 15, -1 [0x00000002]      ; var18, var19 = var15(var16, var17); if var18 ~= nil then goto [196]
[198] #153 [0x00011104]      LOADN 17, 1                       ; var17 = 1
[199] #154 [0x00230F04]      LOADN 15, 35                      ; var15 = 35
[200] #155 [0x00011004]      LOADN 16, 1                       ; var16 = 1
[201] #156 [0x00060F38]      FORNPREP 15, 6                    ; for var17 = var17, var15, var16 do -- If loop shouldn't start (var17 > var15) then goto [208]
::207::
[202] #157 [0x00111206]      MOVE 18, 17                       ; var18 = var17
[203] #158 [0x0004121A]      JUMPIFNOT 18, 4                   ; if not var18 then goto [208] end
[204] #159 [0x0A12122B]      MODK 18, 18, 10                   ; var18 %= 1
[205] #160 [0x00020017]      JUMP 2                            ; -- goto [208]
[206] #161 [0x00010017]      JUMP 1                            ; -- goto [208]
[207] #162 [0xFFFA0F39]      FORNLOOP 15, -6                   ; var17 += var16; if var17 <= var15 then goto [202] end
::201::, ::203::, ::205::, ::206::
[208] #163 [0x00150F0C]      GETIMPORT 15, 21 [0x41400000]     ; var15 = print
[210] #164 [0x00161005]      LOADK 16, 22                      ; var16 = "PASSED"
[211] #165 [0x01020F15]      CALL 15, 2, 1                     ; var15(var16)
[212] #166 [0x0000000B]      CLOSEUPVALS 0                     ; move_upvalues_to_heap(var0->...)
[213] #167 [0x00010016]      RETURN 0, 1                       ; return

Decompiled:

-- Decompiled with Nemo BETA
-- Unknown instruction: PREPVARARGS
local v1 = "hello world"
local v1 = nil
local v1 = true
local v1 = false
local v1 = 1
local v1 = 9000000000
function func1 ()
end
local v1 = func1
local v2 = newproxy
FUNC_GLOBAL = v2
-- Unknown instruction: NEWTABLE
function stub ()
	-- Unknown instruction: PREPVARARGS
	local v1 = FUNC_GLOBAL
	local v1 = v1()
	-- Unknown instruction: GETUPVAL
	-- Unknown instruction: SETTABLEKS
	-- Unknown instruction: SETTABLEN
	-- Unknown instruction: SETTABLE
	-- Unknown instruction: GETTABLE
	-- Unknown instruction: SETUPVAL
	-- Unknown instruction: GETTABLEKS
	-- Unknown instruction: GETTABLEN
	-- Unknown instruction: GETTABLE
	return
end
local v3 = stub
-- Unknown instruction: CAPTURE
-- Unknown instruction: CAPTURE
local v4 = v3
local v4 = v4()
function upv ()
	local function foo ()
		-- Unknown instruction: GETUPVAL
		return
	end
	local v1 = foo
	-- Unknown instruction: CAPTURE
	-- ABSOLUTE Unknown! Raw: ::5::
	local v2 = FALSE_GLOBAL
	-- Unknown instruction: JUMPIFNOT
	-- Unknown instruction: JUMPBACK
	-- ABSOLUTE Unknown! Raw: ::4::
	local v2 = v1
	local v2 = v2()
	local v3 = FUNC_GLOBAL
	local v3 = v3()
	return
end
local v5 = upv
-- Unknown instruction: CAPTURE
-- Unknown instruction: DUPTABLE
-- Unknown instruction: SETTABLEKS
-- Unknown instruction: LENGTH
local v6 = v5
local v6 = v6()
local v5 = v6
-- Unknown instruction: NEWTABLE
local v7 = v5
local v8 = v5
local v8 = v8()
-- Unknown instruction: NAMECALL
-- error:ReplicatedStorage.Nemo:582: invalid argument #2 to 'format' (string expected, got nil) raw: [35] #27 [0x00000B15]        CALL 11, 0, 0                     ; var11->(top) = var11(var12->(top))
local v7 = v7()
-- Unknown instruction: SETLIST
-- Unknown instruction: NEWTABLE
function dup ()
	local function func2 ()
	end
	local v1 = func2
	return
end
local v9 = dup
local v10 = v9
local v10 = v10()
local v11 = v10
local v10 = v9
local v10 = v10()
local v8 = v10
local v12 = v9
local v12 = v12()
-- Unknown instruction: NEWTABLE
local v13 = v11
local v14 = v8
local v15 = v12
-- Unknown instruction: SETLIST
local v7 = v10
local v14 = 1
local v10 = 35
local v13 = 1
-- Unknown instruction: FORNPREP
-- ABSOLUTE Unknown! Raw: ::174::
local v15 = v14
-- Unknown instruction: JUMPIFNOT
-- Unknown instruction: JUMP
-- ABSOLUTE Unknown! Raw: ::63::, ::64::
-- Unknown instruction: JUMPIF
-- Unknown instruction: JUMP
-- ABSOLUTE Unknown! Raw: ::65::, ::66::
-- Unknown instruction: JUMPIFNOTEQ
-- Unknown instruction: JUMP
-- ABSOLUTE Unknown! Raw: ::67::, ::69::
-- Unknown instruction: JUMPIFEQ
-- Unknown instruction: JUMP
-- ABSOLUTE Unknown! Raw: ::70::, ::72::
local v16 = nil
-- Unknown instruction: JUMPIFNOTLE
local v16 = "hello "
-- Unknown instruction: JUMP
-- ABSOLUTE Unknown! Raw: ::74::, ::77::
-- Unknown instruction: JUMPIFNOTLT
-- Unknown instruction: JUMP
-- ABSOLUTE Unknown! Raw: ::78::, ::80::
-- Unknown instruction: JUMPIFLE
-- Unknown instruction: JUMP
-- ABSOLUTE Unknown! Raw: ::81::, ::83::
-- Unknown instruction: JUMPIFLT
-- Unknown instruction: JUMP
-- ABSOLUTE Unknown! Raw: ::84::, ::86::
-- Unknown instruction: JUMPXEQKN
-- ABSOLUTE Unknown! Raw: ::87::
-- Unknown instruction: JUMPXEQKS
-- ABSOLUTE Unknown! Raw: ::89::
-- Unknown instruction: JUMPXEQKB
-- ABSOLUTE Unknown! Raw: ::91::
-- Unknown instruction: JUMPXEQKB
-- ABSOLUTE Unknown! Raw: ::93::
-- Unknown instruction: JUMPXEQKNIL
-- ABSOLUTE Unknown! Raw: ::95::
-- Unknown instruction: JUMPXEQKN
-- ABSOLUTE Unknown! Raw: ::97::
-- Unknown instruction: JUMPXEQKS
-- ABSOLUTE Unknown! Raw: ::99::
-- Unknown instruction: JUMPXEQKB
-- ABSOLUTE Unknown! Raw: ::101::
-- Unknown instruction: JUMPXEQKB
-- ABSOLUTE Unknown! Raw: ::103::
-- Unknown instruction: JUMPXEQKNIL
-- ABSOLUTE Unknown! Raw: ::105::
-- Unknown instruction: NOT
-- Unknown instruction: MINUS
local v17 = v16
local v18 = "world"
-- Unknown instruction: CONCAT
-- Unknown instruction: JUMPIFEQ
local v17 = false -- goto [116]
-- ABSOLUTE Unknown! Raw: ::112::
local v17 = true
-- ABSOLUTE Unknown! Raw: ::114::
-- Unknown instruction: ANDK
-- Unknown instruction: ORK
-- Unknown instruction: AND
-- Unknown instruction: OR
-- Unknown instruction: ADDK
-- Unknown instruction: ADD
-- Unknown instruction: SUBK
-- Unknown instruction: SUBRK
-- Unknown instruction: SUB
-- Unknown instruction: MULK
-- Unknown instruction: MUL
-- Unknown instruction: DIVK
-- Unknown instruction: DIVRK
-- Unknown instruction: DIV
-- Unknown instruction: IDIVK
-- Unknown instruction: IDIV
-- Unknown instruction: POWK
-- Unknown instruction: POW
-- Unknown instruction: MODK
-- Unknown instruction: MOD
-- Unknown instruction: GETVARARGS
-- Unknown instruction: FASTCALL1
local v19 = v15
local v20 = math.floor
local v20 = v20(v19)
-- ABSOLUTE Unknown! Raw: ::137::
-- Unknown instruction: FASTCALL2
local v21 = v15
local v22 = v15
local v19 = math.floor
local v19 = v19(v21)
-- ABSOLUTE Unknown! Raw: ::143::
-- Unknown instruction: FASTCALL2K
local v22 = v15
local v23 = 1
local v21 = math.floor
local v21 = v21(v22)
-- ABSOLUTE Unknown! Raw: ::150::
local v24 = 1
local v25 = 2
-- Unknown instruction: FASTCALL3
local v23 = v15
local v22 = math.floor
local v22 = v22(v23)
-- ABSOLUTE Unknown! Raw: ::159::
local v24 = v15
local v25 = 1
local v26 = 2
local v27 = 3
local v28 = 4
local v29 = 5
-- Unknown instruction: FASTCALL
local v23 = math.floor
local v23 = v23(v24)
-- ABSOLUTE Unknown! Raw: ::170::
-- Unknown instruction: FORNLOOP
-- ABSOLUTE Unknown! Raw: ::61::
-- Unknown instruction: NEWTABLE
local v13 = nil
local v14 = nil
-- Unknown instruction: FORGPREP
-- ABSOLUTE Unknown! Raw: ::179::, ::180::
-- Unknown instruction: FORGLOOP
local v10 = ipairs
-- Unknown instruction: NEWTABLE
local v10 = v10(v13)
-- Unknown instruction: FORGPREP
-- ABSOLUTE Unknown! Raw: ::187::, ::188::
-- Unknown instruction: FORGLOOP
local v10 = next
-- Unknown instruction: NEWTABLE
local v14 = nil
-- Unknown instruction: FORGPREP
-- ABSOLUTE Unknown! Raw: ::195::, ::196::
-- Unknown instruction: FORGLOOP
local v14 = 1
local v10 = 35
local v13 = 1
-- Unknown instruction: FORNPREP
-- ABSOLUTE Unknown! Raw: ::207::
local v15 = v14
-- Unknown instruction: JUMPIFNOT
-- Unknown instruction: MODK
-- Unknown instruction: JUMP
-- Unknown instruction: JUMP
-- Unknown instruction: FORNLOOP
-- ABSOLUTE Unknown! Raw: ::201::, ::203::, ::205::, ::206::
local v10 = print
local v13 = "PASSED"
v10(v13)
-- Unknown instruction: CLOSEUPVALS
return
