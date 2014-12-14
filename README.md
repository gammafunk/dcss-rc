RandomTiles
===========

This project has lua code for use in configuration files for
[DCSS](http://crawl.develz.org/wordpress/) that automatically and randomly
changes the player's display tile using the *tile_player_tile* configuration
option.

To use this code, you need 1) to include it in your rc file and 2) add or edit
the `ready()` function in your rc file.

## 1. Including RandomTiles in your rc

If you play on the server [CSZO](http://crawl.s-z.org/), you can add the
following to your rc

```
include += PlayerTiles.rc
include += RandomTiles.rc
```

If you don't play on CSZO or you'd like to change either **RandomTiles.rc** (to
set options) or **PlayerTiles.rc** (to add/change the tiles used), copy these
files into your rc directly. They need to be copied so the PlayerTiles.rc code
is before the RandomTiles.rc code, and both must come before the `ready()`
function described below. These two files have some basic comments showing how
to modify them.

## 2. Updating the `ready()` function in your rc

A minimal `ready()` function would be

```lua
{
  function ready()
  -- Enable RandomTiles
  random_tile()
  end
}
```

You can copy this code directly into your rc anywhere *after* the
includes/copies of **PlayerTiles.rc** and **RandomTiles.rc**. Make sure the `{`
at the beginning and the `}` at the end are the first characters on their
respective lines.

If you have an existing `ready()` defined, add `random_tile()` to any line of
this function.

## Some helpful macro functions

The function `set_tile_by_name()` will prompt for a monster name defined in
PlayerTiles.rc and then change your tile to the matching monster. Note that
only monster tiles defined in PlayerTiles.rc will work, and the match is
case-insensitive with partial matches allowed.

The function `new_random_tile()` will switch your current tile to a new, randomly
chosen one.

To bind either of these functions to a key, use *~* or *Ctrl-d* followed by
*m*, and then enter `===set_tile_by_name` or `===new_random_tile` depending on
which function you want.
