# dms-kanata-layers

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) plugin for [kanata](https://github.com/jtroo/kanata). It shows the active layer in the bar and pops up that layer's keymap while you hold it.

- Holding a layer listed in the settings shows an overlay at the bottom of the screen after a short delay. The overlay draws the layer on your `defsrc` rows, with tap-hold keys showing both sides and chord combos listed underneath.
- The bar pill shows the current layer. Clicking it opens a popout where you can browse every layer.
- The keymap comes from your `.kbd` file, so it stays in sync with your config. The plugin re-reads the file when it changes or when kanata reports a reload.

## Setup

Kanata has to run its TCP server. Bind it to loopback, because any client can switch layers and reload the config:

```sh
kanata --cfg ~/.config/kanata/kanata.kbd --port 127.0.0.1:5829
```

Link or clone this repo into the plugins directory, then enable **Kanata Layers** under Settings → Plugins and add its widget to the bar:

```sh
git clone https://github.com/BalajiLeninrajan/dms-kanata-layers ~/.config/DankMaterialShell/plugins/kanataLayers
```

## Settings

| Setting | Default | |
|---|---|---|
| Kanata config | `~/.config/kanata/kanata.kbd` | The file the keymap is read from |
| Kanata TCP address | `127.0.0.1:5829` | Must match `--port` |
| Overlay layers | every layer but the first | Comma-separated, e.g. `util, nav` |
| Overlay delay | `250` ms | Holds shorter than this don't show the overlay |

## IPC

```sh
dms ipc call kanataLayers layer          # print the active layer
dms ipc call kanataLayers toggle util    # pin the overlay open on a layer, again to hide
dms ipc call kanataLayers reload         # re-read the config and reconnect
```

`toggle` works well as a compositor bind for checking a layer without holding it. In niri:

```kdl
Mod+Slash { spawn "dms" "ipc" "call" "kanataLayers" "toggle" ""; }
```

## Limits

- Quickshell sockets only support Unix sockets, so the plugin connects through bash's `/dev/tcp`. That's why bash is a requirement.
- The parser handles `defsrc`, `deflayer`, `deflayermap`, `defalias`, `defchords`, the `tap-hold` family, layer actions, `multi`, and `unicode`. Anything else shows its action name. It doesn't expand `include` files or `defvar` values.
