# 05 PRESET MAP — 146개 기성 이펙트 ↔ 우리 니즈

원본: `%USERPROFILE%\.overdare\skills\vfx-recipe\references\presets.md` (146행, 자동생성 — 손으로 고치지 마라)
**`vfx-recipe` 스킬은 "VFX 데이터를 네트워크에서 찾지 마라"고 명시한다.** 이 로컬 파일이 유일한 출처다.

행 형식: `| Resource | DisplayName | Category | Subcategory | Genre | Keywords |`
`Resource` 값을 그대로 `VFXPreset.PresetName`에 넣는다.

---

## 1. 카테고리 분포 (146행 전수)

| 개수 | 카테고리 |
|---|---|
| 22 | Skill / Abilities |
| 21 | Combat / Attacks |
| 16 | Combat / Impacts |
| 14 | Status / Buffs |
| **14** | **(분류 없음 — 빈 칸)** |
| 11 | Interaction / Object Reactions |
| 8 | Skill / Casts & Charges |
| 5 | Feedback / Results |
| 4 | Status/Defenses · Status/Debuffs · Movement/Dashes · **Environment/Nature** |
| 3 | Movement/Spawns&Teleports · Movement/Landings |
| 2 | Status/Deaths&Respawns · Interaction/Portals · Interaction/Item Interactions · Feedback/Highlights · **Environment/Fire&Smoke** |
| 1 | UI/Warnings · **Environment/Weather** · Environment/Fires&Smokes *(오타 중복 카테고리)* |

**환경 카테고리는 통틀어 8개뿐이다.** 전투·스킬이 압도적이다 — 이 카탈로그는 액션 게임용으로 만들어졌다.
**분류 없는 14행을 무시하지 마라** — `Muzzle_02/04`, `Dust_01`, `BrickBreak_01`이 여기 숨어 있다.

---

## 2. 산곡 환경 ↔ 프리셋 후보

실제 지형 오브젝트(`06_TERRAIN.md`)에 대응시켰다. **전부 미검증 — 눈으로 봐야 한다.**

| 니즈 | 붙일 자리 | 프리셋 후보 | 판정 |
|---|---|---|---|
| **계류 물안개** | `STA_StreamWater` (90 m × 19 m, 수면 Y≈+37.6) | `VFX_UGC_Fog_01` — *Fog · Environment/Fire&Smoke · Adventure · fog, mist, environment, ambient, atmosphere* | **1순위.** 키워드가 정확히 일치. 톤 확인 필수 — 규칙 6(안개색은 하늘보다 어둡게)·규칙 8(있는지 모를 밀도) |
| **여울 포말** | `STA_StreamWater` 얕은 구간 | `VFX_UGC_Jungle_Splash_01` — *Water Splash · Interaction/Object Reactions · **cartoon*** | **주의.** 장르 태그에 `cartoon`. 일회성 튐이라 지속 포말과 성격이 다를 수 있다 |
| **낙하 솔잎·송화분** | `SGK_Pine_00xx` 341그루 (카메라 위 추적 방식이면 개별 참조 불필요) | `VFX_UGC_Jungle_Leaf_01` — *Leaf · Environment/Nature · leaf, jungle, nature, fall, ambient* | **1순위.** 단 "jungle 잎"과 "솔잎"은 실루엣이 다르다. **색만 바꿔서 될지, C경로로 솔잎 스프라이트를 구울지 판단** |
| | | `VFX_UGC_FloatingRose_01` — *Rose Rain* | 꽃잎이라 솔잎엔 안 맞음 |
| **빛무리 / dust motes** | 계류·절벽 발치 | `VFX_UGC_Dust_01` — 분류·키워드 전부 빈 칸 | 후보. 정보가 없어 눈으로 봐야 한다 |
| **절벽 발치 안개** | `SGK_Rock_*` 군집 아래 | `VFX_UGC_Fog_01` (파라미터만 다르게) | 물안개가 되면 이것도 된다 |
| **바람 돌풍** | 전역 | `VFX_UGC_Updraft_01` — *Updraft · Environment/Nature · updraft, smoke, dash, movement, trail* | 후보. `VFX_UGC_Start_03`(*Wind Cast*)도 있으나 스킬 이펙트라 과할 것 |
| **정자 등불** | `SGK_Pavilion` (-30000, 360, -40900), 처마 Y≈550 | — | **프리셋 없음.** `PointLight` + Neon 박스 = 경로 F |
| **점령 링** | `CaptureServer.lua`가 이미 만든다 | — | **프리셋 없음.** 기존 구현 유지 |
| *(참고)* 비 | | `VFX_UGC_Rain_01` — *Environment/Weather* | 새벽 물안개 무드엔 안 쓴다 |
| *(참고)* 새떼 | | `VFX_UGC_FlockofBirds_01` — *horror, dark* | 톤 안 맞음 |

