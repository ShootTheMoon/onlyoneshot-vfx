# onlyoneshot-vfx

**OVERDARE VFX 작업 인계 패키지.** 이 리포만 읽으면 ONLY ONE SHOT의 이펙트 작업에 바로 들어갈 수 있다.

대상 게임: [`ShootTheMoon/onlyoneshot`](https://github.com/ShootTheMoon/onlyoneshot) — OVERDARE(Luau, Unreal 기반 UGC) 근접전 FPS.
작성 2026-09-08 · 모든 수치는 **v0.10.0 런타임 타입파일과 라이브 Studio에서 실측**했다.

이 문서의 경로는 `%USERPROFILE%` = `C:\Users\<사용자>` 로 읽는다.

---

## 0. 30초 요약 — 지금 상황

**이 게임에는 파티클 시스템이 한 번도 쓰인 적이 없다.**

라이브 레벨 인스턴스 5,882개를 전수 조사한 결과:

```
Part 4735 · MeshPart 947 · Model 118 · ModuleScript 20 · LocalScript 13
Script 11 · SpawnLocation 9 · RemoteEvent 5 · SoundGroup 3 · Animation 2 · Outline 2
```

**ParticleEmitter 0 · Beam 0 · Trail 0 · PointLight 0 · BillboardGui 0 · VFXPreset 0 · VFXRecipe 0.**
3D 이펙트는 전부 Neon/Plastic `Part`를 코드로 만들어 페이드시킨 것이고, 2D는 전부 `Frame` 색판이다.

그런데 엔진에는:

- **`VFXPreset` 기성 이펙트 146개**가 이미 들어 있다 — `Fog`, `Leaf`, `Water Splash`, `Landing`×3, `Dust`, `Muzzle`×4 …
- **`ParticleEmitter`가 플립북을 완전 지원한다** (`Grid2x2/4x4/8x8`)
- **`VFXRecipe`로 Niagara 소스 39개를 3레이어 조합**할 수 있다

**우리는 창고를 열어본 적이 없다.** 네 첫 임무는 창고 문이 실제로 열리는지 확인하는 것이다 → `09_PROBE.md`.

**작업 방법은 별도 리포에 있다** — [`overdare-vfx-guide`](https://github.com/ShootTheMoon/overdare-vfx-guide).
이 리포는 *무엇이 있는가*(API 표면·이 게임의 지형과 UI)를 다루고, 저쪽이 *어떻게 하는가*(작업 루프·도구 사용법·굽기·크래프트·체크리스트)를 다룬다. 겹치지 않게 나눠놨으니 둘 다 봐라.

---

## 1. 읽을 순서

| 순서 | 파일 | |
|---|---|---|
| 1 | **[02_DO_NOT.md](02_DO_NOT.md)** | **필독.** 이 엔진은 로블록스와 문법이 같고 의미가 다르다. 없는 API를 부르면 에러가 아니라 **조용한 실패**다 |
| 2 | [01_ENGINE_TRUTH.md](01_ENGINE_TRUTH.md) | 검증된 API 표면. 선언문 원문 + 줄번호 |
| 3 | **[08_ART_RULES.md](08_ART_RULES.md)** | **필독.** 아트디렉션 구속 조건. 1차 FX가 "비눗방울 안개"로 반려된 이력과 그 반성 |
| 4 | [06_TERRAIN.md](06_TERRAIN.md) · [07_UI_INVENTORY.md](07_UI_INVENTORY.md) | 실제 지형/UI에 붙일 자리. **실명과 좌표가 들어 있다** |
| 5 | [03_ROUTES_WORLD.md](03_ROUTES_WORLD.md) · [04_ROUTES_UI.md](04_ROUTES_UI.md) | 결정 트리 — 어떤 이펙트를 어느 경로로 |
| 6 | **[09_PROBE.md](09_PROBE.md)** | **네 1번 태스크** |
| 참고 | [05_PRESET_MAP.md](05_PRESET_MAP.md) · [10_OPEN_QUESTIONS.md](10_OPEN_QUESTIONS.md) | 프리셋 카탈로그 · 미해결 |

---

## 2. 권위 있는 소스 — 이건 읽고, 저건 읽지 마라

| | 경로 |
|---|---|
| ✅ **읽어라** | `%USERPROFILE%\.overdare\updates\runtime-v0.10.0\assets\lua\overdare-types.d.lua` (85 KB, 3093줄) |
| ❌ **읽지 마라** | `%USERPROFILE%\.overdare\updates\runtime\assets\lua\overdare-types.d.lua` — **v0.5.7 낡은 사본이다** |

`runtime-current.json`이 `{"version":"0.10.0","dir":"runtime-v0.10.0"}`로 활성 런타임을 가리킨다.
v0.10.0에만 있는 것: **`UIStroke` · `Rect` · `ScaleType` · `SliceCenter` · `Font` · `TextService` · `ProgressBar` · `VFXRecipe`**.

**프로젝트 안의 주석을 근거로 삼지 마라.** 일부는 v0.5.7 시절 판단이라 지금은 틀렸다 — `02_DO_NOT.md` §7에 대조표가 있다.

기타 로컬 권위 소스:
- `%USERPROFILE%\.overdare\skills\vfx-recipe\` — VFXPreset/VFXRecipe 공식 카탈로그. **이 스킬은 "VFX 데이터를 네트워크에서 찾지 마라"고 명시한다**
- `%USERPROFILE%\.overdare\system-prompt.txt` — `<roblox-gap>` 부재 목록, Mobility 규칙, 스케일 규칙
- 게임 프로젝트: `%USERPROFILE%\Desktop\onlyonetap\` (내부 파일명은 `onlyoneshot.*`)

---

## 3. ★ 안전 규칙 — 어기면 사람이 손으로 수습해야 한다

1. **Studio에 쓰기 전 반드시 `overdare_stop`.** 플레이테스트 중 쓰면 `level.apply`가 타임아웃되고 **Studio 메인 스레드가 잠긴다. 사람이 Stop을 눌러야만 풀린다.** (`.ovdrjm`는 롤백돼 데이터 손실은 없다)
2. **`overdare_rc_batch`와 `overdare_rc_python`을 쓰지 마라.** MCP README 원문: *"do not work against a shipping Studio build: `PUT /remote/batch` has **crashed Studio outright**."* 1번은 Stop으로 풀리지만 **이건 Studio를 죽인다.**
3. **모든 프로퍼티 쓰기는 `pcall`.** 없는 프로퍼티 하나가 스크립트 전체를 중단시킨다.
4. **FX 파츠를 캐릭터 아래에 두지 마라.** `MovementSpeedServer.stripCharacterApparel`이 표준 신체 부위가 아닌 `BasePart`를 전부 지운다. Workspace에 띄우고 매 프레임 따라가라 (`BarrierFX.lua` 패턴).
5. **맵 컨테이너(`SGK_Sangok` 등) 아래에 두지 마라.** 맵 스왑 시 고아가 된다.
6. **런타임 스폰 FX는 Movable 최상위 아래에.** `Mobility`는 Workspace 직계 자식에만 설정 가능하고 서브트리 전체에 전파된다. **Static 서브트리는 런타임 생성·이동이 불가능하다.**
7. **매 프레임 새로 만들지 마라 — 사전 할당 후 재배치.** (`ViewmodelController_2.lua:3225`: *"매 프레임 새로 만들면 파츠가 수백 개씩 쌓인다"*)
8. **`Transparency`만으론 안 사라진다 — `Size`도 줄여라.** 코드베이스 전체의 페이드 규칙(`ViewmodelController_2.lua:3181`):
   ```lua
   e.part.Transparency = k
   e.part.Size = e.size0 * (1 - k * 0.85)
   ```
   명멸도 알파가 아니라 **Size**로. (배경은 `10_OPEN_QUESTIONS.md` Q-1)
9. **`Debris`가 없다** → `task.delay` + `Destroy` (`task.cancel`로 정리).
10. **런타임 `RemoteEvent` 생성 금지** → 기존 `CombatEvent` / `RyunochiEvent` + `_G.Sfx` 래퍼.
11. **이름은 전역 유일 접두사로.** 기존 관례: `FX_Puff`, `Ruin_Aim`, `SGKFX_`.
12. **`ZZ_` 접두 스크립트는 디버그 잔재다.** 헤더에 *"확인 후 삭제한다"*고 적혀 있고, 2026-09-08에 `ZZ_Cli`/`ZZ_Srv`가 `Enabled = false`로 꺼졌다 (`_G.InLobby`를 0.2초마다 false로 덮어써서 로비 음악을 죽이고 있었다). **다시 켜지 마라.**

---

## 4. ★ 1 stud = 28 units

`system-prompt.txt`: *"1 = 1 cm (therefore 1 Stud equals 28 units)"*.

**로블록스 튜토리얼에서 베낀 모든 `Size` / `Speed` / `Acceleration` / `Range` 숫자는 ×28 해야 한다.** 안 하면 이펙트가 안 보이거나(28배 작음) 화면을 덮는다.

| 로블록스 | 오버데어 |
|---|---|
| `NumberSequence.new(1)` | `NumberSequence.new(28)` |
| `NumberRange.new(5, 10)` | `NumberRange.new(140, 280)` |
| `Vector3.new(0,-10,0)` | `Vector3.new(0,-280,0)` |
| `PointLight.Range = 16` | `448` |

문서에 **cm로 적힌 값은 이미 엔진 단위**다. 중복 환산하지 마라.

---

## 5. 도구 환경

MCP 서버: [`Seungpyo1007/overdare-mcp`](https://github.com/Seungpyo1007/overdare-mcp) — `node dist/index.js`. 도구 50개.

**VFX 작업에 직접 쓰는 것:**

| 도구 | |
|---|---|
| **`overdare_validate_lua`** | Studio가 배포한 타입 정의로 Luau를 검사한다. **⚠️ 스크립트가 `--!strict`로 시작해야만 잡는다** — `--!nolint`면 전부 통과한다. §6 참조 |
| **`overdare_ui_browse`** | UI 트리를 읽는다. **`overdare_screenshot`엔 UI가 절대 안 나온다.** 플레이테스트 중에만 동작 |
| `overdare_observe` | 캐릭터·UI·인스턴스 상태를 한 번에. 값 확인은 스크린샷 말고 이걸로 |
| `overdare_image_import` | 로컬 PNG → `ovdrassetid://N`. 커스텀 스프라이트의 유일한 통로 |

**파일 경로 vs 라이브 RPC — 도구가 두 벌이다:**
- `overdare_create_instance` / `update_instance` / `delete_instance` → 프로젝트 파일을 고친다. **`overdare_apply`로 리로드해야 보인다**
- `overdare_instance_create` / `instance_update` / `instance_delete` → 즉시 반영, 리로드 없음

**FX 튜닝은 라이브 경로가 맞다.** 파라미터를 수십 번 고쳐 보며 눈으로 맞추는 작업이라 리로드가 끼면 못 한다. 다 맞춘 뒤 `overdare_save`.

`script.add` RPC는 엔진에 없다 — MCP가 프로젝트 파일 경유로 만든다. 파일 기반 편집 도구는 매 편집 전에 레벨을 백업한다.

---

## 6. ★ `validate_lua`를 제대로 쓰는 법

실측(2026-09-08). 같은 파일을 두 모드로 검사한 결과:

```lua
-- --!nolint  →  "No problems found."   (전부 통과. 무의미하다)
-- --!strict  →  네 개를 전부 잡는다:
TypeError: Key 'ZOffset' not found in external type 'ParticleEmitter'
TypeError: Key 'LightInfluence' not found in external type 'ParticleEmitter'
TypeError: Key 'BorderSizePixel' not found in external type 'Frame'
TypeError: Key 'ImageRectOffset' not found in external type 'ImageLabel'
```

같은 파일의 `FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4`와 `Rotation = 45`는 **통과했다** — 존재한다는 뜻이다.

**규칙: 새로 쓰는 FX 스크립트는 `--!strict`로 시작하고, 인게임에 넣기 전에 `overdare_validate_lua`를 통과시켜라.**
기존 프로젝트 파일은 대부분 `--!nolint`라 검사해도 아무것도 안 나온다 — 그걸 "깨끗하다"고 읽지 마라.

---

## 7. 네 1번 태스크

`09_PROBE.md`를 읽고 프로브를 돌려라.

산곡 FX 계획(`SGK_FXData.lua`)은 능력 플래그가 이렇게 되어 있었다:

```lua
M.CAP = { particle = false, light = false, beam = false, flipbook = false, billboard = false }
```

**이 `false`들은 "안 된다"가 아니라 "확인한 적 없다"이다.** `Play.log`에 프로브 라인이 한 번도 찍힌 적이 없다. 이걸 채우면 `03`/`04`의 결정 트리 분기가 확정된다. **그 전에 내린 모든 라우팅 결정은 잠정이다.**
