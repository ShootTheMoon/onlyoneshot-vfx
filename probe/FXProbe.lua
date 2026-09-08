--!strict
-- FXProbe — OVERDARE VFX 능력 실측 프로브
--
-- 목적 : 10_OPEN_QUESTIONS.md 의 P-1 ~ P-11 을 한 번에 태운다.
--        이 게임엔 파티클이 한 번도 쓰인 적이 없어서, "안 된다"가 아니라
--        "확인한 적 없다" 인 항목이 대부분이다. 그걸 사실로 바꾼다.
--
-- 두는 곳 : StarterPlayer > StarterPlayerScripts > LocalScript
-- 도는 법 : 플레이테스트 시작 → 콘솔에서  _G.FXPROBE_RUN = true
--           (자동으로 안 돈다. 켜야 돈다)
-- 읽는 법 : Play.log 에서 "[FXPROBE]" 를 grep. 단계마다 overdare_screenshot.
-- 끝나면  : 이 스크립트를 지우거나 Enabled = false.
--
-- ★ 안전
--   - 만드는 건 전부 Workspace.FXProbe_Root 아래에 두고 끝에 통째로 지운다
--   - 모든 프로퍼티 쓰기는 pcall. 없는 프로퍼티 하나가 스크립트를 멈춘다
--   - 1 stud = 28 units. 아래 숫자는 전부 엔진 단위(cm)다

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local TAG = "[FXPROBE]"
local function log(...)
	print(TAG, ...)
end

--- 프로퍼티를 쓰고, 쓴 뒤 되읽어 실제로 반영됐는지 본다.
--- 쓰기만 성공하고 값이 안 바뀌는 경우가 이 엔진에 있다.
local function tryProp(obj: any, name: string, value: any): (boolean, any)
	local okWrite = pcall(function()
		obj[name] = value
	end)
	if not okWrite then
		return false, nil
	end
	local okRead, got = pcall(function()
		return obj[name]
	end)
	if not okRead then
		return true, nil
	end
	return true, got
end

local function tryNew(className: string): any
	local ok, inst = pcall(function()
		return (Instance :: any).new(className)
	end)
	if ok and inst then
		return inst
	end
	return nil
end

----------------------------------------------------------------- 준비
local root: any = nil

local function ensureRoot(): any
	if root and root.Parent then
		return root
	end
	root = Instance.new("Folder")
	root.Name = "FXProbe_Root"
	root.Parent = Workspace
	return root
end

--- 카메라 앞 origin. 프로브 결과를 눈으로 보려면 여기 둬야 한다.
local function originCFrame(): CFrame
	local cam = Workspace.CurrentCamera
	if cam then
		local ok, cf = pcall(function()
			return cam.CFrame * CFrame.new(0, 0, -900) -- 9 m 앞
		end)
		if ok and cf then
			return cf
		end
	end
	return CFrame.new(0, 500, 0)
end

local function makePart(name: string, offset: Vector3, size: number): any
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Size = Vector3.new(size, size, size)
	p.CFrame = originCFrame() + offset
	pcall(function()
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
	end)
	p.Parent = ensureRoot()
	return p
end

----------------------------------------------------------------- P-10 런타임 생성
local function probeInstanceNew()
	log("=== P-10 런타임 Instance.new ===")
	local classes = {
		"ParticleEmitter", "Attachment", "BillboardGui", -- 타입 목록에 있는 것
		"Trail", "Beam", "PointLight", "SpotLight",      -- 무타입 오버로드
		"VFXPreset", "VFXRecipe", "MaterialVariant", "UIStroke",
	}
	for _, c in ipairs(classes) do
		local inst = tryNew(c)
		if inst then
			local okName, cname = pcall(function()
				return inst.ClassName
			end)
			log(string.format("  %-18s 생성 O  ClassName=%s", c, okName and tostring(cname) or "?"))
			pcall(function()
				inst:Destroy()
			end)
		else
			log(string.format("  %-18s 생성 X", c))
		end
	end
end

