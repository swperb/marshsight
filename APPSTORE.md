# MarshSight - App Store submission kit

Everything needed for the App Store Connect listing and review. Copy fields
straight into App Store Connect (ASC). Last updated June 2026.

---

## 1. App information

- **Name (30 char max):** `MarshSight`
- **Subtitle (30 char max):** `AR maps for hunt & fish` (23)
- **Primary category:** Navigation
- **Secondary category:** Sports
- **Bundle ID:** com.marshsight.app
- **Support URL:** https://marshsight.com
- **Marketing URL:** https://marshsight.com
- **Privacy Policy URL:** https://marshsight.com/privacy
- **Copyright:** 2026 MarshSight

---

## 2. Promotional text (170 char, editable anytime without review)

Open-source, public-data maps for the marsh, the timber, and the water. See your
boundaries in AR. Free where it counts.

---

## 3. Description

MarshSight is a free, AR-first map for hunters and anglers, built entirely on
public-domain data. See public land, hunting units, water, and your own spots
laid over the real world through your camera, then navigate to the stand or the
ramp and back to the truck.

CORE - FREE, FOREVER
- Satellite, topo, and terrain basemaps
- Public land, hunting units, and boundaries (USGS, PAD-US, USFS)
- Full water network, lakes, and live USGS river gauges
- Augmented-reality overlay of boundaries and your saved spots
- Drive preview and back-to-truck navigation
- Weather, tides, and moon phase
- Offline maps for no-signal country
- Logbook and trophy room for your harvests and catches
- Community feed and shared spots
- Tag public-land and property owners with your community

MARSHSIGHT+ (OPTIONAL)
Support the project and unlock the features that cost real money to run:
- Trail-camera sync - email your cameras straight onto your map
- AI movement and bite forecasts from weather, moon, and tide
- Scent cone and wind overlay
- Unlimited offline regions and cloud sync

Annual subscription or a one-time Founder lifetime license. The open core stays
free for everyone, funded by the people who choose to chip in.

BUILT IN THE OPEN
Every map layer comes from public, government data. No closed data, no locked
core. MarshSight is an independent community project and is not affiliated with,
endorsed by, or derived from onX or any other app.

SAFETY
MarshSight is a navigation aid, not a survey instrument or an authority. GPS,
compass, and boundary data have real error and can be out of date. Always verify
land access, boundaries, regulations, and hazards yourself, carry a backup, and
hunt and boat legally and safely.

---

## 4. Keywords (100 char max, comma-separated, no spaces)

hunting,fishing,map,gps,onx,hunt,offline maps,public land,duck,deer,marsh,ar,boundaries,waypoint

(Note: "onx" as a keyword is generally allowed as a competitor term, but if
review pushes back, drop it. Do not use it in the name/subtitle/icon.)

---

## 5. Age rating

