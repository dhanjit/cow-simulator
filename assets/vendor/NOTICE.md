# Third-party assets

## quaternius/Cow.gltf

- **Source:** Ultimate Animated Animal Pack by Quaternius —
  <https://quaternius.com/packs/ultimateanimatedanimals.html>
- **Licence:** CC0 1.0 Universal (public domain dedication).
  <https://creativecommons.org/publicdomain/zero/1.0/>
- **Attribution required:** No. Recorded here anyway so provenance is not
  guesswork later.
- **Modifications:** none to the file. It is scaled, repositioned and repainted
  at runtime by `scripts/cow_rig.gd`; the asset on disk is unmodified.

Only the cow is vendored. The pack also ships Alpaca, Bull, Deer, Donkey, Fox,
Horse, Horse_White, Husky, ShibaInu, Stag and Wolf, all on the same 42-bone rig.

### Clip list, read from the file rather than the marketing copy

`Attack_Headbutt`, `Attack_Kick`, `Death`, `Eating`, `Gallop`, `Gallop_Jump`,
`Idle`, `Idle_2`, `Idle_Headlow`, `Idle_HitReact1`, `Idle_HitReact2`,
`Jump_toIdle`, `Walk`.

**There is no lying-down clip**, and none of the other eleven animals has one
either — every animal in the pack carries this same set (the canines swap
`Idle_Headlow` for `Idle_2_HeadLow`). `Death` does end with the cow on the
ground, but in lateral recumbency, which reads as a dead animal. Cattle rest
sternally, so the resting pose is built by folding the legs from the standing
rest pose in `cow_rig.gd` instead.

### Things that will bite whoever touches this next

- **Twelve of the 42 bones are inert.** `PoleTarget*`, `IKBackLeg*`,
  `IKFrontLeg*`, `FF*` and `FFB*` are Blender IK constraints, and Godot does not
  evaluate them. Do not try to pose them. Bake to FK before any Blender
  round-trip or the result will look right in Blender and wrong in-engine.
- **Export animation libraries as `.tres`, never `.res`** — godot#94483 has
  `.res` silently ignoring the BoneMap and falling back to raw name matching.
- **Keep one animal per file.** The importer renames duplicate bones with `_2`
  suffixes when several skeletons share a file, which breaks BoneMaps
  (godot#106073).
- The model's origin sits 0.9495 units *below* its hooves, and the bind pose is
  3.58 units tall. Both constants live in `cow_rig.gd`.
