Building a Level with Conveyor Belts and Switches
1. Starting Point
The easiest way is to duplicate Scenes/TestLevel.tscn and build on that. 
The TileSet is currently embedded in that scene and not saved as a separate file, so a new empty scene would not have it.
Everything happens on one TileMapLayer with the script Data/Conveyor/conveyor_map.gd attached.

2. Painting Conveyor Belts
Straight pieces: atlas rows 0–3, one per direction.
Curves: atlas rows 4–11, both turning directions for every exit.
Only paint tiles from column 0. Columns 1–3 are animation frames that Godot plays on its own.
The arrow shows the running direction. The direction you paint a belt in is its starting direction.
A belt must be continuous: the exit of each tile has to lead into the entry of the next one.

3. Painting Switches
Use the blue arrows: 0,12 (up), 1,12 (right), 0,13 (left), 1,13 (down). The arrow is the switch’s starting direction.
Do not paint the orange and brown arrows (rows 14–15). The game places those itself, for “selected” and for “blink”.

4. Give Every Switch a Switch Node
Drag Scenes/Switch.tscn into the scene as a child of the TileMapLayer.
Place the node exactly on the switch tile. The easiest way is with snapping turned on (magnet icon). Under “Configure Snap…” set Grid Offset to 32, 32 and Grid Step to 64, 64.
In the node’s inspector:
Key: the number key that selects this switch (1–10, where 10 is the 0 key). Each number may be used only once.
Forbidden Directions: tick every side the switch must never point to:
the side the belt from the input port comes from (otherwise the player can reverse that belt),
every side without a belt (otherwise items run into nothing).

5. How It Behaves In Game
Number key: selects the switch, and it turns orange.
Arrow keys or WASD: set the selected switch to that direction. If a belt there runs towards the switch, it reverses and then runs away from it.
The switch briefly blinks brown and stays as it is if
the direction is forbidden in the inspector, or
the switch at the other end of the belt already points into that belt. Whoever takes a belt first keeps it.
You set how long the blink lasts on the TileMapLayer under Blink Duration.

6. Checking
Start the level with F6 while the scene is open. F5 starts the main scene.
Red errors in the debugger at start mean:
“… does not sit on a switch tile”: the switch node is next to its tile.
“Key … is used by … and …”: two switches have the same number.

7. Not Tested Yet
Two switches directly next to each other, with no belt in between. Avoid that for now.
