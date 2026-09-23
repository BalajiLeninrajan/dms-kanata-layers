.pragma library

// Parses a kanata .kbd config into something a keymap view can draw: the
// defsrc rows (keeping the line breaks the author used, since that's usually
// the physical layout) and a label for every key on every layer.

const KEY_UNITS = {
    bspc: 2, tab: 1.5, "\\": 1.5, caps: 1.75, ret: 2.25, lsft: 2.25, rsft: 2.75,
    lctl: 1.25, lmet: 1.25, lalt: 1.25, spc: 6.25, ralt: 1.25, rmet: 1.25, rctl: 1.25,
    cmp: 1.25, menu: 1.25
};

const KEY_NAMES = {
    left: "←", down: "↓", up: "↑", right: "→",
    bspc: "⌫", del: "Del", ret: "⏎", enter: "⏎", spc: "␣", tab: "⇥", esc: "Esc",
    caps: "Caps", lsft: "⇧", rsft: "⇧", lctl: "Ctl", rctl: "Ctl",
    lmet: "Super", rmet: "Super", lalt: "Alt", ralt: "Alt",
    home: "Home", end: "End", pgup: "PgUp", pgdn: "PgDn", ins: "Ins",
    vold: "Vol−", volu: "Vol+", mute: "Mute", brdn: "Bri−", brup: "Bri+",
    pp: "⏯", prev: "⏮", next: "⏭", grv: "`", prnt: "PrtSc"
};

const SHIFTED = {
    "1": "!", "2": "@", "3": "#", "4": "$", "5": "%", "6": "^", "7": "&", "8": "*",
    "9": "(", "0": ")", "-": "_", "=": "+", "[": "{", "]": "}", "\\": "|",
    ";": ":", "'": "\"", ",": "<", ".": ">", "/": "?", grv: "~"
};

const MOD_PREFIX = { "S-": "⇧", "C-": "Ctl+", "A-": "Alt+", "M-": "Super+", "RA-": "AltGr+", "AG-": "AltGr+" };

// Kanata only treats ";;" as a line comment; a lone ";" is the semicolon key.
function stripComments(text) {
    return text.replace(/#\|[\s\S]*?\|#/g, m => m.replace(/[^\n]/g, " "))
        .replace(/;;.*$/gm, "");
}

function tokenize(text) {
    const tokens = [];
    const re = /\s+|(\()|(\))|("(?:[^"\\]|\\.)*")|([^\s()"]+)/g;
    let line = 0;
    let m;
    while ((m = re.exec(text)) !== null) {
        if (m[0].trim() === "") {
            line += (m[0].match(/\n/g) || []).length;
            continue;
        }
        tokens.push({ text: m[0], line: line });
    }
    return tokens;
}

function parseForms(tokens) {
    let i = 0;
    function parse() {
        const tok = tokens[i++];
        if (tok.text === "(") {
            const list = [];
            list.line = tok.line;
            while (i < tokens.length && tokens[i].text !== ")")
                list.push(parse());
            i++;
            return list;
        }
        return tok;
    }
    const forms = [];
    while (i < tokens.length) {
        const form = parse();
        if (Array.isArray(form))
            forms.push(form);
    }
    return forms;
}

function atom(node) {
    return Array.isArray(node) ? null : node.text;
}

function prettyKey(name) {
    for (const prefix in MOD_PREFIX) {
        if (name.startsWith(prefix) && name.length > prefix.length) {
            const rest = name.slice(prefix.length);
            if (prefix === "S-" && SHIFTED[rest] !== undefined)
                return SHIFTED[rest];
            return MOD_PREFIX[prefix] + prettyKey(rest);
        }
    }
    if (KEY_NAMES[name] !== undefined)
        return KEY_NAMES[name];
    if (name.length === 1 || /^f\d+$/.test(name))
        return name.toUpperCase();
    return name;
}

function Config(forms) {
    this.src = [];
    this.layers = [];
    this.layerActions = {};
    this.aliases = {};
    this.chords = {};

    for (const form of forms) {
        const head = atom(form[0]);
        const args = form.slice(1);
        if (head === "defsrc") {
            this.src = args.map(n => ({ name: atom(n), line: n.line }));
        } else if (head === "deflayer") {
            const name = Array.isArray(args[0]) ? atom(args[0][0]) : atom(args[0]);
            this.layers.push(name);
            this.layerActions[name] = args.slice(1);
        } else if (head === "deflayermap") {
            const name = Array.isArray(args[0]) ? atom(args[0][0]) : atom(args[0]);
            const map = {};
            for (let j = 1; j + 1 < args.length; j += 2)
                map[atom(args[j])] = args[j + 1];
            this.layers.push(name);
            this.layerActions[name] = { map: map };
        } else if (head === "defalias") {
            for (let j = 0; j + 1 < args.length; j += 2)
                this.aliases[atom(args[j])] = args[j + 1];
        } else if (head === "defchords") {
            const group = [];
            for (let j = 2; j + 1 < args.length; j += 2) {
                const keys = Array.isArray(args[j]) ? args[j].map(atom) : [atom(args[j])];
                group.push({ keys: keys, action: args[j + 1] });
            }
            this.chords[atom(args[0])] = group;
        }
    }
}

