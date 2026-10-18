# Building a Level
## Overview

| Part | Scene / File | What it does |
|---|---|---|
| Conveyor map | `TileMapLayer` + `Data/Conveyor/conveyor_map.gd` | Holds belts and switches, handles switch controls, keeps items from overlapping |
| TileSet | `Data/Conveyor/conveyor_tileset.tres` | Shared by all levels. Stores direction and entry of every belt tile |
| Switch | `Scenes/Conveyor Belt/Switch.tscn` | Gives a switch tile its number key and forbidden directions |
| Item | `Scenes/Conveyor Belt/Item.tscn` | Moves along the belts. Is either metal or trash |
| OutputPort | `Scenes/Conveyor Belt/OutputPort.tscn` | Where items are **created** (used by the generator) |
| InputPort | `Scenes/Conveyor Belt/InputPort.tscn` | **Takes in** metal |
| TrashPort | `Scenes/Conveyor Belt/TrashPort.tscn` | **Takes in** trash |
| Generator | `Data/Items/item_generator.gd` | Spawns items at the OutputPorts |

The easiest start is to **duplicate `Scenes/Playable Scenes/level1.tscn`**. It already contains all parts, correctly connected.

## 1. Conveyor Map
- One `TileMapLayer` with the script `conveyor_map.gd`.
- Its **Tile Set** must be `conveyor_tileset.tres`. In the inspector, use the arrow next to *Tile Set* → **Load**. Never create a new TileSet inside a scene.
- Switches, InputPorts and TrashPorts are **children** of this node.

## 2. Painting Belts
- **Straight pieces:** atlas rows 0–3. **Curves:** atlas rows 4–11.
- Only paint tiles from **column 0**. Columns 1–3 are animation frames.
- **The arrow is the running direction.** The direction you paint is the starting direction.
- A belt must be continuous: each tile's exit leads into the next tile's entry.

## 3. Switches
1. Paint a **blue arrow**: 0,12 (up), 1,12 (right), 0,13 (left), 1,13 (down). The arrow is the starting direction.
   Do **not** paint the orange or brown arrows (rows 14–15). The game uses them for "selected" and "blink".
2. Add `Switch.tscn` as a child of the conveyor map and place it **exactly on** the switch tile.
   Tip: turn on snapping (magnet icon) → *Configure Snap…* → Grid Offset `32, 32`, Grid Step `64, 64`.
3. In the inspector:
   - **Key:** number key that selects this switch (1–10, 10 = key 0). Each number only once.
   - **Forbidden Directions:** tick every side the switch must **never** point to:
	 - the side the belt from an OutputPort comes from (otherwise the player can reverse that belt),
	 - every side without a belt (otherwise items run into nothing).

## 4. Ports
**OutputPort** (items appear here)
- Place it on the **first tile** of a belt. Its place in the scene tree does not matter.
- Add it to the generator's **Output Ports** list.

**InputPort / TrashPort** (items go in here)
- Add as a **child of the conveyor map**.
- Place it on the **empty cell right after the last belt tile**. That cell must have **no tile**, otherwise items drive on.
- Connect its signal **`part_fed`** to the generator: select the port → *Node → Signals* → `part_fed` → Generator → method `_on_port_fed`.
- After taking in an item, the port is blocked for a while and shows its second frame. Items behind it queue up.

Default block times (seconds), adjustable in each port's inspector:

| Item | InputPort | TrashPort |
|---|---|---|
| Metal | 2 | 4 |
| Trash | 4 | 1 |

## 5. Generator

A `Node2D` with `item_generator.gd`. Inspector fields:

| Field | Value |
|---|---|
| Output Ports | all OutputPorts of the level (no empty slots!) |
| Item | `Scenes/Conveyor Belt/Item.tscn` |
| Conveyor Map | the conveyor map node |
| Trash Sprite / Metal Sprite | a PNG from `Assets/Sprites` |
| Trash Port Count / Metal Port Count | number of TrashPorts / InputPorts |
| Spawn Interval | seconds between two items |

## 6. Controls

- **Number keys 1–0** (also numpad) select a switch. It turns orange.
- **Arrow keys / WASD** set its direction. A belt it points at that runs towards it reverses.
- The switch **blinks** and keeps its direction if the direction is forbidden, or if the switch at the other end of that belt already points into it. Whoever takes a belt first keeps it.

## Known Limitations

- Two switches **directly next to each other** without a belt in between are not handled. Avoid this.
- If the generator spawns an item while the OutputPort's cell is still occupied, both items overlap briefly before the new one queues up.