----------------------------------------------------------------- P-1 Transparency
local function probeTransparency()
	log("=== P-1 Transparency 단계별 (스크린샷 필요) ===")
	local steps = { 0, 0.25, 0.5, 0.75, 1.0 }
	-- 큰 판과 작은 판을 같이 둔다. BoundaryFX 는 큰 벽에서 실패했다고 적혀 있다.
	for i, t in ipairs(steps) do
		local small = makePart("P1_small_" .. tostring(t), Vector3.new((i - 3) * 120, 0, 0), 80)
		pcall(function()
			small.Color = Color3.fromRGB(220, 60, 60)
			small.Transparency = t
		end)
		local big = makePart("P1_big_" .. tostring(t), Vector3.new((i - 3) * 400, 300, 0), 300)
		pcall(function()
			big.Color = Color3.fromRGB(60, 120, 220)
			big.Transparency = t
		end)
		local _, got = tryProp(small, "Transparency", t)
		log(string.format("  t=%.2f  쓰기후 읽기=%s", t, tostring(got)))
	end
	log("  → 화면을 보고 t=1.0 판이 실제로 사라졌는지 확인해라 (Q-1)")
end

----------------------------------------------------------------- P-11 / 파티클 기본
local function probeParticle()
	log("=== P-7/P-8/P-11 ParticleEmitter ===")
	local host = makePart("PE_Host", Vector3.new(0, 200, 0), 28)
	pcall(function()
		host.Transparency = 1
	end)

	local pe = tryNew("ParticleEmitter")
	if not pe then
		log("  ParticleEmitter 생성 X — 여기서 중단")
		return
	end
	pe.Parent = host

	local okRate = select(1, tryProp(pe, "Rate", 20))
	local okLE = select(1, tryProp(pe, "LightEmission", 1))
	local okBr, brGot = tryProp(pe, "Brightness", 5)
	local okLock, lockGot = tryProp(pe, "LockedToPart", true)
	local okSpread = select(1, tryProp(pe, "SpreadAngle", 45))
	local okRot = select(1, tryProp(pe, "RotSpeed", 90))
	log(string.format("  Rate=%s LightEmission=%s SpreadAngle=%s RotSpeed=%s",
		tostring(okRate), tostring(okLE), tostring(okSpread), tostring(okRot)))
	log(string.format("  ★ Brightness 쓰기=%s 값=%s   (Q-7: 로블록스에 없는 프로퍼티)",
		tostring(okBr), tostring(brGot)))
	log(string.format("  ★ LockedToPart 쓰기=%s 값=%s (Q-7)", tostring(okLock), tostring(lockGot)))

	-- 시퀀스/레인지
	pcall(function()
		pe.Lifetime = NumberRange.new(1, 2)
		pe.Speed = NumberRange.new(140, 280) -- 5~10 stud 를 28배 환산
		pe.Size = NumberSequence.new(28, 84)
		pe.Transparency = NumberSequence.new(0, 1)
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 240, 200), Color3.fromRGB(255, 240, 200))
		pe.Acceleration = Vector3.new(0, -280, 0)
	end)

	-- 열거형: 철자 확인 (타입파일은 Outward, MCP 스키마는 OutWard)
	local okShape = pcall(function()
		pe.Shape = (Enum :: any).ParticleEmitterShape.Box
		pe.ShapeStyle = (Enum :: any).ParticleEmitterShapeStyle.Volume
		pe.ShapeInOut = (Enum :: any).ParticleEmitterShapeInOut.Outward
		pe.Orientation = (Enum :: any).ParticleOrientation.FacingCameraWorldUp
		pe.EmissionDirection = (Enum :: any).NormalId.Top
	end)
	log("  열거형(Box/Volume/Outward/FacingCameraWorldUp/Top) 쓰기 = " .. tostring(okShape))

	-- 플립북 — 텍스처가 있어야 의미가 있다. SPRITE_ID 를 채우고 다시 돌려라.
	local SPRITE_ID = "" -- ← overdare_image_import 로 얻은 ovdrassetid 를 넣어라
	if SPRITE_ID ~= "" then
		local okTex = select(1, tryProp(pe, "Texture", SPRITE_ID))
		local okFB = pcall(function()
			pe.FlipbookLayout = (Enum :: any).ParticleFlipbookLayout.Grid4x4
			pe.FlipbookMode = (Enum :: any).ParticleFlipbookMode.Loop
			pe.FlipbookFramerate = NumberRange.new(24, 24)
			pe.FlipbookStartRandom = true
		end)
		log(string.format("  플립북 Texture=%s Layout/Mode/Framerate=%s", tostring(okTex), tostring(okFB)))
	else
		log("  플립북 미검사 — SPRITE_ID 를 채우고 다시 돌려라 (P-6 와 함께)")
	end

	pcall(function()
		pe.Enabled = true
	end)
	-- :Emit() 은 Enabled=true 뒤 한 틱 기다린 뒤에 부른다
	task.delay(0.2, function()
		local okEmit = pcall(function()
			pe:Emit(30)
		end)
		log("  :Emit(30) = " .. tostring(okEmit))
	end)

	-- P-8 : 3층 겹침. 카메라를 돌려보고 층 순서가 깨지는지 본다 (Q-8)
	for i = 1, 3 do
		local h = makePart("PE_Layer" .. tostring(i), Vector3.new(200, 100 * i, 0), 28)
		pcall(function()
			h.Transparency = 1
		end)
		local e = tryNew("ParticleEmitter")
		if e then
			e.Parent = h
			pcall(function()
				e.Rate = 6
				e.Lifetime = NumberRange.new(4, 6)
				e.Size = NumberSequence.new(200, 200)
				e.Transparency = NumberSequence.new(0.88, 0.88)
				e.Speed = NumberRange.new(0, 10)
				e.Orientation = (Enum :: any).ParticleOrientation.FacingCameraWorldUp
				e.Squash = NumberSequence.new(-0.45, -0.45)
				e.Enabled = true
			end)
		end
	end
	log("  3층 겹침 배치 완료 — 카메라를 360도 돌려 깜빡임/순서 뒤바뀜을 봐라 (Q-8)")