// Returns { label, hold } for an action. hold is the tap-hold's hold side,
// shown smaller under the tap label.
Config.prototype.describe = function (node, depth) {
    depth = depth || 0;
    if (depth > 8)
        return { label: "…", hold: "" };

    if (!Array.isArray(node)) {
        const name = node.text;
        if (name === "_" || name === "‗" || name === "≝")
            return { label: "", hold: "", transparent: true };
        if (name === "XX" || name === "✗" || name === "∅" || name === "•")
            return { label: "✗", hold: "", blocked: true };
        if (name.startsWith("@") && this.aliases[name.slice(1)] !== undefined)
            return this.describe(this.aliases[name.slice(1)], depth + 1);
        return { label: prettyKey(name), hold: "" };
    }

    const head = atom(node[0]) || "";
    const args = node.slice(1);

    if (head.startsWith("tap-hold")) {
        // Every tap-hold variant is (name tap-timeout hold-timeout tap hold ...).
        const tap = args[2] ? this.describe(args[2], depth + 1) : { label: "" };
        const hold = args[3] ? this.describe(args[3], depth + 1) : { label: "" };
        return { label: tap.label, hold: hold.label };
    }
    if (head === "layer-switch")
        return { label: "→" + atom(args[0]), hold: "", layer: atom(args[0]) };
    if (head === "layer-toggle" || head === "layer-while-held")
        return { label: atom(args[0]), hold: "", layer: atom(args[0]) };
    if (head === "chord") {
        const group = this.chords[atom(args[0])] || [];
        const key = atom(args[1]);
        const solo = group.find(c => c.keys.length === 1 && c.keys[0] === key);
        return solo ? this.describe(solo.action, depth + 1) : { label: key, hold: "" };
    }
    if (head === "multi")
        return { label: args.map(a => this.describe(a, depth + 1).label).filter(Boolean).join("+"), hold: "" };
    if (head === "unicode")
        return { label: atom(args[0]) || "", hold: "" };
    if (head === "macro" || head.startsWith("macro-"))
        return { label: "macro", hold: "" };
    return { label: head, hold: "" };
};

Config.prototype.actionFor = function (layer, index) {
    const actions = this.layerActions[layer];
    if (!actions)
        return null;
    if (Array.isArray(actions))
        return actions[index] || null;
    const src = this.src[index];
    return src ? (actions.map[src.name] || null) : null;
};

// Only chords spanning keys on this layer are worth listing; those are the
// combos the grid can't show on a single key.
Config.prototype.combosFor = function (layer) {
    const seen = {};
    const combos = [];
    for (let i = 0; i < this.src.length; i++) {
        const action = this.actionFor(layer, i);
        const group = this._chordGroupOf(action, 0);
        if (!group || seen[group])
            continue;
        seen[group] = true;
        for (const c of this.chords[group]) {
            if (c.keys.length < 2)
                continue;
            combos.push({ keys: c.keys.map(prettyKey).join(" + "), label: this.describe(c.action).label });
        }
    }
    return combos;
};

Config.prototype._chordGroupOf = function (node, depth) {
    if (!node || depth > 8)
        return null;
    if (!Array.isArray(node)) {
        const name = node.text;
        if (name.startsWith("@") && this.aliases[name.slice(1)] !== undefined)
            return this._chordGroupOf(this.aliases[name.slice(1)], depth + 1);
        return null;
    }
    return atom(node[0]) === "chord" ? atom(node[1]) : null;
};

function parse(text) {
    const cfg = new Config(parseForms(tokenize(stripComments(text))));
    if (cfg.src.length === 0)
        throw new Error("no defsrc found");

    const rows = [];
    let lastLine = -1;
    cfg.src.forEach((key, i) => {
        if (key.line !== lastLine) {
            rows.push([]);
            lastLine = key.line;
        }
        rows[rows.length - 1].push({ index: i, name: key.name, units: KEY_UNITS[key.name] || 1 });
    });

    const layers = {};
    for (const name of cfg.layers) {
        const keys = cfg.src.map((src, i) => {
            const action = cfg.actionFor(name, i);
            const d = action ? cfg.describe(action) : { label: "", hold: "", transparent: true };
            d.src = prettyKey(src.name);
            return d;
        });
        layers[name] = { keys: keys, combos: cfg.combosFor(name) };
    }

    return { rows: rows, layerNames: cfg.layers, layers: layers };
}
