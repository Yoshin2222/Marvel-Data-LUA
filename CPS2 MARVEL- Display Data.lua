--Initialise Variables/Addresses
--Massive thanks to Jesuszilla for the tips/rewrite
local int textx = 2
local int textx2 = 290
local int textx3 = 130
local int texty = 10
local timepassed = 0

local sw = emu.screenwidth()
local sh = emu.screenheight()
local rom = emu.romname()
	--Memory Macros
rb = memory.readbyte
rw = memory.readword
rd = memory.readdword
wb = memory.writebyte
ww = memory.writeword
wd = memory.writedword
	--SIGNED VALUES
rbs = memory.readbytesigned
rws = memory.readwordsigned
rds = memory.readdwordsigned
wbs = memory.writebytesigned
wws = memory.writewordsigned
wds = memory.writedwordsigned

local int text = {
x = 2,
x2 = 40,
x3 = 290,
y = 10,
}

local games = {
--Name, Timer, charselct timer, P1 UID, P2 UID,Number of Players, Match Active(UNUSED ATM)
	["Invalid"] = {}, -- null case
--	xmcota = {"xmcota",0x0FF4808,0x0FF480A,0xFF4000,0xFF4400,2},
--	xmvsf  = {"xmvsf" ,0x0FF5008,0x0FF480A,0xFF4000,0xFF4400,4},
--	mvsc   = {"mvsc"  ,0x0FF4008,0x0FF416E,0xFF3000,0xFF3400,4},
	["xmcota"]    = {"xmcota"	,0x0FF4808,0x0FF480A,0xFF4000,0xFF4400,2},
    ["xmvsf"]     = {"xmvsf" 	,0x0FF5008,0x0FF480A,0xFF4000,0xFF4400,2},
    ["mvsc"]  	  = {"mvsc"  	,0x0FF4008,0x0FF416E,0xFF3000,0xFF3400,4},
    ["msh"]   	  = {"msh"      ,0x0FF4808,0x0FF491E,0xFF4000,0xFF4400,2,0xFF8FA2},
    ["mshvsf"]    = {"mshvsf"   ,0x0FF4808,0x0FF495E,0xFF3800,0xFF3C00,4,0xFF8FA2},
}

local View_Mode = {
	CPS3,
	Mugen,
}
local Current_Mode = 2 --Default, 1= CPS3, 2 = Mugen

--ADDRESSES

local Player_UID = {
P1 = 0,
P2 = 0,
}

local UID_Data = {
	visible  = 0x01,
	player_ctrl = 0x02,
	facing   = 0x03,
	pos_X   = 12,
	pos_X_subpixel = 14,
	pos_Y   = 16,
	pos_Y_subpixel = 18,	
	vel_X   = 20,
	vel_X_Subvel   = 22,
	accel_X   = 24,
	vel_Y   = 28,
	subvel_Y   = 30,
	accel_Y = 32,
	Anim_Pointer = 52,
	char_id = 80,
	animelemtime = 63, --BYTE
	Sprite_Header = 65,
	P2_Ptr 		  = 140,
}
local Current_Player = 0 --0 = P1, 1= P2
local infinite_time = 1
local pressing_C = 0 -- Infinite time button
local pressing_V = 0 -- Mode Toggle
local pressing_P = 0 -- Toggle Players + 1
local pressing_O = 0 -- Toggle Players - 1
local Time_Frozen
local PlayerZ = {}

-- Used in conversion function 
	local Division_Type = {
		B = 256.0,			--BYTE
		b = 256.0,			--BYTE
		W = 65536,			--WORD
		w = 65536,			--WORD		
		D = 4294967296.0, 	--DWORD
		d = 4294967296.0, 	--DWORD		
	}
	
	----------------------------------------------
