--Initialise Variables/Addresses
--Massive thanks to Jesuszilla for the tips/rewrite
local int textx = 2
local int textx2 = 290
local int texty = 10
local sw = emu.screenwidth()
local sh = emu.screenheight()
--Input Resolution of target system here
--Exapmle: CPS2/3
--local resolution_multipier = {
--	X = 384 / sw,
--	Y = 224 / sh,
--}
--NEOGEO

local games = {
--Name, Timer, charselct timer, P1 UID, P2 UID,Number of Players, MaxTimer, Maxcharselect timer
	["Invalid"] = {}, -- null case
--	xmcota = {"xmcota",0x0FF4808,0x0FF480A,0xFF4000,0xFF4400,2},
--	xmvsf  = {"xmvsf" ,0x0FF5008,0x0FF480A,0xFF4000,0xFF4400,4},
--	mvsc   = {"mvsc"  ,0x0FF4008,0x0FF416E,0xFF3000,0xFF3400,4},
	["xmcota"]    = {"xmcota"	,0x0FF4808,0xFF4910,0xFF4000,0xFF4400,2,0x99,0x05},
    ["xmvsf"]     = {"xmvsf" 	,0x0FF5008,0x0FF480A,0xFF4000,0xFF4400,2,0x99,0x20},
    ["mvsc"]  	  = {"mvsc" 	,0x0FF4008,0x0FF416E,0xFF3000,0xFF3400,4,0x99,0x20},
    ["msh"]   	  = {"msh"      ,0x0FF4808,0x0FF491E,0xFF4000,0xFF4400,2,0x99,0x20},
    ["mshvsf"]    = {"mshvsf"   ,0x0FF4808,0x0FF495E,0xFF3800,0xFF3C00,4,0x99,0x20},
}

local res_offset = {
	X = 320 / sw,
	Y = 224 / sh,
}

-- Used in conversion function 
	local Division_Type = {
		B = 256.0,			--BYTE
		b = 256.0,			--BYTE
		W = 65536,			--WORD
		w = 65536,			--WORD		
		D = 4294967296.0, 	--DWORD
		d = 4294967296.0, 	--DWORD		
	}
--Useful Maths functions for converting floating points and data
	--X = Velocity, Y = Subpixel to be converted to Floating Point, d = Division_Type (Byte,WORD,DWORD)
	function OutputFloat(x,y,d)
			return x + Subpixel_Floatconvert(d,y)--y
	end

	function Subpixel_Floatconvert(c,x)
	local Output
	if c == 0 and x == 0 then
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
	
--	b = Number of bytes to read
--	x = memory address
-- Helps read weird 3-Byte Poitners the CPS2/NeoGeo seem to like
	function Read_3Bytes(x)
	local result = 0
	local fresult = 0
	if rb(x) == 0 then
		return 0
	else
--Loop through values
		for i = 0,2,1 do
			result = rb(x+i) * (0x100^(2-i))
			fresult = fresult + result
		end
			return fresult
		end
	end

--USED TO LOCATE LOCATIONS IN PROGRAM DATA	
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
		if x == 0 then
			return
		else
			Index  = math.floor(x / 0x80000)
			return x - (0x80000 * Index)
		end
	end

	--Memory Macros
rb = memory.readbyte
rw = memory.readword
rt = Read_3Bytes
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

local Current_Mode = 2 --Default, 1= Source, 2 = Mugen

local valid_player_no = 2


local Current_Player = 0 --0 = P1, 1= P2
local infinite_time = 1
local pressing_C = 0 -- Infinite time button
local pressing_V = 0 -- Mode Toggle
local pressing_P = 0 -- Toggle Players + 1
local pressing_O = 0 -- Toggle Players - 1

local PlayerZ = {}


while true do
--ADDRESSES (Moved down here to be persistently updated)
local rom = emu.romname()
	current_game = ""
	current_game = games[rom]
	local timer_address = current_game[2]
	local charselect_timer_address = current_game[3]
	local Pointers = {
		P1_UID = current_game[4],
		P2_UID = current_game[5],
	}
	local Num_Players = current_game[6]
	local Max = {
		timer = current_game[7],
		charselect_timer = current_game[8],
	}
local UID = {
	P1 = Pointers.P1_UID,
	P2 = Pointers.P2_UID,
--	P1 = rd(Pointers.P1_UID),
--	P2 = rd(Pointers.P2_UID),
}
--local Space = UID.P2 - UID.P1

local Data_length = {
	Players = UID.P2 - UID.P1,
}

