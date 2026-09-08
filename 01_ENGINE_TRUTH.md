# 01 ENGINE TRUTH — 검증된 API 표면 (원문 발췌)

출처: `%USERPROFILE%\.overdare\updates\runtime-v0.10.0\assets\lua\overdare-types.d.lua` (3093줄)
**아래는 요약이 아니라 원문이다.** 줄번호를 붙였으니 의심되면 그 줄을 직접 봐라.

---

## 1. ParticleEmitter — L2471-2500 (원문)

```lua
declare class ParticleEmitter extends Instance
	Acceleration: Vector3
	Brightness: number
	Color: ColorSequence
	Drag: number
	EmissionDirection: NormalId
	Enabled: boolean
	FlipbookFramerate: NumberRange
	FlipbookLayout: ParticleFlipbookLayout
	FlipbookMode: ParticleFlipbookMode
	FlipbookStartRandom: boolean
	Lifetime: NumberRange
	LightEmission: number
	LockedToPart: boolean
	Orientation: ParticleOrientation
	Rate: number
	Rotation: NumberRange
	RotSpeed: number
	Shape: ParticleEmitterShape
	ShapeInOut: ParticleEmitterShapeInOut
	ShapeStyle: ParticleEmitterShapeStyle
	Size: NumberSequence
	Speed: NumberRange
	SpreadAngle: number
	Squash: NumberSequence
	Texture: string
	Transparency: NumberSequence
	function Clear(self): ()
	function Emit(self, ParticleCount: number): ()
end
```

**이 목록에 없는 것은 없는 것이다.**

### 관련 열거형 (원문, L1261-1315)

```lua
declare class ParticleEmitterShape_INTERNAL extends Enum
	Box · Sphere · Cylinder · Disc          -- Disk 아님
end
declare class ParticleEmitterShapeInOut_INTERNAL extends Enum
	Outward · Inward                        -- MCP 도구로는 "OutWard" / "InWard"
end
declare class ParticleEmitterShapeStyle_INTERNAL extends Enum
	Volume · Surface
end
declare class ParticleFlipbookLayout_INTERNAL extends Enum
	None · Grid2x2 · Grid4x4 · Grid8x8
end
declare class ParticleFlipbookMode_INTERNAL extends Enum
	Loop · OneShot · PingPong · Random
end
declare class ParticleOrientation_INTERNAL extends Enum
	FacingCamera · FacingCameraWorldUp · VelocityParallel · VelocityPerpendicular
end
declare class NormalId_INTERNAL extends Enum   -- EmissionDirection 이 쓴다
	Right · Top · Back · Left · Bottom · Front
end
```

**플립북은 완전 지원된다.** 아틀라스 산수 (업로드 권장 512 px 기준):

| 레이아웃 | 프레임 | 프레임당 |
|---|---|---|
| `Grid2x2` | 4 | 256 px |
| **`Grid4x4`** | **16** | **128 px** — 기본값으로 삼아라 |
| `Grid8x8` | 64 | 64 px — 연기·안개처럼 뭉개져도 되는 것만 |

MCP 스키마 기본값: `Rate = 5`, `Enabled = true`, `LightEmission (0~1)`, `Texture` = "Texture asset ID".

---

## 2. Trail / Beam / Attachment — 엔진 유일의 UV 스크롤

```lua
-- L2869-2880
declare class Trail extends Instance
	Color: ColorSequence   Enabled: boolean   Lifetime: number
	Offset: Vector3        Texture: string    TextureLength: number
	TextureSpeed: number   Transparency: NumberSequence
	Width: number          WidthScale: NumberSequence
end

-- L1833-1847
declare class Beam extends Instance
	Attachment0: Attachment   Attachment1: Attachment
	Color: ColorSequence      CurveSize0: number   CurveSize1: number
	Enabled: boolean          FaceCamera: boolean
	Texture: string           TextureLength: number   TextureSpeed: number
	Transparency: NumberSequence
	Width0: number            Width1: number
end

-- L1769-1777
declare class Attachment extends Instance
	Axis · CFrame · SecondaryAxis · WorldAxis · WorldCFrame · WorldSecondaryAxis
	function GetConstraints(self): {any}
end
```

⚠️ **`Trail`에 `Attachment0`/`Attachment1`이 선언돼 있지 않다.** MCP 도구 설명은 *"rendered between two Attachments"*라고 한다 — **문서와 타입이 충돌한다.** 프로브 항목. `FaceCamera`·`LightEmission`·`MinLength`/`MaxLength`도 없다.
`Beam`에 `Segments`·`LightEmission`·`ZOffset`·`TextureMode` 없음.

