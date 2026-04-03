# Dialogue Event Runtime Status

## Current split

- `dialogue_event`: only for battle-entry conversations
- `standard_event`: for non-battle NPC conversations that still need speaker/portrait presentation

## Battle-entry dialogue events

- `2001` -> `9101`
- `2004` -> `9201`
- `2005` -> `9301`
- `2003` -> `9401`

These remain `dialogue_event`.

## Migrated non-battle NPC conversations

- `2002`
- `2102`
- `2201`
- `2202`
- `2203`
- `2008`
- `2007`

These now use `standard_event`.

## Runtime/UI guarantees

- Old talk-mode fallback is removed
- Non-battle NPC conversations no longer use dialogue-stage hub logic
- Speaker-led standard events can still render in `scene_mode = dialogue`
- Reward/dialogue tags are still resolved in the view model layer
- The markdown compiler now downgrades `dialogue_event` to `standard_event` when no `battle_id` is present

## Validation

Validated with `tools/validation/validate_non_battle_dialogue_runner.gd`.

Verified:

- migrated events resolve as `standard_event`
- `scene_mode` stays `dialogue`
- reward/dialogue tags stay correct
- no migrated event exposes `__observe__` or `__intrude__`
