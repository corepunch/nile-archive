# Centred portrait-and-bubble dialogue

Before: main at `6c5a48aedccdced22978b07d19141824267033b9`. After: this PR.

The shared story renderer centres framed phone portraits and their bubble as a single unit within the safe screen. It measures the portrait frame and actual bubble outline, including cloud puffs and shout spikes. A listener participates in the same unit. The badge keeps its existing outline alignment; the Skip pill travels with the unit and sits above it when a listener occupies the opposite side. Standing-figure and no-portrait staging keep their existing layouts.

All captures use the actual game, `--headless --fresh --mute --frames 240 --shot <path>.png`, with `--dialog intro|mara|tomas|adrian` for Elena's cloud, Mara's shout, Tomas's one-line speech and Adrian's two-line speech. Each is captured at `--size 480x900` and `--size 390x844 --safe-area 0,47,0,34`. Review images are capped at 480×900; canonical screenshots retain capture resolution. `make shots` refreshes the canonical images.

`make test-platform` checks actual rendered bounds across all three bubble kinds, one/two-line copy, both sides, listeners, resize/letterbox and safe areas. It finds the relocated Skip pill in rendered pixels and clicks it through the platform input queue to dismiss the conversation. Build, unit tests and all three games' smoke runs also cover the shared renderer.

No artwork, source atlas, rule or interaction state is added.
