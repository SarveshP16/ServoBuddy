# To do

## 1. Redesign the app with the Road Sign mockup (light and dark) — done

- [x] Remove the current theming options: Match phone / Light / Dark / Red & Black, and the Teal / Ember / Purple accents (palettes, accent picker, theme settings, saved prefs).
- [x] Build the Road Sign look: sign green, plate yellow, Archivo (condensed headings).
- [x] Make a light and a dark version of it, with a simple Light / Dark / Match phone choice in Settings.
- [x] Redesign Home, Vehicles, vehicle page, Expenses, Log expense and Settings to match.
- [x] Re-render `test/preview/*.png` and update the README screenshots.

## 2. Local backup — done

- [x] Export everything (vehicles, expenses, recurring costs, schedules, settings, photos) to one backup file on the phone.
- [x] Restore from a backup file, with a clear warning before it replaces current data.
- [x] Show when the last backup was made in Settings.

## 3. Odometer prompt when logging a rego renewal

- [ ] When a Rego expense is logged, ask for the current odometer (prefilled with the last reading).
- [ ] Save it as an odometer reading, so service due estimates stay current once a year at least.

## 4. Titles for all expense types

Today only services have a title ("New battery" ends up in Notes). Give every category a title field with one-tap suggestions:

| Category | Suggested titles |
|---|---|
| Fuel | E10, U91, P95, P98, Diesel |
| Service | Logbook service, Oil and filter, Minor service, Major service, Brake service |
| Repairs & parts | Battery, Tyres, Brake pads, Rotors, Wiper blades, Globe / light, Alternator, Spark plugs |
| Rego | Rego renewal, CTP green slip, Pink slip inspection |
| Insurance | Comprehensive, Third party property |
| Tolls | Linkt top-up, E-toll account |
| Parking | Street parking, Car park |
| Car wash | Wash, Detail |
| Other | Fine, Accessories, Roadside assist membership |

- [ ] Suggestions are a starting point; any title can be typed.
- [ ] Show the title in lists instead of just the category name.

## 5. Rego and CTP checklist

- [ ] For each car, a checklist that opens before rego is due: green slip (CTP) → pink slip (cars 5+ years old) → pay rego.
- [ ] Ticking a step can log it as an expense (amount + date).
- [ ] Builds on the existing green and pink slip reminders.

## 6. Tyre and battery age

- [ ] Record when tyres and a battery were fitted (from a Repairs & parts expense with that title, or set by hand).
- [ ] Show their age on the vehicle page, and remind when they near typical replacement (battery ~3–5 years, tyres ~5 years or by km).

## 7. Home screen widget

- [ ] Android widget showing the next thing due (service, rego, insurance or recurring cost) and this month's spend.
- [ ] Tapping it opens the app on that item.
