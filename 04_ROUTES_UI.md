# 04 ROUTES — 2D UI FX

용처: **인게임 HUD·전투 피드백 + 로비·메뉴 연출 + 월드 빌보드**, 셋 다.
실제 UI가 어떻게 생겼는지는 `07_UI_INVENTORY.md`.

---

## 0. ★ 먼저 — `UIMotion`이 이미 있다. 다시 만들지 마라

`ReplicatedStorage.UIMotion` (ModuleScript, 20 KB). **헤더에 Studio 프로브를 실제로 돌려 얻은 실측치가 적혀 있다.**

```lua
local Motion = require(ReplicatedStorage:WaitForChild("UIMotion"))
```

| API | |
|---|---|
| `Motion.tween(obj, props, opts)` | 트윈 1개. **같은 속성을 쥔 기존 트윈을 먼저 취소한다** (레지스트리 내장). `opts = {time, ease, delay, repeatCount, reverses}`. 반환 핸들에 **`:andThen(fn)`** |
| `Motion.cancel(obj, prop)` · `Motion.cancelAll(obj)` | 취소 |
| `Motion.group(objs)` | **그룹 페이드.** `:rebase()`로 각 요소의 원래 알파를 기억, `:set(a)` — `a=1` 원래 / `a=0` 사라짐. 공식 `1-(1-base)*a` |
| `Motion.toast(objs, spec)` · `Motion.popText(label, scale, tint)` | 등장 연출 |
| `Motion.bar(front, ghost)` | 게이지 + 잔상 |
| `Motion.countUp(label, from, to, dur, fmt)` | 숫자 카운트 |
| `Motion.pulse(objs, prop, from, to, hz)` | 무한 펄스 |
| `Motion.every(fn)` · `after(sec, fn)` · `onLobby(fn)` | 스케줄 (RenderStepped 하나가 클라이언트 전체를 덮는다) |
| `Motion.bezier(x1,y1,x2,y2)` · `lerpColor(a,b,t)` | 커브·색 보간 |
| `Motion.T` | `SNAP .06` · `PRESS .09` · `OUT .16` · `POP .20` · `QUICK .22` · `IN .26` · `BAR .30` · `MOTION .42` · `GHOST .55` |
| `Motion.E` | `OUT`(Quint) · `IN`(Quad) · `POP`(Back) · `IMPACT`(Quart) · `LINEAR` · `SINE` |

**헤더의 실측 사실 — 문서가 아니라 측정값이다:**

- `TweenService`는 제대로 보간한다 (`ProgressBar.Value` / `Position` / `Transparency` 전부)
- **`:Cancel()`은 값을 그 자리에 둔다** (시작값으로 되감지 않는다)
- ⚠️ **취소된 트윈도 `Completed`를 쏜다** (state = `Cancelled`) → 후속 콜백은 반드시 `PlaybackState`를 봐야 한다. 안 보면 **이중 발화**한다
- `repeatCount = -1` + `reverses = true` = 무한 핑퐁, **프레임당 Lua 비용 0**
- **동시 트윈 60개에 56 fps — 트윈 개수는 걱정할 대상이 아니다**
- ⚠️ **`ZIndex`는 형제(계층) 기준이고 전역이 아니다.** 컨테이너를 하나 끼우면 겹침 순서가 통째로 바뀐다

**추가로 없는 것 (UIMotion 실측):**

| 없는 것 | 우회 |
|---|---|
| **`UIScale`** | 팝은 `Size`(UDim2)를 트윈하고 `AnchorPoint`로 재중심화 |
| **`Color3:Lerp`** | `Motion.lerpColor` (퍼스트파티 코드도 같은 우회를 한다) |
| **`TweenService:GetValue`** | 수동 프레임 보간은 `Motion.bezier` / `Motion.E` |
| **호버 이벤트** | 누름 반응을 `Activated` 순간에 전부 건다 |
| `CanvasGroup` | `Motion.group` |

**`ProgressBar`가 실재한다** (v0.10.0 신규). 알파 속성이 `BackgroundTransparency` / `FillTransparency` / `TrackTransparency` 셋이다.

> **`UIMotion`은 인스턴스를 만들거나 부모를 바꾸지 않는다 — 호출자가 준 것만 건드린다.** (`ZIndex`가 형제 기준이라서 내린 설계 결정) **깨지 마라.**

---

## 1. 낡은 제약 두 개가 풀렸다

이 프로젝트의 UI 코드 상당수가 v0.5.7 기준으로 쓰였다. v0.10.0에서 다음이 **생겼다.**

