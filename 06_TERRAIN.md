# 06 TERRAIN — 실제 지형과 FX 부착점

라이브 Studio의 DataModel을 전수 조사한 결과다 (2026-09-08). **추상적인 "앵커"가 아니라 실제 오브젝트 이름과 좌표다.**

---

## 1. Workspace 최상위 — 맵 4개가 동시에 올라가 있다

| 컨테이너 | 클래스 | 하위 인스턴스 |
|---|---|---|
| **`SGK_Sangok`** | Model | **3,336** ← 조선 산곡. 주 무대 |
| `Hwaseong Place` | Model | 998 |
| `Changdeokgung Place` | Model | 835 |
| `KRM_Palace` | Model | 301 |
| `Lobby` | Model | 23 |
| `LobbyDisplay_japan` | Model | 14 |
| `GND_Base` | Part | 0 |
| `WarCitySpawn` | SpawnLocation | 0 |
| `Wakizashi_Viewmodel_Model` / `_Split` / `Wakizashi1_Arms` / `Gukgung_Viewmodel_Merged` | Model | 뷰모델 |
| `ZZ_Wakizashi1_Arms_DUP` | Model | **디버그 잔재 (DUP)** |
| `Camera` · `dd`(Sound) | | |

`ServerStorage`에 `Hwaseong Collision`, `Gyeongbokgung Place`가 더 있다.
`Lighting`에는 **`Atmosphere` 하나**가 이미 놓여 있다.

**맵 스왑이 있으므로 FX를 맵 컨테이너 아래에 두면 고아가 된다** (README §3.5).

---

## 2. `SGK_Sangok` 3,336개 내역

| 개수 | 접두 | 정체 |
|---|---|---|
| **2,756** | `COL_*` | **콜리전 Part.** 보이지 않는 충돌체. FX 대상이 아니다 |
| 341 | `SGK_Pine_00xx` | 소나무 |
| 54 | `SGK_Und_Fern_*` | 고사리 |
| 44 | `SGK_Rock_*` | 바위 |
| 38 | `SGK_Und_Eulalia_*` | 억새 |
| 20 | `SGK_Und_Sapling_*` | 묘목 |
| 12 | `STA_TER_00`~`32` | **지형 타일 4×3** |
| 9 | `SGK_Und_SmallPine_001`~`009` | 어린 소나무 |
| 8 | `SGK_Und_Stump_*` | 그루터기 |
| 5 | `SGK_Und_Artemisia_*` | 쑥 |
| 4 | `SGK_Und_DeadTrunk_*` | 고사목 |
| 4+2 | `SGK_Wall*` / `SGK_WallL_*` | 담 |
| 1씩 | `STA_StreamWater` · `SGK_Bridge` · `SGK_Pavilion` · `STA_Cairn` · `STA_STEPS` · `STA_Terrace_N` · `STA_WALL_{E,W,N1,N2,S1,S2}` | |
| 1씩 | `SGK_Bound_{North,South,East,West}` | 경계 Part |
| 1씩 | `SGK_Spawn_Red` · `SGK_Spawn_Blue` | SpawnLocation |

타입 분포: Part 2,760 / MeshPart 574 / SpawnLocation 2 / Model 1.
**보이는 지오메트리는 MeshPart 574개뿐이고 나머지는 전부 충돌체다.**

---

## 3. FX 부착점 — 실측 좌표

### `STA_StreamWater` — 계류 수면 (물안개·포말의 자리)

```
Position   (-30000, -42.3, -40021.4)
Size       9000 × 159.7 × 1911.9        ← 90 m × 19 m 의 물줄기
Orientation(0, -180, 0)
Transparency 0.45      Material Basic    CastShadow false
CanCollide false       CollisionProfile NoCollision
MeshId  ovdrassetid://44705800     TextureId ovdrassetid://44738000
DoubleSided true
```

수면 상단 Y ≈ `-42.3 + 79.87` ≈ **+37.6**. 물안개 3층은 여기에 `+50 / +100 / +160` (엔진 단위 cm) 로 올린다.
X는 `-30000` 중심으로 ±4500, Z는 `-40021` 중심으로 ±956 범위에 앵커를 뿌리면 물줄기를 덮는다.

