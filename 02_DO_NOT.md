# 02 DO NOT — 환각 차단 목록

**이 문서가 이 패키지에서 단일 최고가치다.**

OVERDARE는 로블록스와 문법이 거의 같다. 그래서 로블록스 지식이 그대로 나온다 — 그리고 **여기 있는 것들은 이 엔진에 없다.**
없는 클래스를 `Instance.new`로 만들면 무타입 오버로드(`(className: string) -> Instance`)로 떨어져 **에러 없이 무언가를 돌려주거나 조용히 실패한다.** 없는 프로퍼티에 쓰면 `pcall` 밖에서는 스크립트 전체가 멈춘다.

확인 방법: `grep -c "\bNAME\b" runtime-v0.10.0\assets\lua\overdare-types.d.lua` → 0.
**그리고 `--!strict` + `overdare_validate_lua`가 이걸 기계로 잡는다** (README §6).

---

## 1. 없는 클래스 (grep 0건) → 대체물

| 로블록스에서 쓰던 것 | 오버데어 | 대신 이렇게 |
|---|---|---|
| `Sparkles` | **없음** | `ParticleEmitter` + 반짝임 스프라이트, `Rotation`/`RotSpeed` 랜덤 |
| `Fire` | **없음** — grep의 유일한 히트는 `RemoteEvent:Fire()` 메서드다 | `VFXPreset "VFX_UGC_Fire_01/02"` 또는 `ParticleEmitter` 플립북 |
| `Smoke` | **없음** | `VFXPreset "VFX_UGC_SimpleSmoke_01"` 또는 연기 아틀라스 |
| `Explosion` | **없음** (물리 밀어내기도 같이 없다) | `VFXPreset "VFX_UGC_Explosion_02"` / `VFXRecipe combo_05` + 직접 쓴 반경 데미지 |
| `Highlight` | **없음** | **`Outline`**(`Color`, `Thickness`) + **`Fill`**(`Color`, `Transparency`, `DepthMode`). 둘 다 `OverlayBase`라 `.Adornee`를 쓴다. ⚠️ `Fill.DepthMode`는 문서대로 동작하지 않는다 — `10_OPEN_QUESTIONS.md` Q-2 |
| `Decal` | **없음** | 얇은 `Part` + `SurfaceGui`+`ImageLabel`, 또는 `VFXRecipe`의 `NeutralDecal_A`/`FireDecal_A`/`TechDecal_R_A` 소스 |
| `Texture` (클래스) | **없음** | 위와 같음. **`OffsetStudsU/V`·`StudsPerTileU/V`가 통째로 없다는 뜻이다** |
| `SurfaceAppearance` | **없음** | **`MaterialVariant`** — `ColorMap`/`NormalMap`/`RoughnessMap`/`MetalnessMap` + **`Emissive`/`EmissiveIntensity`/`EmissiveMap`**. `BasePart.MaterialVariant`에 *이름 문자열*로 붙인다 |
| `Sky` / `Clouds` | **없음** | **`Atmosphere`** 하나에 다 있다 — `CloudAmount`/`CloudSpeed`/`CloudTexture`/`FogColor`/`FogDensity`/`FogFalloff`/`FogStart`/`HazeColor`/`GlareColor`. **라이브 레벨의 `Lighting` 아래에 이미 하나 놓여 있다** |
| `SpecialMesh` | **없음** | `MeshPart` (`MeshId`, `TextureId`, `MeshSize`, `DoubleSided`) |
| `Debris` | **없음** | `task.delay(t, function() obj:Destroy() end)` |
| `ViewportFrame` | **없음** | 3D 오브젝트를 실제로 배치하고 카메라 수식으로 화면 좌표를 구해 투명 버튼을 얹어라 |
| `EditableImage` / `EditableMesh` | **없음** | 오프라인(PIL·블렌더)에서 굽고 `overdare_image_import` |
| `Motor6D` / `WeldConstraint` | **없음** | 부모-자식 계층 + `CFrame` |