Answer the ASC questionnaire honestly. Relevant points:
- No graphic violence depictions (hunting context is not "realistic violence"
  in Apple's sense - there are no depictions of violence toward people).
- The app DOES host user-generated content (feed, shared spots) -> answer YES.
  With report/block/filter/moderation in place this is compliant.
- No gambling, no unrestricted web access, no mature themes.

Expected result: 12+ (driven mainly by user-generated content). If you prefer a
wider margin, 17+ is also fine. Do not under-rate the UGC question.

---

## 6. App Privacy ("nutrition label") answers

Set these in ASC > App Privacy. We do NOT use data to track you (no ATT prompt
needed): choose "Data Not Used to Track You."

Data collected (only when the user shares; choose "Used for App Functionality",
"Linked to the user" because it is tied to an anonymous device identifier and an
optional display name):

| Data type | Collected? | Purpose | Linked | Tracking |
|---|---|---|---|---|
| Precise Location | Yes (only on public/group/feed share) | App Functionality | Linked | No |
| Photos or Videos | Yes (feed photos, trail-cam photos) | App Functionality | Linked | No |
| Other User Content (notes, spot names, posts) | Yes | App Functionality | Linked | No |
| User ID / Device ID (anonymous per-install id) | Yes | App Functionality | Linked | No |
| Display name (optional) | Yes | App Functionality | Linked | No |

NOT collected by the app: contact info/email (waitlist email is website-only),
browsing history, search history, purchases (Apple handles IAP), diagnostics,
usage data/analytics, contacts, health, financial info.

Camera (live AR) frames are processed on device and never uploaded - do not list
the live camera feed as collected data.

---

## 7. Review notes (paste into "Notes" for the reviewer)

MarshSight is a navigation/mapping app for hunters and anglers built on public,
government data (USGS, NOAA, PAD-US, USFS) and Esri imagery. No account or login
is required to use the app or to review it - just launch and accept the safety
notice.

Location: used for map position and the AR overlay. It is only transmitted if the
user explicitly shares a public spot or a feed post (off by default).

User-generated content (Guideline 1.2): the community feed and shared spots are
moderated. Users agree to community guidelines before posting; there is in-app
reporting and user blocking; an objectionable-language filter runs on submission;
reported content is auto-hidden after multiple reports and removed within 24
hours; repeat offenders are banned. Contact: stephenproctor291@gmail.com.

In-app purchases: MarshSight+ (annual subscription and a non-consumable Founder
lifetime). All MarshSight+ features are currently unlocked for everyone during
the beta; purchasing is for support.

AR/camera: the camera is used only to render the live AR navigation view; frames
are never recorded or uploaded.

---

## 8. Screenshots

Required sizes (upload at least one set; ASC can scale 6.9" down to 6.5"):
- 6.9" (iPhone 16 Pro Max): 1320 x 2868
- 6.5" (optional if 6.9" provided)
- 13" iPad (only if you ship iPad; otherwise iPhone-only)

Plan (5-6 shots, captions baked in or via ASC):
1. AR view with boundaries overlaid - "See your boundaries in the real world"
2. Map with public land + units + your spots - "Public land, units, and water - free"
3. Pricing/feature value or feed - "Strava for hunting and fishing"
4. Offline + back-to-truck - "Works with no signal. Always find the truck."
5. Trail-camera photos on map - "Your cameras, on your map" (MarshSight+)

Capture from a real device (Settings stable) or the simulator. Avoid showing any
onX UI, marks, or screenshots. No pricing claims that contradict the listing.

---

## 9. Pre-submission checklist

Done via the App Store Connect API (already live on the record):
- [x] App name, subtitle, description, keywords, promotional text.
- [x] Support / Marketing / Privacy Policy URLs.
- [x] Primary category Navigation, secondary Sports.
- [x] Copyright.
- [x] Expired the stale TestFlight builds (v1-v3, pre-moderation).

App Store Connect / account (USER must do - not available via API):
- [ ] Set App Privacy answers (section 6) - ASC UI only.
- [ ] Complete the age-rating questionnaire (section 5) - ASC UI only.
- [ ] Upload screenshots (section 8) - need the actual images.
- [ ] Paste review notes (section 7) into App Review Information.
- [ ] Sign the Paid Applications agreement (Agreements, Tax, and Banking).
- [ ] Create 2 IAP products and submit them WITH this version (required because
      the paywall is visible):
      - com.marshsight.premium.annual (auto-renewable subscription, $24.99/yr)
      - com.marshsight.premium.lifetime (non-consumable, $99)
      Add localized name/description + a review screenshot for each.
- [ ] Upload a fresh build (current code) and attach it to version 1.0.
- [ ] Submit for Review.

Backend / infra (USER):
- [ ] Run platform/supabase/moderation_schema.sql in Supabase.
- [ ] Push to main so api.marshsight.com deploys the /v1/reports route.

Engineering (in the build):
- [x] UGC moderation: report, block, filter, EULA agreement, auto-hide.
- [x] Privacy policy + Terms/EULA pages live on marshsight.com.
- [x] Premium gating mechanism (gatingEnabled flag, off during beta).
- [ ] When IAP is approved, set gatingEnabled = true to turn on the freemium wall.

Optional but recommended:
- [ ] File a US trademark for "MarshSight" (see trademark notes).
