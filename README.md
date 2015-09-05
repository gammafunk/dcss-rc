DCSS RC
=======
This project has settings and lua code for use in configuration files for
[DCSS](http://crawl.develz.org/wordpress/).

## Installation

#### 1. Include the .rc or .lua file in your rc

For [RandomTiles](#RandomTiles), some servers have *RandomTiles.rc* available
for use in `include` statements; see the documentation in that section.

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
[bread_swing](#bread_swing), and [safe_eat](#safe_eat) components require a macro
definition to call a function. Most other components also have useful functions
available for macros. See each component's help section for the required and
available functions.

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
used, copy the contents of *RandomTiles.rc* into your rc directly. Regardless
of how you include *RandomTiles.rc* in your rc you must add a call to the
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
*RandomTiles.rc* and its associated comments. You can copy this variable
definition into a lua code block in your rc and change e.g. the number of turns
before a tile change, the setting to use when RandomTiles is disabled, and
customize the tile change messages.

To change the tileset used, you'll have to copy *RandomTiles.rc* directly into
your rc and redefine the variable `player_tiles`; see the comments above that
variable describing the format. To disable a particular tile, you can remove
the entry's line or comment it out by preceeding it with `--`. If you add or
modify an entry, be aware that it must have the same structure as the other
entries in `player_tiles`.

## target_skill

Opens the skill screen automaticaly when a skill reaches a target level set by
the player. Original code by elliptic with some reorganization. This code
works in DCSS versions 0.16 and later.

To enable in your rc, add a lua code block with the contents of
*target_skill.lua* and a call to the function `target_skill()` in your
`ready()` function. _Note: You must add `target_skill()` to `ready()` after the
call to `char_defaults()` if you're also using char_defaults._

Additionally assign a key to a macro with a target of `===set_target_skill` so
can change the skill target on the fly. See the [installation
section](#installation) for examples.

## char_defaults

Load default skill settings for each race+class combination automatically on
turn 0. Recommended that you also use *target_skill.lua* so that you can set
skills (and a skill target) on turn 0 for chars without defaults and have this
data automatically become the new default. This code works in DCSS versions
0.16 and later.

To enable in your rc, add a lua code block with the contents of
*char_defaults.lua* and a call to the function `char_defaults()` in your
`ready()` function. If you are using *target_skill.lua*, this call must come
before the call to `target_skill()` in `ready()`. To save or load your defaults
on the fly (e.g. if you forgotten to set something), you can assign a keys to
macros with a targets of `===save_char_defaults` or `===load_char_defaults` or
simply run these functions as needed in the lua console. See the [installation
section](#installation) for examples.

Additionally, to save your defaults on the fly, you can assign a key to a macro
with a target of `===save_char_defaults`.

## force_mores

Add and remove force-more messages based on hp/xl conditions. A force-more is
triggered the first time it comes into view if it's of a certain kind and
requires the player to hit e.g. space to continue. These messages can help to
avoid killing your weaker characters under manual movement (e.g. in
speedruns).

To enable in your rc, add a lua code block with the contents of
*force_mores.lua* and a call to the function `force_mores()` in your `ready()`
function according to the instructions in the [installation
section](#installation).

## bread_swing

Automatic bread swinging for either a single turn or fixed number of turns. An
item in a fixed inventory slot is automatically wielded if it isn't
already. The default slot used is that of a bread or meat ration, but see
configuration below. This function prevents you from swinging if hostiles are
in LOS and interrupts multi-turn swings if hostiles wander into LOS or any
relevant message occurs. This code works in DCSS versions 0.16 and later.

To enable in your rc, add a lua code block with the contents of
*bread_swing.lua* and a call to the function `bread_swing()` in your `ready()`
function. Additionally assign two macro keys, one with a target of
`===one_bread_swing` for the single-turn swing and one with a target of
`===start_bread_swing` for the multiple turn swing. See the [installation
section](#installation) for examples.

If the variable `automatic_slot` is true (default), the swing item slot is
automatically chosen to that of any bread or meat ration in inventory on turn 0
or if a slot isn't chosen already. If `automatic_slot` is false or no ration is
found, the slot in the variable `fallback_slot` is used (default is slot
'c'). The variable `num_swing_turns` sets the max number of swing (default
20). You can set a macro key to a target of `===set_swing_slot` or call
`set_swing_slot()` from the lua console to change the slot on the fly.

## safe_eat

Prompt when eating in LOS of charmed tier-one demon, such as those made by
summon greater demon, since they can become hostile mid-meal. To enable in your
rc, add a lua code block with the contents of *force_mores.lua* and make a
macro binding your 'e' key to `===safe_eat`. See the instructions in the
[installation section](#installation) for examples.

## load_message

Leave a message on save that will be displayed next time the player loads the
game. Original code by elliptic with some reorganization. This code works in
DCSS versions 0.16 and later.

 To enable in your rc, add a lua code block with the contents of
*load_message.lua*, add a call to the functionn `load_message()` in your
`ready()` function, and make a macro binding 'S' to `===save_with_message`. See
the instructions in the [installation section](#installation) for examples.

## char_dump

Make a character dump every N turns (default of 1000). To enable in your rc,
add a lua code block with the contents of *char_dump.lua* and a call to the
function `char_dump()` in your `ready()` function according to the instructions
in the [installation section](#installation).
