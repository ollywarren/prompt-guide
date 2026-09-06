# Prompt guide

An [Omarchy](https://omarchy.org/) shell plugin. A bar icon that opens a panel
of best-practice prompt skeletons: pick a template, edit it in place, copy it.

Your edits are kept per template and survive closing the panel, restarting the
shell, and rebooting. **Reset** puts the shipped template back.

```
󰛨  ->  ┌──────────────────────────────┐
       │ Prompt guide                 │
       │ ROLE, TASK, CONTEXT, FORMAT  │
       │ [General task            ▾]  │
       │ ┌──────────────────────────┐ │
       │ │ # Role                   │ │
       │ │ You are <ROLE>.          │ │
       │ │ ...                      │ │
       │ └──────────────────────────┘ │
       │ [󰆏 Copy]  [󰑐 Reset]  edited  │
       │ ── BEST PRACTICE ──          │
       │ • Give a role and a goal.    │
       │ • State the output format.   │
       └──────────────────────────────┘
```

## Templates

| Template | For |
|---|---|
| General task | Anything: role, task, context, output, done-criteria |
| Code & debugging | Symptom vs expected, repro, environment, what you tried |
| Writing & editing | Audience, purpose, voice, length, what must not change |
| Research & synthesis | A question with scope, sources, and uncertainty handling |
| Data analysis | Data shape, question, method, and how to handle gaps |

`ALL-CAPS <SLOTS>` are the parts you replace. Everything else is scaffolding
worth keeping.

## Install

Already installed if this directory is `~/.config/omarchy/plugins/ollywarren.omarchy-prompt-guide`.
From scratch:

```bash
omarchy plugin add <git-url> --enable --yes
```

By hand:

```bash
git clone <git-url> ~/.config/omarchy/plugins/ollywarren.omarchy-prompt-guide
omarchy-shell shell rescanPlugins
omarchy plugin enable ollywarren.omarchy-prompt-guide right
```

## Using it

**Mouse** — left click opens the panel · right click copies the current prompt
without opening anything · middle click moves to the next template · scroll
cycles templates.

**Keyboard**, once the panel is open:

| Key | Does |
|---|---|
| `c` | Copy the prompt |
| `r` | Reset to the shipped template |
| `e` / `Enter` | Edit (caret goes to the end) |
| `j` / `k` / arrows | Previous / next template |
| `Esc` | Leave the editor; again to close the panel |
| `Ctrl+Enter` | Copy, while editing |
| `Tab` | Move to the neighbouring bar panel |

Bind the panel to a key in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER CTRL", "P", "Prompt guide", "omarchy-shell ollywarren.omarchy-prompt-guide toggle")
```

## IPC

```bash
omarchy-shell ollywarren.omarchy-prompt-guide toggle      # open / close the panel
omarchy-shell ollywarren.omarchy-prompt-guide copy        # copy the current prompt
omarchy-shell ollywarren.omarchy-prompt-guide prompt      # print it instead
omarchy-shell ollywarren.omarchy-prompt-guide current     # id of the selected template
omarchy-shell ollywarren.omarchy-prompt-guide select code # switch template
omarchy-shell ollywarren.omarchy-prompt-guide next        # or: previous
omarchy-shell ollywarren.omarchy-prompt-guide reset       # discard edits to this template
```

`copy` works whether or not the panel is open, so a keybind can put the prompt
on the clipboard without any UI.

## Settings

Per-widget settings live inline on the layout entry in
`~/.config/omarchy/shell.json`, which hot-reloads on save:

```json
{ "id": "ollywarren.omarchy-prompt-guide", "panelWidth": 520, "showTips": false }
```

| Key | Default | What |
|---|---|---|
| `icon` | `󰛨` | Bar glyph |
| `panelWidth` | `420` | Panel width in px |
| `editorHeight` | `200` | Prompt box height in px |
| `showTips` | `true` | Show the best-practice checklist |

Or from the shell: `omarchy bar set ollywarren.omarchy-prompt-guide panelWidth 520`.

## Making it yours

The templates are plain data in [`Templates.js`](Templates.js) — `id`, `label`,
`hint`, `body`, `tips`. Add or rewrite them there.

Drafts are stored per template `id`, so renaming an id orphans its draft rather
than corrupting it; if you rewrite a `body`, any template you have edited keeps
showing your draft until you hit **Reset**.

## Files

| Path | What |
|---|---|
| `manifest.json` | Plugin declaration and settings schema |
| `Panel.qml` | Bar button + popup |
| `Templates.js` | The templates and their checklists |
| `~/.local/state/omarchy/prompt-guide.json` | Your drafts and last selection |

## Hacking

Saving a file under `~/.config/omarchy/plugins/` normally hot-reloads it. If a
change to `Panel.qml` doesn't show up, force it:

```bash
omarchy-shell shell rescanPlugins
omarchy restart shell          # if the widget itself looks stale
omarchy plugin validate ~/.config/omarchy/plugins/ollywarren.omarchy-prompt-guide
```

QML errors land in the shell's log:

```bash
journalctl --user -f | grep omarchy-shell
```

## Licence

MIT — see [LICENSE](LICENSE).
