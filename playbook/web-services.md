# Web Services & Dashboards

Patterns for building and maintaining web services, dashboards, and APIs.

## Tech Stack Recommendation

For simple dashboards and tools served alongside your main site:
- **Vanilla HTML/CSS/JS** — no build step, single-file deployment, easy to maintain
- **GSAP** (CDN) for animations — best timeline control, battle-tested
- **Server-Sent Events (SSE)** for live updates — simpler than WebSockets, sufficient for dashboards
- No React, no Vite, no build pipeline. Consistent, simple, debuggable.

## Authentication Pattern

For admin pages that should be invisible to the public:

```javascript
// Server-side: return real 404 without auth
const PROTECTED_PAGES = ['/agents', '/status', '/monitor'];
app.use((req, res, next) => {
    const isProtected = PROTECTED_PAGES.some(p => req.path.startsWith(p));
    if (isProtected && req.query.key !== process.env.API_KEY) {
        return res.status(404).send('Not Found');
    }
    next();
});
```

Key principles:
- URL parameter auth (`?key=...`) — simple, works everywhere, no login page needed
- Return real 404 (not 403) without the key — pages don't exist to the outside world
- Same API key across all admin endpoints for simplicity
- Client-side JS should also check and redirect on missing key

## API Endpoint Patterns

### Health Checks
Every service should have a GET `/health` endpoint:
```javascript
app.get('/health', (req, res) => {
    res.json({ ok: true, service: 'my-service', uptime: process.uptime() });
});
```
No auth required — health checks should be simple to monitor.

### Webhook Endpoints
- POST-only, validate signatures when the provider supports it
- Return 200 quickly, process async if work is heavy
- Log payloads for debugging (redact secrets)

### Admin/Management APIs
- Always behind auth (API key in header or query param)
- Return JSON, not HTML
- Include error details in development, minimal info in production

## systemd Service Tips

- Use full binary paths (`/home/user/.npm-global/bin/node` not `node`)
- Set `Environment=PATH=...` to include user bin directories
- `WorkingDirectory` should be the project root
- Use `Restart=always` with `RestartSec=5` for resilience
- Check with `systemctl --user status <service>` and `journalctl --user -u <service>`

## Reverse Proxy (nginx)

- Proxy to localhost ports, never expose Node directly
- SSL via Let's Encrypt / certbot
- If using Cloudflare: main domain proxied (hides IP), webhook subdomains DNS-only

## Screenshots for Debugging

Install Playwright for headless screenshots:
```bash
npx playwright install chromium
```

Usage:
```javascript
const { chromium } = require('playwright');
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(url, { waitUntil: 'domcontentloaded' }); // NOT networkidle
await page.screenshot({ path: 'output.png', fullPage: true });
await browser.close();
```

⚠️ Use `http://127.0.0.1:<port>` for your own services — external URLs through Cloudflare may block headless browsers.

## Common Pitfalls

- **SSE connections prevent `networkidle`** — always use `domcontentloaded`
- **Comments in JS object spreads crash Node** — `{...obj, // comment}` is a syntax error
- **CSS animations conflict with JS animation libs** — let one own the lifecycle, not both
- **Cloudflare blocks headless browsers** — use headed + off-screen, or hit localhost directly