**`Beam.TextureSpeed`와 `Trail.TextureSpeed`가 이 엔진에서 UV를 움직일 수 있는 유일한 수단이다.**

---

## 3. VFXPreset / VFXRecipe — 네이티브 Niagara 시스템

```lua
-- L2967-2977
declare class VFXPreset extends Instance
	Color: ColorSequence   Enabled: boolean
	InfiniteLoop: boolean  LoopCount: number
	PresetName: string     Size: number      Transparency: number
	function Clear(self): ()
	function Emit(self, ParticleCount: number): ()
end

-- L2979-2995  ★ v0.10.0 신규
declare class VFXRecipe extends Instance
	AutoActivate: boolean
	BaseLayer: {any}   DetailLayer: {any}   ExtraLayer: {any}
	InfiniteLoop: boolean   LoopCount: number   LoopDuration: number
	function GetParam(self, SourceName: string, ParamName: string): any
	function GetParamAt(self, LayerName: string, Index: number, ParamName: string): any
	function IsPlaying(self): boolean
	function Play(self): ()
	function SetParam(self, SourceName: string, ParamName: string, Value: any): ()
	function SetParamAt(self, LayerName: string, Index: number, ParamName: string, Value: any): ()
	function Stop(self): ()
	Finished: ScriptSignal
end
```

`VFXPreset`으로 바꿀 수 있는 건 **`Color`/`Size`/`Transparency` 셋뿐**이다 — 내부 구조는 못 건드린다. **이게 프리셋 경로의 진짜 비용이다.**
`LoopDuration`은 파생값(읽기 전용) — 이걸로 길이를 못 줄인다. 소스의 `Duration`/`Delay`를 고치거나 제일 긴 소스를 갈아라.

⚠️ **`VFXRecipe`가 온디스크 MCP 카탈로그 스냅샷의 `studiorpc_instance_upsert` 클래스 enum에 없다.** 타입파일에는 있다. **프로브 1번 항목.**

카탈로그는 `05_PRESET_MAP.md`. 원본은 `%USERPROFILE%\.overdare\skills\vfx-recipe\references\`.

---

## 4. 조명 · 대기 · 머티리얼

```lua
declare class Light extends Instance      Brightness: number  Color: Color3  Enabled: boolean  end  -- L2238
declare class PointLight extends Light    Range: number  end                                        -- L2543
declare class SpotLight extends Light     Angle: number  Face: NormalId  Range: number  end         -- L2749

-- L1749-1767  (Sky/Clouds 클래스는 없다. 전부 여기 들어있다)
declare class Atmosphere extends Instance
	AirColor  CloudAmount  CloudSpeed  CloudTexture  Color  Density
	FogColor  FogDensity   FogFalloff  FogFalloffClear  FogHorizon  FogStart
	GlareColor  GlareFalloff  HazeColor  HazeSpread  StartDistance
end

-- 색보정 손잡이는 Contrast 와 Saturation 둘뿐이다 (포스트FX 클래스 없음)
declare class Lighting extends Instance
	Ambient  AmbientSkyBrightness  AmbientSkyColor  AutoTimeCycle  Brightness
	ClockTime  Contrast  GroundReflectionColor
	Moon{Brightness,CastShadow,LightColor,MaterialColor,MaxHeight,PathAngle,Phase}
	NightBrightness  RealTimeDayDuration: string  Saturation  ShadowDetailLevel
	SkyColorInfluence  StarsBrightness  StarsColor
	Sun{Brightness,CastShadow,LightColor,MaxHeight,PathAngle}  TimeFlowSpeed
end

-- L2405-2418  ★ SurfaceAppearance 의 대체물이고 로블록스보다 낫다
declare class MaterialVariant extends Instance
	BaseMaterial: Material    ColorMap: Content     CustomPhysicalProperties
	Emissive: Color3          EmissiveIntensity: number   EmissiveMap: Content
	Metalness: number         MetalnessMap: Content       MetersPerTile: number
	NormalMap: Content        Roughness: number           RoughnessMap: Content
end