-- ROM NAME
----------------------------------------------
--current_game = ""
--for i, v in pairs(games) do
--	for _, k in ipairs(v) do
--		if (rom == k) then
--			current_game = v
--			--Chuck table data to local vars to be used later
--local  timer_address = current_game[2]
--local charselect_timer_address = current_game[3]
--Player_UID.P1 = current_game[4]
--Player_UID.P2 = current_game[5]
--local Num_Players = current_game[6]
--local Space = Player_UID.P2 - Player_UID.P1
--		end
--	end
--end
local valid_player_no = 2

	current_game = ""
	current_game = games[rom]
	local timer_address = current_game[2]
	local charselect_timer_address = current_game[3]
	Player_UID.P1 = current_game[4]
	Player_UID.P2 = current_game[5]
	local Num_Players = current_game[6]
	local Space = Player_UID.P2 - Player_UID.P1
	local match_state = current_game[7]


	match_active = function()
		return rd(current_game[7]) == Player_UID.P1
	end

match_active()
	
--Useful Maths functions for converting floating points
	function Subpixel_Floatconvert(c,x)
	local Output
	if x == 0 then
		return 0--x = x
	else
		Output = math.abs(x)/ c
		return Output + .0--absx + .0
		end
	end

--Weirdly it's documented as an inherent function but it isn't. FBNeo is weird i guess	
	function math.sign(x)
	if x<0 then
		return -1
		elseif x>0 then
			return 1
		else
			return 0
		end
	end
	
	--X = Velocity, Y = Subpixel to be converted to Floating Point
	--Z = Container for current velocity direction
	function OutputFloat(x,y,axis)
			return x + y -- (math.abs(x) + y) * math.sign(x)
--		if axis == 1 then --If X Axis
--			return x + y -- (math.abs(x) + y) * math.sign(x)
--		else			  --If Y Axis
--			return (math.abs(x) + y) * math.sign(x)
--		end
	end
	
	function define_file_index(x)
	local Index = x
		if x == 0 then
			return 0
		else
			Index = math.floor(x / 0x80000)
			return Index + 3
		end
	end
	
	function define_file_offset(x)
	local Index
	local Offset	
		if x == 0 then
			return
		else
			Index  = math.floor(x / 0x80000)
			Offset = x - (0x80000 * Index)
			return Offset
		end
	end

	function Freeze_Timer(parse_input)
	if infinite_time == 0 then
		return false
	else
		wb(timer_address, 0x99)
		wb(charselect_timer_address, 0x99)
		end
	end
	
	function update_info()
	match_active()
	for i = 0,Num_Players-1,1 do
