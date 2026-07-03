# Architecture Diagram

Presentation-ready diagram for the Hermes + Ansible GB10 operator repository.

Files:

- `architecture-diagram.html` — self-contained source.
- `architecture-diagram.svg` — vector source/export.
- `architecture-diagram.png` — 1920×1080 PNG export.
- `checks/` — viewport screenshots used for visual QA.

Regenerate screenshots from repo root:

```bash
chromium --headless --no-sandbox --disable-gpu --window-size=1920,1080 \
  --screenshot=docs/architecture/architecture-diagram.png \
  file://$PWD/docs/architecture/architecture-diagram.html
```

Quality gates checked during creation:

- 16:9 composition.
- explicit SVG text line breaks.
- no private hostnames/IPs/usernames/local paths.
- no body text below 18px in source coordinates.
- viewport screenshots at 1920×1080, 1366×768, 1280×720, and 1024×576.
