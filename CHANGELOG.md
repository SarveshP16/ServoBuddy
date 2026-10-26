# Changelog

All notable changes to ServoBuddy are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and version numbers
follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.5.0] - 2026-10-27

Keeping on top of the car: rego renewals step by step, tyre and battery
ages, a home screen widget, and titles for every expense.

### Added

- **Rego renewal checklist.** Six weeks before rego is due, the car's page
  and Home show the steps: CTP green slip, pink slip (cars 5+ years old) and
  paying the rego. Tap **Log** on a step to record it with its amount and
  date. Logging the rego payment moves the car's rego date on a year, and the
  checklist goes away until next time.
- **Tyres and battery.** Record when they were fitted, from the car's page
  (handy when they were part of a service bill) or by logging an expense
  titled "Tyres" or "Battery". ServoBuddy shows how old they are and when to
  replace them: batteries at 4 years, tyres at 5 years or 40,000 km,
  whichever your driving reaches first. They join Coming up and get
  reminders as the date nears.
- **Home screen widget.** Add "ServoBuddy" from your launcher's widgets for
  the next thing due and this month's spend at a glance. Tap it to open that
  car.
- **Odometer on rego.** Logging a Rego expense asks for the current
  odometer, so service due dates stay accurate even for cars that rarely
  see a fill-up log.
- **Titles for every expense**, not just services. A "What was it?" field
  sits under the category, with one-tap suggestions for each: E10 or U91
  for fuel, Battery or Tyres for repairs, Rego renewal or CTP green slip for
  rego, and so on. Any title can be typed instead. Recurring costs get the
  same suggestions.
- The Expenses list shows an expense's title, with its category underneath
  ("Battery", "Repairs & parts · 1 Aug").

### Changed

- Switching category on the form clears a title picked from the old
  category's suggestions, but keeps one you typed yourself.
- The database moves to schema v4 (tyre and battery dates). Upgrades keep
  everything, and older backups still restore.

## [1.2.0] - 2026-10-26

A new look, local backups, and an app that works fully offline.

### Changed

- **New look: Road Sign.** Styled on Australian road signs, in light and
  dark.
  - Sign green and number-plate yellow throughout, with condensed Archivo
    headings in capitals. Archivo replaces Plus Jakarta Sans.
  - Home leads with a road-sign panel for the main car: its name, its plate
    (or "Add plate") and a yellow strip with its next service, or how long
    since the last one.
  - The vehicle page opens with the same green sign across the top.
  - A yellow + on Home logs an expense from anywhere on the page.
- **Theme choice is now Match phone, Light or Dark.** The Teal, Ember and
  Purple accents and the Red & Black theme are gone. Red & Black switches to
  Dark.

### Added

- **Backup and restore** in Settings. "Back up now" saves every vehicle,
  expense, reminder, recurring cost, photo and receipt, plus your theme and
  Home title, to one `.zip` file wherever you choose (Downloads, a USB
  stick, Google Drive). "Restore from backup" replaces everything on the
  phone with a backup, after a warning. Settings shows when you last backed
  up.
- **Finish setting up** on Home: the main car's missing odometer, rego expiry
  and service reminders, each one tap away. It disappears once they're set.

### Removed

- **The Fuel tab and the cheapest-fuel finder.** No more NSW FuelCheck
  prices, price map, favourite stations, brand filter or discounts. The app
  now has four tabs: Home, Vehicles, Expenses and Settings.
- The "Nearby fuel" card on Home, and the "Fuel prices" and "Map data" rows
  in Settings.
- The location and internet permissions. ServoBuddy now works fully offline.
- API keys and `env.json`. The app builds and runs with a plain
  `flutter run`, with no keys to set up.

Logging fuel fills, fuel economy and each car's fuel type all stay as they
were.

## 1.1.0 - 2026-09-28

### Added

- **App icon: "Buddy Car".** A friendly teal car with gold headlight eyes, on
  dark green.
  - Adaptive icon on Android 8+, so it fits round, squircle and square
    launchers.
  - A monochrome layer for themed icons on Android 13+.
  - Notifications use a matching white car silhouette. They used the full app
    icon before, which Android shows as a plain white square.
- **Sort expenses by year.** An "All years · 2026 · 2025 …" row shows one
  year at a time, still grouped by month. It appears once your expenses span
  more than one year.
- **Totals card on Expenses.** Shows the all-time total and the selected
  year's total, or this year's when no year is picked. Both follow the car
  and category filters.
- **Recurring costs summary.** Shows how many recurring costs are active and
  roughly what they add up to over a year. Paused costs aren't counted.

### Changed

- **Expenses now has two pages: Expenses | Recurring costs.** A switch under
  the header moves between them, and the + button adds to whichever page is
  showing. Recurring costs used to be a separate screen, opened from a card
  at the top of Expenses.
- Due "Log $120" cards for recurring costs now scroll with the Expenses list
  instead of staying fixed above it.
- Release APKs are signed with ServoBuddy's own release key instead of the
  debug key.

## 1.0.0 - 2026-09-28

First release.

### Added

#### Garage

- Add, edit and delete cars: make, model, year, body type, fuel type, rego
  plate, odometer, photo, and rego and insurance expiry dates.
