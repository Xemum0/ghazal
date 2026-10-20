# Bundled fonts and licences

All three families are licensed under the SIL Open Font License 1.1 (full texts next to this file). Source: github.com/google/fonts (`ofl/<family>`), downloaded 2026-10-20.

| Flutter family (`fontFamily`) | Web name | Role | Files | Weights | Licence file |
|---|---|---|---|---|---|
| `ElMessiri` | El Messiri | Display (headings, wordmark), Arabic and Latin | `ElMessiri-{Regular,Medium,SemiBold,Bold}.ttf` | 400 500 600 700 | `OFL-ElMessiri.txt` |
| `Manrope` | Manrope | English UI | `Manrope-{Light,Regular,Medium,SemiBold,Bold}.ttf` | 300 400 500 600 700 | `OFL-Manrope.txt` |
| `Almarai` | Almarai | Arabic UI (and Arabic fallback of the Latin families) | `Almarai-{Light,Regular,Bold,ExtraBold}.ttf` | 300 400 700 800 | `OFL-Almarai.txt` |

## Family-name mapping (web to Flutter)

The web tokens say `"El Messiri"`, `"Manrope"`, `"Almarai"` (`--gz-font-display`, `--gz-font-ui`). Flutter family names have no spaces: `ElMessiri`, `Manrope`, `Almarai`. Always set `package: 'ghazal_ui'` on a `TextStyle` that names them (so the engine resolves `packages/ghazal_ui/<Family>`); `GzFonts` holds the names.

## Static instances

Google Fonts ships El Messiri and Manrope as variable fonts (axis `wght`). Flutter picks weights by declared file, so the statics above were cut from the variable files with `fontTools.varLib.instancer` (`wght=<weight> --update-name-table`); Almarai is static upstream (a ExtraBold exists and is bundled). Latin Manrope has no Arabic glyphs: the Arabic UI uses Almarai and Latin runs inside Arabic text fall back to Manrope.