--		gui.clearuncommitted()
	--DISPLAY MUGEN DAYA
	PlayerZ[i] = { 
	Current_X_Vel 			  = rws(Player_UID.P1 + (Space * i) +  UID_Data.vel_X),
	Current_X_Vel_Subvel 	  = rw(Player_UID.P1 + (Space * i) +  UID_Data.vel_X_Subvel),
	Current_Y_Vel 			  = rws(Player_UID.P1 + (Space * i) +  UID_Data.vel_Y),
	Current_Y_SubVel 		  = rw(Player_UID.P1  + (Space * i) +  UID_Data.subvel_Y)	,
	Current_X_Accel 		  = rds(Player_UID.P1 + (Space * i) +  UID_Data.accel_X),
	Current_Y_Accel 		  = rds(Player_UID.P1 + (Space * i) +  UID_Data.accel_Y),
	Current_X_Pos 			  = rws(Player_UID.P1  + (Space * i) +  UID_Data.pos_X),
	Current_pos_X_subpixel 	  = rw(Player_UID.P1  + (Space * i) +  UID_Data.pos_X_subpixel),
	Current_Y_Pos 		 	  = rws(Player_UID.P1  + (Space * i) +  UID_Data.pos_Y),
	Current_pos_Y_subpixel 	  = rw(Player_UID.P1  + (Space * i) +  UID_Data.pos_Y_subpixel),
	Current_Animelemtime 	  = rb(Player_UID.P1  + (Space * i) +  UID_Data.animelemtime),
	Current_Anim_Ptr 		  = rd(Player_UID.P1  + (Space * i) +  UID_Data.Anim_Pointer),
	
--	Current_Animelem_Ptr 	  = rd(Player_UID.P1  + (Space * i) +  UID_Data.Animelem_Pointer),
--	Current_Sprite_Header_Ptr = rd(Player_UID.P1  + (Space * i) +  UID_Data.Sprite_Header),
	Current_Sprite_Header_Ptr = rb(Player_UID.P1  + (Space * i) +  UID_Data.Sprite_Header)* 0x10000 + rw(Player_UID.P1  + (Space * i) +  UID_Data.Sprite_Header+1),
	}
	
	PlayerZ[i].Current_pos_X_subpixel = Subpixel_Floatconvert(Division_Type.W,PlayerZ[i].Current_pos_X_subpixel)
	PlayerZ[i].Current_X_Vel_Subvel   = Subpixel_Floatconvert(Division_Type.W,PlayerZ[i].Current_X_Vel_Subvel)			
	PlayerZ[i].Current_X_Accel 		  = Subpixel_Floatconvert(Division_Type.W,PlayerZ[i].Current_X_Accel)
	PlayerZ[i].Current_pos_Y_subpixel = Subpixel_Floatconvert(Division_Type.W,PlayerZ[i].Current_pos_Y_subpixel)
	PlayerZ[i].Current_Y_SubVel 	  = Subpixel_Floatconvert(Division_Type.W,PlayerZ[i].Current_Y_SubVel)
	PlayerZ[i].Current_Y_Accel 		  = Subpixel_Floatconvert(Division_Type.W,PlayerZ[i].Current_Y_Accel)

	PlayerZ[i].Current_Anim_Ptr_index    = define_file_index(PlayerZ[i].Current_Anim_Ptr)
	PlayerZ[i].Current_Anim_Ptr_offset   = define_file_offset(PlayerZ[i].Current_Anim_Ptr)
	PlayerZ[i].Current_Sprite_Header_Ptr_index    = define_file_index(PlayerZ[i].Current_Sprite_Header_Ptr)
	PlayerZ[i].Current_Sprite_Header_Ptr_offset   = define_file_offset(PlayerZ[i].Current_Sprite_Header_Ptr)	
		end	
	end

function render_text1()
		--` INFINITE TIME
	gui.text(text.x+140,text.y*20, "C - Infinite Time = ".. infinite_time)
	--` TOGGLE PLAYER
	gui.text(text.x+140,text.y*21, "P - Toggle Current Player")	
	end
	
