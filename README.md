# Marvel-Data-LUA
- A script designed to gather data for Mugen, as well as make editing/gathering sprite/animation info easier and accurate
- IMPORTANT!!!
- "File" refers to the numbered file found in a given games ROM. Can be opened in HxD to get raw data
- SUPPORTED GAMES
- xmcota
- xmvsf
- mvsc
- msh
- mshvsf
-     REVISION 1.1
- Added display for FrameTime to make finding data in the ROM a bit easier
- Per the request of Sir Ghostler, added support for MSHVSF
- Added the option to press O to decrement the current player
-     REVISION 1.2
- Can now use the script whenever ya like
- Can target any player, any time
- Added TileDef output
- XCOTAs Character Select timer was wrong, now properly freezes
- A port over from the Samsho script, can display Pos/Vel Data as either converted Floats for Mugen, or Hexadecimal like the Source game
-     REVISION 1.3
- XMCOTA Handles sprites slightly differently than the other VS Games, requiring 2 Pointers for the TileMap as opposed to 1. The script now accommodates that
- Alongside that change, the script now properly updates depending on the current game, and it now shows which game is currently loaded for fun
