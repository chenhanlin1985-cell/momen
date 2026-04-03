# Event Type Mapping Current

This project currently has two different event-type layers:

- runtime structure: `presentation_type`
- UI/gameplay label: `event_type_key`

These should not be treated as the same thing.

## Runtime `presentation_type`

Common values:

- `standard_event`
- `dialogue_event`
- `battle_event`
- `summary_event`
- `compact_choice_event`
- `ending_event`

This layer controls runtime behavior.

## UI `event_type_key`

Common values:

- `story`
- `dialogue`
- `random`
- `reward`
- `review`
- `shop`
- `normal_battle`
- `elite_battle`
- `boss_battle`

This layer controls labels and player-facing gameplay framing.

## Important current mappings

### Battle-entry dialogue events

- `2001` -> `dialogue_event` / `boss_battle`
- `2004` -> `dialogue_event` / `elite_battle`
- `2005` -> `dialogue_event` / `elite_battle`
- `2003` -> `dialogue_event` / `elite_battle`

### Non-battle NPC conversations migrated to standard events

- `2002` -> `standard_event` / `reward`
- `2102` -> `standard_event` / `reward`
- `2201` -> `standard_event` / `reward`
- `2202` -> `standard_event` / `reward`
- `2203` -> `standard_event` / `reward`
- `2007` -> `standard_event` / `reward`
- `2008` -> `standard_event` / `dialogue`

### Compact reward events

- `1301` -> `compact_choice_event` / `reward`
- `1302` -> `compact_choice_event` / `reward`
- `1303` -> `compact_choice_event` / `reward`
- `2301` -> `compact_choice_event` / `reward`
- `2302` -> `compact_choice_event` / `reward`
- `2303` -> `compact_choice_event` / `reward`
- `2401` -> `compact_choice_event` / `reward`
- `2402` -> `compact_choice_event` / `reward`
- `2403` -> `compact_choice_event` / `reward`

## Practical rule

- If a node needs `observe / intrude / battle`, use `dialogue_event`
- If a node is a non-battle NPC conversation with portraits/speaker framing, use `standard_event`
- If a node should render as a compact reward/choice card, use `compact_choice_event`
- If markdown content is marked as `dialogue_event` but has no `battle_id`, the compiler will now downgrade it to `standard_event`