function render_text2()
	if match_active == false then
		--` INFINITE TIME
	gui.text(text.x+140,text.y*20, "C - Infinite Time = ".. infinite_time)
	--` TOGGLE PLAYER
	gui.text(text.x+140,text.y*21, "O/P - Toggle Current Player")	
	else
		--` INFINITE TIME
	gui.text(text.x+140,text.y*20, "C - Infinite Time = ".. infinite_time)
	--` TOGGLE PLAYER
	gui.text(text.x+140,text.y*21, "O/P - Toggle Current Player")	
	
	--` Current Player
	gui.text(0,0, "Player ".. Current_Player+1)	
--	gui.text(44,0, "".. rom)	
	gui.text(44,0, "".. current_game[1])
 --	POS X
--	gui.text(text.x,text.y, "Pos X =")
--	gui.text(text.x2,text.y, string.format("%d", PlayerZ[Current_Player].Current_X_Pos))	
--	gui.text(text.x,text.y, string.format("Pos X = %f", OutputFloat(PlayerZ[Current_Player].Current_X_Pos,PlayerZ[Current_Player].Current_pos_X_subpixel,1)))
	if PlayerZ[Current_Player].Current_X_Pos == 0 then
	gui.text(text.x,text.y, "Pos X = 0.0")
	else
	gui.text(text.x,text.y, string.format("Pos X = %f", OutputFloat(PlayerZ[Current_Player].Current_X_Pos,PlayerZ[Current_Player].Current_pos_X_subpixel,1)))
	end
--	VEL X
--	gui.text(text.x2+30,text.y, "Vel X =")
--	gui.text(text.x2+52,text.y, string.format("Vel X = %f", PlayerZ[Current_Player].Current_X_Vel))
--	gui.text(text.x2+52,text.y, string.format("Vel X = %f", OutputFloat(PlayerZ[Current_Player].Current_X_Vel,PlayerZ[Current_Player].Current_X_Vel_Subvel,1)))
	if PlayerZ[Current_Player].Current_X_Vel == 0 then
	gui.text(text.x2+52,text.y, "Vel X = 0.0")
	else
	gui.text(text.x2+52,text.y, string.format("Vel X = %f", OutputFloat(PlayerZ[Current_Player].Current_X_Vel,PlayerZ[Current_Player].Current_X_Vel_Subvel,1)))
	end
--	ACCEL X
--	gui.text(text.x2+168,text.y*2,"Accel Y =")
--	gui.text(text.x2+142,text.y, string.format("Accel X = %f", PlayerZ[Current_Player].Current_X_Accel))
	if PlayerZ[Current_Player].Current_X_Accel == 0 then
	gui.text(text.x2+142,text.y, "Accel X = 0.0")
	else
	gui.text(text.x2+142,text.y, string.format("Accel X = %f", PlayerZ[Current_Player].Current_X_Accel))
	end
--	POS Y
--	gui.text(text.x,text.y*2,"Pos Y =")
--	gui.text(text.x2,text.y*2, string.format("%d", PlayerZ[Current_Player].Current_Y_Pos))
--	gui.text(text.x,text.y*2, string.format("Pos Y = %f", OutputFloat(PlayerZ[Current_Player].Current_Y_Pos,PlayerZ[Current_Player].Current_pos_Y_subpixel,2)))
	if PlayerZ[Current_Player].Current_Y_Pos == 0 then
	gui.text(text.x,text.y*2, "Pos Y = 0.0")
	else
	gui.text(text.x,text.y*2, string.format("Pos Y = %f", OutputFloat(PlayerZ[Current_Player].Current_Y_Pos,PlayerZ[Current_Player].Current_pos_Y_subpixel,2)))
	end
--	VEL Y
--	gui.text(text.x2+60,text.y*2,"Vel Y =")
--	gui.text(text.x2+52,text.y*2, string.format("Vel Y = %f", OutputFloat(PlayerZ[Current_Player].Current_Y_Vel,PlayerZ[Current_Player].Current_Y_SubVel,2)))
	if PlayerZ[Current_Player].Current_Y_Vel == 0 then
	gui.text(text.x2+52,text.y*2, "Vel Y = 0.0")
	else
	gui.text(text.x2+52,text.y*2, string.format("Vel Y = %f", OutputFloat(PlayerZ[Current_Player].Current_Y_Vel,PlayerZ[Current_Player].Current_Y_SubVel,2)))
	end
--	ACCEL Y
--	gui.text(text.x2+168,text.y*2,"Accel Y =")
--	gui.text(text.x2+142,text.y*2, string.format("Accel Y = %f", PlayerZ[Current_Player].Current_Y_Accel))
	if PlayerZ[Current_Player].Current_Y_Accel == 0 then
	gui.text(text.x2+142,text.y*2,"Accel Y = 0.0")
	else
	gui.text(text.x2+142,text.y*2, string.format("Accel Y = %f", PlayerZ[Current_Player].Current_Y_Accel))
	end
--	ANIM POINTER
	gui.text(text.x,text.y*3, "Anim Ptr =")
	if PlayerZ[Current_Player].Current_Anim_Ptr == 0 then
	gui.text(text.x2+10,text.y*3,"0x000000")
	else
	gui.text(text.x2+10,text.y*3, string.format("0x%x", PlayerZ[Current_Player].Current_Anim_Ptr))
	end
-- FILE INFO
--INDEX
	if PlayerZ[Current_Player].Current_Anim_Ptr_index == 0 then
	gui.text(text.x2+50,text.y*3,"0x00")
	else
	gui.text(text.x2+50,text.y*3, string.format("File = %d", PlayerZ[Current_Player].Current_Anim_Ptr_index))	
	end
--OFFSET	
	if PlayerZ[Current_Player].Current_Anim_Ptr_offset == 0 then
	gui.text(text.x2+90,text.y*3,"0x000000")
	else
	gui.text(text.x2+90,text.y*3, string.format("Offset = 0x%x", PlayerZ[Current_Player].Current_Anim_Ptr_offset))		
	end
--ANIMELEMTIME	
	if PlayerZ[Current_Player].Current_Animelemtime == 0 then
	gui.text(text.x2+160,text.y*3,"0x00")
	else
	gui.text(text.x2+160,text.y*3, string.format("Animelemtime = 0x%x", PlayerZ[Current_Player].Current_Animelemtime))		
	end	
	
--	SPRITE HEADER POINTER
	gui.text(text.x,text.y*4, "Sprite Header Ptr =")
	if PlayerZ[Current_Player].Current_Sprite_Header_Ptr == 0 then
	gui.text(text.x2+40,text.y*4,"0x00000000")
	else
	gui.text(text.x2+40,text.y*4, string.format("0x%x", PlayerZ[Current_Player].Current_Sprite_Header_Ptr))
	end
-- FILE INFO
	if PlayerZ[Current_Player].Current_Sprite_Header_Ptr_index == 0 then
	gui.text(text.x2+80,text.y*4,"0x00000000")
	else
	gui.text(text.x2+80,text.y*4, string.format("File = %d", PlayerZ[Current_Player].Current_Sprite_Header_Ptr_index))	
	end
	if PlayerZ[Current_Player].Current_Sprite_Header_Ptr_offset == 0 then
	gui.text(text.x2+120,text.y*4,"0x00000000")
	else
	gui.text(text.x2+120,text.y*4, string.format("Offset = 0x%x", PlayerZ[Current_Player].Current_Sprite_Header_Ptr_offset))
		end	
	end
end

	function parse_input()
	local keys = input.get()
	
			--Infinite Time Toggle
	if keys.C and pressing_C == 0 then
		if infinite_time == 1 then
			infinite_time = 0
			pressing_C = 1
		else
			infinite_time = 1
			pressing_C = 1
	end
end
	
	if pressing_C == 1 and not keys.C then
			pressing_C = 0
	end

	--Toggle Cuurent Player +1
	if pressing_P == 0 and keys.P then
		if Current_Player == Num_Players-1 then
			Current_Player = 0
			pressing_P = 1
		else
			Current_Player = Current_Player + 1
			pressing_P = 1
		end
	end
	
	if pressing_P == 1 and not keys.P then
			pressing_P = 0
	end	

	--Toggle Cuurent Player -1
	if pressing_O == 0 and keys.O then
		if Current_Player == 0 then
			Current_Player = Num_Players - 1
			pressing_O = 1
		else
			Current_Player = Current_Player - 1
			pressing_O = 1
		end
	end
	
	if pressing_O == 1 and not keys.O then
			pressing_O = 0
	end	
end
--	emu.registerstart(function()
--	update_info()
--end)

	emu.registerstart(function()
		parse_input()
	end)
	
	gui.register(function()
		parse_input()
		Freeze_Timer()
		update_info()
		if match_active == false then
		render_text1()
		else
		render_text2()
	end
end)

emu.registerafter(function()
		update_info()
		if match_active == false then
		render_text1()
		else
		render_text2()
	end
	end)

--	emu.frameadvance()
--end
