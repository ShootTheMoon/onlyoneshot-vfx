# 10 OPEN QUESTIONS — 미해결

문서만으로 확답이 안 나오는 것들. 대부분 `09_PROBE.md`가 답한다.
**아래 항목에 의존하는 설계를 확정하지 마라 — 양쪽 분기를 다 준비해라.**

---

## Q-1 ★ `BasePart.Transparency`는 어디까지 동작하나 — 코드베이스 안에서 모순이 있다

**주장 A** — `BoundaryFX_1.lua` 헤더 (2026-08-21 실측):
> *"투명도로 감추지 않는다. **이 엔진은 `Transparency`를 제대로 안 먹는다.** `Transparency = 1`로 둔 빨간 벽이 그대로 다 보였고, 울타리도 흐려지질 않았다. 그래서 '있다/없다'로만 다룬다."*

**주장 B** — `ViewmodelController_2.lua:3181`, 같은 프로젝트의 페이드 규칙:
```lua
e.part.Transparency = k
e.part.Size = e.size0 * (1 - k * 0.85)   -- "투명도 하나만 믿지 않는다"
```

**주장 C** — 라이브 레벨 실측: `STA_StreamWater`가 **`Transparency = 0.45`로 렌더되고 있다** (`06_TERRAIN.md` §3).

**해석 가설:** 부분 알파(0 < t < 1)는 동작하고, **`t = 1`(완전 투명)이 안 먹는 것**이다. 그리고 큰 파츠일수록 눈에 띈다.

**왜 중요한가:** 알파 페이드는 거의 모든 FX의 기본이다. `t = 1`이 안 먹으면 **생애 끝에서 파츠가 사라지지 않고 남는다** — 그래서 코드베이스가 `Size`를 같이 줄이는 것이다.

**판정 방법:** 같은 크기 Part 5개를 `Transparency` 0 / 0.25 / 0.5 / 0.75 / 1.0으로 두고 스크린샷. 크기를 바꿔가며 반복. → `09_PROBE.md` P-1
**그 전까지:** README §3.8을 무조건 지켜라 — `Transparency`와 `Size`를 함께 줄인다.

---

## Q-2 ★ `Fill.DepthMode = AlwaysOnTop`이 문서대로 동작하지 않는다

`FriendlyHighlight.lua` 헤더 (2026-08-19 실측):
> *"문서엔 '가려져도 앞에 그린다'고 돼 있는데 **실제로는 엄폐물 뒤 아군이 안 보였다. 문서와 동작이 다르다.**"*

그래서 관통 표시를 렌더링에 안 맡기고 `WorldToViewportPoint` + `ScreenGui`로 우회한다.

**왜 중요한가:** 벽 너머로 보여야 하는 FX(팀 마커, 궁극기 경고, 목표 지점)의 경로가 통째로 갈린다.
**미확인:** `Outline`은 되는데 `Fill`만 안 되는 건지, `DepthMode` 값별로 다른지. `FillDepthModeType`은 `AlwaysOnTop` / `VisibleWhenNotOccluded` / `VisibleWhenOccluded` 세 값이다.
**판정:** 세 값을 각각 걸고 엄폐물 뒤에서 스크린샷. → P-2

---

## Q-3 ★ `VFXRecipe`가 런타임에 실존하는가

- v0.10.0 타입파일(L2979)에 **있다**
- 온디스크 MCP 카탈로그 스냅샷(2026-08-28)의 `studiorpc_instance_upsert` 클래스 enum에 **없다**
- `Instance.new` 타입 목록(L3054-3082)에도 **없다** → 무타입 오버로드

**이 하나로 라우팅이 갈린다:**
- **있다** → 경로 B·E가 열린다. 39소스 + 템플릿 7종 + `EmptySprite` 커스텀 텍스처
- **없다** → **B·E 붕괴.** 경로가 A(프리셋) + C(ParticleEmitter) + D(Beam/Trail) + F(Part)로 축소된다

**판정:** `upsert class="VFXRecipe"` 1회. 성공/실패 이진. → **P-3, 프로브 최우선 항목**

---

## Q-4 `EmptySprite`를 실제로 배치할 수 있는가

`vfx-recipe` 스킬이 두 군데서 금지한다:
> *"A blank sprite template for manual authoring. **Not used in AI composition.**"*
> *"`EmptySprite` / `EmptySprite_R` … **never pick them when composing an effect.**"*

**그런데 이건 커스텀 텍스처를 `VFXRecipe`에 넣는 유일한 통로이고**, `ParticleEmitter`보다 강하다 (임의 행×열 플립북 + `Size2D` 비정사각).

**질문: 기술적 제약인가(에디터 전용이라 upsert가 거부), 절차적 권고인가(AI가 자동 조합할 때 쓰지 말라는 뜻)?**
전자면 경로 E는 없는 것이고, 후자면 **의도적으로 커스텀 스프라이트를 넣을 때는 정당한 경로**다.
**판정:** `EmptySprite`를 BaseLayer에 넣은 `VFXRecipe`를 upsert해보고, `Texture`에 `ovdrassetid`를 물려본다. → P-4

