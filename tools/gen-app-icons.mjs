#!/usr/bin/env node
// App icons and native launch screens of the two apps, drawn from the brand doorway (the Majlis doorway with the lamp, direction 11).
//   node tools/gen-app-icons.mjs [--only client|provider]
// Client: gold linework on Ink. Partner: ink linework on Soft Rose, so the two icons sit apart on a home screen while staying inside the
// three brand colours. The mark is vector: Chrome (playwright-core of design/) rasterises it at every size; ImageMagick only removes alpha
// where the App Store forbids it. Writes (and overwrites):
//   ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png (sizes from its Contents.json, opaque), LaunchImage*.png, the storyboard colour
//   android/app/src/main/res: mipmap-*/ic_launcher.png (legacy rounded), drawable-*/ic_launcher_foreground.png and _monochrome.png
//     (adaptive, Android 8+ and the themed icon of 13+), mipmap-anydpi-v26/ic_launcher.xml, values/colors.xml, drawable/launch_background.xml
//     (+ drawable-v21), drawable-*/launch_mark.png, values-v31/styles.xml (the Android 12 system splash)
import { createRequire } from 'node:module'
import { execFileSync } from 'node:child_process'
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const { chromium } = createRequire(join(root, 'design/package.json'))('playwright-core')

const INK = '#2E2528', GOLD = '#D8B26E', ROSE = '#F8E7EC', PAPER = '#FFF9F5', INK_SOFT = '#3F3337'
const APPS = {
  client: { dir: 'apps/client_app', bg: INK, line: GOLD, lamp: GOLD, halo: GOLD, haloOpacity: 0.5, splashLine: INK, splashLamp: GOLD },
  provider: { dir: 'apps/provider_app', bg: ROSE, line: INK, lamp: GOLD, halo: INK, haloOpacity: 0.28, splashLine: INK, splashLamp: GOLD },
}
const only = process.argv.includes('--only') ? process.argv[process.argv.indexOf('--only') + 1] : null

/** The doorway in a 1024 box. `scale` is px per drawing unit (the doorway spans x 14..106, y 22..104 of its 120 unit grid). */
function art({ line, lamp, halo, haloOpacity, scale, sw = 1 }) {
  const s = scale
  const tx = 512 - 60 * s, ty = 512 - 63 * s
  const w = (u) => (u * sw).toFixed(2)
  return `<g transform="translate(${tx.toFixed(1)} ${ty.toFixed(1)}) scale(${s})" fill="none" stroke-linecap="round" stroke-linejoin="round">
    <path d="M26 104V56A34 34 0 0 1 94 56V104" stroke="${line}" stroke-width="${w(1.7)}"/>
    <path d="M40 104V58A20 20 0 0 1 80 58V104" stroke="${line}" stroke-width="${w(1.2)}" stroke-opacity="0.62"/>
    <path d="M20 56H32M88 56H100" stroke="${line}" stroke-width="${w(1.2)}"/>
    <path d="M60 38V47" stroke="${line}" stroke-width="${w(1.2)}"/>
    <circle cx="60" cy="52" r="6.6" stroke="${halo}" stroke-opacity="${haloOpacity}" stroke-width="${w(0.9)}"/>
    <circle cx="60" cy="52" r="4.5" fill="${lamp}" stroke="none"/>
    <path d="M14 104H106" stroke="${line}" stroke-width="${w(1.5)}"/>
  </g>`
}