## 2. 포스트 프로세싱 — **API가 통째로 0이다**

`BloomEffect` · `SunRaysEffect` · `ColorCorrectionEffect` · `BlurEffect` · `DepthOfFieldEffect` — **전부 0건.** `Lighting`의 자식으로도 없다.

전역 화면 조정에 쓸 수 있는 건 `Lighting.Brightness` / **`Contrast`** / **`Saturation`** / `Ambient` 넷뿐이다.

→ **"빛나 보이게"는 전부 소재 레벨에서 해결해야 한다** — `03_ROUTES_WORLD.md` §4.

## 3. 없는 UI 클래스

| | 오버데어 | 대신 |
|---|---|---|
| `UICorner` | **없음** | 둥근 모서리 PNG를 `ImageLabel`로. **단 `ScaleType.Slice`+`SliceCenter`가 생겼으니 9-slice가 된다** (§7) |
| `UIGradient` | **없음** | 그라디언트 PNG + `ImageColor3` 틴트 |
| `UIPadding` | **없음** | `Position`/`Size` 오프셋으로 직접 |
| **`CanvasGroup`** | **없음** | **그룹 페이드가 안 된다.** → **`UIMotion.M.group`을 써라** (`04_ROUTES_UI.md` §0). 직접 짜지 마라 |
| **`UIScale`** | **없음** (UIMotion 실측) | 팝은 `Size`(UDim2)를 트윈하고 `AnchorPoint`로 재중심화 |
| `TextBox` | **없음** | 입력 없음 |
| **`ImageRectOffset` / `ImageRectSize`** | **없음 (0건, `validate_lua`로 재확인)** | **UI 스프라이트시트 재생이 프로퍼티로는 불가능하다.** `ui-generator` 스킬 문서(`patterns\direct-gui.md:58`)에 나오지만 **타입파일에도 MCP 스키마에도 없다 — 문서가 틀렸다.** 우회법은 `04_ROUTES_UI.md` §2 |

**`ScaleType`은 `Stretch` / `Slice` 둘뿐이다.** 로블록스의 `Tile`/`Fit`/`Crop`은 없다 → **`Crop`으로 아틀라스 셀을 자르는 트릭도 불가능하다.**

## 4. ParticleEmitter에 없는 프로퍼티

| 없는 것 | 영향 | 대신 |
|---|---|---|
| **`ZOffset`** | **파티클 정렬 제어 불가.** 불을 연기 앞에 강제로 둘 수 없다 | 이미터를 카메라 쪽으로 물리적으로 오프셋. 겹침 의존 설계를 피해라 |
| `LightInfluence` | 조명 영향도 조절 불가 (`SurfaceGuiBase`에는 있다) | `LightEmission` + `Brightness` |
| `VelocityInheritance` | 이동체가 파티클을 끌고 가지 않는다 | `LockedToPart`(오버데어 추가) 또는 수동 `Acceleration` |
| `TimeScale` | 슬로모션 불가 | — |
| `WindAffectsDrag` | 전역 바람 연동 없음 | `Acceleration`에 바람 벡터를 직접 |
| `ShapePartial` | 부분 방출각 없음 | `SpreadAngle` + `EmissionDirection` |
| 커스텀 `FlipbookSizeX/Y` | **행×열 자유 지정 불가** | `Grid2x2/4x4/8x8` 셋 중에서만. 자유 격자는 `VFXRecipe`의 `EmptySprite`(`FlipbookRows`/`FlipbookColumns`) |

**반대로 로블록스에 없는데 여기 있는 것:** `Brightness: number` · `LockedToPart: boolean` · `Clear()`.
**타입이 다른 것:** `SpreadAngle`이 `number`다 (로블록스는 `Vector2`). `RotSpeed`는 `number`, `Rotation`은 `NumberRange`.

## 5. 없는 서비스·함수

