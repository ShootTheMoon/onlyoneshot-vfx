# 09 PROBE — 실측 절차 (네 1번 태스크)

`10_OPEN_QUESTIONS.md`의 Q-1 ~ Q-11을 사실로 바꾼다. **이걸 하기 전에 내린 라우팅 결정은 전부 잠정이다.**

스크립트: [`probe/FXProbe.lua`](probe/FXProbe.lua) — **`--!strict`로 작성됐고 `overdare_validate_lua`를 통과한 상태로 들어 있다.**

---

## 1. 돌리는 법

```
1. overdare_status         → studioRpc / ueRemoteControl 도달 확인
2. overdare_stop           → ★ 쓰기 전엔 무조건. 플레이 중 쓰면 Studio 가 잠긴다
3. probe/FXProbe.lua 를 StarterPlayer > StarterPlayerScripts 에 LocalScript 로 반입
4. overdare_save
5. overdare_play
6. 콘솔에서  _G.FXPROBE_RUN = true
7. Play.log 에서 "[FXPROBE]" 를 grep
8. 단계마다 overdare_screenshot (3D) / overdare_ui_browse (UI)
9. 콘솔에서  _G.FXPROBE_CLEANUP()
10. overdare_stop → 스크립트를 지우거나 Enabled = false
```

스크립트는 **자동으로 안 돈다.** `_G.FXPROBE_RUN`을 켜야 시작한다. 만드는 건 전부 `Workspace.FXProbe_Root` 아래에 두고 `_G.FXPROBE_CLEANUP()`이 통째로 지운다.

---

## 2. 스크립트가 자동으로 답하는 것

| # | 항목 | 어떻게 |
|---|---|---|
| **P-10** | 런타임 `Instance.new`가 무타입 클래스에도 되나 | 11개 클래스를 `pcall`로 만들고 `ClassName`을 되읽는다 → 로그 |
| **P-1** | `Transparency` 0/0.25/0.5/0.75/1.0 | **작은 판과 큰 판을 같이 둔다** (BoundaryFX는 큰 벽에서 실패했다고 적혀 있다). **로그가 아니라 스크린샷으로 판정** |
| **P-7** | `Brightness` · `LockedToPart` (로블록스에 없는 프로퍼티) | 쓰고 되읽어 값이 유지되는지 |
| **P-5** | `Trail.Attachment0/1` 존재 여부 | 쓰기 성공/실패 → 로그. **Q-5의 문서/타입 충돌을 여기서 끝낸다** |
| **P-8** | `ZOffset` 부재가 3층 스프라이트를 깨나 | 3층을 겹쳐 배치. **카메라를 360° 돌리며 스크린샷** |
| **P-2** | `Fill.DepthMode` 3종 + `Outline` 관통 | 벽 뒤에 타겟을 두고 배치. **스크린샷으로 판정** |
| **P-9** | `ClipsDescendants` 클리핑 창 | 96×96 창 + 384×384 필름. **`overdare_ui_browse`로 rect를 읽어** 필름이 창 밖으로 안 삐져나오는지 확인 |
| 부가 | `GuiObject.Rotation` (낡은 주석은 없다고 한다) | 쓰기 성공 여부 |
| 부가 | 열거형 철자 `Outward` / `Box` / `Volume` / `FacingCameraWorldUp` | 한 덩어리 `pcall` |
| 부가 | `:Emit()` — `Enabled = true` 뒤 한 틱 기다린 뒤 | `task.delay(0.2, ...)` |

---

## 3. 스크립트로는 안 되는 것 — 도구로 해라

| # | 항목 | 방법 |
|---|---|---|
| **P-3** ★ | **`VFXRecipe`가 upsert enum에 있나** | `overdare_create_instance` / `instance_create`로 `class = "VFXRecipe"` 1회. **성공/실패 이진.** 실패하면 경로 B·E를 즉시 잘라내고 A+C+D+F로 축소해라 |
| **P-4** | `EmptySprite`를 배치할 수 있나 | `VFXRecipe`의 `BaseLayer`에 `NiagaraSystem = "EmptySprite"`를 넣어 upsert. 되면 `Texture`에 `ovdrassetid`를 물려본다 |
| **P-6** | 이미지 업로드 해상도 상한 | 512 / 1024 / 2048 PNG 각 1장을 `overdare_image_import` → 반환 id를 `ParticleEmitter.Texture`에 물리고 **육안 열화 비교** |
| **P-11** | 파티클 예산 | `ParticleEmitter`를 1 → 4 → 8 → 16개로 늘리며 `PerfProbe` 로그(3초마다 자동)를 읽는다. **현재 기준선은 안정 50대 fps** |
| 부가 | `VFXPreset` 리틴트 범위 | 프리셋 하나(`VFX_UGC_Fog_01` 권장)를 배치하고 `Color`/`Size`/`Transparency`를 바꿔가며 스크린샷. **톤 조절이 어디까지 되는지가 경로 A 채택의 관건이다** |

---

## 4. 결과를 어디에 적나

프로브가 끝나면 이 리포에 `11_PROBE_RESULTS.md`를 만들어 **항목별 O/X + 근거(로그 발췌·스크린샷 파일명)**를 적어라. 그리고:

1. **`10_OPEN_QUESTIONS.md`의 해당 항목을 지우고 결론을 `01_ENGINE_TRUTH.md`로 옮긴다**
2. **`03_ROUTES_WORLD.md` / `04_ROUTES_UI.md`의 "미검증 전제" 표시를 걷어낸다**
3. P-3이 실패했으면 경로 B·E 행을 매트릭스에서 **삭제**한다 (회색 처리 말고 삭제 — 다음 사람이 또 시도한다)

---

## 5. 첫 실전 대상 추천

프로브가 끝나면 **총구 화염(muzzle)**을 첫 대상으로 잡아라:

- 프리셋에 `VFX_UGC_Muzzle_01` ~ `04` **4종이 있다** (경로 A)
- 우리 아틀라스를 구울 수도 있다 (경로 C)
- 현행 구현(Neon Part)이 대조군으로 이미 있다 (경로 F)
- **같은 이펙트를 A / C / F 세 가지로 만들어 같은 카메라에서 스크린샷하면 경로별 품질/노력비가 한 장에 나온다**

그 결과가 나머지 전체의 기준이 된다.

두 번째 대상은 **계류 물안개** — `STA_StreamWater`(90 m × 19 m, 수면 Y≈+37.6)에 `VFX_UGC_Fog_01`을 얹고 `08_ART_RULES.md`의 8규칙으로 채점해라. 특히 **규칙 6(양 팀 스폰에서 역광 확인)**과 **규칙 8(있는지 모를 밀도)**.
