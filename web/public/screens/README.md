# App screenshots

These are real screenshots used on the landing page.

- `map-satellite.png`, `map-topo.png`, `layers.png`, `features.png`, `intro.png`
  were captured from the app in the iOS Simulator.

## Adding the AR shot

The augmented-reality view only renders on a physical iPhone (it uses the live
camera). When you have a refined AR screenshot, drop it here as:

```
web/public/screens/ar.png      (or ar.jpg)
```

The "Augmented reality — Look up, not down" row on the landing page appears
**automatically** once the file exists — no code change needed. Rebuild/redeploy
the site (`npm run build`) to pick it up in production.

Recommended: a portrait iPhone screenshot (same aspect as the other screens,
e.g. 1320 × 2868). It sits in a device frame, so a clean full-screen capture
works best.