-- Highlight 대체물. 둘 다 OverlayBase(Adornee, Enabled) 상속
declare class Outline extends OverlayBase   Color: Color3  Thickness: number  end   -- L2466
declare class Fill    extends OverlayBase   Color  DepthMode  Transparency   end    -- L2026
-- FillDepthModeType: AlwaysOnTop / VisibleWhenNotOccluded / VisibleWhenOccluded
```

`BasePart.MaterialVariant`는 **문자열(이름)**이다. `Enum.Material`은 **96개** 값이고 FX에 중요한 건 **`Neon`**(L1106)·**`Unlit`**(L1095)·`Basic`(L1090)·`Plastic`(L1091).
`BasePart`의 FX 관련: `Anchored` `CanQuery` `CanTouch` `CastShadow` `CFrame` `Color` `Material` `MaterialVariant` `Size` `Transparency`. (`Reflectance` 없음)

**라이브 레벨에 `Lighting.Atmosphere`가 이미 하나 놓여 있다.** 새로 만들지 말고 그걸 조정해라.

---

## 5. UI — 2D FX가 쓸 표면 (원문)

```lua
-- L1849-1853 / L2042-2057
declare class GuiBase2d extends Instance  AbsolutePosition: Vector2  AbsoluteSize: Vector2  AutoLocalize  end
declare class GuiObject extends GuiBase2d
	Active: boolean            AnchorPoint: Vector2
	BackgroundColor3: Color3   BackgroundTransparency: number
	ClipsDescendants: boolean  LayoutOrder: number
	Position: UDim2            Rotation: number        -- ★ 있다
	Size: UDim2                Visible: boolean        ZIndex: number
	InputBegan / InputChanged / InputEnded: ScriptSignal
end

-- L2216-2223
declare class ImageLabel extends GuiObject
	Image: string        ImageColor3: Color3    ImageTransparency: number
	ScaleType: ScaleType SliceCenter: Rect      SliceScale: number
end
-- ImageRectOffset / ImageRectSize 는 여기 없다 (전체 파일 grep 0건)

declare class ImageButton extends GuiButton                                                    -- L2205-2214
	HoverImage · Image · ImageColor3 · ImageTransparency · PressImage
	ScaleType · SliceCenter · SliceScale
end
declare class Frame extends GuiObject   BorderColor3  BorderMode  BorderPixelSize: number  end -- L2059
declare class TextLabel extends GuiObject                                                      -- L2840-2851
	FontFace: Font  LocalizedText  Text  TextColor3  TextScaled: boolean  TextSize
	TextTransparency  TextWrapped  TextXAlignment  TextYAlignment
end
declare class ScreenGui extends LayerCollector   DisplayOrder: number  end                     -- L2616
declare class UIStroke extends Instance                                                        -- L2930-2941 ★ v0.10.0 신규
	ApplyStrokeMode  BorderOffset: UDim  BorderStrokePosition  Color: Color3
	Enabled  LineJoinMode  StrokeSizingMode  Thickness  Transparency  ZIndex
end

-- 월드 공간 2D
declare class SurfaceGuiBase extends LayerCollector                                            -- L1859-1869
	Active  Adornee: Instance  AlwaysOnTop  Brightness  ClipsDescendants
	LightInfluence  MaxDistance  Size: UDim2  ZIndexBehavior
end
declare class BillboardGui extends SurfaceGuiBase                                              -- L1871-1880
	CurrentDistance: number    DistanceLowerLimit: number   DistanceUpperLimit: number
	ExtentsOffsetWorldSpace    PlayerToHideFrom: Player
	PositionOffset: Vector3    PositionOffsetWorldSpace     SizeOffset: Vector2
end
declare class SurfaceGui extends SurfaceGuiBase   Face: NormalId  ZOffset: number  end         -- L2799

declare class ScaleType_INTERNAL extends Enum   Stretch  ·  Slice   end
-- Tile / Fit / Crop 없음

declare class BaseScript extends LuaSourceContainer   Enabled: boolean   end
-- Disabled 는 없다
```

> **`BillboardGui`의 `MaxDistance` / `DistanceLowerLimit` / `DistanceUpperLimit` / `CurrentDistance`는 카메라 거리 페이드를 엔진이 직접 제공한다는 뜻이다.** `08_ART_RULES.md` 규칙 3("4 m 안 0 → 10 m 밖 1")을 매 프레임 계산 없이 구현할 수 있다. 프로브에서 확인해라.

---

## 6. 트윈 · 시퀀스 · 런타임

```lua
declare TweenInfo: {                                                              -- L400-402
	new: (InTime: number, InEasingStyle: EasingStyle, InEasingDirection: EasingDirection,
	      InRepeatCount: number, InReverses: boolean, InDelayTime: number) -> TweenInfo,
}   -- 옵셔널 표기가 없다 — 6인자 다 넘겨라
declare class TweenService extends Instance
	function Create(self, Instance: Instance, TweenInfo: TweenInfo, PropertyTable: any): Instance
