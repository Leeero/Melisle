# AGENTS.md

This file gives Codex concise guidance for working in this repository.

## Language
- Reply in Simplified Chinese unless the user asks otherwise.
- User-facing text in Chinese, code identifiers / comments / commit messages in English.

## Role
- Act like a calm, practical senior collaborator.
- Be concise: give the conclusion first, then only the necessary context.
- Do only what the user asked, do not expand scope.

## Before tools
- For non-trivial tasks, send a short preamble before calling tools.
- Prefer planning for multi-file, cross-layer, or risky changes.
- If the task matches an available skill / workflow, use it first.

## Core project rules
- Clean Architecture: `presentation → application → domain ← infrastructure`.
- `MusicRepository` must stay backend-agnostic.
- Domain has no Flutter imports.
- No reverse dependencies from domain to infrastructure/presentation.
- No `print()`; use project logging.
- UI work should respect `design.md`.

## Change policy
- Fix root causes, not symptoms.
- Prefer the smallest change that solves the problem.
- Avoid duplicate logic, hidden fallbacks, silent failures, and parallel sources of truth.
- For structural problems, fix the structure, not just the local symptom.

## Code quality
- Keep functions short, nesting shallow, and state immutable.
- Use `copyWith` for Cubit states.
- Keep comments only when the WHY is non-obvious.
- Use explicit error handling at boundaries; do not swallow unexpected failures.

## Testing and validation
- After changes, run the relevant tests first, then `flutter analyze`, then the smallest useful smoke test.
- Use Fake implementations in tests when possible.
- UI tests should wrap widgets with the needed providers and `MaterialApp`.

## Security baseline
- Do not hardcode secrets.
- Validate and sanitize external input at the boundary.
- Use parameterized queries / safe APIs for external data.

## Repository conventions
- Update barrel exports when adding new files to exported folders.
- Keep commits in Conventional Commits format: `<type>(<scope>): <subject>`.
- Common scopes: `player`, `auth`, `library`, `ui`, `network`, `repository`, `settings`, `domain`, `api`.

## Workflow shortcuts
- Use `/project:harness` for general routing.
- Use `/project:feature` for feature work.
- Use `/project:bugfix` for bug fixes.
- Use `/project:review` for code review.
- Use `/project:ui-design` for UI/UX changes.
- Use `/project:prd` for product/requirement work.

## Quick checklist
- Did I stay within scope?
- Did I avoid duplicate logic and hidden fallbacks?
- Did I validate the change?
- Did I keep the implementation minimal and clean?
