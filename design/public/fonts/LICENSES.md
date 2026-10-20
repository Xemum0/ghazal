# Font licences

All four families are licensed under the SIL Open Font License 1.1 (OFL-1.1): free to use, embed, self-host and redistribute with the app, including commercially; they may not be sold on their own; the Reserved Font Name rules apply to modified versions (we ship the files unmodified). The full licence text of each family is in `OFL/`.

| Family | Role (docs/design/01-direction.md 2.4) | Weights shipped | Copyright | Licence file |
|---|---|---|---|---|
| Poppins | EN UI | 400, 500, 600 (Latin) | 2020 The Poppins Project Authors (github.com/itfoundry/Poppins) | `OFL/poppins-OFL.txt` |
| Cairo | AR UI, figures (Western digits, both languages), Arabic runs inside English | 400, 500, 600, 700 (Arabic + Latin) | 2009 The Cairo Project Authors (github.com/Gue3bara/Cairo) | `OFL/cairo-OFL.txt` |
| Newsreader | EN display (names, hero price, brief sentence, countdown) | 300, 400 (Latin) | 2020 The Newsreader Project Authors (github.com/productiontype/Newsreader) | `OFL/newsreader-OFL.txt` |
| Amiri | AR display, same moments | 400 (Arabic + Latin) | 2010-2022 The Amiri Project Authors (github.com/aliftype/amiri) | `OFL/amiri-OFL.txt` |

No italics, no slant, no Cairo 300, no Newsreader italic are shipped (ADR 0030).

## Where the files came from

- `woff2/`: the unicode-range subset files of `@fontsource/{poppins,cairo,newsreader,amiri}` 5.3.0, copied out unchanged and renamed `<family>-<subset>-<weight>.woff2`.
- `ttf/`: the static instances published in `@expo-google-fonts/{poppins,cairo,newsreader,amiri}`, copied out unchanged (for the Flutter assets later, ADR 0022 and ADR 0024 item 8: the same family files in `@font-face` and in Flutter).
- Both npm packages were used purely as a download source in a scratch directory; neither is a dependency of this repository.

Re-fetching: `npm i @fontsource/cairo @expo-google-fonts/cairo` in an empty directory, copy the files named above, update the version here.

## Budget (ADR 0016 D7: at most 150 KB per script)

- Arabic script: Cairo arabic x4 (about 55 KB) + Amiri arabic x1 (109 KB) at the very most; a screen loads only the weights it uses (`unicode-range` + `font-display: swap`).
- Latin: Poppins x3 (24 KB), Newsreader x2 (45 KB), Cairo latin x4 (61 KB, digits and figures), Amiri latin (20 KB).
