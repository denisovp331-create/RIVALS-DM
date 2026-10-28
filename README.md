# RIVALS-DM

Unofficial community leaderboard concept for Roblox RIVALS Free For All (FFA / DM).

## Current preview
- FFA leaderboard columns: best score, K/D, match count and best place.
- Player profile prototype and community badge tiers:
  - 1–2 gold weapons: silver check
  - 3–4 gold weapons: gold check
  - 5+ gold weapons: diamond check
- Screenshot upload and OCR attempt in the browser (Tesseract.js); the detected values must be checked manually.
- Added a manager review queue with approve/reject actions; only approved submissions affect the local demo leaderboard.
- OCR attempts to read score, K/D, placement and kills from screenshots; OCR results still require human verification.
- Record submissions and demo profile choices are stored in the current browser only.

## Important limitations of the preview
The current `index.html` is a front-end prototype, not a production account system. The manager panel is not protected by real authentication and is only a local demo: browser storage is not shared between visitors and can be edited, so approvals are not global or secure. The OCR is best-effort and cannot prove that a screenshot is genuine. The badge count in the prototype is not independently verified.

## To make it a real shared site
1. Create a **separate Supabase project for RIVALS-DM**. Do not reuse the STAR MARKET project.
2. In Supabase SQL Editor, run `supabase-schema.sql`.
3. Connect Supabase Auth, the database and private screenshot storage to the frontend.
4. Add a trusted moderation workflow for approving/rejecting submitted screenshots and checking badge claims.
5. Keep any service-role key only on a trusted server/Edge Function; never in the public frontend or GitHub.
6. Redeploy the Netlify site after connecting the backend. A Git-connected Netlify site usually deploys again after a commit.

The site is a fan-made community project and is not affiliated with Roblox or Nosniy Games. FFA mechanics may change; check the game for current rules.
