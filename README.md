# dms-kanata-layers

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) plugin for [kanata](https://github.com/jtroo/kanata). It shows the active layer in the bar, and clicking it opens the keymap for any layer.

- The bar pill shows the current layer and updates as you switch.
- The popout draws each layer on your `defsrc` rows. Tap-hold keys show both sides, and chord combos are listed under the grid.
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

## IPC

```sh
dms ipc call kanataLayers layer    # print the active layer
dms ipc call kanataLayers reload   # re-read the config and reconnect
```

## Limits

- Quickshell sockets only support Unix sockets, so the plugin connects through bash's `/dev/tcp`. That's why bash is a requirement.
- The parser handles `defsrc`, `deflayer`, `deflayermap`, `defalias`, `defchords`, the `tap-hold` family, layer actions, `multi`, and `unicode`. Anything else shows its action name. It doesn't expand `include` files or `defvar` values.
