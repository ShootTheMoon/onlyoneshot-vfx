# VFX 조사 → GPT-6 인계 패키지

## Context

**최종 산출물은 사람이 읽는 조사 보고서가 아니라, 컨텍스트가 0인 실행 에이전트(GPT-6)가 그대로 작업에 들어갈 수 있는 인계 패키지다.**
GPT-6는 이 컴퓨터의 **파일과 OVERDARE Studio에 직접 접근**하며, **Luau FX 코드 작성 + 블렌더 스프라이트/아틀라스 굽기 + 설계·아트디렉션 판단**을 수행한다.

### 왜 이 조사가 필요한가 — 서로 이어지지 않은 덩어리 셋

1. **블렌더 오프라인 VFX — 성공했지만 엔진엔 못 넘어간다.** `GameDev\Weapons\_Showcase\FX_AK_*.blend`(각 29 MB). 4단계 진화 끝에 "실사 사진 스프라이트 화염 + Mantaflow 연기 + Cycles"로 정착. 트레이서는 3D로 13번 실패하고 PIL 2D 후합성으로 해결. 오프라인 렌더 품질이고 런타임엔 한 줄도 못 옮긴다.
2. **인게임 FX — 돌아가지만 원시적이다.** `onlyoneshot\Lua\` 60여 파일 전체의 `Instance.new("X")` 클래스가 이게 전부다: Part, Model, Folder, ScreenGui, Frame, TextLabel, ImageLabel, ImageButton, Outline, Sound, SoundGroup, Animation, RemoteEvent. **ParticleEmitter·Beam·Trail·PointLight·BillboardGui 전부 0건.** 3D는 절차 생성 Neon Part, 2D는 코드로 그린 `Frame` 색판.
3. **07_FX — 다리로 쓰였지만 한 번도 실행되지 않았다.** Luau 5개(1224줄) + 스프라이트 9장 + "지형 이펙트 규칙" 8개가 다 쓰여 있는데 `SGK_FXData.CAP`의 `{particle, light, beam, flipbook, billboard}` **다섯 개 전부 `false`**, `SPRITES` 전부 `""`, `Play.log`에 `[FXPROBE]` 없음. **`false`는 "안 된다"가 아니라 "확인 안 했다"이다.**

### 사전 조사에서 나온 발견 둘

> **발견 1 — 오버데어에 네이티브 VFX 시스템이 통째로 있는데 0건 쓰고 있다.**
> `~\.overdare\skills\vfx-recipe\` — Niagara 기반. **VFXPreset 기성 이펙트 146개**, VFXRecipe 소스 39개(Base 17/Detail 14/Extra 8), 복붙 가능한 템플릿 7종.
> 목록에 이런 게 실제로 있다: `VFX_UGC_Fog_01`(fog, mist) · `Jungle_Leaf_01` · `Jungle_Splash_01` · `Landing_01/02/03` · `Dust_01` · `Updraft_01` · `Rain_01` · `BrickBreak_01` · `Muzzle_01/03`.
> **산곡2가 Neon 구체로 손수 만들려던 환경 이펙트 7개 중 4~5개가 이미 공식 프리셋으로 존재한다.**
> 그리고 `ParticleEmitter`는 **플립북을 완전 지원한다**(Grid2x2/4x4/8x8, Loop/OneShot/PingPong/Random, FlipbookFramerate). 블렌더에서 구운 시트를 `overdare_image_import` → `ovdrassetid://N` → `Texture`로 바로 꽂을 수 있다.

