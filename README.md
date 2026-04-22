# GPS Grade – Hill Gradient Watch App for Garmin Instinct 3 Solar

A real-time GPS-based gradient (hill steepness) display app for the Garmin Instinct 3 Solar watch. Shows signed percent grade with one decimal place, real-time gradient trend graph, and supports four sport profiles (trail, road, cycling, hiking) with independent smoothing and filtering parameters.

## Features

- **GPS-only grade computation**: Uses barometer-free Haversine distance calculation and sliding-window altitude analysis
- **Real-time gradient trend graph**: 50-point rolling history plotted on screen; clamped to ±20% for readability
- **Sport profiles**: Trail (default), Road, Cycling, Hiking — each with tuned thresholds for GPS confidence, speed, and window size
- **Low-confidence suppression**: Displays `--` when GPS accuracy is below threshold or insufficient distance traveled
- **Exponential moving average (EMA) smoothing**: Configurable for both altitude and gradient to reduce noise
- **Dynamic profile switching**: Press Select button to cycle through all four profiles on the fly
- **Debug overlay**: Press Menu button to toggle speed, GPS quality, and window distance display
- **Balanced outlier rejection**: Detects and filters altitude spikes and unrealistic grade jumps

## Requirements

### Hardware
- **Watch**: Garmin Instinct 3 Solar (45mm), model `instinct3solar45mm`
- **GPS enabled** for continuous position updates

### Software
- **Connect IQ SDK 9.1.0** (or compatible version)
  - macOS: `$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b`
- **Java 17+** (e.g., Temurin via Homebrew: `brew install --cask temurin@17`)
- **Developer Key**: `developer_key.der` and `developer_key.pem` (generate via [Garmin Developer](https://developer.garmin.com))

## Setup

### 1. Environment Variables

Add to `~/.zshrc` or `~/.bash_profile`:

```bash
export CIQ_SDK_HOME="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b"
export PATH="$CIQ_SDK_HOME/bin:$PATH"
```

Then reload:
```bash
source ~/.zshrc
```

### 2. Clone/Download the Project

```bash
cd ~/Projects
git clone <repo-url>
cd garmin-hill
```

### 3. Verify Java and SDK

```bash
java -version
monkeyc --version
```

## Build

Compile the app into a `.prg` file:

```bash
monkeyc -f monkey.jungle -o bin/garmin-hill.prg -y developer_key.der
```

Expected output: `BUILD SUCCESSFUL`

## Testing in Simulator

### Launch Simulator

```bash
$CIQ_SDK_HOME/bin/connectiq &
```

Wait for the simulator window to appear with an Instinct 3 Solar device.

### Deploy App to Simulator

```bash
monkeydo bin/garmin-hill.prg instinct3solar45mm
```

The app should launch on the simulated watch face.

### Simulate GPS Navigation

1. In the simulator window, go to **Simulation → Set Navigation Data**
2. Enter starting position (e.g., Latitude: `37.3382`, Longitude: `-121.8863`, Altitude: `100m`, Speed: `1.5 m/s`)
3. Click **OK** — the app receives a GPS update
4. Repeat with nearby coordinates and different altitude to simulate a hill (e.g., +20m altitude over ~200m horizontal = ~10% grade)

**Example hill sequence:**
- Point 1: Lat `37.3382`, Lon `-121.8863`, Alt `100m`, Speed `1.5 m/s`
- Point 2: Lat `37.3400`, Lon `-121.8863`, Alt `120m`, Speed `1.5 m/s`

The app requires at least 25m of accumulated distance before outputting a grade; the graph will draw a rising trend as samples accumulate.

## App Usage

### Screen Layout

- **Top**: Real-time gradient trend graph (rises for uphill, falls for downhill, flat near 0%)
- **Bottom**: Current grade (e.g., `+8.3%`), status line (`GPS grade` or `Low confidence`)

### Button Controls

| Button | Action |
|--------|--------|
| **SELECT** (middle) | Cycle to next sport profile (Trail → Road → Cycling → Hiking) |
| **MENU** (upper-left) | Toggle debug overlay (shows speed, GPS quality, window distance) |

## Configuration

Sport profiles are configured in `source/Constants.mc`:

| Parameter | Trail | Road | Cycling | Hiking |
|-----------|-------|------|---------|--------|
| Min GPS Quality | 2 | 3 | 2 | 2 |
| Min Speed (m/s) | 0.5 | 1.0 | 0.5 | 0.3 |
| Window Distance (m) | 80 | 120 | 150 | 70 |
| Alt Smoothing α | 0.15 | 0.15 | 0.15 | 0.15 |
| Grade Smoothing α | 0.30 | 0.25 | 0.20 | 0.35 |

To adjust: edit `source/Constants.mc`, rebuild, and redeploy.

## Project Structure

```
garmin-hill/
├── README.md                  # This file
├── monkey.jungle              # Build config pointing to manifest
├── manifest.xml               # App metadata, permissions, target device
├── developer_key.der          # Signing key for deployment
├── developer_key.pem          # Signing key (alternate format)
├── source/
│   ├── App.mc                 # UI view, input delegate, gradient graph rendering
│   ├── GradeEngine.mc         # Sliding-window grade computation, EMA smoothing
│   ├── GradientService.mc     # GPS event listener, Haversine distance calculation
│   └── Constants.mc           # Sport profile thresholds and configuration
├── resources/
│   ├── bitmaps.xml            # Icon resource declaration
│   ├── strings/strings.xml    # String resources
│   └── images/icon.png        # App launcher icon
├── bin/
│   ├── garmin-hill.prg        # Compiled app (generated after build)
│   └── default.jungle         # Device definitions (from SDK)
└── .gitignore                 # Ignores bin/ and build artifacts
```

## Known Limitations

- **Barometer-free**: Grade is computed from GPS altitude only; less accurate on devices without post-processing
- **Simulator only simulates discrete points**: Real GPS streams continuous data; simulator requires manual updates
- **Profile persistence**: Selected profile resets on app restart (planned for future release)
- **No always-visible profile label**: Profile name shown only in debug overlay (planned refinement)

## Troubleshooting

### "BUILD SUCCESSFUL" but app won't launch
- Ensure simulator is running: `$CIQ_SDK_HOME/bin/connectiq` in background
- Verify device ID: `instinct3solar45mm` must match simulator device

### App shows `--` (no grade)
- Feed multiple navigation data points with increasing altitude and distance (at least 25m)
- Check debug overlay (MENU) to see GPS quality and speed — they may be below thresholds

### Simulator crashes on deploy
- Check terminal for stack trace; report error line in `source/` file
- Rebuild and redeploy: `monkeyc ... && monkeydo ...`

### Resource compilation error
- Verify `resources/bitmaps.xml` references exist: `resources/images/icon.png`
- Icon should be copied from SDK sample or custom 48×48 PNG

## Building for Device (Advanced)

To sideload onto actual Instinct 3 Solar (requires Connect IQ developer account):

1. Build: `monkeyc -f monkey.jungle -o bin/garmin-hill.prg -y developer_key.der`
2. Connect watch to Garmin Connect app or use Garmin Express
3. Use `monkeydo` or Garmin Connect to install the `.prg` file

(Full device deployment varies by Garmin toolchain version; see [Garmin Developer Docs](https://developer.garmin.com).)

## License

Project-specific — modify and use freely for personal training or hobby use.