local UID_Data = {
	Visible					= 0,--Byte
	Pos_X 					= 12, --- 0x2E WORD
	Pos_X_FloatingPoint 	= 14, --- 0x30 WORD
	Pos_Y 					= 16, --- 0x32 WORD
	Pos_Y_FloatingPoint 	= 18, --- 0x34 WORD
	Vel_X 					= 20, --- 0x3E WORD
	Vel_X_FloatingPoint 	= 22, --- 0x40 WORD
	Accel_X					= 24, -- 0x80
	Accel_Y					= 32, -- 0x94
	Vel_Y 					= 28, --- 0x42 WORD
	Vel_Y_FloatingPoint 	= 30, --- 0x44 WORD
	Accel_Y					= 32, -- 0x94
	Animelem_Pointer 		= 52, --- 0x4F 3Bytes, LOOK IN TO THIS!!! 
	Animelemtime 			= 63, --BYTE
	Sprite_Pointer 			= 65, --- 0x61, 3Bytes
	char_id = 80,
	Hitpause = 133, --Byte
	Facing = 0xB4, --Byte, 1 = Right, 0 = Left
--	Friction		  = 229, --LOOOK IN TO THIS!!!
	Health = 625, --BYTE, P1 ADR = FF3271
	Super_Gauge = 627, -- BYTE
	Super_Stock = 628 -- BYTE
}

	function validplayer()
		local address = UID.P1 + (Data_length.Players * Current_Player) --+  UID_Data.Visible
		if rw(address) == 0 or rw(address) == nil then
			return 1
		else
			return 2
		end
	end
	

gui.clearuncommitted()
	local keys = input.get()
	
	for i = 0,Num_Players-1, 1 do

