---
name: rtl-check
description: Check a screen or CSS file for Arabic RTL correctness (logical properties, mirrored icons, bidi isolation of numbers, Arabic font). Use when building or reviewing anything user-facing, and after shooting Arabic screenshots.
---
# RTL check

1. **Code scan** (from the repo root, on the files you touched):
   - `rg -n "(margin|padding|border)-(left|right)|\b(left|right)\s*:|text-align:\s*(left|right)" <paths>`: physical properties are forbidden; use `margin-inline-start`, `inset-inline-end`, `text-align: start`. `pnpm lint:css` enforces this too.
   - `rg -n "translateX|scaleX|rotate" <paths>`: horizontal transforms must account for direction.
   - Direction-bearing icons (chevrons, arrows, back, send) mirror through the icon registry flag (`<Icon>` adds `gz-mirror`); nothing else flips (ADR 0014). Logos, play, checkmarks and phone glyphs do not mirror.
2. **Bidi:** numbers, phones, codes, voucher codes and currency amounts are LTR-isolated inside Arabic text (`<Num>`, `<Phone>`, `<Ltr>`, `<Auto>` from `design/src/i18n`; phone is LTR per ADR 0012). Arabic money is the number then `د.ك` with no trailing period; English `KD`.
3. **Shoot** `pnpm shots --screen <ID> --lang ar --w 390 360` and Read the PNG. Check: start edge is on the right; back arrow points right; tab bar and progress run right to left; carousels and timelines start from the right; text is not truncated (Arabic runs about 1.3x longer); Almarai renders (no fallback face); no clipped diacritics; charts mirror the time axis only (ADR 0014 D5).
4. **Compare** with `--lang en` for layout parity; any element that sits on the same side in both languages is a bug unless intended.
5. Report as a list: file or screen, issue, fix. State what you did not check.
