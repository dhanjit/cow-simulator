# Shipping to Steam

A Godot 4 game, published by a solo developer in India. Every number below is from Valve's own docs or the IRS; where a fact could not be verified from a primary source it is marked as unverified.

---

## Phase 0 — Before you spend money

- [ ] Confirm the game will be a native desktop executable. Windows `.exe` is the practical minimum; macOS/Linux builds are optional and chosen as checkboxes at release time ([platforms](https://partner.steamgames.com/doc/store/application/platforms)).
- [ ] Decide whether you need Steamworks features at all. Valve: "The Steamworks SDK is only required to upload your content to Steam, everything else provided through the SDK is optional." ([SDK](https://partner.steamgames.com/doc/sdk)). A plain Godot binary with zero Steam calls is a valid Steam product.
- [ ] Note that Steam Cloud does **not** need in-game code — Steam Auto-Cloud works "without writing code or modifying the game in any way" ([Cloud](https://partner.steamgames.com/doc/features/cloud)). Achievements, stats, leaderboards, Steam Input and rich presence *do* need GodotSteam.
- [ ] Pick your legal identity now. If you form a company, do it **before** starting the digital paperwork — Valve says so explicitly ([FAQ](https://partner.steamgames.com/doc/gettingstarted/faq)). Otherwise you register as a Sole Proprietorship in your full legal name.
- [ ] Line up three names that must match each other exactly: the legal name on the Steam paperwork, the name on your tax documents, and the account holder name on your bank account ([onboarding](https://partner.steamgames.com/doc/gettingstarted/onboarding)).
- [ ] Have your PAN handy for the W-8BEN foreign-TIN field. *Unverified — check before relying on this:* Valve's docs never name PAN. What is documented is that a foreign TIN is required and that only Slovakia is called out as needing a US TIN instead.
- [ ] Budget the calendar, not just the money. Absolute documented floor from store-page submission to release is about **3 weeks**; with Valve's own recommended padding and one round of review fixes, **4–5 weeks** is realistic.
- [ ] Decide if you want a long Coming Soon runway. Wishlists only accrue while that page is live ([coming soon](https://partner.steamgames.com/doc/store/coming_soon)). The 14-day minimum is a floor, not a plan. Valve publishes no recommended duration.

### Costs

| Item | Amount | Notes |
|---|---|---|
| Steam Direct Fee (per app) | **$100 USD** / **₹8,999** on the India storefront | Per product, not per developer. Three games = $300. [appfee](https://partner.steamgames.com/doc/gettingstarted/appfee) · [store sub](https://store.steampowered.com/sub/163632/) |
| Fee recoupment | Refunded to you after the product hits **$1,000.00 Adjusted Gross Revenue** | Non-refundable otherwise. AGR = gross store revenue for that app, not your net share. Appears as a separate line item on the monthly report. |
| US withholding on royalties | **15%** with a valid W-8BEN + TIN, **30%** without | US–India treaty, Article 12(2)-(4), copyright royalty rate. [IRS Table 1, Rev. May 2023](https://www.irs.gov/pub/irs-lbi/tax-treaty-table-1.pdf) |
| Payout floor | **$100 USD** | Valve may hold payment below this. USD only. |
| Inward SWIFT wire costs | Variable | Valve doesn't charge its own wire fee, but intermediary/receiving bank charges and your bank's FX spread are on you. |
| Godot | Free | Export templates are a ~1.2 GB download per version. |
| GodotSteam | Free | |

Indian-side GST treatment of Steam royalties (export of services, LUT/RFD-11, registration thresholds, FIRC) is **entirely outside Valve's documentation and unverified here** — take it to a CA. Valve collects and remits 18% GST on Indian *consumer* sales itself, inclusive in the listed price ([taxes](https://partner.steamgames.com/doc/finance/taxfaq)).

---

## Phase 1 — Steamworks account, app fee, tax paperwork

You enter Steamworks by logging in with an ordinary Steam account: "Access Steamworks by logging in with your existing Steam account. Don't have a Steam account? Creating one is easy and free!" ([partner](https://partner.steamgames.com/)). No Valve page states any prerequisite beyond that — **no purchase history, no phone number, no email-verification gate**. The widely repeated "$5 spend" figure is Steam's consumer limited-account rule, not a Steamworks gate.

The documented flow on [Steam Direct](https://partner.steamgames.com/steamdirect) is six steps plus release, not four:

- [ ] **1. Sign the digital paperwork** — a Non-Disclosure Agreement and the Steam Distribution Agreement, both signed electronically.
- [ ] **2. Pay the app deposit fee** — any Steam-supported payment method in your country, "excluding Steam wallet funds." You cannot pay from an existing wallet balance. Only users with **Admin** permissions in a partner account can purchase app credits.
- [ ] **3. Complete bank + tax paperwork and identity verification.**
  - [ ] Tax interview: takes 5–10 minutes. As an India-based individual you take the **W-8BEN** path (US persons take W-9).
  - [ ] Enter a foreign TIN so treaty benefits apply. Without a valid TIN you are withheld at the full 30%.
  - [ ] Bank details: routing number, bank account number, bank address. Account holder name must match your onboarding legal name.
  - [ ] Wait 2–7 business days for third-party verification of your tax info. You may be asked for additional documentation.
- [ ] **4. Steamworks access** — you can now create the app and prepare the title.
- [ ] **5. Review** — store page and build, 1–5 days.
- [ ] **6. Timing gates** — the 30-day fee wait and the 2-week Coming Soon page (Phase 6).

### If you need a US TIN

You normally don't — a foreign TIN suffices for India. If you do:

- EIN by **phone**: (267) 941-1099 (not toll-free, international charges apply). Valve states no turnaround time for the phone route.
- EIN by **fax** (Form SS-4): approximately **4 business days**.
- EIN by **mail**: approximately **4 weeks**.
- ITIN: "may take a few months or longer." Obtaining one does not require you to file a US tax return.

Source for all of the above: [Getting Started FAQ](https://partner.steamgames.com/doc/gettingstarted/faq).

### Payouts

- Monthly, **by the 30th of the month following the sales month**. February sales → paid by March 30, plus a few business days to post.
- Outside the US, payment is a **USD SWIFT wire** (ACH is US-only).
- Minimum **$100** payout. You can set a higher self-imposed hold via the "Holding Payment" dropdown in company information settings.
- Non-US partners receive **Form 1042-S** showing US-source income and withholding.
- The 15% withheld is a *cap on US withholding*, not your total tax. You still owe Indian income tax on the royalty; the withheld amount is claimable as foreign tax credit. It applies to US-source revenue only, not your global Steam revenue.

Source: [Payments FAQ](https://partner.steamgames.com/doc/finance/payments_salesreporting/faq) · [Taxes FAQ](https://partner.steamgames.com/doc/finance/taxfaq).

### The 30-day clock

> "A 30-day waiting period between when you paid the app fee and when you can release your game."

This applies to your first few titles. It runs **in parallel** with your store-page work — it is not additive to the 2-week Coming Soon requirement. Pay the fee early. ([onboarding](https://partner.steamgames.com/doc/gettingstarted/onboarding))

---

## Phase 2 — Create the app + store page

- [ ] Create the app in Steamworks. Note your **AppID** and the **DepotIDs** Steam generates (typically AppID+1 for the first depot).
- [ ] Configure depots on the Depots page, split by OS/language if you need to.
- [ ] Define **at least one launch option** in General Installation Settings — "the path and optionally, any arguments required to launch the game." Without this your build is unlaunchable.
- [ ] Fill in the store page: title, description (detailed, coherent, **no external website links** — that is a documented rejection cause), tags, genres, system requirements.
- [ ] Set the release date presentation (see Phase 7 for the granularity trap).
- [ ] Complete the Content Survey (Phase 5) — it is a hard prerequisite for regional ratings.
- [ ] Do not plan on pre-purchase. It "is not a self-served feature and will need to be set up by Valve," Valve doesn't recommend it, and — decisive for you — "We also don't run pre-purchases with partners we haven't worked with in the past." ([release options](https://partner.steamgames.com/doc/store/types))

Two separate checklists exist and are marked "ready for review" independently: **Store Presence** first, then **Game Build**.

---

## Phase 3 — Store assets (exact pixel dimensions)

Every dimension below is read off Valve's live spec pages. Export at exactly these sizes — the rules page requires capsule images to have accurate dimensions.

| Asset | Exact size (px) | Required? | Notes |
|---|---|---|---|
| Header capsule | **920 × 430** | Yes | Store page top, "Recommended For You", Big Picture. Logo must be legible. |
| Small capsule | **462 × 174** | Yes | Steam auto-generates 120×45 and 184×69 from it. Logo "should nearly fill" it; art "does not need to be the same as the other capsules." |
| Main capsule | **1232 × 706** | Yes | Homepage carousel / front-page features. |
| Vertical capsule | **748 × 896** | Yes | Seasonal sale and event pages. |
| Page background | **1438 × 810** | No | The only optional item in the standard store set. |
| Bundle header | **707 × 232** | Only if you make a bundle | |
| Library capsule | **600 × 900** PNG | Yes | 300×450 half-size auto-generated. |
| Library header | **920 × 430** PNG | Yes | Separate upload slot from the store header, same pixels. |
| Library hero | **3840 × 1240** PNG | Yes | 1920×620 half-size auto-generated. **860 × 380 centered safe area** — art extends full width, critical content stays inside. **No text at all, ever.** |
| Library logo | **1280 wide and/or 720 tall** PNG, transparent | Yes | Logotype + optional logomark only. Anchor chosen post-upload: left-bottom, centered top, centered middle, centered bottom. |
| App icon (community) | **184 × 184** JPG | Yes | Won't render on the store page until the app is Coming Soon or released. |
| Shortcut icon (client) | **256 × 256** or **512 × 512**, ICO or PNG | Yes | Valve's overview page lists only 256×256; the detail page lists both. **Export 256×256** — accepted by both. macOS additionally needs an **ICNS** in the separate Mac Icon field, or shortcuts fall back to the generic Steam logo. |
| Screenshots | min **1920 × 1080**, 16:9, **at least 5** | Yes | Gameplay only. |
| Trailer | up to **1920 × 1080** | Yes | See below. |

Sources: [standard assets](https://partner.steamgames.com/doc/store/assets/standard) · [library assets](https://partner.steamgames.com/doc/store/assets/libraryassets) · [community assets](https://partner.steamgames.com/doc/store/assets/community) · [asset rules](https://partner.steamgames.com/doc/store/assets/rules)

### Format notes

Valve documents formats unevenly. **Documented**: App icon is `.jpg`; all four library assets are PNG; Library Logo genuinely must be PNG because transparency is load-bearing. **Not documented**: no format is stated for the store Header, Small, Main, Vertical, Page Background or Bundle Header — the uploader accepts JPG and PNG in practice. **No file-size limits are published anywhere.**

### Content rules (these get you soft-banned from sales, not rejected outright)

Base capsules may contain only three things: **game artwork, the game's name, and any official subtitle.** Prohibited:

- Review scores of any kind, Steam or press
- Award names, symbols, or logos
- Discount marketing copy ("On Sale Now", "Up to 90% off")
- Text or imagery promoting a different product
- Any other miscellaneous text

Per-asset text budget:

| Asset | Text allowed |
|---|---|
| Library Hero | **None. Zero words.** |
| Library Capsule | Game logo + optional subtitle |
| Library Logo | Logotype + optional logomark |
| Store capsules | Name + official subtitle |

Any text you do place "MUST be localized into **at least** the same set of languages supported by the game." Temporary/seasonal text (major updates, events, new DLC) is only permitted via an **Artwork Override**, capped at **one month**, still localized, still no marketing copy. Baking it into the base capsule violates the rules.

Penalty for violations: reduced store visibility and exclusion from official Steam sales and events. In force since **September 1, 2022**.

### Screenshots

- [ ] At least 5, minimum 1920×1080, 16:9.
- [ ] "Exclusively show the gameplay of your game" — no concept art, pre-rendered cinematic stills, awards, marketing copy, or written descriptions.
- [ ] Menu screens are acceptable **only if they represent a unique component of your game**. This is narrower than "UI is fine."
- [ ] Flag **at least 4** as suitable for all ages (no gore, violence, suggestive themes). They are not flagged by default. Games without enough all-ages screenshots may not appear in certain store locations.

### Trailer

Required: "As part of the release process on Steam, you will be required to upload a trailer for your product." Valve strongly recommends the first listed trailer be primarily gameplay, from the perspective the player actually interacts with. Categories: General/Cinematic, Teaser, Gameplay, Interview/Dev Diary.

- Resolution: highest you have, up to **1920×1080**. Use a common resolution (1920×1080 or 1280×720) to avoid processing issues.
- Frame rate: **30 / 29.97 or 60 / 59.94 fps**.
- Bitrate: **5,000+ Kbps**. Containers: `.mov`, `.wmv`, `.mp4`. H.264 video + AAC audio preferred. 16:9 preferred, 4:3 accepted.
- Audio sample rate **must be 44 kHz or 48 kHz** — anything else fails processing. Multichannel gets downmixed to stereo on transcode.
- Valve's recommended export preset: **H.264 Video (20 Mbs) with AAC Stereo Audio (192 Kbps)**.
- Steam auto-generates a **600×380** poster image and a **232×130** thumbnail. A custom thumbnail "must be a frame from the video itself, and must be 1920×1080 .jpg or .png" — a designed/composited thumbnail is rejected.
- **You cannot release your game while a trailer is still converting.** If it hangs, cancel and restart the conversion.

Source: [trailers](https://partner.steamgames.com/doc/store/trailer)

---

## Phase 4 — Export from Godot, upload with SteamPipe

Current stable Godot as of this writing is **4.7.1**, released 14 July 2026 ([download](https://godotengine.org/download/windows/) · [archive](https://godotengine.org/download/archive/4.7.1-stable/)).

### Install Godot

```powershell
# winget — the 4.7.1 manifest is merged
winget install --id GodotEngine.GodotEngine -e --version 4.7.1 --silent --accept-package-agreements --accept-source-agreements

# scoop — lives in extras, not main
scoop bucket add extras
scoop install godot
```

Note on scoop: the manifest renames the console exe to `godot.console.exe` and points the `godot` shim at it (`"bin": [["godot.console.exe", "godot"]]`). So scoop's `godot` on PATH **is** the console binary — the one that actually prints to stdout. That is what you want for CI. The GUI exe is exposed only as a Start Menu shortcut.

For reproducible CI, prefer pinning the exact binary from [godot-builds releases](https://github.com/godotengine/godot-builds/releases) over a package manager.

### Export templates

These are the precompiled per-platform runtimes. Godot does not ship them inside the editor; export fails with "No export template found at the expected path" until installed. They are version-locked to your editor version string.

Measured sizes for 4.7.1:

| Archive | Size |
|---|---|
| `Godot_v4.7.1-stable_export_templates.tpz` | 1221.2 MiB (~1.28 GB) |
| `Godot_v4.7.1-stable_mono_export_templates.tpz` | 1146.1 MiB (~1.20 GB) |

(The .NET archive is *smaller*, not larger.)

- [ ] In-editor: **Editor → Manage Export Templates → Install Selected Templates**.
- [ ] Offline/CI: download the `.tpz` (it's a ZIP) and use the button in the **upper right** of that same dialog to install from file.
- [ ] Install **ICU Data** if your project uses emoji or any of: Burmese, Chinese, Japanese, Korean, Central Khmer, Lao, Thai.

Windows install path: `%APPDATA%\Godot\export_templates\<version>\`, e.g. `...\4.7.1.stable\`. A .NET editor looks in a `.mono`-suffixed directory (`4.7.1.stable.mono`). For CI you can skip the GUI: unzip the `.tpz` and drop its contents into that directory, renaming the extracted folder to the exact version string. ([exporting projects](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html))

*Unverified — check before relying on this:* the Linux template path `~/.local/share/godot/export_templates/<version>/` is convention, not documented.

### Export presets

`export_presets.cfg` uses numbered sections. Each `[preset.N]` has a `name=` and a `platform=`, followed by a matching `[preset.N.options]`:

```ini
[preset.0]
name="Windows Desktop"
platform="Windows Desktop"
runnable=true
export_path="builds/windows/game.exe"

[preset.0.options]

[preset.1]
name="Linux"
platform="Linux"
runnable=true
export_path="builds/linux/game.x86_64"

[preset.1.options]
```

`--export-release` matches the **`name`**, not the `platform`. The `name` field is free text — read the actual values out of your own file rather than trusting any tutorial.

The Linux `platform` value was renamed from `"Linux/X11"` to `"Linux"` in Godot 4.3 ([issue #89012](https://github.com/godotengine/godot/issues/89012)). Presets made in 4.2 or earlier error with `!preset.is_valid()`. The `name` key is **not** auto-migrated, so an old config can still carry `name="Linux/X11"`. Godot's own command-line docs still show `"Linux/X11"` in their example — the docs are themselves the stale tutorial.

### Headless export

```powershell
# Target directories must exist FIRST
New-Item -ItemType Directory -Force builds\windows
New-Item -ItemType Directory -Force builds\linux

godot --headless --path C:\path\to\project --export-release "Windows Desktop" builds/windows/game.exe
godot --headless --path C:\path\to\project --export-release "Linux" builds/linux/game.x86_64
```

Flag semantics, verbatim from [the command line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html):

- `--headless` — "Enable headless mode (`--display-driver headless --audio-driver Dummy`). Useful for servers and with `--script`."
- `--export-release <preset> <path>` — "The preset name should match one defined in `export_presets.cfg`. `<path>` should be absolute or relative to the project directory, and include the filename for the binary (e.g. `builds/game.exe`). The target directory must exist."
- `--export-debug` — same but debug template. Implies `--import`.
- `--export-pack` — exports only the game pack; `<path>` extension picks PCK or ZIP. Implies `--import`.
- `--path <directory>` — directory must contain `project.godot`.

Two gotchas, both documented:

1. **The target directory must exist.** Create it before invoking, or the export fails.
2. **Relative paths resolve against the project directory, not your shell's cwd.** Verbatim: "the path will be relative to the directory containing the `project.godot` file, not relative to the current working directory."

### GodotSteam (optional)

Skip this for a first release if you don't need achievements — adding it later is a plugin drop-in, not a re-architecture.

Current release: **4.20.1**, 16 July 2026, bundling **Steamworks SDK 1.64** (README states 1.63 or newer as the floor). Source and releases live on [Codeberg](https://codeberg.org/godotsteam/godotsteam/releases); GitHub still mirrors.

- `v4.20.1` — module / custom-build editors, targeting Godot 4.7.1, 4.7, 4.6.3, 4.6.2 and 4.5.2. Android ARM64 module updates are **temporarily paused**.
- `v4.20.1-gde` — the GDExtension. "Works on any Godot version 4.4 and up."

Use the **GDExtension** unless you need engine-level changes. Two hard constraints:

- GDExtension and module versions are **not compatible** — pick one.
- When exporting with the GDExtension you must use the **normal Godot export templates**, not GodotSteam templates.

Install ([asset 2445](https://godotengine.org/asset-library/asset/2445)): drop the contents of the zip into the base of your project. "It does not require enabling but you may need to restart your editor." Enabling the plugin in Project Settings only shows the Steamworks dock and "has no effect on functionality." Ignore the deprecated "GDExtension 4.0" and "4.1 – 4.3" Asset Library listings.

### Steam overlay caveat (test this early)

The Steam overlay does not render, or flickers, with Godot's Vulkan renderers (Forward+/Mobile) when the build runs from the editor or standalone outside Steam. It renders correctly once the Forward+ build is **launched by the Steam client itself**, because Steam injects the overlay at process boot. Root cause is Godot's rendering side, not GodotSteam — the GodotSteam maintainer states it is not fixable there.

Status of the trackers, so you don't chase them: [godot#73532](https://github.com/godotengine/godot/issues/73532) is closed as not planned and archived; godot#84251 is closed; GodotSteam #836 is closed. Only [GodotSteam #839](https://codeberg.org/godotsteam/godotsteam/issues/839) (Wayland) is open, and Wayland is the worst case — the overlay never appears there in any launch scenario, including via the Steam client. Under X11 it works only when launched through Steam.

Workarounds:
- [ ] Switch the renderer to **Compatibility (OpenGL)** — renders the overlay reliably.
- [ ] Or test the real launch path: put a throwaway build on Steam and launch it from the client before you commit to Forward+.
- [ ] Adding the build as a **Non-Steam App** will show an overlay but it isn't tied to your AppID, so achievements and store artwork won't appear — a poor test for achievement UI.

*Unverified:* GPU driver rollback as an overlay fix is folklore; not corroborated on either tracker.

### SteamPipe: what you need

From [uploading](https://partner.steamgames.com/doc/sdk/uploading):

- [ ] A Steam account in your Steamworks account with **Edit App Metadata** and **Publish App Changes To Steam**. Use a dedicated build account, not your personal one.
- [ ] For a **released** app, that account needs either a phone number or the Steam Mobile App attached. And: after **any** account security change (email, phone), you must wait **3 days** before you can set a build live for a released app.
- [ ] At least one launch option defined.
- [ ] Depots configured.
- [ ] The SDK, downloaded from [partner downloads](https://partner.steamgames.com/downloads/list) (login-gated). Current SDK is **1.65**, ~24 July 2026 — a hardware/telemetry API release with no SteamPipe, ContentBuilder or steamcmd changes.

SDK top level: `glmgr`, `public/steam`, `redistributable_bin`, `steamworksexample`, `tools`. SteamPipe is under `tools/ContentBuilder/`:

```
tools/ContentBuilder/
  builder/        steamcmd.exe (Windows)
  builder_linux/  steamcmd for Linux
  builder_osx/    steamcmd for macOS
  content/        your game files
  output/         build logs, chunk cache, intermediates (safe to delete; next upload is slower)
  scripts/        your .vdf build scripts
```

### App build script

`tools/ContentBuilder/scripts/app_build_480.vdf` — replace the IDs with your own:

```vdf
"AppBuild"
{
	"AppID" "480"
	"Desc" "v0.1.0 first upload"
	"Preview" "0"
	"SetLive" ""
	"ContentRoot" "..\content\"
	"BuildOutput" "..\output\"

	"Depots"
	{
		"481" "depot_build_481.vdf"
	}
}
```

`ContentRoot` and `BuildOutput` resolve relative to the **script file's** location. Use **single** backslashes — doubled backslashes in scraped docs are a rendering artifact. Optional keys: `Preview "1"` does a dry run and uploads nothing; `Local "..\..\ContentServer\htdocs"` puts content on a local content server; `SetLive "<branch>"` sets the build live on a **beta** branch (never `default` — see below).

### Depot build script

`tools/ContentBuilder/scripts/depot_build_481.vdf`. Note the root key is **`DepotBuildConfig`**, not `DepotBuild` — Valve's own doc page renders it truncated when scraped, but every shipped SDK sample file uses `DepotBuildConfig`. If your build fails to parse, check this first.

Simple whole-folder case:

```vdf
"DepotBuildConfig"
{
	"DepotID" "481"

	"FileMapping"
	{
		"LocalPath" "*"
		"DepotPath" "."
		"recursive" "1"
	}

	"FileExclusion" "*.pdb"
	"FileExclusion" "*.debug"
}
```

Fuller example with subdirectory mapping, exclusions, an install script, and file properties:

```vdf
"DepotBuildConfig"
{
	"DepotID" "482"
	"ContentRoot" "C:\content\depot482"

	"FileMapping"
	{
		"LocalPath" "bin\*"
		"DepotPath" "executables\"
		"Recursive" "1"
	}

	"FileMapping"
	{
		"LocalPath" "localization\german\audio\*"
		"DepotPath" "audio\"
	}

	"FileMapping"
	{
		"LocalPath" "localization\german\german_installscript.vdf"
		"DepotPath" "."
	}

	"FileExclusion" "bin\server.exe"
	"FileExclusion" "*.pdb"
	"FileExclusion" "bin\tools*"

	"InstallScript" "localization\german\german_installscript.vdf"

	"FileProperties"
	{
		"LocalPath" "bin\setup.cfg"
		"Attributes" "userconfig"
	}
}
```

The third `FileMapping` is the one people drop: it maps the install script into the depot root so the `InstallScript` key has something to point at. Without it, `InstallScript` references a file that was never uploaded.

`FileExclusion` supports `?` and `*` wildcards. `DepotPath "."` is the depot install root. `Attributes` accepts `userconfig` and `versionedconfig` (the latter is overwritten locally when the user's game updates). A `ContentRoot` here overrides the app script's; omit it to inherit.

Key names are case-insensitive in practice — Valve's own samples mix `"recursive"` and `"Recursive"` for the same key — but match the SDK's capitalization anyway.

### Upload

```powershell
# Run from the ContentBuilder root
tools\ContentBuilder\builder\steamcmd.exe +login <build_account> <password> +run_app_build ..\scripts\app_build_480.vdf +quit
```

The `..\scripts\` path is relative to the `builder\` directory where `steamcmd.exe` lives. Linux/macOS swaps `builder\` for `builder_linux/` or `builder_osx/` and uses `./steamcmd.sh` with forward slashes.

`+run_app_build_http` also exists — steamcmd's own help lists it as "alias for run_app_build". It works, but `+run_app_build` is the only Valve-documented form; prefer it.

### Steam Guard on a fresh machine

Login fails with "Account Login Denied". Check the build account's email for the Steam Support code, then at the steamcmd prompt:

```
set_steam_guard_code <code>
Steam>login <build_account> <password>
```

After that the machine is remembered.

### CI login

Valve's documented method is the only one Valve blesses: log in once interactively, then preserve `<Steam>\config\config.vdf` between runs. Verbatim: "Be sure that the config file stored in `<Steam>\config\config.vdf` is saved and preserved between runs, as this file may be updated after a successful login." And the trap: "**NOTE: If you do login again and provide your password, a new SteamGuard token will be issued and required to login.**" That is the number-one cause of a CI pipeline breaking right after a manual local upload.

Subsequent runs need no password:

```bash
steamcmd.exe +login <build_account> +run_app_build ..\scripts\app_build_480.vdf +quit
```

For GitHub Actions, [game-ci/steam-deploy](https://github.com/game-ci/steam-deploy) exposes two paths. Its README puts **TOTP first** ("Recommended if you have access to the shared secret") and describes the config.vdf route as "an alternative method requiring a one-time setup"; `configVdf` is documented as "required if totp not used". Note that is game-ci's recommendation — Valve documents only the config.vdf method. To produce the secret:

```bash
steamcmd +login <username> <password> +quit   # enter the emailed MFA code
steamcmd +login <username> +quit              # verify passwordless login works
cat config/config.vdf | base64 > config_base64.txt
```

Store the result as a repo secret and pass it as `configVdf`. Other inputs: `username`, `password`, `totp`, `appId`, `buildDescription`, `rootPath`, `depot[X]Path`, `firstDepotIdOverride`, `releaseBranch`, `debugBranch`. `config.vdf` sits at `config/config.vdf` on Windows/Linux and `~/Library/Application Support/Steam/config/config.vdf` on macOS. `ssfn` files are no longer part of the flow.

### Branches

A build uploads to depots but is **not live** until assigned to a branch.

- `default` is what customers download. Pre-release, it's what testers get by default.
- Beta branches are named branches you create in App Admin, optionally password-protected. With a password, players must enter it before they can even see the branch name.
- Players opt in via right-click game → Properties → the "Game Versions & Betas" tab (the shipping client often labels it just "Betas").

**You cannot set a build live on `default` from a script.** Valve: "When uploading your content you can not set the build live on the default branch automatically." `SetLive` only targets beta branches. There is no such thing as a "default beta branch."

The working loop:

1. Upload with `"SetLive" "<yourbeta>"` → live on that beta immediately.
2. Verify by installing from the beta branch.
3. Open `https://partner.steamgames.com/apps/builds/<AppID>`, select the same build, choose `default` in the dropdown, click **Set Build Live Now**, and publish the change in App Admin.

Source: [branches](https://partner.steamgames.com/doc/store/application/branches)

There is also a **SteamPipeGUI** (`SteamPipeGUI.zip` in the SDK's `tools` folder, Windows only) that generates the same VDF files. Fine for a first manual upload; it has no CI story.

---

## Phase 5 — Content survey and age rating

Mandatory, and completed **before** store page and build submission. Three sections ([content survey](https://partner.steamgames.com/doc/gettingstarted/contentsurvey)):

- [ ] **General Content** — topics present in the game. This is what generates the regional-board ratings shown on your store page.
- [ ] **Mature Content** — violence, sexual content, etc. Drives content-preference filtering.
- [ ] **Generative Artificial Intelligence Content** — disclosure of AI-generated content.

Hard rules:

- [ ] Disclose "all the adult content you've uploaded in your builds, **even if it's not accessible or presented in your product**." Cut content, debug-locked content and unused assets sitting in a depot all count. Common cause of failed review.
- [ ] You do **not** need an official ESRB, PEGI or USK rating. "If you already have ratings issued for your game directly by official rating board authorities, you may enter those" — otherwise Valve issues one from your survey answers.

### Age gates

Two independent mechanisms ([age gate](https://partner.steamgames.com/doc/store/age_gate)):

1. **Content preferences** — "if your product has content descriptors that the user has indicated they do not want to see (**including defaults**), they will be presented with a warning." The defaults clause means users who never set a preference still get gated. Flows from your Mature Content answers.
2. **Regional board ratings** — entering an ESRB/PEGI rating exposes a checkbox in the same place, which enables a hard age-gate requiring login and age confirmation. Opt-in.

### Territory-specific

| Territory | Status |
|---|---|
| **Germany** | Rating mandatory since **2024-11-15**: "Steam will no longer display games to customers in Germany if the game is missing a valid age rating." USK rating not required — Valve self-issues: "Steam will issue an appropriate rating for your game in Germany as soon as you have submitted the questionnaire," unless conflicting info from its content-review teams or community feedback. Existing owners keep access. Content that is illegal in Germany can still leave the game unavailable there. [Germany page](https://partner.steamgames.com/doc/gettingstarted/contentsurvey/germany) |
| **Indonesia** | Rating required — "games must have an age rating in order to be offered to Indonesian customers on Steam" — but enforcement **has not started**: "In the near future, Steam may no longer be able to display games..." No date given. IGRS or Valve self-rating. Tiers: 3+, 7+, 13+, 15+, 18+, Refused Classification. [Indonesia page](https://partner.steamgames.com/doc/gettingstarted/contentsurvey/indonesia) |
| **Brazil** | *Unverified — check before relying on this.* Widely reported as covered by the same Nov 2024 mandate, but there is no Brazil page under `/contentsurvey` (only Germany and Indonesia) and the Steamworks announcement body could not be read. Check the ratings healthcheck in your own dashboard. |
| **Korea** | No Steamworks-documented GRAC requirement and no Korea page. Steam is not an IARC storefront (Steam appears nowhere on [the IARC storefront list](https://globalratings.com/storefronts/)), so Valve runs its own self-rating instead. Korean law does impose obligations on domestic distribution; Valve does not enforce them at the Steamworks level. This is an argument from documented absence — weaker than a positive statement. |

Both the Germany and Indonesia pages carry the same blocking precondition: "Your game cannot receive a content review rating from Valve if you have not filled in the game's content survey." **The survey is a hard gate on regional visibility**, not just metadata.

---

## Phase 6 — Coming Soon page and the 14-day rule

> "For new products, you must have a Coming Soon page up for at least two weeks before releasing."

The clock starts when the page is **approved and live**, not when you submit it. Real lead time = review turnaround + 14 days. ([coming soon](https://partner.steamgames.com/doc/store/coming_soon) · [releasing](https://partner.steamgames.com/doc/store/releasing))

- [ ] No Early Access exemption: "you will still need to have a Coming Soon page up for at least two weeks before your product will be **playable** on Steam." Note "playable", not "released."
- [ ] Minimum contents: "a set of branding images, written description, and ideally a gameplay trailer." Everything in the **Your Store Presence** checklist section must be complete before the page can post. "Ideally" is Valve's own hedge on the trailer — what reviewers actually enforce is not documented.
- [ ] Submit for review **at least 7 business days** before you want it live — that's ~9–11 calendar days, not 7.
- [ ] Wishlists only accrue while the page is live. A page up for the bare 14 days collects 14 days of wishlists.

---

## Phase 7 — Review and release day

### Two separate reviews

| Review | Turnaround |
|---|---|
| Store presence | "typically takes 3-5 business days" |
| Game build | Same 3–5 business day baseline (implied — Valve's page says "Adult Content store pages **and builds** can take longer than the typical 3-5 business days") |

Build review can run **during** the 14-day Coming Soon window, so it is usually not additive to the critical path. Adult-content pages and builds explicitly exceed the window. 3–5 days is a typical, never an SLA — it stretches around Steam sales, Next Fest and holidays.

Each submission is one round. Valve either "will send you any feedback if necessary, or if none is necessary, we'll mark your store page as 'Ready for release'." **No round count is documented anywhere**, and no re-review turnaround. The gap between the 3–5 day actual and the 7-business-day recommended padding exists "to account for potential changes you'll need to make" — budget for one corrective round.

*Unverified:* the term "Review Notes" is not defined on any Steamworks page and no doc names where feedback renders in the admin UI. In practice it lands against the checklist and by email to the submitting account.

### Documented rejection causes

- [ ] Screenshots, trailers or listed features containing content that is incomplete or planned — "You will need to remove" them.
- [ ] Capsule images without "a readable product title or logo."
- [ ] Screenshots that aren't gameplay — concept art, pre-rendered cinematic stills, awards, marketing copy, written product descriptions.
- [ ] A description that isn't detailed and coherent.
- [ ] External website links in the description.

Source: [review process](https://partner.steamgames.com/doc/store/review_process)

### Release date mechanics

Five display granularities, and Steam sorts by the **last possible day** of whatever window you pick ([release dates](https://partner.steamgames.com/doc/store/release_dates)):

| You choose | Displays | Sorts as |
|---|---|---|
| Exact date | "Aug 24, 2023" | that day |
| Month and year | "August 2023" | last day of August |
| Quarter | "Q3 2023" | last day of Q3 |
| Year | "2023" | last day of the year |
| No date | "Coming Soon" | behind everything more specific |

Narrowing the window is a free visibility win on upcoming-release lists. The date picker hides weekends by default because "the Steam Team is unavailable to assist with any issues that might arise" — review-approved games can override.

- **You can change the date freely** up until the lock. "It's fine to change your release date-- plans change, delays happen, and you control the timing of your release on Steam." The requirement is accuracy, not immovability.
- **The lock**: "Once your Coming Soon Page is live **and** your release date is within 14 days, you will be unable to change your release date without contacting us." Note the lock is conditioned on the page being live, not on the date alone. Steam sends advance notice before it activates. Entering the 14-day window is what earns placement on upcoming-release lists — that visibility is why it freezes.

### Release day

- [ ] Confirm no trailer is still converting — that blocks release.
- [ ] Confirm the build you want is set live on `default` in App Admin, and the change is published.
- [ ] Confirm your account has both **"Publish app changes to Steam"** and **"Manage pricing and discounts"**. Missing either produces an error at the release click.
- [ ] Click the green **Release App** button, then confirm **Publish Now**.

> "Approved titles will not release themselves -- you need to use these controls yourself at the moment you wish your product to be released."

Source: [releasing](https://partner.steamgames.com/doc/store/releasing)

---

## Phase 8 — After launch

- [ ] Watch for the **$1,000 Adjusted Gross Revenue** mark — that's when the $100 fee is recouped, shown as a separate line item on the monthly report. Note that recoupment and revenue payment can be withheld "if deposit payment is charged-back, refunded, or otherwise identified as fraudulent."
- [ ] First payout lands by the **30th of the month after** your first sales month, assuming you cleared the $100 minimum. Then a few business days for the SWIFT wire to post.
- [ ] Reconcile your Form 1042-S against what you claim as foreign tax credit in your Indian return.
- [ ] Remember the **3-day lockout**: any security change on the build account (email, phone) blocks setting a build live for a released app for 72 hours. Don't rotate credentials the week of a patch.
- [ ] Don't bake update or seasonal text into base capsules. Use **Artwork Overrides**, one month maximum, localized.
- [ ] Adding GodotSteam post-launch is a plugin drop-in — but you must pick GDExtension *or* module (they're incompatible) and, with GDExtension, keep using normal Godot export templates.
- [ ] Re-check the `/contentsurvey` sub-page list before any re-launch or major update. Regional rating mandates have expanded more than once (Germany 2024-11-15; Indonesia pending).

---

## Things that will bite you

1. **Two unrelated 14-day rules.** (a) The Coming Soon page must be live 14+ days before release. (b) The release date locks 14 days before the date you set. They are independent and both bite. Don't conflate them.
2. **"7 days" is 7 *business* days.** Valve's padding advice is ~9–11 calendar days. Feed that into your launch math.
3. **Name mismatch stalls payouts.** Legal name on onboarding, name on tax documents, and bank account holder name must all match exactly. Classic cause of a stuck first payment.
4. **A password login kills your CI token.** Re-entering the password issues a new SteamGuard token and invalidates the preserved `config.vdf`. Do one manual local upload after setting up CI and you've broken the pipeline.
5. **`DepotBuildConfig`, not `DepotBuild`.** Valve's doc page renders the root key truncated when scraped. The shipped SDK samples are authoritative.
6. **The export target directory must exist**, and relative export paths resolve against the project dir, not your shell's cwd. Both silently fail otherwise.
7. **The Linux preset rename.** `platform` went `"Linux/X11"` → `"Linux"` in Godot 4.3, and `name` is *not* migrated. Godot's own docs still print the old value in their example.
8. **Steam overlay + Forward+ outside Steam.** Looks broken in the editor and standalone; works when launched by the Steam client. Wayland is broken in every scenario. Test the real launch path before you commit.
9. **App Icon alpha becomes solid black** if Steam generates it from your Shortcut Icon. Upload a purpose-made 184×184 JPG. Meanwhile the Library Logo *must* have true transparency. Opposite requirements, adjacent slots.
10. **The Library Hero takes zero words.** Not "minimal text" — none. A tagline there is a guaranteed rejection.
11. **Trailer audio at 44.1/48 kHz only.** Anything else fails processing, and you cannot release while a trailer is converting.
12. **Undisclosed content in your depots.** You must declare adult content sitting in uploaded builds even if it is unreachable in-game.
13. **Pre-purchase is off the table for you.** Not just discouraged — "We also don't run pre-purchases with partners we haven't worked with in the past."
14. **GDExtension ≠ module.** Incompatible. And with GDExtension you must export with normal Godot templates, not GodotSteam ones.
15. **Only Admin-permission users can buy app credits.** If someone else is paying the fee, they need Admin on the partner account.
16. **A missing content survey blocks German (and eventually Indonesian) visibility entirely** — Valve cannot issue a rating without it.
17. **Asset-rule violations are quiet.** Your page can go live and still be excluded from sales and events. In force since 2022-09-01.

---

*Researched 2026-07-26 against live Valve, Godot, GodotSteam and IRS sources. Steamworks documentation pages carry no last-modified dates and Valve revises them without changelogs — the August 2024 capsule-size change and the November 2024 Germany rating mandate are both precedents. Re-check [partner.steamgames.com/doc](https://partner.steamgames.com/doc/home) before a production export or a launch date commitment.*