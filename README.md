# dost

[AnyBar](https://github.com/tonsky/AnyBar), but floating.

dost puts status indicator dots in a transparent, always-on-top window that
you can drag anywhere on screen, instead of pinning them to the menubar. It
speaks the exact same UDP API as AnyBar, so every script, plugin, and
integration that works with AnyBar works with dost unchanged.

## Why

- **Position anywhere** — drag the dots to any corner, any screen. The
  position is remembered across launches.
- **Multiple indicators, one process** — one dost instance hosts any number
  of dots, each on its own UDP port.
- **Stacking** — indicators stack vertically or horizontally.
- **Spacing** — three densities: `cozy`, `regular`, `tight`.
- **Sizes** — three dot sizes: `small`, `medium`, `big`.
- **Always on top** — visible over full-screen apps and on every Space.

## Install

### Homebrew

```sh
brew tap danielfilho/dost https://github.com/danielfilho/dost
brew trust danielfilho/dost   # required on Homebrew 6+
brew install --cask dost
```

The app is not notarized, so macOS will complain the first time you launch
it. Either right-click → Open once, or clear the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/dost.app
```

### From source

Requires macOS 13+ and Xcode command line tools.

```sh
git clone https://github.com/danielfilho/dost.git
cd dost
make install   # builds dost.app and copies it to /Applications
```

Or run the bare binary without installing:

```sh
make run
```

## Usage

Start dost:

```sh
open -a dost                          # single dot on port 1738
open -a dost --args --spacing tight   # pass options through open
dost --ports 1738:build,1739:tests &  # or use the CLI (installed by the cask)
```

Change the dot from anywhere, exactly like AnyBar:

```sh
echo -n "red" | nc -4u -w0 localhost 1738
```

or with plain bash:

```sh
bash -c 'echo -n "green" > /dev/udp/localhost/1738'
```

### Messages

| Message | Result |
|---|---|
| `white` `red` `orange` `yellow` `green` `cyan` `blue` `purple` `black` | colored dot |
| `question` | gray dot with `?` |
| `exclamation` | orange dot with `!` |
| `filled` | dot that follows system appearance (dark in light mode, light in dark mode) |
| `hollow` | outlined dot that follows system appearance |
| `quit` | quits dost |
| anything else | looked up as a custom image (see below) |

### Multiple indicators

Give each indicator its own port, with an optional title:

```sh
dost --ports 1738:build,1739:tests,1740:deploy
```

Hovering a dot shows its title, port, and current style, e.g.
`build — port 1738 — green`.

Dots can also be added and removed at runtime: right-click the dots and use
**Add Dot…** (port plus optional name) or **Remove Dot**. The port list is
persisted across launches; passing `--ports` (or `DOST_PORTS`) replaces it.

Then talk to each one independently:

```sh
echo -n "green"  | nc -4u -w0 localhost 1738   # build ok
echo -n "red"    | nc -4u -w0 localhost 1739   # tests failing
echo -n "yellow" | nc -4u -w0 localhost 1740   # deploy in progress
```

### Stacking, spacing and size

Right-click the dots for a menu with all options, or set them at launch:

```sh
dost --orientation horizontal --spacing tight --size small
```

- **Orientation**: `vertical` (default) or `horizontal`
- **Spacing**: `cozy`, `regular` (default), or `tight`
- **Size**: `small`, `medium`, or `big` (default)

All three are persisted, so they only need to be set once.

### Options

```
-p, --ports LIST       Comma-separated UDP ports, each with an optional
                       :title used as tooltip (default: 1738, persisted)
-o, --orientation DIR  vertical | horizontal (persisted)
-s, --spacing MODE     cozy | regular | tight (persisted)
-z, --size SIZE        small | medium | big (persisted)
    --init NAME        Initial style for every indicator (default: white)
-h, --help
    --version
```

### Environment variables

| Variable | Effect |
|---|---|
| `DOST_PORTS` | same format as `--ports` |
| `DOST_INIT` | same as `--init` |
| `ANYBAR_PORT` | single port, AnyBar drop-in compatibility |
| `ANYBAR_TITLE` | tooltip when running a single indicator |
| `ANYBAR_INIT` | same as `--init` |

### Custom images

Drop `NAME.png` (19×19) and/or `NAME@2x.png` (38×38) into `~/.dost/` and send
`NAME` as the message. `~/.AnyBar/` is also searched, so an existing AnyBar
image collection keeps working as-is.

## License

[MIT](LICENSE)