--	if validplayer() == 2 then 	
		if Current_Mode == 1 then
			PlayerZ[i] = { 
				visible						= rb(UID.P1 + (Data_length.Players * i) +  UID_Data.Visible),
				Current_X_Vel 			  	= rw(UID.P1 + (Data_length.Players * i) +  UID_Data.Vel_X),
				Current_X_Vel_FloatingPoint	= rw(UID.P1 + (Data_length.Players * i) +  UID_Data.Vel_X_FloatingPoint),
				Current_Y_Vel 			  	= rw(UID.P1 + (Data_length.Players * i) +  UID_Data.Vel_Y),
				Current_Y_Vel_FloatingPoint	= rw(UID.P1 + (Data_length.Players * i) +  UID_Data.Vel_Y_FloatingPoint),
				Current_Accel_X 		  	= rd(UID.P1 + (Data_length.Players * i) +  UID_Data.Accel_X),
				Current_Accel_Y 		  	= rd(UID.P1 + (Data_length.Players * i) +  UID_Data.Accel_Y),
				Current_X_Pos 			  	= rw(UID.P1 + (Data_length.Players * i) +  UID_Data.Pos_X),
				Current_Pos_X_FloatingPoint = rw(UID.P1 + (Data_length.Players * i) +  UID_Data.Pos_X_FloatingPoint),
				Current_Y_Pos 		 	  	= rw(UID.P1 + (Data_length.Players * i) +  UID_Data.Pos_Y),
				Current_Pos_Y_FloatingPoint = rw(UID.P1 + (Data_length.Players * i) +  UID_Data.Pos_Y_FloatingPoint),
			--	Current_Anim_Ptr 		  	= rd(UID.P1 + (Data_length.Players * i) +  UID_Data.Anim_Pointer),
			--	Current_Animelem_Ptr 	  	= rd(UID.P1 + (Data_length.Players * i) +  UID_Data.Animelem_Pointer),
				Current_Animelem_Ptr 	  	= rd(UID.P1 + (Data_length.Players * i) +  UID_Data.Animelem_Pointer),
				Current_Animelemtime 	  	= rb(UID.P1 + (Data_length.Players * i) +  UID_Data.Animelemtime),
				Current_Sprite_Pointer 		= rt(UID.P1 + (Data_length.Players * i) +  UID_Data.Sprite_Pointer),
			}

			--DISPLAY ANIMELEM BYTES
		--	for i = 0, Data_length.Animelem-1, 1 do
		--		gui.text(text.x + (17*i),text.y*5, string.format("0x%x", rb(PlayerZ[Current_Player].Current_Animelem_Ptr+i)))
		--	end
			
		--	POS X
			gui.text(text.x,text.y, string.format("Pos X = 0x%x", PlayerZ[Current_Player].Current_X_Pos))	
		--	FloatingPointX
			gui.text(text.x+58,text.y, string.format(".0x%x", PlayerZ[Current_Player].Current_Pos_X_FloatingPoint))
		--	VEL X
			gui.text(text.x2+51,text.y, string.format("Vel X = 0x%x", PlayerZ[Current_Player].Current_X_Vel))
		--	FloatingPointX
			gui.text(text.x2+109,text.y, string.format(".0x%x", PlayerZ[Current_Player].Current_X_Vel_FloatingPoint))
		--	POS Y
			gui.text(text.x,text.y*2, string.format("Pos Y = 0x%x", PlayerZ[Current_Player].Current_Y_Pos))
		--	FloatingPointY
			gui.text(text.x+58,text.y*2, string.format(".0x%x", PlayerZ[Current_Player].Current_Pos_Y_FloatingPoint))
		--	VEL Y
			gui.text(text.x2+51,text.y*2, string.format("Vel Y = 0x%x", PlayerZ[Current_Player].Current_Y_Vel))
		--	FloatingPointY
			gui.text(text.x2+109,text.y*2, string.format(".0x%x", PlayerZ[Current_Player].Current_Y_Vel_FloatingPoint))
		--	ACCEL X
		--	gui.text(text.x2+158+12,text.y,"Accel X =")
		--	gui.text(text.x2+197+12,text.y, string.format("0x%x", PlayerZ[Current_Player].Current_Accel_X))
		--	ACCEL X
			gui.text(text.x2+142,text.y, string.format("XAccel = 0x%x", PlayerZ[Current_Player].Current_Accel_X))
		--	ACCEL Y
			gui.text(text.x2+142,text.y*2, string.format("YAccel = 0x%x", PlayerZ[Current_Player].Current_Accel_Y))
		--	ANIMELEMTIME
			gui.text(text.x+90,text.y*3, string.format("Animelemtime = 0x%x", PlayerZ[Current_Player].Current_Animelemtime))

		else
		
		--DISPLAY MUGEN DAYA
		PlayerZ[i] = { 
			visible						= rb(UID.P1 + (Data_length.Players * i) +  UID_Data.Visible),
			Current_X_Vel 			  	= rws(UID.P1 + (Data_length.Players * i) +  UID_Data.Vel_X),
			Current_X_Vel_FloatingPoint	= rw(UID.P1  + (Data_length.Players * i) +  UID_Data.Vel_X_FloatingPoint),
			Current_Y_Vel 			  	= rws(UID.P1 + (Data_length.Players * i) +  UID_Data.Vel_Y),
			Current_Y_Vel_FloatingPoint	= rw(UID.P1  + (Data_length.Players * i) +  UID_Data.Vel_Y_FloatingPoint),
		--	Current_Accel_X 		  	= rds(UID.P1 + (Data_length.Players * i) +  UID_Data.Accel_X),
			Current_Accel_X 		  	= Subpixel_Floatconvert(Division_Type.W, rds(UID.P1 + (Data_length.Players * i) +  UID_Data.Accel_X)),
			Current_Accel_Y 		  	= Subpixel_Floatconvert(Division_Type.W, rds(UID.P1 + (Data_length.Players * i) +  UID_Data.Accel_Y)),
		--	Current_Accel_Y 		  	= rds(UID.P1 + (Data_length.Players * i) +  UID_Data.Accel_Y),
			Current_X_Pos 			  	= rw(UID.P1  + (Data_length.Players * i) +  UID_Data.Pos_X),
			Current_Pos_X_FloatingPoint = rw(UID.P1  + (Data_length.Players * i) +  UID_Data.Pos_X_FloatingPoint),
			Current_Y_Pos 		 	  	= rw(UID.P1  + (Data_length.Players * i) +  UID_Data.Pos_Y),
			Current_Pos_Y_FloatingPoint = rw(UID.P1  + (Data_length.Players * i) +  UID_Data.Pos_Y_FloatingPoint),
		--	Current_Animelem_Ptr 	  	= rd(UID.P1  + (Data_length.Players * i) +  UID_Data.Animelem_Pointer),
			Current_Animelem_Ptr 	  	= rd(UID.P1  + (Data_length.Players * i) +  UID_Data.Animelem_Pointer),
			Current_Animelemtime 	  	= rb(UID.P1 + (Data_length.Players * i) +  UID_Data.Animelemtime),
			Current_Sprite_Pointer 		= rt(UID.P1 + (Data_length.Players * i) +  UID_Data.Sprite_Pointer),
		}

		--	POS X
		--	gui.text(text.x,text.y, "Pos X =")
		--	gui.text(text.x2,text.y, string.format("%d", PlayerZ[Current_Player].Current_X_Pos))	
			gui.text(text.x,text.y, string.format("Pos X = %f", OutputFloat(PlayerZ[Current_Player].Current_X_Pos,PlayerZ[Current_Player].Current_Pos_X_FloatingPoint,Division_Type.W)))
		--	VEL X
		--	gui.text(text.x2+30,text.y, "Vel X =")
		--	gui.text(text.x2+52,text.y, string.format("Vel X = %f", PlayerZ[Current_Player].Current_X_Vel))
			gui.text(text.x2+52,text.y, string.format("Vel X = %f", OutputFloat(PlayerZ[Current_Player].Current_X_Vel,PlayerZ[Current_Player].Current_X_Vel_FloatingPoint,Division_Type.W)))
		--	POS Y
		--	gui.text(text.x,text.y*2,"Pos Y =")
		--	gui.text(text.x2,text.y*2, string.format("%d", PlayerZ[Current_Player].Current_Y_Pos))
			gui.text(text.x,text.y*2, string.format("Pos Y = %f", OutputFloat(PlayerZ[Current_Player].Current_Y_Pos,PlayerZ[Current_Player].Current_Pos_Y_FloatingPoint,Division_Type.W)))
		--	VEL Y
		--	gui.text(text.x2+60,text.y*2,"Vel Y =")
			gui.text(text.x2+52,text.y*2, string.format("Vel Y = %f", OutputFloat(PlayerZ[Current_Player].Current_Y_Vel,PlayerZ[Current_Player].Current_Y_Vel_FloatingPoint,Division_Type.W)))
		--	ACCEL X
		--	gui.text(text.x2+168,text.y*2,"Accel Y =")
			gui.text(text.x2+142,text.y, string.format("XAccel = %f", PlayerZ[Current_Player].Current_Accel_X))
		--	ACCEL Y
			gui.text(text.x2+142,text.y*2, string.format("YAccel = %f", PlayerZ[Current_Player].Current_Accel_Y))
		--	ANIMELEMTIME
			gui.text(text.x+90,text.y*3, string.format("Animelemtime = %d", PlayerZ[Current_Player].Current_Animelemtime))
		end
		
		if validplayer() == 2 then