> **발견 2 — 우리가 들고 있는 UI 능력표가 낡았다.**
> 권위 소스는 `runtime-v0.10.0\...\overdare-types.d.lua`(3093줄)인데, 지금까지 근거로 삼아온 `runtime\` 경로는 **v0.5.7 사본**이다. v0.10.0에만 있는 것: `UIStroke`, `Rect`, `ScaleType`, `SliceCenter`, `Font`, `TextService`, `ProgressBar`, `VFXRecipe`.
> 즉 **로비를 "9-slice 없음 / UIStroke 없음" 전제로 재작성했는데 그 전제가 지금은 틀렸을 수 있다.** `GuiObject.Rotation`은 기록 자체가 충돌한다 — 로비 실측 메모엔 "있다", `ParryFX.lua` 헤더엔 "이 엔진 문서에 없다"(그래서 별을 십자막대 두 개로 그렸다).

### 사용자 확정 사항

- 범위 = 인게임 런타임 FX + 블렌더 시네마틱 릴 + 블렌더→엔진 브리지 + **2D UI VFX**
- 구조 = **3D 월드 FX / 2D UI FX 양대 축, 동등**
- UI 용처 = **인게임 HUD·전투 피드백 + 로비·메뉴 연출 + 월드 빌보드(BillboardGui) 전부**
- 월드 축 우선 대상 = 산곡2 환경 FX (07_FX 이어서)
- 조사 단계에서 **Studio는 건드리지 않는다.** 실측은 **GPT-6의 1번 태스크**로 넘긴다
- 스프라이트 실제 굽기·CC0 대량 다운로드도 GPT-6 몫. 이번엔 레시피와 링크만

---

## 인계 패키지의 설계 원칙

GPT-6가 대상이라는 사실이 문서 구조를 결정한다.

| 원칙 | 이유 |
|---|---|
| **환각 차단이 1급 산출물** | GPT-6는 로블록스를 아주 잘 안다. `Sparkles` `Fire` `Smoke` `Explosion` `Highlight` `Decal` `ZOffset` `Debris` `UICorner` `UIGradient` `CanvasGroup` `BindToRenderStep` `LightInfluence` `VelocityInheritance` `TimeScale` — **전부 이 엔진에 없는데 자신 있게 뱉는다.** "없는 것 + 대체물" 목록이 튜토리얼 요약보다 값지다 |
| **철자까지 명시** | `ParticleEmitterShapeInOut`이 타입파일엔 `Outward`/`Inward`, MCP 스키마엔 `OutWard`/`InWard`. `ParryFX.lua`는 `BorderPixelSize`와 `BorderSizePixel`을 양쪽 다 pcall로 시도한다. **틀린 철자는 에러가 아니라 조용한 실패다** |
| **28배 환산 규칙 전면 배치** | 1 stud = 28 units(1 unit = 1 cm). 튜토리얼에서 베낀 Size/Speed/Acceleration은 ×28 안 하면 안 보이거나 화면을 덮는다 |
| **원문 발췌 인라인** | GPT-6가 파일을 읽을 수 있어도, 3093줄 중 **어디를** 읽어야 하는지 모른다. 핵심 클래스 선언은 줄번호와 함께 그대로 박아 넣는다 |
| **"이건 읽고 저건 읽지 마라"** | `runtime\`(v0.5.7) 함정에 즉시 걸린다. 권위 경로를 명시하고 옛 경로를 금지 목록에 넣는다 |
| **안전 규칙이 1급 산출물** | GPT-6가 Studio 쓰기 권한을 갖는다. **플레이 중 쓰기 → Studio 메인 스레드 잠김 → 사용자가 Stop 누를 때까지 안 풀림.** 이건 이제 GPT-6의 위험이다 |
| **아트디렉션 구속 조건 명시** | GPT-6가 미적 판단을 한다. 1차 산곡 FX가 "비눗방울 안개"로 반려된 이력과 그 반성인 8개 지형 규칙은 참고자료가 아니라 **구속 조건**이다 |
| **작업 큐 형태** | 조사 결과가 "읽을 것"이 아니라 "할 일 목록"으로 끝나야 한다. 07_FX가 다 써놓고 한 번도 안 돌린 전례의 방어선 |

---

## 조사 질문

각 질문은 판정 가능해야 한다. "알아본다"가 아니라 "표의 이 칸을 채운다".

### Part 1 — 3D 월드 FX

| # | 질문 | 채울 것 |
|---|---|---|
| **W1** | 월드 FX 경로 6개 중 어떤 이펙트를 어디로 | 라우트 매트릭스 |
| **W2** | 산곡2 환경 7 + 전투 8은 각각 어느 경로 | 15행 매핑. `SGK_FX.lua` 403줄 중 얼마가 불필요해지는지 |
| **W3** | 146 프리셋 중 쓸 수 있는 것과 공백 | 전수 분류 + "니즈 ↔ 프리셋" 매핑 + 미충족 목록 |
| **W4** | 뭐가 제일 효과적인가 (품질/노력비) | 기법 순위. 1차 필터 = **128 px/프레임에서 읽히는가**(512÷4×4) |
| **W5** | 오버데어에서 **죽는** 기법과 우회법 | 사망 목록 + 항목별 "대신 이렇게" |

**W1의 여섯 경로**

| 경로 | 정체 | 커스텀 아트 | 자유도 | 현재 |
|---|---|---|---|---|
| **A** `VFXPreset` | 공식 기성 146개. `PresetName` 한 줄 | ✗ | Color/Size/Transparency만(?) | 0건 |
| **B** `VFXRecipe` | Niagara 39소스 3레이어, 템플릿 7종, `SetParam` | 간접 | 소스 교체·색·강도·딜레이 | 0건 |
| **C** `ParticleEmitter` + 플립북 | 우리가 구운 아틀라스. Grid 2x2/4x4/8x8 | ✓ | NumberSequence 커브 전부 | 0건 |
| **D** `Beam` / `Trail` | 텍스처 리본. **엔진 유일의 UV 스크롤**(`TextureSpeed`) | ✓ | 폭·색·스크롤 | 0건 |
| **E** `EmptySprite` (B 하위) | **임의 행×열 플립북 + `Size2D` 비정사각 → C보다 엄격히 상위** | ✓ | 최고 | 0건 |
| **F** 절차적 `Part` | Neon/Plastic을 코드로 생성·페이드 | 해당 없음 | 최고, 단 파츠 수가 곧 fps | **출시분 100%** |

### Part 2 — 2D UI FX

| # | 질문 | 채울 것 |
|---|---|---|
| **U1** | **v0.10.0 기준 UI 능력표를 다시 그리면 뭐가 달라지나** | 신구 델타표. v0.5.7 전제로 만든 로비 우회법 중 이제 불필요해진 것 |
| **U2** | UI FX 경로 5개 중 어떤 이펙트를 어디로 | UI 라우트 매트릭스 |
| **U3** | **`ImageRectOffset`/`ImageRectSize`가 있는가** | 이진. 2D UI VFX 전체 설계의 최대 분기 |
| **U4** | `CanvasGroup` 없이 여러 요소를 한 덩어리로 페이드하려면 | 그룹 페이드 관용구 |
| **U5** | HUD 전투 피드백 / 로비 연출 / 월드 빌보드 각각의 관용구 | 용처별 레시피 + 현행 대비 개선폭 |
| **U6** | 2D VFX를 뭘로 저작하나 | 블렌더 Grease Pencil / 정면 직교 렌더 / PIL 절차생성 / 외부 2D 툴 비교 |

**U2의 다섯 경로**

| 경로 | 정체 | 에셋 수 | 조건 | 현재 |
|---|---|---|---|---|
| **U-a** `ImageLabel` + `TweenService` | 정지 이미지 한 장을 트윈으로 | 1 | EasingStyle 11~14종 + `DelayTime` 확인됨 | 로비 일부 |
| **U-b** 아틀라스 플립북 | `ImageRectOffset/Size`로 시트 한 장을 셀 단위 재생 | **1** | **U3에 전적으로 걸림** | 0건 |
| **U-c** 프레임 시퀀스 | ImageLabel N개 프리로드 후 `Visible` 토글, 또는 `Image` 교체 | **N** | U-b 없을 때 폴백. 업로드 비용 N배 | 0건 |
| **U-d** 절차적 `Frame` | 코드로 그림. 색판·막대·테두리 | 0 | 회전 불가 시 십자막대 우회 | **출시분 100%** |
| **U-e** `BillboardGui` + `ImageLabel` | 위를 3D 공간에 | 1~N | 미검증 (SGK Tier 0.5) | 0건 |

**U3이 왜 최대 분기인가.** `ImageRectOffset`/`ImageRectSize`는 `ui-generator` 스킬 문서(`patterns\direct-gui.md:58`)엔 나오는데 **v0.10.0 타입파일의 `ImageLabel`에도 없고 MCP 스키마에도 없다.**
- **있다** → 16프레임 이펙트가 업로드 **1장**. 월드축 C경로와 **아틀라스 자산을 공유**할 수 있다. 2D/3D 파이프라인이 하나로 합쳐진다.
- **없다** → 16프레임이면 업로드 **16장**, 이펙트 종류마다 곱해진다. **저프레임 + 트윈 보간**으로 설계를 통째로 틀어야 한다.

### Part 3 — 공통

| # | 질문 | 채울 것 |
|---|---|---|
| **X1** | 블렌더에서 2D/3D 아틀라스를 굽는 정확한 레시피 | bpy 스니펫 + 버전 함정 |
| **X2** | 시네마틱 릴 FX에서 AK 작업의 일반화 | 릴 전용 기법 + 왜 그 방법이 이겼는지 |
| **X3** | 포스트FX가 0인 환경에서 "빛나 보이게" 하는 법 | `Neon`/`Unlit`/`MaterialVariant.Emissive`/`LightEmission`/글로우 굽기 비교 |
| **X4** | 참고할 실제 사례·샘플은 어디에 | 링크 목록 (라이선스 + 라우트 태그 필수) |
| **X5** | 문서만으로 확답 못 내는 건 뭔가 | **GPT-6 1번 태스크가 될 프로브 명세 + 실행 가능한 `FXProbe2.lua`** |

---

## 비목표 — 조사하지 않는다

팬아웃 에이전트 프롬프트에 그대로 박아 넣는다.

1. **Studio 실측** — GPT-6 몫. X5는 **명세와 스크립트만** 만든다.
2. **스프라이트 실제 굽기 / CC0 대량 다운로드** — GPT-6 몫. 레시피와 링크만.
3. **오버데어 API 표면 재조사** — 3093줄은 이미 채굴됐다. **단 UI 부분(U1)은 예외** — v0.5.7 기준이라 다시 그려야 한다.
4. **셰이더 의존 기법** — 모션벡터 플립북, 소프트/뎁스 페이드, VAT, 런타임 디졸브, SDF 왜곡, 6-way lighting. 커스텀 셰이더도 머티리얼 그래프도 없다. **"제외 사유" 칸에만.**
5. **포스트 프로세싱** — Bloom/DOF/ColorCorrection/Blur/SunRays 전부 API 0. X3 한 항목만.
6. **Mantaflow 고해상도 시뮬** — Blender 문서가 res 256 × 250프레임 ≈ 최대 ~80 GB라고 적어놨다. 여유 14 GB에서 즉사. CC0 VDB 경로가 대체.
7. **VectorayGen / 벡터 필드, Gaussian splat** — 오버데어에 소비처가 없다. 무료라는 이유로 목록에 넣지 않는다.
8. **AK 오프라인 파이프라인 재론** — 증명됐고 엔진 이전 불가. "정답 그림" 참조용으로만.
9. **UV 스크롤 표면 효과** — Decal/Texture 클래스가 없어 `OffsetStudsU/V`가 없다. `Beam/Trail.TextureSpeed`가 유일하고 그건 D경로.
10. **사운드 전 범위 제외.**
11. **이미 확정된 것 재조사 금지** — 8개 지형 규칙, AK 진화 4단계, `Instance.new` 클래스 목록, `FX_LIMIT` 예산. 이건 **입력**이다.

---

## 실행 구조 — Workflow 1회

### Phase 1 — 9축 병렬 조사 (pipeline, 배리어 없음)

각 축은 조사 → 적대적 검증을 독립적으로 통과한다.

| 축 | 내용 | 소스 |
|---|---|---|
| **W-a** 월드 기법 분류 | 실시간 VFX 기법 전체 → 생존/부분생존/사망 3분류 + 우회법 | 웹 |
| **W-b** ParticleEmitter 크래프트 | 로블록스 관용구를 오버데어 차이분 반영해 번역. 28배 환산, `ZOffset` 없음(레이어링 대안), `LightInfluence`/`VelocityInheritance`/`TimeScale` 없음, `SpreadAngle`이 number, `Brightness`·`Clear()` 추가분 | 웹 + 로컬 타입파일 |
| **W-c** 오버데어 로컬 카탈로그 채굴 | 146 프리셋 전수 분류, 39 소스 파라미터, 템플릿 7종, `EmptySprite` 제약의 성격(스킬은 "AI 조합에 쓰지 마라" — 금지인가 권고인가) | **로컬 전용, 네트워크 금지** |
| **U-a** UI 능력표 재작성 | v0.10.0 ↔ v0.5.7 델타. `UIStroke`/`Rect`/`ScaleType`/`SliceCenter`/`Font`/`ProgressBar` 신규분. `GuiObject.Rotation` 충돌 판정. `ImageRectOffset/Size` 3자 대조(스킬문서/타입파일/MCP스키마) | **로컬 전용, 네트워크 금지** |
| **U-b** 2D/UI VFX 크래프트 | 히트마크, 데미지 비네트, 킬 피드, 화면 전환, 버튼 반응, 로딩. 트윈 커브 설계, 저프레임+보간, `CanvasGroup` 없는 그룹 페이드, 빌보드 2D | 웹 |
| **X-a** 블렌더 → 아틀라스 굽기 | **2D 경로**(Grease Pencil, 정면 직교 렌더, PIL — 기존 `sgk_fx_sprites.py` 선례) + **3D 경로**(CC0 VDB → EEVEE 베이크). 알파 프리멀티플라이, **4.2+ Render Method 기본값 Dithered → 알파 가장자리 노이즈, Blended 명시 필수**, **5.0에서 `BLENDER_EEVEE_NEXT`→`BLENDER_EEVEE` 엔진 ID 변경**, 프레임 간 패딩, 아틀라스 패킹 애드온 | 웹 + Blender 릴리스노트 |
| **X-b** 시네마틱 릴 | AK 일반화: 실사 스프라이트+심 연기+Cycles가 왜 이겼나, 2D 후합성이 옳은 경우(트레이서 13번 실패의 구조적 이유), 릴 전용 기법, 노트북 예산 안의 렌더 규모 | 로컬 + 웹 |
| **X-c** 샘플 인덱스 | CC0 플립북(Unity 무료 시퀀스), CC0 VDB(JangaFX), Kenney, OpenGameArt, GoVFX, 로블록스 오픈소스(Yuruzuu, CIX 600+, Mesh Flipbook Pack, Lumina), 커뮤니티(RealTimeVFX, VFXDoc), 갤러리(Niagara Examples, Unity VFX Graph Samples), **UI FX 전용 소스** | 웹 |
| **I** 우리 이펙트 인벤토리 | 출시분(ParryFX / BarrierFX / HUD.flash / Crosshair / BoundaryFX / FriendlyHighlight / ViewmodelController_2의 makePuff·fxPart·arrow·aimPart / RyunochiDragon) + 계획분(07_FX 환경 7 + 전투 8) 전수. **월드/UI 양쪽** | **로컬 전용, 네트워크 금지** |

**축 분리 원칙**: W-c · U-a · I는 **네트워크를 쓰지 않는다.** 순수 로컬 마이닝이다. 웹 축과 섞으면 웹 상식이 로컬 사실을 오염시킨다.

**공통 출력 스키마 — `required_api`가 핵심 장치**

```json
{
  "claim": "한 줄 주장",
  "source_tag": "overdare_v0.10.0_types:L2471 | overdare_local_skill | roblox_docs_UNVERIFIED | web",
  "url": "…",
  "required_api": ["ParticleEmitter.FlipbookLayout"],
  "exact_spelling": "Outward",
  "route": "A|B|C|D|E|F|U-a|U-b|U-c|U-d|U-e|none",
  "license": "CC0|CC-BY|proprietary|trial|n/a",
  "verdict": "adopt|candidate|reject",
  "reject_reason": "오버데어에 SurfaceAppearance 없음",
  "confidence": "high|med|low",
  "needs_probe": false,
  "stud_scale_applied": true
}
```

`required_api`를 못 채우면 **자동 기각**. 검증 노드가 그 이름을 v0.10.0 타입파일에서 grep해 즉시 판정한다. `stud_scale_applied`는 28배 환산 누락을 잡는다.

**적대적 검증 (각 축 직후, 3렌즈)**
- *정확성* — 정말 **v0.10.0** 타입파일에 있나? `runtime\`(v0.5.7)을 보고 있는 건 아닌가? 철자는?
- *적용가능성* — "된다"가 이 엔진에서 되나, 로블록스에서만 되나? `required_api`가 실존하나?
- *비용* — 노트북 14 GB / 인스턴스 예산 안에서 되나? 128 px에서 읽히나?

과반이 반박하면 결론에서 빼고 "미검증"으로만 남긴다. `unverifiable`은 **자동으로 프로브 명세로 승격**된다.

> **최대 실패 모드는 로블록스 자료를 오버데어 사실로 오염시키는 것이다.** 두 엔진은 문법이 같고 의미가 다르다. **그리고 이번엔 그 오염이 GPT-6에게 그대로 상속된다** — 잘못된 한 줄이 조용히 실패하는 코드가 된다. 검증은 옵션이 아니다.

### Phase 2 — 교차 통합 (배리어)

1. 월드 라우트 매트릭스(A~F) + UI 라우트 매트릭스(U-a~U-e). **"아트디렉션 통제권"** 칸 필수 — 프리셋의 진짜 비용이 거기 있다
2. **결정 트리 2개** — 이 조사의 본체
3. **인벤토리 매핑** = GPT-6의 작업 큐
4. **프로브 명세 + `FXProbe2.lua`** — GPT-6의 1번 태스크
5. **환각 차단 목록** — 없는 API 전수 + 각각의 대체물

### Phase 3 — 인계 리허설 (이 조사 고유의 검증)

**패키지만 읽은 신선한 에이전트**(다른 컨텍스트 일절 없음)에게 실제 과제를 준다:
- "산곡2 계류 물안개를 만들어라. 어느 경로로 갈지 정하고 코드를 써라."
- "로비 버튼 프레스 이펙트를 만들어라."
- "총구 화염 아틀라스를 구울 bpy 스크립트를 써라."

**막히거나 없는 API를 부르면 그게 패키지의 구멍이다.** 구멍을 메우고 다시 돌린다. 두 라운드 연속 구멍이 없으면 종료.
동시에 *레드팀*이 추천 자체를 공격: 프리셋 우선이 아트디렉션 상한을 만드는가(146개는 남의 게임 톤 — 조선/산곡과 맞나)? 자작 플립북이 노트북 예산에서 지속 가능한가? 결정 트리에 "어느 쪽도 아님" 분기가 있는가? U3이 "없다"로 나와도 UI 설계가 성립하는가?

---

## 산출물 — 인계 패키지

`Handoffs\` 폴더의 기존 규약(`KRM_이관_명세서.md`, `크렘린_이관_명세서.md` — "이 폴더만 있으면 Studio에 넣을 수 있다")을 따른다.

```
GameDev\Handoffs\VFX_이관_명세서.md   진입점. 규약대로. GPT-6가 제일 먼저 읽는 것