**요약: 환경 니즈 7개 중 5~6개에 프리셋 후보가 있고, 등불·점령링 2개는 없다.**
이게 사실이면 손으로 짤 코드가 크게 줄어든다. **다만 여울 포말·솔잎은 톤/실루엣 위험이 있고, 전부 프로브 뒤 눈으로 확인해야 한다.**

---

## 3. 전투 FX ↔ 프리셋 후보

| 니즈 | 프리셋 후보 |
|---|---|
| 착지 먼지 | `VFX_UGC_Landing_01`(Heavy) · `Landing_02`(Cartoon) · `Landing_03`(Simple) — **3종** |
| 지면 충격 | `VFX_UGC_Bounce_01` — *bounce, dust, ground, landing, light* |
| 돌조각·파편 | `VFX_UGC_BrickBreak_01` — *brick, break, debris, dust, impact* · `VFX_UGC_Jungle_Minning_01` — *ore, debris* |
| 흙 파임 | `VFX_UGC_Jungle_Dig_01` — *dirt, cartoon* |
| 물튐 | `VFX_UGC_Jungle_Splash_01` |
| 타격 임팩트 | `VFX_UGC_Hit_01`(Flash Hit) · `Hit_02` · `HitObject_01`(Pulse Hit) · `HitObject_02`(spark) · `HitBall_01` |
| 유혈 | `VFX_UGC_HitObject_Blood_01` · `VFX_UGC_SplashBlood_01`(*cartoon, horror*) |
| 총구 화염 | `VFX_UGC_Muzzle_01`(General) · `Muzzle_02` · `Muzzle_03`(Sci-Fi) · `Muzzle_04`(spread, strong) — **4종** |
| 칼 궤적 | `VFX_UGC_WaterAttackTrail_01`(*IP/Cartoon* — 톤 주의). 경로 D(Trail)도 검토 |
| 연막·소멸 | `VFX_UGC_SimpleSmoke_01` — *smoke, simple, vanish* |

**총구 화염이 4종이나 있다.** 직접 만들기 전에 **먼저 `Muzzle_01`을 눈으로 봐라.**

---

## 4. VFXRecipe — 프리셋으로 안 될 때

프리셋은 내부를 못 고친다(`Color`/`Size`/`Transparency`만). 톤이 안 맞으면 여기로 내려온다.

**39개 소스** (`references/sources.md`):

| Layer | 개수 | 짧은 이름 (= 리소스명에서 `VFX_UGC_<Layer>_` 제거) |
|---|---|---|
| **Base** (17) | 본체. 최소 1개 필수 | `EmptySprite` `EmptySprite_R` `FireRise_A` `FireBurst_A` `LiquidFlash_A` `LiquidScatter_R_A` `NeutralBurst_A` `NeutralBurst_B` `NeutralTrail_A` `SmokeBurst_A` `SmokeRing_A` `LightFlash_A/B/C` `LightBurst_A` `LightRise_R_A` `TechDecal_R_A` |
| **Detail** (14) | 악센트 | `FireScatter_B` `FireDecal_A` `FireFlash_A` `LightBurst_R_A` `LightShimmer_A` `LightShimmer_R_B` `LightRise_R_B/C` `NeutralDecal_A` `NeutralFlash_C` `NeutralPulse_R_A` `NeutralRing_B` `SmokeBurst_A` `SmokeTrail_A` |
| **Extra** (8) | 잔여물 | `FireScatter_C/D` `LiquidScatter_R_A` `SmokeRise_A` `NeutralRing_A` `MagicRing_A` `LightningScatter_A` `LightRise_R_A` |

**원소:** Fire · Liquid · Smoke · Light · Neutral · Lightning · Magic · Tech · Empty
**`_R` = Rate 이미터** → `Duration`(초) + `SpawnRate`(개/초). 나머지는 **Burst** → `SpawnCount`. **섞어 쓰면 안 된다.**

**함정:**
- 같은 짧은 이름이 **여러 레이어에 다른 자산으로 존재한다** — `LiquidScatter_R_A`/`LightRise_R_A`(Base·Extra), `SmokeBurst_A`(Base·Detail). **어느 레이어에 넣느냐가 어느 자산이 재생될지를 결정한다**
- 다른 레이어의 소스를 넣으면 스키마 검증에서 거부된다 (에러가 유효 목록을 알려준다)
- `ObjectType` 태그는 사이드카가 주입한다 — `{X,Y,Z}`, `{R,G,B,Time}` 같은 평범한 값으로 써라
- **레이어 배열은 업데이트 시 통째로 교체된다.** 델타가 아니라 수정된 전체 배열을 보내라
- 일회성: `InfiniteLoop: false, LoopCount: 1`
- **`LoopDuration`은 읽기 전용 파생값** — 소스의 `Duration`/`Delay`를 고치거나 제일 긴 소스를 갈아라