---

## Q-5 `Trail`에 `Attachment0`/`Attachment1`이 있는가

타입파일 `Trail`(L2869-2880)에 **선언돼 있지 않다.** MCP 도구 설명은 *"rendered between two Attachments"*라고 한다. **문서와 타입이 충돌한다.**

없으면 Trail을 무엇에 붙이는지가 불명확해진다 (부모 파츠? `Offset`?).
**판정:** `Trail`을 만들어 `Attachment0`에 pcall로 써보고 read-back. → P-5

---

## Q-6 이미지 업로드 해상도 상한

공식 문서: **.png/.tga, 15 MB 이하, 권장 512×512** (저사양 256). **"권장"이라고만 적혀 있고 하드캡이라는 말이 없다.**

- 512 → `Grid4x4`에서 프레임당 **128 px**
- 1024가 되면 → **256 px.** 판이 달라진다 (`03_ROUTES_WORLD.md` §3)

**판정:** 512 / 1024 / 2048 각 1장을 `overdare_image_import`하고 육안으로 열화 비교. → P-6

---

## Q-7 `ParticleEmitter`의 오버데어 고유 프로퍼티 두 개

로블록스에 없는 것: **`Brightness: number`** · **`LockedToPart: boolean`**.
문서가 없다. `Brightness`가 `LightEmission`과 어떻게 다른지, `LockedToPart`가 `VelocityInheritance`의 대체물인지 불명.
**판정:** 값을 0/1/5로 바꿔가며 스크린샷, `LockedToPart`는 움직이는 파츠에 붙여 관찰. → P-7

---

## Q-8 `ZOffset` 부재가 3층 스프라이트를 깨뜨리나

`08_ART_RULES.md` 규칙 1이 안개를 **3층 겹치기**로 만든다. 그런데 `ParticleEmitter`에 `ZOffset`이 없어 정렬 제어가 안 된다.
카메라가 회전할 때 층 순서가 뒤바뀌면 깜빡임(z-fighting 유사)이 생길 수 있다.
**판정:** 3층을 겹쳐 두고 카메라를 360° 돌리며 관찰. 깨지면 **3층 → 단층 고밀도로 규칙을 개정해야 한다.** → P-8

---

## Q-9 `ClipsDescendants` 클리핑 창 방식이 되는가

`04_ROUTES_UI.md` §2의 UI 플립북 우회법. `GuiObject.ClipsDescendants`는 타입에 있지만 **실제로 자식을 잘라내는지 미검증**이다.
되면 UI 아틀라스가 업로드 1장, 안 되면 프레임 수만큼 N장.
**판정:** 창+필름을 만들고 `overdare_ui_browse`로 rect를 읽는다. → P-9

---

## Q-10 런타임 `Instance.new`가 무타입 클래스에도 되는가

타입 목록에 `Trail` · `Beam` · `PointLight` · `SpotLight` · `VFXPreset` · `VFXRecipe` · `MaterialVariant` · `UIStroke`가 **없다** → `(className: string) -> Instance` 오버로드로 떨어진다.
MCP `instance_upsert` enum에는 있으므로 **정적 배치는 지원 경로**지만, **런타임 생성이 되는지는 별개다.**
전투 FX는 런타임 생성이 필수라 이게 막히면 정적 풀링(미리 만들어두고 켜고 끄기)으로 설계를 바꿔야 한다.
**판정:** 각각 `pcall(Instance.new, "X")` 후 `.ClassName` 확인. → P-10

---

## Q-11 파티클 예산의 실제 한계

로블록스 공식은 초당 400개(모바일 100). **오버데어 수치는 문서가 없다.**
현재 안정 fps가 50대라 여유가 크지 않다 (`06_TERRAIN.md` §4).
**판정:** `ParticleEmitter`를 1 → 4 → 8 → 16개로 늘리며 `PerfProbe` 로그를 읽는다. → P-11

---

## Q-12 (낮은 우선순위) 로비 BGM 볼륨

2026-09-08에 로비 음악이 안 나던 문제를 고쳤다 (`ZZ_Cli`가 `_G.InLobby`를 0.2초마다 false로 덮어쓰고 있었다 → `Enabled = false`).
**남은 것:** `bgm_lobby.vol = 0.18` × `SoundGroup Music = 0.5` = **실효 0.09**. 옛 `SoundDB.lua`에는 `0.35`였다. 들리긴 하나 매우 작을 수 있다.
또 `bgm_battle.id`가 `""`(전장 음악 없음), `boundary_warn` 슬롯도 비어 있다.
**FX 범위 밖이지만 같은 사운드 계통이라 기록해둔다.**