GameDev\VFX\
  00_START_HERE.md      임무 · 읽을 순서 · 1번 태스크 · ★안전 규칙
  01_ENGINE_TRUTH.md    ★검증된 API 표면. 선언문 원문 발췌 + 줄번호. 있다/없다/정확한 철자
  02_DO_NOT.md          ★환각 차단. "로블록스 습관 → 오버데어 대체" 대조표
  03_ROUTES_WORLD.md    A~F 매트릭스 + 결정 트리
  04_ROUTES_UI.md       U-a~U-e 매트릭스 + 결정 트리 (U3 양 분기 병기)
  05_PRESET_MAP.md      146 프리셋 ↔ 우리 니즈 + 공백 목록
  06_RECIPES.md         복붙 가능한 Luau 스니펫 / VFXRecipe JSON 페이로드
  07_BAKE.md            블렌더 굽기 — bpy 스니펫 + 버전 함정
  08_ART_RULES.md       ★아트디렉션 구속 조건. 8개 지형 규칙 + "비눗방울 안개" 반려 이력
  09_INVENTORY.md       출시분 + 계획분 ↔ 라우트 = 작업 큐
  10_PROBE.md           실측 명세 (월드 + UI)
  11_OPEN_QUESTIONS.md  검증 안 된 주장 · 미해결 · 판단 유보
  12_SAMPLES.md         샘플 링크 (URL·라이선스·MB·라우트 태그)
  manifest.json         기계 판독용 인덱스 — 라우트/API/인벤토리 구조화
  probe\FXProbe2.lua    ★GPT-6의 1번 태스크. 바로 실행 가능
