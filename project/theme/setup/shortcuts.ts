import type { NavOperations, ShortcutOptions } from '@slidev/types'
import { defineShortcutsSetup } from '@slidev/types'

/**
 * ЙЦУКЕН mirrors of Slidev's letter shortcuts: with the Russian layout
 * active the same physical keys keep working (event.key arrives as the
 * Cyrillic letter, so the latin bindings alone never match).
 *   d → в  toggle dark      o → щ  overview      ` → ё  overview
 *   g → п  goto dialog
 */
export default defineShortcutsSetup((nav: NavOperations, base: ShortcutOptions[]) => [
  ...base,
  { name: 'toggle_dark_ru', key: 'в', fn: nav.toggleDark },
  { name: 'toggle_overview_ru', key: 'щ', fn: nav.toggleOverview },
  { name: 'toggle_overview_yo', key: 'ё', fn: nav.toggleOverview },
  { name: 'goto_ru', key: 'п', fn: nav.showGotoDialog },
])
