# Design: Remove Duplicate Manual Setup Steps from README.md

**Date:** 2026-05-16
**Status:** Approved

## Problem

README.md contains a "Manual Setup Steps" subsection (lines 197–254) with five numbered steps, each with shell commands. Every step is fully covered — with greater detail, troubleshooting, and context — in `docs/Lab-Setup-Guide.md`. The duplication creates a maintenance burden: changes must be applied in two places, and they will inevitably drift out of sync.

## Decision

Remove the "Manual Setup Steps" subsection entirely and replace it with a single pointer line at the end of the "Automated Setup" section:

> For manual step-by-step setup, see [Lab Setup Guide](docs/Lab-Setup-Guide.md).

## Scope

**File changed:** `README.md`

**Removed:** The `### Manual Setup Steps` heading and its body (five numbered steps covering prerequisites, environment config, Kind cluster creation, service startup, and application build — approximately 57 lines).

**Added:** One sentence after the port forwarding management block, before the "First Steps After Setup" section.

**Unchanged:** All other README.md sections. `docs/Lab-Setup-Guide.md` is not modified.

## Rationale

- `docs/Lab-Setup-Guide.md` is the authoritative manual setup reference. It covers each step in more depth, includes troubleshooting, and is already linked from the "Key Resources" block at the bottom of README.md.
- The README's role is orientation and quick start, not a duplicate of the full guide.
- A pointer line is sufficient for discoverability without adding noise.
