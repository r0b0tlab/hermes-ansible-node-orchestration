# Presentation Architecture Diagram Plan

> **For Hermes:** Use `creative-programmatic-media` for the actual diagram build. Use `baoyu-infographic` only for visual-layout vocabulary; the deliverable should be deterministic SVG/HTML, not a hallucinated image.

**Goal:** Create a presentation-ready architecture diagram showing how the Hermes + Ansible GB10 operator repository works end to end, with proper scaling, legible labels, and zero text overflow.

**Architecture:** Build a deterministic, self-contained SVG/HTML diagram from repo facts. Render it in a browser at multiple viewport sizes, inspect screenshots, and fix layout until every label is readable. Export both editable source and high-resolution PNG/SVG for slides.

**Tech Stack:** HTML + inline SVG + CSS design tokens + Playwright/browser screenshot verification + optional PNG export.

---

## Deliverables

Create:

- `docs/architecture/architecture-diagram.html` — self-contained source artifact.
- `docs/architecture/architecture-diagram.svg` — clean vector export if generated separately.
- `docs/architecture/architecture-diagram.png` — 16:9 presentation export, minimum 1920×1080.
- `docs/architecture/README.md` — short explanation and regeneration instructions.

Optional if time allows:

- `docs/architecture/architecture-diagram-dark.png`
- `docs/architecture/architecture-diagram-light.png`

## Diagram story

The visual should answer: “How does Hermes safely operate a GB10 cluster through this repo?”

Main flow:

```text
Operator request
  → Hermes Agent project context
  → AGENTS.md + bundled skill
  → inventory + vars source of truth
  → safe playbook selection
  → Ansible roles
  → GB10 nodes / Docker / vLLM / benchmarks
  → health checks + evidence bundle
  → concise operator report
```

## Visual layout

Use a technical-schematic / executive architecture style:

- Aspect: 16:9 landscape.
- Canvas: 1920×1080 logical design target.
- Background: dark neutral, subtle grid, no heavy gradients.
- Primary accent: cyan/teal for Hermes control plane.
- Secondary accent: green for validation/evidence.
- Warning accent: amber for safety gates.
- Use rounded cards, orthogonal connectors, and small icon-like glyphs.

Recommended structure:

1. **Top band: Operator + Hermes control plane**
   - Operator request
   - Hermes reads `AGENTS.md`
   - Hermes loads bundled skill

2. **Middle band: Repository as source of truth**
   - inventories
   - group_vars / host_vars
   - playbooks
   - roles
   - docs / CI

3. **Right band: Execution targets**
   - GB10 head node
   - worker nodes
   - Docker + NVIDIA runtime
   - vLLM containers
   - tmux benchmark jobs

4. **Bottom band: Safety and evidence loop**
   - `--limit/-l` target gate
   - check mode / syntax / lint
   - endpoint health checks
   - evidence bundles
   - operator report

## Components to include

### Control plane

- Operator
- Hermes Agent
- `AGENTS.md`
- `skills/hermes-gb10-cluster-orchestration/SKILL.md`

### Repository source of truth

- `inventories/examples/three-node-gb10.yml`
- `group_vars/gb10.yml`
- `group_vars/gb10_models.yml`
- `host_vars/`

### Playbook layer

Group playbooks into 4 lanes instead of showing every file as an equally large box:

1. Inspect
   - health
   - discover placeholder
2. Prepare
   - provision-node
   - deploy-docker-image
   - sync-model
3. Run
   - serve-model
   - benchmark
   - stop-services
4. Prove
   - collect-evidence
   - validation script
   - CI

### Role layer

Show roles as compact modules:

- `gb10_health`
- `gb10_base`
- `nvidia_container_runtime`
- `model_artifacts`
- `vllm_service`
- `benchmark_runner`
- `evidence_bundle`

### Cluster layer

Show generic nodes, not private topology:

- head01
- worker01
- worker02

Each node can contain small stacked chips:

- Docker
- NVIDIA runtime
- model path
- vLLM
- tmux benchmark

### Evidence loop

Show the loop from nodes back to repo/operator:

- health output
- endpoint verification
- benchmark logs
- evidence bundle
- concise report

## Text-overflow rules

This is the critical quality gate.

1. No freeform paragraph inside diagram cards.
2. Card titles max 22 characters.
3. Body labels max 2 lines, 28 characters per line.
4. Use explicit SVG `text` line breaks; do not rely on browser wrapping.
5. Every card gets a defined width/height and internal padding.
6. Use `dominant-baseline`, measured font sizes, and line-height constants.
7. If a label is longer than the allowed line count, shorten the label, do not shrink below 18px.
8. Minimum exported diagram font sizes:
   - title: 46–60px
   - lane headings: 24–30px
   - card titles: 20–24px
   - body text: 18–20px
   - connector labels: 16–18px
9. No text should touch card borders; minimum padding 16px.
10. No connector line should cross over text.

## Scaling rules

1. Build at 1920×1080 viewBox.
2. Use SVG `viewBox="0 0 1920 1080"` and CSS `width:100%; height:auto`.
3. Export PNG at 1920×1080 and optionally 3840×2160.
4. Test screenshots at:
   - 1920×1080
   - 1366×768
   - 1280×720
   - 1024×576
5. At 1024×576, text must remain readable and non-overlapping.
6. Prefer fewer components over dense unreadable detail.

## Implementation tasks

### Task 1: Create architecture directory

Create:

```bash
mkdir -p docs/architecture
```

### Task 2: Draft diagram data model

Create a small JSON object inside the HTML source containing:

- nodes/cards
- lanes
- connectors
- labels
- color class

Keep layout coordinates explicit for deterministic rendering.

### Task 3: Build HTML/SVG source

Create `docs/architecture/architecture-diagram.html` with:

- inline CSS variables
- SVG viewBox 1920×1080
- `<defs>` for arrows, glows, subtle grid
- card rendering helpers in JS or static SVG groups
- accessible title/description

### Task 4: Render and screenshot

Use browser automation to open the HTML and export screenshots at required sizes.

Expected outputs:

```text
docs/architecture/architecture-diagram.png
docs/architecture/checks/1920x1080.png
docs/architecture/checks/1366x768.png
docs/architecture/checks/1280x720.png
docs/architecture/checks/1024x576.png
```

### Task 5: Visual QA pass

Inspect screenshots and fix:

- clipped labels
- overlapping connector lines
- crowded cards
- low contrast
- tiny text
- inconsistent spacing
- accidental private hostnames/IPs

### Task 6: Add README

Create `docs/architecture/README.md` with:

- what the diagram shows
- source and export files
- how to regenerate
- quality checks performed

### Task 7: Validate repo and commit

Run:

```bash
./scripts/validate-inventory.sh inventories/examples/three-node-gb10.yml
find docs/architecture -type f -size +50M -print
grep -RInE 'r0b0tdgx|gn100|r0b0t-dgx|192\.168\.|HF_TOKEN|GITHUB_TOKEN|BEGIN OPENSSH|PRIVATE KEY' docs/architecture || true
```

Commit:

```bash
git add docs/architecture docs/plans/ARCHITECTURE_DIAGRAM_PLAN.md
git commit -m "docs: add presentation architecture diagram"
```

## Acceptance checklist

- [ ] Diagram explains the full Hermes → Ansible → GB10 → evidence loop.
- [ ] No private hostnames, IPs, usernames, or local paths.
- [ ] 16:9 presentation-ready composition.
- [ ] 1920×1080 PNG export exists.
- [ ] SVG/HTML source is committed.
- [ ] No text overflow at 1920×1080, 1366×768, 1280×720, or 1024×576.
- [ ] Minimum body font size is 18px in source coordinates.
- [ ] Connectors do not cross labels.
- [ ] CI/validation still passes.

## Design note

Use deterministic SVG/HTML rather than text-to-image generation. Text-to-image is useful for mood boards, but architecture diagrams need precise typography, controlled line breaks, reproducible layout, and editable source. The final artifact should look like a polished conference-slide schematic, not a generated illustration.