const svg = (px, body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${px}" height="${px}" viewBox="0 0 1024 1024">${body}</svg>`

const browser = await chromium.launch({ channel: 'chrome', headless: true })
const page = await browser.newPage({ deviceScaleFactor: 1 })
async function render(file, px, body, { transparent = false } = {}) {
  mkdirSync(dirname(file), { recursive: true })
  await page.setViewportSize({ width: px, height: px })
  await page.setContent(`<html><body style="margin:0;background:transparent">${svg(px, body)}</body></html>`)
  await page.screenshot({ path: file, omitBackground: transparent, clip: { x: 0, y: 0, width: px, height: px } })
}
const magick = (...args) => execFileSync('magick', args, { stdio: 'pipe' })

try {
  for (const [name, a] of Object.entries(APPS)) {
    if (only && only !== name) continue
    const base = join(root, a.dir)
    const bgRect = `<rect width="1024" height="1024" fill="${a.bg}"/>`
    const iconBody = bgRect + art({ ...a, scale: 6.5, sw: 1.3 })

    // ---- iOS app icon (opaque squares; iOS applies the mask)
    const iconset = join(base, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    const contents = JSON.parse(readFileSync(join(iconset, 'Contents.json'), 'utf8'))
    for (const im of contents.images) {
      const px = Math.round(parseFloat(im.size) * parseInt(im.scale))
      const file = join(iconset, im.filename)
      await render(file, px, iconBody)
      magick(file, '-alpha', 'off', file)
    }

    // ---- iOS launch image (the mark on paper: the storyboard paints the paper, the image is transparent)
    const launchSet = join(base, 'ios/Runner/Assets.xcassets/LaunchImage.imageset')
    const markBody = art({ line: a.splashLine, lamp: a.splashLamp, halo: a.splashLine, haloOpacity: 0.3, scale: 10.4 })
    for (const [suffix, px] of [['', 96], ['@2x', 192], ['@3x', 288]]) await render(join(launchSet, `LaunchImage${suffix}.png`), px, markBody, { transparent: true })
    const sb = join(base, 'ios/Runner/Base.lproj/LaunchScreen.storyboard')
    let story = readFileSync(sb, 'utf8')
    story = story.replace(/<color key="backgroundColor" red="[\d.]+" green="[\d.]+" blue="[\d.]+" alpha="1" colorSpace="custom" customColorSpace="sRGB"\/>/, '<color key="backgroundColor" red="1" green="0.97647" blue="0.96078" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>')
    story = story.replace(/<image name="LaunchImage" width="\d+" height="\d+"\/>/, '<image name="LaunchImage" width="96" height="96"/>')
    writeFileSync(sb, story)

    // ---- Android
    const res = join(base, 'android/app/src/main/res')
    const dens = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 }
    for (const [d, k] of Object.entries(dens)) {
      // legacy launcher icon: rounded square with transparent corners (Android 7 and older)
      const rounded = `<rect width="1024" height="1024" rx="226" fill="${a.bg}"/>` + art({ ...a, scale: 6.3, sw: 1.3 })
      await render(join(res, `mipmap-${d}/ic_launcher.png`), Math.round(48 * k), rounded, { transparent: true })
      // adaptive foreground: 108 dp canvas, the mark inside the 66 dp safe circle
      await render(join(res, `drawable-${d}/ic_launcher_foreground.png`), Math.round(108 * k), art({ ...a, scale: 4.8, sw: 1.3 }), { transparent: true })
      // themed (monochrome) icon of Android 13: one colour, the lamp as a filled disc
      await render(join(res, `drawable-${d}/ic_launcher_monochrome.png`), Math.round(108 * k), art({ line: '#000', lamp: '#000', halo: '#000', haloOpacity: 0.6, scale: 4.8, sw: 1.3 }), { transparent: true })
      // launch mark of the pre-12 window background
      await render(join(res, `drawable-${d}/launch_mark.png`), Math.round(96 * k), markBody, { transparent: true })
    }
    // Android 12 system splash icon: 288 dp canvas, the glyph inside the central 192 dp circle
    await render(join(res, 'drawable-nodpi/splash_icon.png'), 864, art({ line: a.splashLine, lamp: a.splashLamp, halo: a.splashLine, haloOpacity: 0.3, scale: 5.6 }), { transparent: true })
    mkdirSync(join(res, 'mipmap-anydpi-v26'), { recursive: true })
    writeFileSync(join(res, 'mipmap-anydpi-v26/ic_launcher.xml'), `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
`)
    writeFileSync(join(res, 'values/colors.xml'), `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">${a.bg}</color>
    <color name="gz_paper">${PAPER}</color>
</resources>
`)
    const launchXml = `<?xml version="1.0" encoding="utf-8"?>
<!-- The native launch screen: Paper with the doorway mark; Flutter draws over it at the first frame. -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/gz_paper" />
    <item>
        <bitmap android:gravity="center" android:src="@drawable/launch_mark" />
    </item>
</layer-list>
`
    writeFileSync(join(res, 'drawable/launch_background.xml'), launchXml)
    writeFileSync(join(res, 'drawable-v21/launch_background.xml'), launchXml)
    mkdirSync(join(res, 'values-v31'), { recursive: true })
    writeFileSync(join(res, 'values-v31/styles.xml'), `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/gz_paper</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_icon</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
`)
    // the dark-mode launch theme must keep the same Paper launch screen (the apps are light only)
    const night = join(res, 'values-night/styles.xml')
    let nightXml = readFileSync(night, 'utf8')
    nightXml = nightXml.replace(/Theme\.Black\.NoTitleBar/g, 'Theme.Light.NoTitleBar')
    writeFileSync(night, nightXml)
    console.log(`${name}: icons and launch screen written under ${a.dir}`)
  }
} finally {
  await browser.close()
}