--OUTSIDE OF MAIN STUFF TO BE LOADED SEPERATELY
		-- Output AnimElem data location
			PlayerZ[Current_Player].Animelem_File = define_file_index(PlayerZ[Current_Player].Current_Animelem_Ptr)
			PlayerZ[Current_Player].Animelem_Offset = define_file_offset(PlayerZ[Current_Player].Current_Animelem_Ptr)
		-- Output Sprite data location
			PlayerZ[Current_Player].Sprite_File = define_file_index(PlayerZ[Current_Player].Current_Sprite_Pointer)
			PlayerZ[Current_Player].Sprite_Offset = define_file_offset(PlayerZ[Current_Player].Current_Sprite_Pointer)
		-- Output TileDef data location	
-- ADJUST OFFSET FOR XMCOTA
			if rom	== "xmcota" then	
				PlayerZ[Current_Player].Current_TileDef_Ptr = rd(PlayerZ[Current_Player].Current_Sprite_Pointer)			
			else
				PlayerZ[Current_Player].Current_TileDef_Ptr = rd(PlayerZ[Current_Player].Current_Sprite_Pointer + 6)			
			end
			PlayerZ[Current_Player].TileDef_File = define_file_index(PlayerZ[Current_Player].Current_TileDef_Ptr)
			PlayerZ[Current_Player].TileDef_Offset = define_file_offset(PlayerZ[Current_Player].Current_TileDef_Ptr)
		-- Output TileMap data location	
			PlayerZ[Current_Player].Current_TileMap_Ptr = rd(PlayerZ[Current_Player].Current_TileDef_Ptr+6)
			PlayerZ[Current_Player].TileMap_File = define_file_index(PlayerZ[Current_Player].Current_TileMap_Ptr)
			PlayerZ[Current_Player].TileMap_Offset = define_file_offset(PlayerZ[Current_Player].Current_TileMap_Ptr)