**템플릿 7종** (`references/templates/`, 복붙 가능한 JSON 페이로드 포함):

| 파일 | 무엇 | 소스 |
|---|---|---|
| `combo_01_acid_liquid_smoke_burst_en.md` | 산성 액체 + 연기 복합 버스트 | LiquidFlash_A, SmokeBurst_A, NeutralFlash_C, FireScatter_C, LiquidScatter_R_A |
| `combo_02_blood_sustained_scatter_en.md` | 지속 분출 (rate Base 하나) | LiquidScatter_R_A |
| `combo_03_neutral_hit_fire_spark_en.md` | **표준 타격 패턴** | NeutralBurst_A, FireScatter_B |
| `combo_04_shimmer_light_smoke_explosion_en.md` | 반짝임 섞인 연기 폭발 | SmokeBurst_A, NeutralPulse_R_A, LightShimmer_A |
| `combo_05_smoke_rise_explosion_en.md` | 연기가 피어오르는 폭발 | SmokeBurst_A, SmokeRise_A |
| `combo_06_fire_pillar_with_decal_en.md` | 불기둥 + **지면 데칼** (3레이어 풀스택) | FireRise_A, NeutralDecal_A, NeutralFlash_C, FireScatter_C/D |
| `combo_07_electric_burst_smoke_carrier_en.md` | **없는 원소를 근사하는 표준 방법** | SmokeBurst_A, NeutralPulse_R_A, LightBurst_R_A, LightShimmer_A |

`combo_06`에 **`NeutralDecal_A`가 있다** — `Decal` 클래스는 없지만 **레시피 안에서는 데칼을 쓸 수 있다.** 지면 그을음·물자국에.

---

## 5. `EmptySprite` — 커스텀 텍스처를 레시피에 넣는 유일한 통로

`VFX_UGC_Base_EmptySprite` / `_R`. 사용자 파라미터:

```
Position: Vector3 · Rotation: Vector3 · Delay
SpawnCount   (또는 _R: Duration + SpawnRate)
Lifetime_Min · Lifetime_Max · BoundSize: Vector3 · Size2D: Vector2
Color: ColorSequence · Transparency · Texture: Content · Acceleration: Vector3
FlipbookMode: number · FlipbookRows: number · FlipbookColumns: number
```

**`ParticleEmitter`보다 엄격히 강하다:**
- **임의 행×열 플립북** — `Grid2x2/4x4/8x8` 셋 중 선택이 아니다. `combo_03`이 `Rows 1 / Columns 4`를 쓴다
- **`Size2D: Vector2`로 비정사각 파티클** — `ParticleEmitter`는 `Squash`로 근사만 가능

**⚠️ 모순:** 스킬은 이걸 *"A blank sprite template for manual authoring. **Not used in AI composition.**"*라고 하고, 함정 목록에 *"never pick them when composing an effect"*라고 못박는다.
**"에디터 전용이라 upsert로 못 넣는다"는 기술적 제약인지, "AI가 조합할 땐 쓰지 마라"는 절차적 권고인지 불명확하다** → `10_OPEN_QUESTIONS.md` Q-4.

---

## 6. 사용 절차 (스킬이 정한 흐름)

1. **프리셋**: `presets.md`를 영어 키워드로 case-insensitive `grep` → `VFXPreset`에 `PresetName` = Resource 값
2. **템플릿**: `templates/00_INDEX.md`에서 2~3개 고름 → 해당 `combo_*.md`의 **Original Payload JSON을 그대로** upsert `properties`로 (붙여넣기 안전: `LoopDuration`은 무시되고 `Alpha` 배열은 통과)
3. **직접 조합**: `sources.md`에서 레이어별로 고름. `NiagaraSystem`에 짧은 이름

**적응 규칙:** 테마 변경 = **Color/Alpha 키포인트만** (소스 유지) · 모션/형태 = **같은 레이어 내** `NiagaraSystem` 교체 · 강도 = `SpawnCount`/`SpawnRate`를 레이어 전반에 같은 비율로.

**스킬은 새 이펙트 요청마다 사람에게 "기성 / 레시피 커스텀(권장) / 완전 커스텀" 중 무엇으로 만들지 먼저 묻게 되어 있다.** 요청에 방법이 지정돼 있거나 기존 레시피를 편집하는 경우만 건너뛴다.