**⚠️ 주석마다 신선도가 다르다.** `Crosshair.lua:45`는 *"엔진에 UIStroke는 생겼지만 여기선 조각마다 회전까지 맞춰야 해서 이 방식이 더 단순하다"*고 **알고 내린 선택**이다. 반면 `LobbyUI.lua:26`과 `HUD.lua:18`은 아직 *"UIStroke 없음"*이라고 적혀 있다(낡은 주석). **주석을 근거로 삼지 말고 항상 v0.10.0 타입파일을 봐라.**

| 항목 | 낡은 주석 | v0.10.0 |
|---|---|---|
| **`GuiObject.Rotation`** | *"없다. 별은 십자 막대 두 개로 그린다"* (`ParryFX`) | **있다** (L2050). 스핀·기울기·회전 슬래시 전부 가능 |
| **`ImageLabel.ScaleType`/`SliceCenter`/`SliceScale`** | *"9-slice 없음"* | **있다** (L2220-2222). 둥근 모서리 판 하나로 임의 크기 대응 |
| **`UIStroke`** | *"없다"* | **있다** (L2930) |
| **`TextLabel.TextScaled`/`FontFace`** | *"글자 스케일 없음, Bold boolean뿐"* | **있다**. `Bold(set)`은 이제 **deprecated 경고를 뿜는다** |

---

## 2. ★ `ImageRectOffset` / `ImageRectSize`는 **없다**

`ui-generator` 스킬 문서(`patterns\direct-gui.md:58`)에는 나온다. 하지만 타입파일 `ImageLabel`(L2216-2223)에 **없고**, 파일 전체 grep **0건**이며, MCP 스키마에도 **없다**. `overdare_validate_lua`(`--!strict`)가 독립 확인해줬다:

```
TypeError: Key 'ImageRectOffset' not found in external type 'ImageLabel'
```

**→ 스킬 문서가 틀렸다. UI에서 스프라이트시트를 프로퍼티로 재생할 수 없다.**
`ScaleType`도 `Stretch`/`Slice` 둘뿐이라 **`Crop` 트릭도 불가능하다.**

### 그래도 아틀라스 1장으로 UI 플립북이 된다 — 클리핑 창 방식

`GuiObject.ClipsDescendants`(L2047)를 쓴다. **부모가 창, 자식이 필름이다.**

```lua
--!strict
-- 4x4 아틀라스(512px, 셀 128px)를 96x96 로 재생
local COLS, ROWS = 4, 4
local W, H = 96, 96

local win = Instance.new("Frame")          -- 창: 셀 하나 크기, 나머지를 잘라낸다
win.Size = UDim2.new(0, W, 0, H)
win.BackgroundTransparency = 1
win.ClipsDescendants = true                -- ★ 핵심

local film = Instance.new("ImageLabel")    -- 필름: 아틀라스 전체를 셀배수로 확대
film.Image = ATLAS_ID
film.Size = UDim2.new(0, W * COLS, 0, H * ROWS)
film.BackgroundTransparency = 1
film.ScaleType = Enum.ScaleType.Stretch
film.Parent = win

local function setFrame(i: number)         -- i = 0..15
	local c = i % COLS
	local r = math.floor(i / COLS)
	film.Position = UDim2.new(0, -c * W, 0, -r * H)
end
```

- **업로드 1장.** 월드축 C경로(`ParticleEmitter` 플립북)와 **같은 아틀라스를 공유할 수 있다**
- 재생은 `Motion.every` 또는 `task.delay` 루프로 `setFrame` 호출
- **`film.Position`을 트윈하지 마라** — 셀 경계가 뭉개진다. 정수 스텝으로 끊어라
- `AnchorPoint`/`Rotation`은 **창(`win`)에 걸어라.** 필름에 걸면 오프셋 계산이 깨진다

**이 방식은 미검증이다** (`ClipsDescendants` 동작 확인 필요 — `09_PROBE.md`). 되면 U-b가 살고, 안 되면 U-c로 떨어진다.

---

## 3. 다섯 경로

| 경로 | 정체 | 업로드 | 언제 |
|---|---|---|---|
| **U-a** `ImageLabel` + `Motion.tween` | 정지 이미지 한 장을 트윈으로 | 1 | 대부분의 UI 연출. **여기서 시작해라** |
| **U-b** 클리핑 창 아틀라스 (§2) | 시트 1장을 셀 단위 재생 | **1** | 프레임 애니메이션이 꼭 필요할 때 |
| **U-c** 프레임 시퀀스 | ImageLabel N개 프리로드 후 `Visible` 토글 | **N** | U-b가 프로브에서 실패했을 때만. 비싸다 |
| **U-d** 절차적 `Frame` | 코드로 그림 | 0 | 단색 판·막대·비네트. **출시분 100%가 이것** |
| **U-e** `BillboardGui` + 위 전부 | 3D 공간에 띄움 | 1~N | 데미지 숫자, 월드 아이콘, 안개 스프라이트 |