end

----------------------------------------------------------------- P-5 Trail / Beam
local function probeRibbon()
	log("=== P-5 Trail / Beam ===")
	local a0 = tryNew("Attachment")
	local a1 = tryNew("Attachment")
	local host = makePart("Ribbon_Host", Vector3.new(-300, 100, 0), 28)
	if a0 then
		a0.Parent = host
	end
	if a1 then
		a1.Parent = host
		pcall(function()
			a1.CFrame = CFrame.new(0, 200, 0)
		end)
	end

	local tr = tryNew("Trail")
	if tr then
		tr.Parent = host
		local okA0 = select(1, tryProp(tr, "Attachment0", a0))
		local okA1 = select(1, tryProp(tr, "Attachment1", a1))
		local okW = select(1, tryProp(tr, "Width", 40))
		local okTS = select(1, tryProp(tr, "TextureSpeed", 1))
		log(string.format("  ★ Trail.Attachment0=%s Attachment1=%s  (Q-5: 타입파일엔 없다)",
			tostring(okA0), tostring(okA1)))
		log(string.format("    Trail.Width=%s TextureSpeed=%s", tostring(okW), tostring(okTS)))
	else
		log("  Trail 생성 X")
	end

	local bm = tryNew("Beam")
	if bm then
		bm.Parent = host
		local okB0 = select(1, tryProp(bm, "Attachment0", a0))
		local okB1 = select(1, tryProp(bm, "Attachment1", a1))
		local okFC = select(1, tryProp(bm, "FaceCamera", true))
		log(string.format("  Beam.Attachment0=%s Attachment1=%s FaceCamera=%s",
			tostring(okB0), tostring(okB1), tostring(okFC)))
	else
		log("  Beam 생성 X")
	end
end

----------------------------------------------------------------- P-2 Outline / Fill 관통
local function probeOverlay()
	log("=== P-2 Outline / Fill DepthMode (스크린샷 필요) ===")
	local target = makePart("Overlay_Target", Vector3.new(0, 0, -400), 100)
	pcall(function()
		target.Color = Color3.fromRGB(80, 200, 120)
	end)
	-- 앞을 가리는 벽
	local wall = makePart("Overlay_Wall", Vector3.new(0, 0, -200), 300)
	pcall(function()
		wall.Color = Color3.fromRGB(60, 60, 60)
	end)

	local ol = tryNew("Outline")
	if ol then
		pcall(function()
			ol.Adornee = target
			ol.Color = Color3.fromRGB(255, 200, 0)
			ol.Thickness = 0.4
			ol.Enabled = true
		end)
		ol.Parent = ensureRoot()
		log("  Outline 배치 — 벽 뒤 target 이 보이나?")
	else
		log("  Outline 생성 X")
	end

	local modes = { "AlwaysOnTop", "VisibleWhenNotOccluded", "VisibleWhenOccluded" }
	for i, m in ipairs(modes) do
		local t2 = makePart("Fill_Target_" .. m, Vector3.new(200 * i, 0, -400), 100)
		local fl = tryNew("Fill")
		if fl then
			local okMode = pcall(function()
				fl.Adornee = t2
				fl.Color = Color3.fromRGB(255, 80, 80)
				fl.Transparency = 0.3
				fl.DepthMode = (Enum :: any).FillDepthModeType[m]
				fl.Enabled = true
			end)
			fl.Parent = ensureRoot()
			log(string.format("  Fill DepthMode=%-24s 쓰기=%s", m, tostring(okMode)))
		end
	end
	log("  → Q-2 : 문서상 AlwaysOnTop 은 벽 뒤에서도 보여야 한다. 실제로 보이는지 확인해라")