- The first car becomes the **main vehicle**, and it can be changed later.
  Its fuel type drives the Home fuel card.
- Car photos are copied into app storage, so they survive the gallery
  original being deleted.
- **Sold / not in use**, with an optional sold date and sale price:
  - The car moves to a "Sold / not in use" section on the Vehicles tab and
    leaves Home, the car pickers and the fuel defaults.
  - All its reminders stop. Its recurring costs are paused rather than
    deleted.
  - If it was the main car, the next car in use takes over.
  - Its expenses still count in Expenses and totals.
  - Its page shows the sold date, total spent, sale price, and the net
    figure (spent minus sale price).
  - "Put back in use" restores it, reminders included.
- **Two kinds of delete**:
  - **Delete, keep expense history**: the car disappears everywhere, but its
    expenses and receipts stay in Expenses under its name.
  - **Delete everything**: the car and all its data are removed.

#### Expenses

- One form for Log expense, Add service record and Mark done.
- Categories: Fuel, Service, Repairs & parts, Rego, Insurance, Tolls,
  Parking, Car wash and Other, each with its own icon and colour.
- Fuel fills record litres, odometer and "filled to full", with the price per
  litre shown as you type.
- Receipt photos can be attached to any expense.
- The Expenses tab groups entries by month with a total for each month, and
  filters by car and category.
- Swipe left to delete, with Undo. Undo brings the receipt photo back too.
- **Recurring costs**, such as monthly insurance or toll-pass top-ups. Set one
  up from Expenses, or with "Repeat this expense" on the Log expense form.
  - Weekly, fortnightly, monthly, quarterly or yearly.
  - On each due date you get a 9 am reminder, and a "Log $120" card appears
    on Home and Expenses. **Log** records it as-is, **Edit** opens the form
    for a different amount, and **Skip** passes it over.
  - Nothing is logged without a tap. Missed dates wait in order ("1 more
    waiting").
  - Can be paused or deleted; expenses already logged are kept.
  - A monthly cost on the 31st returns to the 31st after short months
    instead of drifting to the 28th.
- **Fuel economy** in L/100 km and fuel cost per km on each car's page,
  using the full-to-full method. Fills with missing litres are skipped
  rather than guessed.
- A spend breakdown by category for the year on each car's page.

#### Service reminders

- Each car has its own schedules: "every X km or Y months, whichever comes
  first".
- One-tap presets: logbook service, oil change, tyre rotation, brakes and
  more.
- "Due in ~3 weeks" estimates are based on how fast the odometer has risen
  over the last 180 days.
- Mark done logs the service as an expense and resets the reminder.

#### Notifications and Coming up

- Reminders for services, rego and insurance: 2 weeks before and on the day,
  at 9 am.
- **NSW CTP green slip** reminders 3 weeks before rego is due, and **pink
  slip** reminders when the inspection window opens (6 weeks before) for cars
  5 years or older. Both follow each car's rego date.
- A **Coming up** list, opened from the bell on Home, shows everything due
  soon across all cars. A dot on the bell shows when something is close.
- Notification permission is asked for once, when the first car is added.
- Settings shows whether reminders can actually arrive, with a Fix button for
  each missing permission.

#### Cheapest fuel nearby

- Live prices from **NSW FuelCheck**, cached for 10 minutes to stay within
  the free plan's 2,500 calls a month. Pull to refresh.
- The map is the main view, with the station list scrolling underneath.
- Tapping a price on the map highlights the station in the list, and tapping
  a row highlights its pin. Directions open in Google Maps.
- **Favourite stations**: star a station to pin it above the rest, and use
  "★ Favourites" to show only them.
- **Brand filter and discounts**: hide brands, and set a cents-per-litre
  discount for each brand (e.g. a 4c/L shopper docket). Prices are shown and
  ranked after the discount.
- If location is unavailable, search by suburb or postcode instead.
- Without API keys, clearly labelled sample prices are shown.
- Map tiles come from CARTO, themed to match the app, when a CARTO key is
  set. Otherwise the map uses OpenStreetMap tiles.

#### Home

- A greeting that follows the time of day, your cars, this year's spend, the
  most urgent service across all cars, the nearby-fuel card and recent
  expenses.
- The fuel card never asks for location by itself. It shows a "Show fuel
  near me" button until location is allowed.

#### Themes and settings

- Seven themes: Match phone, Light or Dark, each with a Teal, Ember or Purple
  accent, plus Red & Black.
- Every theme's key colour pairs are tested against WCAG contrast ratios.
- The "Your Garage" title on Home can be renamed, up to 24 characters.

### Technical notes

- Data is stored locally with Drift (SQLite), schema v3. Upgrades from v1 and
  v2 are tested against the real older schemas.
- All date arithmetic uses calendar days rather than fixed 24-hour durations,
  so NSW daylight-saving changes don't shift due dates.
- Fuel prices sit behind a `FuelPriceSource` interface, so other states can be
  added later. The NSW client uses the v1 (NSW-only) endpoints.

[Unreleased]: https://github.com/SarveshP16/ServoBuddy/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/SarveshP16/ServoBuddy/compare/v1.2.0...v1.5.0
[1.2.0]: https://github.com/SarveshP16/ServoBuddy/releases/tag/v1.2.0
