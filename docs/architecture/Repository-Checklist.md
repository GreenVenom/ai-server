# Repository Implementation Checklist

Use this checklist when implementing or reviewing an in-memory repository.

## Architecture

- [ ] Repository purpose is documented.
- [ ] Object schema is defined centrally.
- [ ] Enums are defined centrally.
- [ ] Primitive validation is delegated to shared validators.
- [ ] Repository follows ADR-0009.

## Bash Compatibility

- [ ] Compatible with Bash 3.2.
- [ ] Does not require associative arrays.
- [ ] Does not use `declare -g`.
- [ ] Safe under `set -u`.
- [ ] Empty repository iteration is safe.
- [ ] Shell return values remain within `0-255`.

## Identity

- [ ] Objects receive unique IDs.
- [ ] IDs are immutable.
- [ ] Sequence generation occurs in the current shell.
- [ ] Generated IDs are tested for uniqueness.
- [ ] Reset sequence behavior is explicitly defined.

## Mutation Safety

- [ ] Mutating functions are not invoked through command substitution.
- [ ] Tests verify repository mutations persist.
- [ ] Functions that must return values use globals, direct output without mutation, or another current-shell-safe mechanism.

## Lifecycle

- [ ] Create operation exists.
- [ ] Existence check exists.
- [ ] Count operation exists.
- [ ] First object lookup exists where useful.
- [ ] Last object lookup exists where useful.
- [ ] Delete operation exists.
- [ ] Clear/reset behavior is defined.
- [ ] Reset behavior is tested.

## Field Access

- [ ] Generic getter exists where appropriate.
- [ ] Generic setter exists where appropriate.
- [ ] Immutable fields cannot be modified.
- [ ] Typed getters or convenience accessors exist where useful.
- [ ] Typed setters or lifecycle helpers exist where useful.

## Validation

- [ ] Invalid fields are rejected.
- [ ] Invalid values are rejected.
- [ ] Required fields are validated.
- [ ] Whole-object validation exists where appropriate.
- [ ] Whole-repository validation exists where appropriate.

## Errors

- [ ] Repository integrates with the Error Framework.
- [ ] Validation failures create structured errors.
- [ ] Serialization failures create structured errors.
- [ ] Error details include actionable suggestions where possible.

## Querying

- [ ] Filtering functions exist for common object fields.
- [ ] Empty query results are safe.
- [ ] Query behavior is deterministic.

## Serialization

- [ ] Text serialization is tested if supported.
- [ ] JSON serialization is tested if supported.
- [ ] Markdown serialization is tested if supported.
- [ ] CSV serialization is tested if supported.
- [ ] Destination write failures are handled.

## Reference Implementations

Validated repositories:

```text
Error Repository
Result Repository
```

These implementations define the current repository conventions for the Personal AI Platform.