end

----------------------------------------------------------------- P-9 UI 클리핑 창
local function probeClipWindow()
	log("=== P-9 ClipsDescendants 클리핑 창 (ui_browse 로 확인) ===")
	local player = game:GetService("Players").LocalPlayer
	if not player then
		log("  LocalPlayer 없음 — 건너뜀")
		return
	end
	local pg = player:FindFirstChild("PlayerGui", false)
	if not pg then
		log("  PlayerGui 없음 — 건너뜀")
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "FXProbe_Clip"
	gui.Parent = pg

	local win = Instance.new("Frame")
	win.Name = "ClipWindow"
	win.Size = UDim2.new(0, 96, 0, 96)
	win.Position = UDim2.new(0, 40, 0, 40)
	win.BackgroundTransparency = 0.5
	win.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	local okClip = select(1, tryProp(win, "ClipsDescendants", true))
	win.Parent = gui

	local film = Instance.new("Frame")
	film.Name = "Film"
	film.Size = UDim2.new(0, 96 * 4, 0, 96 * 4) -- 4x4 아틀라스 크기
	film.Position = UDim2.new(0, -96 * 1, 0, -96 * 2) -- 2행 1열 셀을 보여준다
	film.BackgroundColor3 = Color3.fromRGB(200, 60, 200)
	film.BackgroundTransparency = 0
	film.Parent = win

	log(string.format("  ClipsDescendants 쓰기=%s", tostring(okClip)))
	log("  → overdare_ui_browse 로 FXProbe_Clip.ClipWindow 와 .Film 의 rect 를 읽어라")
	log("    Film 이 96x96 창 밖으로 안 삐져나오면 클리핑이 동작하는 것이다 (Q-9)")

	-- 회전 확인 (v0.10.0 에서 생겼다)
	local okRot = select(1, tryProp(win, "Rotation", 15))
	log(string.format("  GuiObject.Rotation 쓰기=%s (낡은 주석은 없다고 한다)", tostring(okRot)))
end

----------------------------------------------------------------- 정리
local function cleanup()
	if root then
		pcall(function()
			root:Destroy()
		end)
		root = nil
	end
	local player = game:GetService("Players").LocalPlayer
	if player then
		local pg = player:FindFirstChild("PlayerGui", false)
		if pg then
			local g = pg:FindFirstChild("FXProbe_Clip", false)
			if g then
				pcall(function()
					g:Destroy()
				end)
			end
		end
	end
	log("정리 완료")
end

_G.FXPROBE_CLEANUP = cleanup

----------------------------------------------------------------- 진입
local started = false
local function run()
	if started then
		return
	end
	started = true
	log("시작 — 결과는 이 태그로 grep 해라")
	log(string.format("RunService IsClient=%s IsStudio=%s",
		tostring(RunService:IsClient()), tostring(RunService:IsStudio())))

	probeInstanceNew()
	probeTransparency()
	probeParticle()
	probeRibbon()
	probeOverlay()
	probeClipWindow()

	log("배치 끝. 스크린샷을 찍고, 끝나면 콘솔에서 _G.FXPROBE_CLEANUP() 을 불러라")
	log("남은 항목은 도구로 해야 한다 : P-3 VFXRecipe upsert · P-4 EmptySprite · P-6 이미지 해상도")
end

task.spawn(function()
	while not started do
		if _G.FXPROBE_RUN then
			run()
		end
		task.wait(0.5)
	end
end)

log("대기 중. 콘솔에서 _G.FXPROBE_RUN = true 를 실행해라")