- **`RunService:BindToRenderStep` / `UnbindFromRenderStep` 없음(0건).** `RunService.RenderStepped:Connect(...)`로 붙이고 `ScriptConnection:Disconnect()`로 직접 관리.
- **`BaseScript`의 프로퍼티는 `Enabled`다. `Disabled`는 없다(0건).** 로블록스와 반대 의미이니 주의.
- **`Color3:Lerp` 없음** (UIMotion 실측) → `UIMotion.M.lerpColor`.
- **`TweenService:GetValue` 없음** (UIMotion 실측) → 수동 보간은 `UIMotion.M.bezier`.
- **호버 이벤트 없음** (LobbyUI 실측) — `InputBegan`에 `MouseMovement`가 **한 번도 안 온다**(로그 0건). `Activated`는 정상. 누름 반응을 `Activated` 순간에 걸어라.
- **`TweenService:Create`의 반환 타입이 `Tween`이 아니라 `Instance`로 선언돼 있다.** `:Play()`는 되지만 자동완성이 안 된다.
- **`TweenInfo.new`는 6인자가 전부 선언돼 있다** (`InTime, InEasingStyle, InEasingDirection, InRepeatCount, InReverses, InDelayTime`). 옵셔널 표기가 없으니 6개 다 넘겨라.
- `EasingStyle`은 **11종**: Linear, Sine, Back, Quad, Quart, Quint, Bounce, Elastic, Exponential, Circular, Cubic. 커스텀 베지어는 `UIMotion.M.bezier`.
- `PathfindingService` · `MessagingService` · `TextChatService` 없음.

## 5b. `--!strict`에서만 드러나는 함정 (실측 2026-09-08)

이 리포의 `probe/FXProbe.lua`를 `overdare_validate_lua`에 태우다 나온 것들이다. **런타임엔 돌 수도 있지만 타입 검사를 통과하지 못한다.**

| 쓰면 안 되는 것 | 왜 | 대신 |
|---|---|---|
| `NumberSequence.new(0.5)` | *"expects 2 arguments, but only 1 is specified"* — 1인자 오버로드가 strict에서 해결되지 않는다 | **`NumberSequence.new(0.5, 0.5)`** |
| `ColorSequence.new(c)` | 위와 같음 | **`ColorSequence.new(c, c)`** |
| `obj:FindFirstChild("Name")` | *"expects 3 arguments, but only 2 are specified"* — recursive 인자가 필수로 선언돼 있다 | **`obj:FindFirstChild("Name", false)`** |

`Enum.*` 접근도 strict에서 자주 막힌다 → `(Enum :: any).ParticleFlipbookLayout.Grid4x4` 처럼 캐스트해라.
`Instance.new`도 무타입 클래스에는 `(Instance :: any).new("Trail")`.

## 6. 철자 함정 — **틀리면 에러가 아니라 조용한 실패다**

| 올바른 것 | 틀린 것 | 근거 |
|---|---|---|
| `Frame.BorderPixelSize` | ~~`BorderSizePixel`~~ (로블록스 철자) | L2062. `validate_lua`가 `--!strict`에서 잡는다 |
| `BaseScript.Enabled` | ~~`Disabled`~~ | 타입파일 |
| **Luau**: `Enum.ParticleEmitterShapeInOut.Outward` / `.Inward` | — | L1271-1277 |
| **MCP 도구 경유**: `"OutWard"` / `"InWard"` (대문자 W) | — | MCP 스키마. **두 경로에서 철자가 다르다** |
| `Enum.ParticleEmitterShape.Disc` | ~~`Disk`~~ | L1261-1269 |
| `TextLabel.FontFace = Font.new(...)` | ~~`Bold = true`~~ | `Bold(set)`은 **deprecated 경고를 뿜는다** (`Play.log`에서 확인). `LobbyUI.lua:742`가 아직 옛 방식이다 |

## 7. 낡은 주석이 "없다"고 했지만 **지금은 있는 것** (v0.5.7 → v0.10.0)

프로젝트 주석 중 상당수가 v0.5.7 시절 판단이다. 다음은 **v0.10.0에 실재한다.**