end   -- 반환이 Tween 이 아니라 Instance 로 선언됨

-- EasingStyle 11종
Linear · Sine · Back · Quad · Quart · Quint · Bounce · Elastic · Exponential · Circular · Cubic
-- EasingDirection: In / Out / InOut

declare class RunService extends Instance
	function IsClient/IsServer/IsStudio(self): boolean
	Heartbeat  ·  RenderStepped  ·  Stepped   : ScriptSignal
end   -- BindToRenderStep 없음

declare task: { wait, spawn, delay, cancel, defer }   -- L3084-3090. Debris 없음

-- 시퀀스 생성자 (전부 존재)
ColorSequence.new(Color3) | (keypoints) | (c0, c1)
ColorSequenceKeypoint.new(Time, Color3)
NumberSequence.new(v) | (keypoints) | (n0, n1)
NumberSequenceKeypoint.new(Time, Value) | (Time, Value, Envelope)
NumberRange.new(Min, Max)
```

**트윈 성능 실측** (`UIMotion.lua` 헤더, 프로브로 확인 후 삭제):
- `TweenService`는 제대로 보간한다 (`ProgressBar.Value` / `Position` / `Transparency` 전부)
- **`:Cancel()`은 값을 그 자리에 둔다** (시작값으로 되감지 않는다)
- ⚠️ **취소된 트윈도 `Completed`를 쏜다** (state = `Cancelled`) → 후속 콜백은 반드시 `PlaybackState`를 봐야 한다. 안 보면 **이중 발화**
- `repeatCount = -1` + `reverses = true` = 무한 핑퐁, **프레임당 Lua 비용 0**
- **동시 트윈 60개에 56 fps — 트윈 개수는 걱정할 대상이 아니다**

MCP 도구로 넘길 땐 생성자가 아니라 JSON이다:
`Color` = `[{Time, Color}]` · `Size`/`Transparency`/`Squash` = `[{Time, Value, Envelope?}]` · `Lifetime`/`Speed`/`Rotation`/`FlipbookFramerate` = `{Min, Max}`.

---

## 7. `Instance.new` 타입 목록 — L3054-3082 (원문)

```
Part · MeshPart · Model · Folder · BillboardGui · ScreenGui · SurfaceGui
Frame · TextLabel · TextButton · ImageLabel · ImageButton
Script · LocalScript · ModuleScript · Sound
ParticleEmitter · Light · Attachment · Animation · Animator · Humanoid
IntValue · StringValue · BoolValue · NumberValue
new: (className: string) -> Instance          -- 나머지 전부는 이 무타입 오버로드
```

**`ParticleEmitter` · `Attachment` · `BillboardGui`는 타입 목록에 있다 → 런타임 생성이 정식 지원된다.**
**`Trail` · `Beam` · `PointLight` · `SpotLight` · `VFXPreset` · `VFXRecipe` · `MaterialVariant` · `UIStroke`는 없다** → 무타입 오버로드로 떨어진다. MCP `instance_upsert` enum에는 있으므로 **정적 배치가 지원 경로다.** 런타임 생성 가능 여부는 프로브 항목.

---

## 8. 에셋 반입 — 커스텀 스프라이트를 넣는 길

```
overdare_image_import(absolute_path)  ->  "ovdrassetid://<number>"
```

이 id를 꽂을 수 있는 곳:
`ParticleEmitter.Texture` · `Beam.Texture` · `Trail.Texture` · `ImageLabel.Image` · `ImageButton.Image/HoverImage/PressImage` · `MeshPart.TextureId` · `MaterialVariant.*Map` · `Atmosphere.CloudTexture`

공식 문서 제약: **.png/.tga, 15 MB 이하, 권장 512×512** (저사양 256). *"권장"이라고만 적혀 있고 하드캡이라는 말은 없다* → 1024/2048 생존 여부는 프로브 항목.
`studiorpc_asset_drawer_import`의 `assetType` enum은 **`["MODEL"]`뿐** — 드로어로는 텍스처를 못 넣는다.

**이미 업로드돼 쓰이고 있는 에셋 id (참고):**

| id | 용도 |
|---|---|
| `ovdrassetid://40281100` | 원형 이미지 — `MobileControls.lua`가 조이스틱에 쓴다. 범용 원형 스프라이트로 재사용 가능 |
| `ovdrassetid://44705800` / `44738000` | `STA_StreamWater` 메시 / 텍스처 |
| `ovdrassetid://44754200` / `44754100` | `SGK_Pavilion` 메시 / 텍스처 |
| `ovdrassetid://43300100` | 로비 BGM |
