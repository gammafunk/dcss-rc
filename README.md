DCSS RC
=======
This project has settings and lua code for use in configuration files for
[DCSS](http://crawl.develz.org/wordpress/).

## Installation

#### 1. Include the .rc or .lua file in your rc

For [RandomTiles](#randomtiles), some servers have
[RandomTiles.rc](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/RandomTiles.rc)
available for use in `include` statements; see the documentation in that
section.

For the other components, you must add a lua code block to your rc with the
contents of the .lua file. To make a code block, add an opening brace followed
by a closing brace to your rc with each on their own lines, then add the file
contents on the lines in between. Each file has opening and closing comment
lines, so your added code block will look something like:

```
{
-------------------------
---- Begin char_dump ----
-------------------------
<lua code>
-----------------------
---- End char_dump ----
-----------------------
}
```

#### 2. Update the `ready()` function in your rc

Almost all component have a function call that needs to be in your rc `ready()`
function. See the components documentation for the function name you need. You
may already have a `ready()` function defined, in which case add the call on
its own line.

If not, you'll need to create a code block to define a `ready()` function.
Using *char_dump* as an example, which has a function called `char_dump()`,
this would be:

```lua
{
  function ready()
    -- Enable char_dump
    char_dump()
  end
}
```

#### 3. Make any necessary or desired macros

To work properly, the [target_skill](#target_skill),
[speedrun_rest](#speedrun_rest), and [safe_eat](#safe_eat) components require a
macro definition to call a function. Most other components also have useful
functions available for macros. See each component's help section for the
required and available functions.

To make a macro binding a function to a key, use *~* or *Ctrl-d* followed by
*m*, and then enter `===function-name`, where "function-name" is the function
you'd like to use without `()`. For example, [RandomTiles](#randomtiles) has a
function `new_random_tile()`, so the macro target is `===new_random_tile`.

###### Optional Lua console

You can enable the crawl lua console to run any function. This is useful if
don't want to make a dedicated key for functions you don't use a lot or to just
try them out. To enable the console, bind a key to it by adding something like
the following to your rc:

```
bindkey = [~] CMD_LUA_CONSOLE
```

This binds the console to the *~* key, since macros already have the *Ctrl-d*
key. Use whatever key you like in the `[]` brackets, including things like
`[^D]` to use e.g. *Ctrl-D*. You can then run any function by activating the
console and typing its name together with `()` at the end:

```
> new_random_tile()
```

## RandomTiles

Automatically and randomly change the player tile to that of various
monsters. This code works in DCSS versions 0.16 and later.

#### Including and enabling RandomTiles in your rc

If you play on the servers [CSZO](http://crawl.s-z.org/),
[CAO](http://crawl.akrasiac.org:8080/), or
[CBRO](http://crawl.berotato.org:8080/), you can add the following to your rc:

```
include += RandomTiles.rc
```

If you don't play on these servers or if or you'd like to change the tiles
used, copy the contents of [RandomTiles.rc](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/RandomTiles.rc) into your rc directly. Regardless
of how you include [RandomTiles.rc](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/RandomTiles.rc) in your rc you must add a call to the
function `random_tile()` in your `ready()` function. See the [installation
section](#installation) for examples.

#### Macro functions to change tiles

The function `set_tile_by_name()` will prompt for a monster name defined in
PlayerTiles.rc and then change your tile to the matching monster. Note that
only monster tiles defined in PlayerTiles.rc will work, and the match is
case-insensitive with partial matches allowed.

The function `new_random_tile()` will switch your current tile to a new,
randomly chosen one.

#### Macro functions for toggling RandomTiles

The function `toggle_random_tile()` will toggle RandomTiles between enabled
and disabled states. When disabled, RandomTiles sets `tile_player_tile` to the
value in `randtile_options.disabled_setting`, which is "normal" by default.

The function `toggle_tile_timer()` will toggle the tile change timer between
enabled and disabled states. When the timer is disabled, RandomTiles doesn't
change tile as turns pass or your XL changes. Hence your tile is fixed to the
current one, but you can still use `set_tile_by_name()` and `new_random_tile()`
to modify it.

#### Settings and changing tile sets.

Note that the tile changes you make using the functions above are saved across
sessions. So if you want to use a fixed tile, select the tile you want with
`set_tile_by name()` and then disable tile changes with
`toggle_tile_timer()`. You will then have this as your fixed tile until you set
a new one or call `toggle_tile_timer()` to enable tile changes again.

For other settings, see the `randtile_options` variable defined in
[RandomTiles.rc](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/RandomTiles.rc) and its associated comments. You can copy this variable
definition into a lua code block in your rc and change e.g. the number of turns
before a tile change, the setting to use when RandomTiles is disabled, and
customize the tile change messages.

To change the tileset used, you'll have to copy [RandomTiles.rc](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/RandomTiles.rc) directly into
your rc and redefine the variable `player_tiles`; see the comments above that
variable describing the format. To disable a particular tile, you can remove
the entry's line or comment it out by preceeding it with `--`. If you add or
modify an entry, be aware that it must have the same structure as the other
entries in `player_tiles`.

## target_skill

Opens the skill screen automatically when a skill reaches a target level set by
the player. Original code by elliptic with some reorganization. This code
works in DCSS versions 0.16 and later.

To enable in your rc, add a lua code block with the contents of
[target_skill.lua](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/target_skill.lua) and a call to the function `target_skill()` in your
`ready()` function. _Note: You must add `target_skill()` to `ready()` after the
call to `char_defaults()` if you're also using char_defaults._

Additionally assign a key to a macro with a target of `===set_target_skill` so
can change the skill target on the fly. See the [installation
section](#installation) for examples.

## char_defaults

Load default skill settings for each race+class combination automatically on
turn 0. Recommended that you also use
[target_skill.lua](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/target_skill.lua)
so that you can set skills (and a skill target) on turn 0 for chars without
defaults and have this data automatically become the new default. This code
works in DCSS versions 0.16 and later.

To enable in your rc, add a lua code block with the contents of
[char_defaults.lua](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/char_defaults.lua)
and a call to the function `char_defaults()` in your `ready()` function. If you
are using [target_skill](#target_skill), this call must come before the call to
`target_skill()` in `ready()`. To save or load your defaults on the fly
(e.g. if you forgotten to set something), you can assign a keys to macros with
a targets of `===save_char_defaults` or `===load_char_defaults` or simply run
these functions as needed in the lua console. See the [installation
section](#installation) for examples.

## force_mores

Add and remove force-more messages automatically based on current max hp or
experience level.

Force-more messages print a message of "--more--" and require the player to hit
space, making the player pause for consideration before acting. These are
normally set in the rc option `force_more_message`. For certain dangerous
monsters it's common to make a force-more specifically for when the monster
first comes into view (i.e. each time the player encounters a new monster of
that type). For some monsters, it's desirable to have these messages only for
weaker characters or only for earlier portions of the game.

This code has a set of dynamic force-mores defined for characters with lower
hp, with sets defined for XL1, Maxhp < 20, Maxhp < 40, Maxhp < 60, and Maxhp
< 90. Other sets can be defined by modifying the variable `fm_patterns`; see
the comments above that variable for details.

To enable in your rc, add a lua code block with the contents of
[force_mores.lua](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/force_mores.lua)
and a call to the function `force_mores()` in your `ready()` function according
to the instructions in the [installation section](#installation).

## speedrun_rest

Automatic slow swinging or walking for either a single turn or fixed number of
turns. Performing actions that take more than 10 aut regenerates more HP per
turn, which is preferred when minimizing turncount for score purposes. This is
also known as "bread swinging", but using 2h weapons when the player is
untrained in the weapon skill can be better as these are even slower to swing
than 15 aut. Additionally some characters like Naga or Chei worshipers might
prefer slow walking to swinging because it gives similar or better (i.e. under
Chei) regen/turn without requiring weapon swap.

This code supports both regen methods and can automatically detect when to use
which. For swinging, an item in a fixed inventory slot is automatically
wielded if it isn't already. The default slot used is the first food item found
in inventory, but see configuration below. For both swinging and walking, this
function prevents you from resting if hostiles are in LOS and interrupts
multi-turn rests if hostiles wander into LOS or any relevant event message
occurs. If the wielded weapon is unswappable (Vampiric, Distortion without
Lugonu, *Contam, *Curse, or *Drain), and the player walk would take more than
10 aut, slow walk is used automatically. This code works in DCSS versions 0.16
and later.

To enable in your rc, add a lua code block with the contents of
[speedrun_rest.lua](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/speedrun_rest.lua)
and a call to the function `speedrun_rest()` in your `ready()`
function. Additionally assign two macro keys, one with a target of
`===one_turn_rest` for the single-turn rest and one with a target of
`===start_resting` for the multiple turn rest. See the
[installation section](#installation) for examples. You can also set a macro
key to a target of `===set_swing_slot` or call `set_swing_slot()` from the lua
console to change the swing slot on the fly.

#### Configuration Variables

These have reasonable defaults and don't require modification, but can be
useful. See the comments above these in
[speedrun_rest.lua](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/speedrun_rest.lua)
for additional details.

* `automatic_slot`: If true, the swing item slot is automatically chosen to be
  the first food item in inventory.
* `fallback_slot`: If `automatic_slot` is false or no food item was found, this
  is the default slot used.
* `num_rest_turns`: How many turns to rest at max for the multi-turn resting
  started by `start_resting()`
* `naga_always_walk`: If true, Naga characters will always walk instead of
  swinging.
* `walk_delay`: The visual delay between each walk command in milliseconds.
* `status_messages` and `ignore_messages`: See the comments in
  [speedrun_rest.lua](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/speedrun_rest.lua)
  to details on how to set these to ignore any additional status change
  messages or general messages while resting.

## safe_eat

Prompt when eating in LOS of charmed tier-one demon, such as those made by
summon greater demon, since they can become hostile mid-meal. To enable in your
rc, add a lua code block with the contents of
[force_mores.lua](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/force_mores.lua)
and make a macro binding your 'e' key to `===safe_eat`. See the instructions in
the [installation section](#installation) for examples.

## load_message

Leave a message on save that will be displayed next time the player loads the
game. Original code by elliptic with some reorganization. This code works in
DCSS versions 0.16 and later.

 To enable in your rc, add a lua code block with the contents of
[load_message.lua](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/load_message.lua),
add a call to the functionn `load_message()` in your `ready()` function, and
make a macro binding 'S' to `===save_with_message`. See the instructions in the
[installation section](#installation) for examples.

## char_dump

Make a character dump every N turns (default of 1000). To enable in your rc,
add a lua code block with the contents of
[char_dump.lua](https://raw.githubusercontent.com/gammafunk/dcss-rc/master/char_dump.lua)
and a call to the function `char_dump()` in your `ready()` function according
to the instructions in the [installation section](#installation).
