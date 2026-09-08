# 07 UI INVENTORY — 실제 UI와 FX 부착점

라이브 레벨 + 소스 실측 (2026-09-08).

**`StarterGui`는 비어 있다.** UI는 전부 `StarterPlayerScripts`의 LocalScript가 런타임에 만든다.

---

## 1. 클라이언트 스크립트 13개 (StarterPlayerScripts)

| 스크립트 | 크기 | UI를 만드나 | 역할 |
|---|---|---|---|
| `ViewmodelController` (`ViewmodelController_2.lua`) | 155 KB | 3D만 | 뷰모델·근접전·모든 월드 FX의 본산 |
| `LobbyUI` | 59 KB | ✅ | 로비 화면 (M3 + 무기 랙) |
| `HUD` | 34 KB | ✅ | 인게임 HUD |
| `Crosshair` | 11 KB | ✅ | 샷건 크로스헤어 `( . )` |
| `ParryFX` | 11 KB | ✅ | 패링 텔레그래프 + 스턴 별 |
| `BoundaryFX` (`BoundaryFX_1.lua`) | 11 KB | ✅ + 3D | 경계 경고 |
| `FriendlyHighlight` | 7 KB | ✅ | 아군/적군 표시 |
| `MobileControls` | 6 KB | ✅ | 조이스틱 |
| `SoundClient` (`SoundClient_1.lua`) | 10 KB | — | 사운드. `_G.Sfx` / `_G.SfxBgm` |
| `FirstPersonLock` (`_1.lua`) | 14 KB | — | 1인칭 고정 |
| `PerfProbe` | 4 KB | — | **3초마다 fps 로그.** FX 전후 비교의 유일한 객관 지표 |
| `ZZ_Cli` | 0.4 KB | — | **디버그 잔재. `Enabled = false`로 꺼놨다. 켜지 마라** |

`ReplicatedStorage`에 **`UIMotion`** (ModuleScript, 20 KB) — 아래 §2.

---

## 2. `UIMotion` — 새 UI FX는 전부 이 위에 얹어라

`04_ROUTES_UI.md` §0에 전체 API가 있다. 요약:

```lua
local Motion = require(ReplicatedStorage:WaitForChild("UIMotion"))

Motion.tween(obj, props, opts)   -- 같은 속성을 쥔 기존 트윈을 먼저 취소한다.
                                 -- 반환 핸들에 :andThen(fn) 이 있다 (HUD.flash 가 쓴다)
Motion.group(objs):rebase():set(a)   -- CanvasGroup 대체. 원래 알파를 보존한다
Motion.toast / popText / bar / countUp / pulse
Motion.every(fn) / after(sec, fn) / onLobby(fn)
Motion.bezier(x1,y1,x2,y2) / lerpColor(a,b,t)
Motion.T  -- SNAP .06 · PRESS .09 · OUT .16 · POP .20 · QUICK .22 · IN .26 · BAR .30 · MOTION .42 · GHOST .55
Motion.E  -- OUT(Quint) · IN(Quad) · POP(Back) · IMPACT(Quart) · LINEAR · SINE
```

**모듈 헤더의 설계 규약:** *"이 모듈은 인스턴스를 만들거나 부모를 바꾸지 않는다. 호출자가 준 것만 건드린다."* (`ZIndex`가 형제 기준이라서 내린 결정) — **깨지 마라.**

---

## 3. 이미 열려 있는 전역 — 다시 만들지 마라

```lua
_G.HUD = { flash, setDim, setAutoDefence, setUlt, setScore, setZone }
_G.Sfx(name, at)          -- 효과음
_G.SfxBgm(name)           -- 배경음
_G.InLobby                -- true / nil  (LobbyUI 가 켜고 끈다)
_G.BoundaryRect / _G.BoundaryEpoch
_G.UltCharge / _G.BowPower / _G.BowCharge / _G.BowStage / _G.BowStageP
_G.MovementFreeze
```

### `_G.HUD.flash(color, strength, hold)` — 화면 테두리 물듦

`HUD.lua:464` 정의, `:496` 노출. `HUD.lua` 헤더가 못박아 놨다:

> *"테두리 물듦은 다른 시스템도 쓸 것이라 `_G.HUD.flash` 로 열어둔다. 패링당함 = 검붉은색 / 원거리 패링 = 검정 / 쿠나이 박힘 = 살짝 검정 / 경계선 이탈 = 주황. 나중에 그 시스템들이 색만 바꿔 부르면 된다. **테두리를 또 만들지 마라.**"*

구현: 4변 `Frame` + `UI.EDGE_PEAK` 기준 `peak = 1 - (1 - EDGE_PEAK) * clamp(strength, 0, 1)`, `Motion.tween(..., time = Motion.T.SNAP, ease = Motion.E.OUT)` → `:andThen()`으로 복귀. **플래시 전용 RenderStepped 루프는 없앴다 — 트윈이 굴린다.**

실제 호출 예:

```lua
flash(UI.BLUE, 1, 0.45)                        -- 오토디펜스
flash(Color3.fromRGB(120, 20, 20), 1, dur+0.35) -- 피격
flash(Color3.fromRGB(235, 235, 235), 0.7, 0.3)  -- 흰 섬광
flash(BOW.FAIL, 0.7, 0.35)                      -- 활 실패
```

**새 전투 피드백은 여기에 색만 추가하는 것으로 끝내라.**

---

## 4. 화면별 실측 제약

### `LobbyUI` — 1386×640 기준 픽셀 + 배수 하나