## 4. 결정 트리

```
이 UI 이펙트는 무엇인가?

├─ 화면 테두리가 물드는 전투 피드백인가? (피격, 패링, 경고)
│   └─ ▶ _G.HUD.flash(color, strength, hold) 를 색만 바꿔 불러라.
│         ★ HUD.lua 헤더: "테두리를 또 만들지 마라."  07_UI_INVENTORY.md §3
│
├─ 3D 공간의 무언가에 붙는가? (적 위 데미지 숫자, 지점 마커, 월드 안개)
│   └─ ▶ U-e (BillboardGui).  ★ 화면 투영을 직접 계산하지 마라.
│         MaxDistance / DistanceLowerLimit / DistanceUpperLimit 로 거리 페이드가 공짜다.
│         (기존 코드가 WorldToViewportPoint 로 손수 투영하는 건 우회법이었다)
│
├─ 색·크기·위치·투명도·회전만 변하는가? (플래시, 팝, 슬라이드, 스핀, 펄스)
│   └─ ▶ U-a (이미지 + Motion.tween).  ★ Rotation 이 이제 있다.
│         단색이면 이미지도 필요 없다 ▶ U-d
│
├─ 그림이 프레임마다 바뀌는가? (연기 퍼짐, 슬래시 궤적, 폭발)
│   ├─ 프레임 8~16장 이하 → ▶ U-b (클리핑 창 아틀라스, §2)
│   └─ 프로브에서 U-b 실패 → ▶ U-c, 단 프레임을 6장 이하로 줄이고
│                              사이는 Motion.tween 으로 메워라
│
├─ 화면 전체를 덮는 단색인가? (페이드 인/아웃, 암전)
│   └─ ▶ U-d (Frame).  전체 화면 알파는 Frame 하나가 제일 싸다.
│
└─ 여러 요소를 한 덩어리로 페이드해야 하는가?
    └─ ▶ Motion.group(objs):rebase()  — §5
```

## 5. `CanvasGroup`이 없다 — **`Motion.group`을 써라**

요소마다 알파 속성이 다르다:

| 요소 | 페이드 프로퍼티 |
|---|---|
| `Frame` · `ScrollingFrame` | `BackgroundTransparency` |
| `ImageLabel` · `ImageButton` | `ImageTransparency` + `BackgroundTransparency` |
| `TextLabel` · `TextButton` | `TextTransparency` + `BackgroundTransparency` |
| `ProgressBar` | `BackgroundTransparency` + `FillTransparency` + `TrackTransparency` |
| `UIStroke` | `Transparency` |

**이 표는 `UIMotion`의 `ALPHA_PROPS`에 이미 들어 있다.**

```lua
local g = Motion.group({ panel, icon, label, stroke }):rebase()
g:set(0)      -- 즉시 사라짐. rebase 가 원래 알파를 기억한다
```

`:rebase()`가 각 요소의 **현재** 알파를 base로 잡고 `:set(a)`가 `1 - (1-base)*a`로 계산한다 — **원래 불투명도가 요소마다 달라도 뭉개지지 않는다.** 직접 짠 순회 코드는 여기서 거의 항상 틀린다.

새 클래스를 페이드해야 하는데 `ALPHA_PROPS`에 없다면 **거기에 한 줄 추가하는 게 맞다.** 별도 페이드 함수를 만들지 마라.

## 6. UI FX가 지켜야 할 것

1. **트윈 직후 같은 속성을 직접 쓰지 마라** — 애니메이션이 통째로 사라진다. `Motion.tween`은 레지스트리로 이걸 처리한다
2. **`Visible = false`인 요소는 `AbsolutePosition`이 갱신되지 않는다** (`Size`는 맞다). 숨은 요소의 레이아웃 로그를 믿지 마라
3. **`Camera:WorldToViewportPoint`는 카메라 뒤 대상에도 좌표를 준다.** `Z > 0`을 직접 걸러라. **애초에 U-e(BillboardGui)를 쓰면 이 문제 자체가 없다**
4. **`TweenInfo.new`는 6인자 전부 넘겨라** — 타입 선언에 옵셔널 표기가 없다
5. **`Frame.BorderPixelSize`** — `BorderSizePixel`이 아니다
6. **커스텀 베지어는 `EasingStyle`로 안 나온다** → `Motion.bezier`
7. **반복 이펙트는 사전 할당 후 재사용.** 매번 `Instance.new` 금지 — 3D와 같은 규칙
8. **새 스크립트는 `--!strict`로 시작하고 `overdare_validate_lua`를 통과시켜라** (README §6)