> **`Transparency = 0.45`로 렌더되고 있다.** 이건 `BoundaryFX_1.lua`의 *"이 엔진은 Transparency를 제대로 안 먹는다"*가 **`Transparency = 1`(완전 투명) 한정**이라는 뜻이다 — 부분 알파는 동작한다. `10_OPEN_QUESTIONS.md` Q-1.

### `SGK_Pavilion` — 정자 (등불의 자리)

```
Position   (-30000, 360.2, -40900)
Size       476.1 × 385.1 × 473.4         ← 4.8 m × 3.9 m × 4.7 m
Orientation(0, -180, 0)
Transparency 0    Material Basic    CastShadow true
MeshId  ovdrassetid://44754200     TextureId ovdrassetid://44754100
```

처마 아래 등불은 `Y ≈ 360 + 190` ≈ **550** 근처. 정자는 계류에서 Z로 약 880 (≈8.8 m) 떨어져 있다.

### 그 외

| 이름 | FX 용도 |
|---|---|
| `SGK_Pine_00xx` (341) | 낙하 솔잎·송화분의 발생원. 카메라 위 8 m 추적 방식이면 개별 참조가 필요 없다 |
| `SGK_Rock_*` (44) · `STA_Cairn` | 돌조각·먼지 (전투 임팩트) |
| `SGK_Und_*` (129) | 스치는 풀잎 반응. 밀도가 높으니 예산 주의 |
| `STA_TER_00`~`32` (12) | 지면. 착지 먼지의 표면 |
| `SGK_Bound_{N,S,E,W}` | 경계. `BoundaryFX`가 이미 쓴다 — 겹치지 마라 |
| `SGK_Spawn_Red` / `SGK_Spawn_Blue` | **역광 방향 판정에 쓴다** (`08_ART_RULES.md` 규칙 6). 두 스폰에서 봤을 때 안개가 다 잘 읽히는지 확인해야 한다 |

---

## 4. 성능 — 이미 빡빡하다

`Play.log` 실측 (2026-09-08 로비):

```
[Perf] 로비 FPS   9.6  평균 83.67ms  최악 400.00ms   ← 첫 3초 (로드 직후)
[Perf] 로비 FPS  42.7  평균 23.41ms  최악 118.39ms
[Perf] 로비 FPS  53.5  평균 18.70ms  최악  21.74ms   ← 안정 후
```

**안정 상태가 50대 fps다.** 맵 4개(5,470 인스턴스)가 동시에 올라가 있는 상태에서 그렇다.
`PerfProbe.lua`가 3초마다 자동으로 이 줄을 찍으니, **FX를 넣기 전/후로 이 숫자를 비교해라.** 그게 유일한 객관 지표다.

예산 (`08_ART_RULES.md` §2와 동일):

| | |
|---|---|
| 환경 FX — Tier 0 (`Part`) | ≤120 |
| 환경 FX — Tier 1 (`ParticleEmitter`) | ≤30 |
| 전투 FX | ≤90 Part |

`ViewmodelController_2.lua:302`의 실제 캡: `RANGE = 40000`(400 m) · `PUFFS = 160` · `KUNAI = 8` · `DRAGONS = 4` · `DEBRIS = 9` · `LOGS = 10` · `XBLADES = 6`.
그 주석에 실제 사고가 적혀 있다 — *"18000(180m) 이었는데 맵이 바뀌면서 남의 이펙트가 전부 사라졌다."* **컬링 반경을 맵보다 작게 잡지 마라.**

---

## 5. 좌표계 메모

- **1 unit = 1 cm. 1 stud = 28 units.** 위 좌표는 전부 cm다
- 산곡의 중심 X가 `-30000` (= -300 m), Z가 `-40000`대 (= -400 m대). **원점에서 멀다** — FX 스폰 좌표를 0 근처로 계산하면 맵 밖이다
- `CFrame`은 항상 월드 공간이다. 자식 파츠는 로컬 좌표를 쓰지만 `CFrame` 값 자체는 월드다
- 새 MeshPart는 기본 `Anchored = true`