- 레이아웃: 상단 바 1338×64 @(24,24) · 좌측 레일 320×512 @(24,104) · 무기 패널 360×320 @(1002,296) · 무기 랙
- 반응형: `s = min(vw/1386, vh/640)`, 남는 `dW/dH`를 요소별 `RULE_*`로 나눠 먹인다 (레터박스로 버리지 않는다)
- **레일 바닥 슬롯 하나를 DEPLOY와 BACK이 넘겨받는다.** `Visible`로 끊지 말고 **투명도로 교대**해야 "자리를 넘겨받는" 느낌이 난다
- **★ 호버 이벤트가 없다** (실측): `InputBegan`에 `MouseMovement`가 **한 번도 안 온다**(로그 "호버 입력 확인" 0건). `Activated`는 정상 → 누름 반응을 `Activated` 순간에 짧게 눌렀다 튕기는 것으로 만든다
- ⚠️ `LobbyUI.lua:742`가 `Bold(set)`을 쓰는데 **deprecated 경고를 뿜는다** — `FontFace = Font.new(family, Enum.FontWeight.Bold)`로 가야 한다
- 서버가 **초반 12초 동안 매초 로비 상태를 다시 보낸다.** 그때마다 초기화하면 로드아웃에서 메인으로 튕긴다 — `setShown`이 이걸 처리한다

### `HUD`

상단 중앙 팀 점수 · 크로스헤어 밑 오토디펜스 2칸 · 우하단 궁극기 게이지 · 화면 테두리 경고.
*"서버는 이미 다 보내고 있었다. 받는 쪽이 없었을 뿐이다"* — `CombatServer`가 `phase = "state"`로 계속 쏜다.

### `Crosshair` — `( . )`

프레임 조각으로 곡선을 그린다. 포물선: 세로 위치 `t(-1~1)`에 대해 바깥 밀림 = `CURVE * (1 - t²)`.
튜닝 상수: `GAP 13` · `HEIGHT 24` · `CURVE 5` · `SEGMENTS 6` · `THICK 2` · `DOT 3`.
`Crosshair.lua:45`: *"엔진에 UIStroke는 생겼지만 여기선 조각마다 회전까지 맞춰야 해서 이 방식이 더 단순하다"* — **알고 내린 선택이다. 함부로 UIStroke로 바꾸지 마라.**

### `ParryFX` — 화면 좌표 방식

흰 십자별 텔레그래프 + 스턴 시 머리 주위 호박색 별 5개. `ScreenGui` + `Frame` 3개/별(세로 막대·가로 막대·중앙 사각).
매 `RenderStepped`마다 `Camera:WorldToViewportPoint`로 투영.
- ⚠️ **카메라 뒤 대상도 좌표를 준다. `sp.Z > 0`을 직접 걸러라** — 안 그러면 좌우 반전된 유령이 찍힌다
- 헤더의 *"GuiObject.Rotation이 없다"*는 **지금은 틀렸다** (`02_DO_NOT.md` §7). 별을 이미지 한 장 + `Rotation`으로 바꿀 수 있다
- `BorderPixelSize`와 `BorderSizePixel`을 양쪽 다 pcall로 시도한다 → **`BorderPixelSize`가 맞다**

### `FriendlyHighlight` — 왜 3D가 아니라 UI인가

> *"`Fill`의 `DepthMode = AlwaysOnTop`이 문서엔 '가려져도 앞에 그린다'고 돼 있는데 **실제로는 엄폐물 뒤 아군이 안 보였다. 문서와 동작이 다르다.**"*

그래서 관통을 렌더링에 안 맡기고 `WorldToViewportPoint`로 `ScreenGui`에 그린다. **UI는 3D 위에 무조건 그려지므로 엄폐 문제가 원천적으로 없고, 거리와 무관하게 크기가 일정하다.**
아군 = `ImageLabel` 파란 점(`CIRCLE_IMAGE = ovdrassetid://40281100`), 적군 = 크로스헤어 조준 시 `Outline` + 이름.

**벽 너머 FX를 계획한다면 이 경로뿐이다.** → `10_OPEN_QUESTIONS.md` Q-2

### `BoundaryFX` — "있다/없다"로만 다룬다

> *"투명도로 감추지 않는다. 이 엔진은 `Transparency`를 제대로 안 먹는다 (2026-08-21 실측). **`Transparency = 1`로 둔 빨간 벽이 그대로 다 보였고**, 울타리도 흐려지질 않았다."*

그래서 멀면 파츠를 Workspace에서 빼고, 가까워지면 그 자리에만 만들어 넣는다. **판은 재사용한다** (매번 만들고 부수면 더 비싸다).
→ 단 `STA_StreamWater`가 `Transparency = 0.45`로 잘 렌더되므로 **이건 1.0 한정 문제로 보인다.** `10_OPEN_QUESTIONS.md` Q-1

---

## 5. UI FX를 확인하는 법

**`overdare_screenshot`에는 UI가 절대 안 나온다.** 3D 뷰포트만 찍힌다. 방법은 둘:

1. **`overdare_ui_browse`** — 플레이테스트 중에만 동작한다. 요소별 dotted path / class / text / 정규화 rect / 가시성 / 화면 안 여부를 준다. 큰 HUD는 `paths`로 좁혀라
2. **`overdare_play` → `Play.log`** — 스크립트가 찍는 로그. `LobbyUI`는 진입·재배치·카메라 보정을 전부 로그로 남긴다

`overdare_observe`에 `ui: true`를 주면 같은 정보를 캐릭터·인스턴스와 한 번에 받을 수 있다.
