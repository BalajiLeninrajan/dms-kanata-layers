# dms-kanata-layers

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) bar button for [kanata](https://github.com/jtroo/kanata). Clicking it opens a keymap of every layer in your config.

- The popout draws each layer on your `defsrc` rows. Tap-hold keys show both sides, and chord combos are listed under the grid.
- The keymap comes from your `.kbd` file and reloads when the file changes. The plugin never talks to kanata itself, so kanata needs no extra flags.

## Setup

Link or clone this repo into the plugins directory, then enable **Kanata Layers** under Settings → Plugins and add its widget to the bar:

```sh
git clone https://github.com/BalajiLeninrajan/dms-kanata-layers ~/.config/DankMaterialShell/plugins/kanataLayers
```

## Settings

| Setting | Default | |
|---|---|---|
| Kanata config | `~/.config/kanata/kanata.kbd` | The file the keymap is read from |

## Limits

The parser handles `defsrc`, `deflayer`, `deflayermap`, `defalias`, `defchords`, the `tap-hold` family, layer actions, `multi`, and `unicode`. Anything else shows its action name. It doesn't expand `include` files or `defvar` values.