| 항목 | 낡은 주석 | v0.10.0 실측 |
|---|---|---|
| **`GuiObject.Rotation`** | `ParryFX.lua`: *"이 엔진 문서에 GuiObject.Rotation 이 없다. 별은 십자 막대 두 개로 그린다"* | **있다 — L2050 `Rotation: number`.** 십자막대 우회 불필요 |
| **`ImageLabel.ScaleType`/`SliceCenter`/`SliceScale`** | *"9-slice 없음 → 판마다 실제 쓰는 크기 그대로 굽는다"* | **있다 — L2220-2222** |
| **`UIStroke`** | `LobbyUI.lua:26`·`HUD.lua:18`: *"없음"* | **있다 — L2930.** ⚠️ 단 `Crosshair.lua:45`는 *"엔진에 UIStroke는 생겼지만 여기선 조각마다 회전까지 맞춰야 해서 이 방식이 더 단순하다"*고 **알고 내린 선택**이다. 주석마다 신선도가 다르다 |
| **`TextLabel.TextScaled` / `FontFace: Font`** | *"글자 스케일 없음, Bold boolean 뿐"* | **있다 — L2841, L2845** |
| `Rect` · `TextService` · `ProgressBar` · `VFXRecipe` | 없음 | **v0.10.0 신규** |

**여전히 유효한 옛 함정:**
- `Camera:WorldToViewportPoint`는 **카메라 뒤 대상에도 좌표를 준다.** `Z > 0`을 직접 걸러라 — 안 그러면 좌우 반전된 유령이 찍힌다
- **`Visible = false`인 요소는 `AbsolutePosition`이 갱신되지 않는다** (`Size`는 맞다)
- **트윈 직후 같은 속성을 직접 쓰면 트윈이 통째로 무효가 된다** — `UIMotion.M.tween`은 이걸 레지스트리로 처리한다
- 레이캐스트는 `CanCollide=false`/`CanTouch=false` 진열물을 통과한다
- ⚠️ **`ZIndex`는 형제(계층) 기준이고 전역이 아니다** (UIMotion 실측). 컨테이너를 하나 끼우면 겹침 순서가 통째로 바뀐다

## 8. 이 프로젝트에서 하지 말아야 할 것

- **다시 만들지 마라 — 이미 있다:**
  - `_G.HUD.flash(color, strength, hold)` — 화면 테두리 물듦. `HUD.lua` 헤더: *"나중에 그 시스템들이 색만 바꿔 부르면 된다. **테두리를 또 만들지 마라.**"*
  - `UIMotion` (ReplicatedStorage ModuleScript) — 트윈·그룹페이드·팝·바·펄스 19개 함수
  - `_G.Sfx(name, at)` / `_G.SfxBgm(name)` — 사운드
- **`overdare_screenshot`으로 UI를 확인하려 하지 마라.** 3D 뷰포트만 나온다. UI는 `overdare_ui_browse`(플레이 중) 또는 `Play.log`.
- **오프라인 블렌더 렌더로 인게임 품질을 판단하지 마라.** 과거에 그렇게 판단한 결과물이 "비눗방울 안개"로 반려됐다. 판정 근거는 `overdare_screenshot`뿐이다.
- **모션벡터 플립북·소프트파티클·VAT·런타임 디졸브·SDF 왜곡·6-way lighting을 시도하지 마라.** 전부 커스텀 셰이더가 필요하고 이 엔진엔 셰이더도 머티리얼 그래프도 없다. → `03_ROUTES_WORLD.md` §5
- **`EmptySprite` / `EmptySprite_R`를 일반 이펙트 조합에 쓰지 마라.** `vfx-recipe` 스킬이 명시적으로 금지한다(*"Not used in AI composition"*). **단 커스텀 텍스처를 VFXRecipe에 넣는 유일한 통로이기도 하다** — `10_OPEN_QUESTIONS.md` Q-4.
- **`ZZ_` 스크립트를 다시 켜지 마라.** README §3.12.