----------------------------------------------------
--DRAW THE TEXT TO THE SCREEN
----------------------------------------------------

		--	ANIM POINTER
			gui.text(text.x,text.y*3, string.format("Anim Ptr  = 0x%x", PlayerZ[Current_Player].Current_Animelem_Ptr))
				if PlayerZ[Current_Player].Current_Animelem_Ptr > 0 then
				--	ANIMELEM FILE
						gui.text(text.x,text.y*4, string.format("Animelem file = %d", PlayerZ[Current_Player].Animelem_File))
				--	ANIMELEM OFFSET
						gui.text(text.x+90,text.y*4, string.format("Offset = %x", PlayerZ[Current_Player].Animelem_Offset))	
				end
		--	SPRITE DATA
		--	SPRITE POINTER
			gui.text(text.x,text.y*5, string.format("Sprite Ptr  = 0x%x", PlayerZ[Current_Player].Current_Sprite_Pointer))
				if PlayerZ[Current_Player].Current_Sprite_Pointer > 0 then
				--	SPRITE FILE
						gui.text(text.x,text.y*6, string.format("Sprite file   = %d", PlayerZ[Current_Player].Sprite_File))
				--	SPRITE OFFSET
						gui.text(text.x+90,text.y*6, string.format("Offset = %x", PlayerZ[Current_Player].Sprite_Offset))	
				end
		--	TILEDEF DATA
		--	TILEDEF POINTER
			gui.text(text.x,text.y*7, string.format("Tiledef Ptr = 0x%x", PlayerZ[Current_Player].Current_TileDef_Ptr))
				if PlayerZ[Current_Player].Current_TileDef_Ptr > 0 then
				--	TILEDEF FILE
						gui.text(text.x,text.y*8, string.format("Tiledef file   = %d", PlayerZ[Current_Player].TileDef_File))
				--	TILEDEF OFFSET
						gui.text(text.x+90,text.y*8, string.format("Offset = %x", PlayerZ[Current_Player].TileDef_Offset))	
				end		
		--	TILEMAP DATA
			if rom	== "xmcota" then
		--	TILEMAP POINTER
			gui.text(text.x,text.y*9, string.format("Tilemap Ptr = 0x%x", PlayerZ[Current_Player].Current_TileMap_Ptr))
				if PlayerZ[Current_Player].Current_TileMap_Ptr > 0 then
				--	TILEDEF FILE
						gui.text(text.x,text.y*10, string.format("Tiledef file   = %d", PlayerZ[Current_Player].TileMap_File))
				--	TILEDEF OFFSET
						gui.text(text.x+90,text.y*10, string.format("Offset = %x", PlayerZ[Current_Player].TileMap_Offset))	
				end		
				end
			end

		--Freeze timer.cancel()
	if infinite_time == 1 then
		wb(timer_address, Max.timer)
		wb(charselect_timer_address, Max.charselect_timer)
--		memory.writedword(P1_Characterselect_cursor_adr,0X0000170E)
	end
	
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
	
	--` TOGGLE MODE
	if Current_Mode == 1 then
	gui.text(text.x+140,text.y*19, "V - Data Mode - SOURCE")
	else
	gui.text(text.x+140,text.y*19, "V - Data Mode - MUGEN")
	end
	--` INFINITE TIME
	gui.text(text.x+140,text.y*20, "C - Infinite Time = ".. infinite_time)
	--` TOGGLE PLAYER
	gui.text(text.x+132,text.y*21, "O/P - Toggle Current Player")	
	
	--` Current Player
	gui.text(0,0, "Player ".. Current_Player+1)	
	--` Current Game
	gui.text(50,0, "".. rom)	

	--Toggle Data view
	if pressing_V == 0 and keys.V then
		if Current_Mode == 1 then
			Current_Mode = 2
			pressing_V = 1
		else
			Current_Mode = 1	
			pressing_V = 1
		end
	end
	
	if pressing_V == 1 and not keys.V then
			pressing_V = 0
	end
	
	--Toggle Cuurent Player +1
	if pressing_P == 0 and keys.P then
			pressing_P = 1
		if Current_Player == Num_Players-1 then
			Current_Player = 0
		else
			Current_Player = Current_Player + 1--getnextvalidplayer()
		end
	end
	
	if pressing_P == 1 and not keys.P then
			pressing_P = 0
	end	

	--Toggle Cuurent Player -1
	if pressing_O == 0 and keys.O then
			pressing_O = 1
		if Current_Player == 0 then
			Current_Player = Num_Players - 1
		else
			Current_Player = Current_Player - 1
		end
	end
	
	if pressing_O == 1 and not keys.O then
			pressing_O = 0
	end	
	
end
	emu.frameadvance()
end