```

마크다운 13개 + JSON + Luau 1개. **총 150 KB 미만.** 디스크 여유 14 GB에 영향 없음.

### 산출물별 판단 (메뉴가 아니라 결정)

| 산출물 | 판단 | 이유 |
|---|---|---|
| **`02_DO_NOT.md`** | **만든다 — 최우선** | GPT-6 대상 패키지에서 단일 최고가치 문서. 없는 API를 부르면 조용히 실패한다 |
| **`01_ENGINE_TRUTH.md`** | **만든다 — 원문 발췌 필수** | 요약하면 GPT-6가 자기 기억으로 보충한다. `ParticleEmitter` 선언 30줄, 열거형 전부, `VFXPreset`/`VFXRecipe`, UI 클래스는 **그대로 인용** |
| **결정 트리 2개** | **만든다 — 본체** | 각 한 페이지. 나머지는 근거자료 |
| **`08_ART_RULES.md`** | **만든다** | GPT-6가 미적 판단을 하므로 구속 조건이 필요하다. "비눗방울 안개" 반려 이력이 여기 없으면 같은 실수를 반복한다 |
| **`09_INVENTORY.md`** | **만든다 — 필수** | 07_FX 전례(다 써놓고 한 번도 안 돌림)의 방어선. 조사 항목마다 어느 줄에 꽂히는지 명시 |
| **`probe\FXProbe2.lua`** | **만든다 — 실행은 GPT-6** | `07_FX\FXProbe.lua`의 pcall 안전 생성자 + `[FXPROBE]` 로그 패턴 재사용. 실측이 **한 세션이면 끝나는 상태**로 놔둔다 |
| **`manifest.json`** | **만든다** | GPT-6가 표를 파싱하는 것보다 구조화된 데이터가 안전하다 |
| **샘플 다운로드** | **안 한다. 인덱스만** | 사용자 지시. 512÷4×4 = 128 px 필터에서 화려한 CC0 팩 대부분이 죽는다. 먼저 거르고 GPT-6가 받는다 |
| **테스트 스프라이트 굽기** | **안 한다** | GPT-6 몫. `07_BAKE.md`에 절차만. 기존 `fx_smoke_4x4_512.png` / `fx_splash_4x4_512.png` 재활용 판정은 포함 |
| **블렌더 프리뷰 렌더** | **자른다** | 오프라인 렌더 품질은 인게임 품질을 예측하지 못한다. `sgk_fx_preview.py`(621줄)로 이미 확인했고 반려됐다 |
| **프리셋 146개 스크린샷** | **자른다** | Studio 세션 수십 회. GPT-6가 필요할 때 후보만 본다 |

### `00_START_HERE.md`에 반드시 들어갈 안전 규칙

GPT-6가 Studio 쓰기 권한을 가지므로 이건 참고사항이 아니다.

1. **쓰기 전 반드시 `overdare_stop`.** 플레이테스트 중 `overdare_script_edit`/`upsert` → `level.apply` 타임아웃 → **Studio 메인 스레드 잠김. 사용자가 Stop을 눌러야만 풀린다.** (2026-08-25 재현됨. `.ovdrjm`는 롤백돼 손실은 없다)
2. **모든 프로퍼티 쓰기는 `pcall`.** 없는 프로퍼티 하나가 스크립트 전체를 중단시킨다.
3. **FX 파츠를 캐릭터 아래에 두지 마라.** `MovementSpeedServer.stripCharacterApparel`이 표준 신체 부위가 아닌 BasePart를 전부 지운다. Workspace에 띄우고 매 프레임 따라가라.
4. **맵 컨테이너 아래에 두지 마라.** 맵 스왑 시 고아가 된다. `_G.MapEpoch` 변하면 통째로 재구축.
5. **런타임 스폰 FX는 Movable 최상위 아래에.** Mobility는 Workspace 직계 자식에만 설정 가능하고 서브트리 전체에 전파된다. Static 서브트리는 런타임 생성·이동 불가.
6. **매 프레임 새로 만들지 마라** — 사전 할당 후 재배치. (`aimPart` 주석: "매 프레임 새로 만들면 파츠가 수백 개씩 쌓인다")
7. **Transparency만으론 안 사라진다** — Size도 같이 줄인다. 명멸은 Size로.
8. **`Debris` 없다** → `task.delay` + `Destroy`.
9. **런타임 RemoteEvent 생성 금지** → 기존 `CombatEvent`/`RyunochiEvent` + `_G.Sfx` 래퍼.

---

## 검증

1. **모든 API 주장에 출처 태그** — `[v0.10.0 타입파일 L####]` / `[로컬 스킬]` / `[로블록스 문서 — 오버데어 미검증]` / `[웹]`. 최대 실패 모드의 유일한 방어선
2. **`required_api`가 빈 findings가 결론에 들어갔나** — 있으면 불합격
3. **v0.5.7 근거 UI 주장이 남아 있나** — 전부 v0.10.0 재확인
4. **`02_DO_NOT.md`의 모든 항목에 대체물이 붙었나** — "없다"만 있고 대안 없는 항목은 미완성
5. **`01_ENGINE_TRUTH.md`의 발췌가 요약이 아니라 원문인가**
6. **인벤토리 전 행이 채워졌나** — 빈 칸은 `10_PROBE.md`로 이관됐는지
7. **결정 트리에 "어느 쪽도 아님" 분기가 있나**
8. **28배 각주가 매트릭스와 레시피 양쪽에 있나**
9. **`FXProbe2.lua`가 문법적으로 유효한가** — 로컬 lint. 실행은 안 함
10. **인계 리허설 통과** (Phase 3) — 신선한 에이전트가 세 과제에서 없는 API를 부르지 않았나
11. **링크 스팟체크** — `12_SAMPLES.md`에서 무작위 5~8개 WebFetch 생존 확인

---

## 리스크

| # | 리스크 | 영향 | 완화 |
|---|---|---|---|
| **R-1** | **로블록스 오염이 GPT-6에게 상속** — 문법 동일, 의미 상이 | 조용히 실패하는 코드. 이미 "비눗방울 안개"로 한 번 당함 | `02_DO_NOT.md` + 출처 태그 강제 + `required_api` 자동 기각 + 3렌즈 검증 + 인계 리허설 |
| **R-2** | **v0.5.7 사본을 근거로 씀** — `runtime\` 경로가 함정 | UI 결론이 통째로 틀림 | 모든 축 프롬프트에 `runtime-v0.10.0` 명시. `00_START_HERE`에 "읽지 마라" 경로 목록 |
| **R-3** | **U3 미확정** | UI 설계가 두 갈래로 갈린 채 결론 안 남 | 결정 트리를 **양 분기 다 그린다.** 프로브 명세 상위 항목 |
| **R-4** | **`VFXRecipe`가 런타임에 없을 수 있음** — 2026-08-28 MCP enum에 부재, 타입파일(09-01)엔 존재 | B·E 경로 붕괴 | 프로브 **1번 항목**. 매트릭스에 "미검증 전제" 명시 |
| **R-5** | **GPT-6가 Studio를 얼림** | 사용자 수동 개입, 세션 손실 | `00_START_HERE` 안전 규칙 1번 + `FXProbe2.lua` 헤더 주석에 중복 명시 |
| **R-6** | **28배 스케일 누락** | 안 보이거나 화면 도배 | 매트릭스·레시피 전역 각주 + 스키마 필드 강제 |
| **R-7** | **프리셋 락인** | 아트디렉션 상한. 산곡/조선 톤과 남의 IP 톤 충돌 | 매트릭스 "통제권" 칸. 레드팀 1번 항목. 리틴트 가능 범위를 프로브로 |
| **R-8** | **`ZOffset` 없음** | 8개 규칙 중 "3층 겹치기"가 카메라 회전 시 깨질 수 있음 | 프로브 항목. 깨지면 3층 → 단층 고밀도로 규칙 개정 |
| **R-9** | 패키지가 너무 커서 GPT-6가 다 안 읽음 | 핵심을 놓친 채 작업 | 150 KB 상한. `00_START_HERE`가 읽을 순서를 지정. `02_DO_NOT`·`08_ART_RULES`는 **필독** 표시 |
| **R-10** | 조사가 실행으로 안 넘어감 (07_FX 전례) | 또 문서만 남음 | `09_INVENTORY.md`가 작업 큐 형태 + `FXProbe2.lua`가 바로 실행 가능 |
| **R-11** | 노트북 / 디스크 14 GB | — | 이번 산출물은 텍스트 150 KB. Studio도 안 건드린다. 비상시 `Handoffs\JSN_Sangok_handoff_20260814.zip`(**1.13 GB**) + `Weapons\_Showcase`(732 MB) + `Media\Renders`(361 MB) ≈ **2.2 GB 회수 가능** — 삭제는 사용자 승인 후에만 |

---

## 규모를 줄여야 한다면 (Cut Path)

"하루 안에"면 이 순서로 자른다.

1. **X-b(시네마틱 릴) 삭제** — AK로 이미 성공했다. GPT-6 임무에서도 우선순위가 낮다.
2. **X-c(샘플 인덱스) 축소** — 프리셋 146개가 사실상 우리 샘플 라이브러리다. CC0 인덱스는 상위 10개만.
3. **X-a를 2D만 남김** — 3D VDB 베이크 빼고, 기존 `sgk_fx_sprites.py`(PIL) 확장 경로만.
4. **최소 코어**: `01_ENGINE_TRUTH` + `02_DO_NOT` + `08_ART_RULES` + `09_INVENTORY` + `10_PROBE` + `probe\FXProbe2.lua`. **웹 0회, Studio 0회.**

이 최소 코어만으로도 GPT-6는 **환각 없이, 아트디렉션 구속 조건을 지키며, 작업 큐를 갖고, 첫 태스크(실측)를 바로 실행할 수 있다.** 나머지는 품질을 올리는 부속이다.
