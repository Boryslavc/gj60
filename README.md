# GameJam60 

## Game Idea
- 2D top-down.
- Items travel on **fixed conveyor belts** from the bottom (entrances) to the top (output bins).
- The player influences **only the switches**. Entrances, belts and bins are fixed.
- The belts wind around with curves and branches.
- Items arrive at random times and in random order (weighted).
- A **raccoon** causes mischief: it walks to switches, changes them and locks them for a while. The player can shoo it away.
- **Goal:** get as many items as possible into the correct bin.

### Prototype
- 2 entrances, 2 bins, 2 switches, one screen.
- For the submission the level will be several screens tall.

### Scoring and End of Round
- Correctly sorted = +1, wrong = 0 (no penalty).
- The round ends as soon as X items have arrived at all bins combined.
- At the end, a corresponding reward animation is displayed.

## Components

| Component                                    | Form                      | Core                                                                            |
| -------------------------------------------- | ------------------------- | ------------------------------------------------------------------------------- |
| ItemType                                     | Resource (.tres)          | name, texture                                                                   |
| SpawnEntry                                   | Resource                  | item type + weight                                                              |
| Entrance (entrance.tscn)                     | Scene                     | list of spawn entries, random choice and random interval                        |
| Item (item.tscn)                             | one scene for all types   | moves from tile center to tile center, has an `Area2D`                          |
| Belts                                        | TileMapLayer              | custom data direction in the TileSet                                            |
| Switches                                     | tiles in the TileMapLayer | arrow shows the direction, a click turns it to the next exit, can be disturbed  |
| Raccoon (raccoon.tscn)                       | Scene                     | walks to switches, winds up for 2 s, changes and locks them, can be shooed away |
| Output bin (output_bin.tscn)                 | Scene                     | checks the type, reports the result, deletes the item                           |
| Round (round.gd)                             | Node                      | counts arrivals, ends the round at X                                            |
| End screen selector (end_screen_selector.gd) | Node                      | shows one of three screens depending on the ratio                               |

---

### ItemType.gd, Resource

One .tres file per item type. There is no separate scene per type, because items differ only in appearance and destination.

```gdscript
@export var name: String
@export var texture: Texture2D
```

### SpawnEntry.gd, Resource

Links an item type with its weight. 

```gdscript
@export var item_type: ItemType
@export var weight: float = 1.0
```

### entrance.tscn

```
Entrance
 ├ spawn_entries: Array[SpawnEntry]
 └ RandomIntervalTrigger   (min_wait, max_wait)
```

- The list is filled in the inspector. Example: entrance A spawns items 1, 2, 3; entrance B spawns items 1, 2, 4.
- Random interval: Each triggered signal spawns one item.
- Random type: RandomNumberGenerator.rand_weighted() over the weights.
- Places the item on its start tile. From there it moves on its own.
- In the group "entrance".

### item.tscn
- One scene for all types. When spawned it receives its "ItemType" and sets its graphic from it.
- Moves from tile center to tile center. At each center it reads the direction of the tile below it and moves to the next tile in that direction.
- Belts and switches are treated the same way, no special case.
- Has a small Area2D so the bin can detect it.

###  TileMapLayer (Conveyor Belts)

- The level is built from a sprite sheet (TileSet).
- The path is stored only in the TileSet: each belt tile has the custom data field "direction" (up, right, down, left). A curve tile carries its exit direction.
- Belts therefore follow the tile grid: straight pieces and 90° curves.

### Switches (tiles in the same TileMapLayer)

- One tile in size, shown as an arrow that indicates where the item will go next.
- There is only one kind of switch. It is operated by the player (click) and by the raccoon.
- The TileSet needs 8 arrow tiles:
  - 4 normal (up, right, down, left): "direction", "is_switch = true"
  - 4 disturbed, clearly different looking: "direction", "is_switch = true", "disturbed = true"
- The "disturbed" state is thus stored in the tile itself, with no extra list.
- Automatic detection at level start (script on the TileMapLayer):
  - Entry = the neighbor tile whose direction points into the switch.
  - Exits = the neighbor tiles that are belts and do not point back into the switch, in clockwise order.
  - The results are stored in a table: tile coordinate → entry + exits.
- One shared function sets a switch to a given exit. Both the player click and the raccoon use this function.

### Click Handling (in the TileMapLayer script)

Click
 ├ 1. Does the click hit the raccoon sprite while it is winding up?  → shoo it away, done
 ├ 2. Is the tile a disturbed switch?                                → do nothing
 ├ 3. Is the tile a switch?                                          → turn to the next exit
 └ otherwise                                                          → nothing

- Turning = 90° steps clockwise to the next exit. The entry and sides without a belt are skipped.
- Because the raccoon is checked first, a click on it never turns the switch below it.

### raccoon.tscn

Raccoon
 ├ Sprite2D
 └ RandomIntervalTrigger               (min_wait, max_wait) – when it sets off
 @export var speed: float              walking speed
 @export var windup_duration: float    time window for the player (e.g. 2 s)
 @export var disturb_duration: float   how long the switch stays locked afterwards
 func is_hit_by_click(position) -> bool
 func shoo()


Sequence in three phases:
1. Walking: On "triggered" it picks a random switch and walks via Tween in a straight line to its tile center.
2. Winding up: It stands on the switch for windup_duration seconds. Only now is it clickable.
   - A click on the sprite: It aborts, the switch stays untouched, and it walks to a different switch.
1. Operating: Without a click it sets the switch to a random exit and places the "disturbed" arrow tile.
   - At the same time a timer starts. When it runs out, the normal arrow tile with the same direction is placed.
   - While disturbed, the switch ignores clicks. Items move normally in the arrow's direction.

### output_bin.tscn


OutputBin
 ├ Area2D + CollisionShape2D   (one tile in size)
 └ Sprite2D                    shows which type belongs here
 @export var item_type: ItemType
 signal item_arrived(correct: bool)


- Placed at the end of a belt. The sprite shows the player which type belongs here.
- On area_entered: compares item.item_type == item_type, emits item_arrived(correct) and deletes the item with queue_free(), whether correct or wrong.
- Does not award points itself, it only reports.
- In the group "output_bin".
- 
### round.gd, node in the level

@export var item_count: int = 10    # X, placeholder
var arrived_count := 0
var points := 0
signal round_finished(points: int, item_count: int)

- At start, connects to all bins.
- On item_arrived(correct): arrived_count += 1, and if correct also points += 1.
- When arrived_count == item_count: emit round_finished(points, item_count)
- 
### end_screen_selector.gd, node


@export var screen_bad: PackedScene
@export var screen_okay: PackedScene
@export var screen_perfect: PackedScene
@export_range(0.0, 1.0) var threshold_okay: float = 0.5      # placeholder
@export_range(0.0, 1.0) var threshold_perfect: float = 1.0   # placeholder

- Listens to round_finished.
- Selection:
  1. ratio >= threshold_perfect → perfect
  2. ratio >= threshold_okay → okay
  3. otherwise → bad
- Each screen has a simple animation.
