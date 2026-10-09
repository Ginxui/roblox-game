-- Wendigo_StealAnEgg — production-style builder script.
-- Original design (no assets copied from any existing game), built as a
-- tall, emaciated, antlered horror boss for a Steal an Egg style game.
--
-- Usage: paste this whole file into Studio's Command Bar and run it, or
-- drop it into a Script (e.g. ServerScriptService), run once, then delete
-- the script -- the finished "Wendigo_StealAnEgg" Model is left in
-- Workspace, built from a fixed seed of named points below.
--
-- Deviations from a literal reading of the brief, and why:
--  * No live Studio MCP session exists in this environment, so this is a
--    builder script rather than a narrated step-by-step Studio session.
--  * HumanoidRootPart is parented directly under the Model (not inside a
--    folder) -- that's the standard Roblox convention most rig/animation
--    code expects when it looks up model:FindFirstChild("HumanoidRootPart").
--  * Only the main skeleton (torso/neck/head/jaw/arms/legs) gets named
--    Motor6D joints, matching the examples given ("...etc."). Secondary
--    detail (fingers, ribs, antlers, teeth, egg shells, frost, blood) is
--    WeldConstraint'd to its nearest rigged part -- naming 100+ individual
--    joints would add animation complexity nothing in the brief asks for.
--  * CollisionFidelity (Box/Hull/None) is a MeshPart/UnionOperation
--    property; these are primitive Parts per requirement #1, so instead
--    every structural part is CanCollide = true and every decorative/fine
--    part (claws, teeth, antlers, frost, eggs, blood) is CanCollide = false.
--  * Per the brief, every Part is Anchored = false EXCEPT the root, which
--    is Anchored = true -- that's "except the root" taken literally.
--  * True tapered cylinders don't exist as a Roblox primitive, so tapered
--    bones (limbs, antlers, claws) are built as two stacked Shape=Cylinder
--    segments of shrinking diameter -- a common cheap taper trick.

local SPAWN_CFRAME = CFrame.new(0, 0, 0) -- where the model is built; relocate the finished Model afterwards

----------------------------------------------------------------------
-- palette (hex given in the brief where specified)
----------------------------------------------------------------------
local SKIN_MAT, BONE_MAT, ANTLER_MAT, FROST_MAT, CLAW_MAT =
	Enum.Material.SmoothPlastic, Enum.Material.Slate, Enum.Material.Wood, Enum.Material.Ice, Enum.Material.SmoothPlastic

local SKIN = Color3.fromRGB(148, 162, 168) -- pale desaturated blue-grey
local SKIN_DARK = Color3.fromRGB(102, 118, 126) -- frost-bitten extremities
local FROST = Color3.fromRGB(225, 238, 242) -- frostbite patches / ice crystals
local BONE = Color3.fromRGB(214, 204, 168) -- off-white, yellow-stained bone
local ANTLER = Color3.fromRGB(38, 30, 24) -- dark brown-black antler
local CLAW = Color3.fromRGB(18, 16, 14) -- near-black claws
local TOOTH = Color3.fromRGB(196, 182, 120) -- yellowed enamel
local SHELL = Color3.fromRGB(214, 206, 182) -- dirty white eggshell
local SHELL_STAIN = Color3.fromRGB(198, 176, 120) -- golden yolk stain
local BLOOD = Color3.fromRGB(74, 24, 20) -- frozen blood trails
local EYE_GLOW = Color3.fromRGB(125, 226, 255) -- #7DE2FF
local CHEST_GLOW = Color3.fromRGB(150, 255, 170) -- subtle parasitic chest sacs

----------------------------------------------------------------------
-- model + folders
----------------------------------------------------------------------
local model = Instance.new("Model")
model.Name = "Wendigo_StealAnEgg"

local folders = {}
for _, n in ipairs({ "Body", "Head", "Antlers", "Arms", "Legs", "Details", "Glow", "EggRemnants" }) do
	local f = Instance.new("Folder")
	f.Name = n
	f.Parent = model
	folders[n] = f
end

----------------------------------------------------------------------
-- low-level helpers
----------------------------------------------------------------------
local function pt(x, y, z)
	return (SPAWN_CFRAME * CFrame.new(x, y, z)).Position
end

local function weld(parent, child)
	local w = Instance.new("WeldConstraint")
	w.Part0 = parent
	w.Part1 = child
	w.Parent = parent
end

local function joint(name, part0, part1, pivotWorldPos)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	local pivot = CFrame.new(pivotWorldPos)
	m.C0 = part0.CFrame:ToObjectSpace(pivot)
	m.C1 = part1.CFrame:ToObjectSpace(pivot)
	m.Parent = part0
end

local function block(name, folder, partCFrame, size, material, color, canCollide, weldParent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = false
	part.CanCollide = canCollide ~= false
	part.Material = material
	part.Color = color
	part.Size = size
	part.CFrame = partCFrame
	part.Parent = folder
	if weldParent then
		weld(weldParent, part)
	end
	return part
end

-- orientation for a Shape=Cylinder part so its length (local X) runs p0->p1
local function cylCFrame(p0, p1)
	local baseCF = CFrame.new(p0, p1) * CFrame.Angles(0, -math.pi / 2, 0)
	local mid = (p0 + p1) / 2
	return CFrame.new(mid) * (baseCF - baseCF.Position)
end

local function cylinder(name, folder, p0, p1, diameter, material, color, canCollide, weldParent)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Anchored = false
	part.CanCollide = canCollide ~= false
	part.Material = material
	part.Color = color
	local len = (p1 - p0).Magnitude
	part.Size = Vector3.new(len, diameter, diameter)
	part.CFrame = cylCFrame(p0, p1)
	part.Parent = folder
	if weldParent then
		weld(weldParent, part)
	end
	return part
end

-- a tapered "bone": two stacked cylinder segments, d0 diameter at p0 shrinking to d1 at p1.
-- returns the near-end segment (segment A) so callers can either weld it (detail) or joint() it (rigged bone)
local function taperedBone(name, folder, p0, p1, d0, d1, material, color, canCollide, weldParent)
	local mid = p0:Lerp(p1, 0.5)
	local dMid = (d0 + d1) / 2
	local segA = cylinder(name .. "A", folder, p0, mid, (d0 + dMid) / 2, material, color, canCollide, weldParent)
	cylinder(name .. "B", folder, mid, p1, (dMid + d1) / 2, material, color, canCollide, segA)
	return segA
end

-- a flat streak between two points, used for blood trails
local function streak(name, folder, p0, p1, width, material, color, weldParent)
	local dist = (p1 - p0).Magnitude
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(width, 0.02, dist)
	part.CFrame = CFrame.new(p0, p1) * CFrame.new(0, 0, -dist / 2)
	part.Material = material
	part.Color = color
	part.CanCollide = false
	part.Parent = folder
	if weldParent then
		weld(weldParent, part)
	end
	return part
end

local function ball(name, folder, position, size, material, color, weldParent)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Material = material
	part.Color = color
	part.CanCollide = false
	part.Parent = folder
	if weldParent then
		weld(weldParent, part)
	end
	return part
end

----------------------------------------------------------------------
-- 1. blockout: spine + pelvis + shoulder anchor points (hunched, curving
--    forward as it rises -- the whole silhouette leans into this curve)
----------------------------------------------------------------------
local pelvis = pt(0, 6.3, 0)
local waist = pt(0, 7.6, -0.15)
local chest = pt(0, 8.9, -0.55)
local shoulderBase = pt(0, 9.9, -1.1)
local neckPt = pt(0, 10.3, -1.55)
local headPt = pt(0, 10.55, -2.05)
local hipL, hipR = pt(-0.5, 6.3, 0.05), pt(0.5, 6.3, 0.05)
local shL, shR = pt(-1.3, 9.7, -1.2), pt(1.3, 9.7, -1.2)

local root = block("HumanoidRootPart", model, CFrame.new(pelvis), Vector3.new(2, 2, 1), SKIN_MAT, Color3.new(1, 1, 1), false)
root.Transparency = 1
root.Anchored = true
model.PrimaryPart = root

----------------------------------------------------------------------
-- 2+3. skeletal structure + flesh: torso tapers to a sunken waist then
--    flares into a flared, visible ribcage; neck bridges to the skull
----------------------------------------------------------------------
local lowerTorso = taperedBone("LowerTorso", folders.Body, pelvis, waist, 0.95, 0.55, SKIN_MAT, SKIN, true)
joint("RootJoint", root, lowerTorso, pelvis)

local upperTorso = taperedBone("UpperTorso", folders.Body, waist, chest, 0.55, 1.15, SKIN_MAT, SKIN, true)
joint("Waist", lowerTorso, upperTorso, waist)

local chestTop = taperedBone("ChestTop", folders.Body, chest, shoulderBase, 1.15, 0.85, SKIN_MAT, SKIN, true)
joint("UpperChest", upperTorso, chestTop, chest)

cylinder("NeckBone", folders.Body, shoulderBase, neckPt, 0.45, SKIN_MAT, SKIN, false, chestTop)
cylinder("Pelvis", folders.Body, hipL, hipR, 0.4, SKIN_MAT, SKIN, true, lowerTorso)
cylinder("Shoulders", folders.Body, shL, shR, 0.32, SKIN_MAT, SKIN, true, chestTop)

-- exposed, flared ribcage: each rib sits past the torso's own silhouette
for i, y in ipairs({ 8.0, 8.3, 8.6, 8.9 }) do
	local halfSpan = 0.85 + (y - 8.0) * 0.25
	cylinder("Rib" .. i, folders.Body, pt(-halfSpan, y, -0.55), pt(halfSpan, y, -0.55), 0.09, BONE_MAT, BONE, false, chestTop)
end

-- frozen blood trails down the chest and one forearm
streak("BloodTrailChest", folders.Details, pt(0.15, 8.9, -0.95), pt(0.08, 7.7, -0.45), 0.09, SKIN_MAT, BLOOD, chestTop)
streak("BloodTrailChest2", folders.Details, pt(-0.3, 8.6, -0.85), pt(-0.2, 7.9, -0.5), 0.07, SKIN_MAT, BLOOD, chestTop)

-- subtle parasitic glow sacs embedded in the chest cavity
for i, p in ipairs({ pt(-0.25, 8.5, -0.8), pt(0.3, 8.7, -0.75), pt(0, 8.15, -0.65) }) do
	local sac = ball("ChestGlowSac" .. i, folders.Glow, p, Vector3.new(0.18, 0.18, 0.18), Enum.Material.Neon, CHEST_GLOW, chestTop)
	local light = Instance.new("PointLight")
	light.Color = CHEST_GLOW
	light.Range = 4
	light.Brightness = 0.6
	light.Parent = sac
end

----------------------------------------------------------------------
-- 4. head & face: elongated skull, hinged jaw, glowing empty sockets,
--    uneven teeth, a forked tongue, and two dark nostril holes
----------------------------------------------------------------------
local head = block("Head", folders.Head, CFrame.new(headPt), Vector3.new(0.95, 1.4, 2.0), SKIN_MAT, SKIN, true)
joint("Neck", chestTop, head, neckPt)

local jaw = block("Jaw", folders.Head, CFrame.new(pt(0, 10.05, -2.65)), Vector3.new(0.75, 0.3, 1.0), SKIN_MAT, SKIN_DARK, true)
joint("Jaw", head, jaw, pt(0, 10.2, -2.3))

-- uneven, yellowed teeth along the jaw
for i = 1, 9 do
	local t = (i - 5) / 4
	local base = pt(t * 0.32, 10.18, -2.6 - math.random() * 0.1)
	local len = 0.12 + math.random() * 0.14
	taperedBone("Tooth" .. i, folders.Head, base, base + Vector3.new(0, -len, -0.03), 0.05, 0.01, CLAW_MAT, TOOTH, false, jaw)
end

-- long black forked tongue
local tongueBase, tongueMid = pt(0, 9.95, -2.55), pt(0, 9.4, -2.3)
local tongue = taperedBone("Tongue", folders.Head, tongueBase, tongueMid, 0.14, 0.09, CLAW_MAT, Color3.fromRGB(10, 8, 8), false, jaw)
for _, dx in ipairs({ -0.07, 0.07 }) do
	taperedBone("TongueFork" .. (dx < 0 and "L" or "R"), folders.Head, tongueMid, tongueMid + Vector3.new(dx, -0.2, -0.1), 0.07, 0.015, CLAW_MAT, Color3.fromRGB(10, 8, 8), false, tongue)
end

-- dark nostril holes
for _, x in ipairs({ -0.13, 0.13 }) do
	ball("Nostril", folders.Head, pt(x, 10.35, -2.95), Vector3.new(0.12, 0.12, 0.12), SKIN_MAT, Color3.fromRGB(10, 8, 8), head)
end

-- sunken, empty eye sockets glowing icy blue
for _, x in ipairs({ -0.3, 0.3 }) do
	block("EyeSocket", folders.Head, CFrame.new(pt(x, 10.75, -2.75)), Vector3.new(0.3, 0.26, 0.2), SKIN_MAT, Color3.fromRGB(20, 22, 24), true, head)
	local eye = ball("Eye", folders.Glow, pt(x, 10.75, -2.8), Vector3.new(0.16, 0.16, 0.16), Enum.Material.Neon, EYE_GLOW, head)
	local light = Instance.new("PointLight")
	light.Color = EYE_GLOW
	light.Range = 10
	light.Brightness = 2.2
	light.Parent = eye
end

-- matted, frost-covered fur around the neck/jaw
for i = 1, 6 do
	local angle = (i / 6) * math.pi * 2
	local base = pt(math.cos(angle) * 0.4, 9.75 + math.random() * 0.3, -1.4 + math.sin(angle) * 0.3)
	taperedBone("FrostTuft" .. i, folders.Details, base, base + Vector3.new(0, -0.25 - math.random() * 0.15, 0), 0.06, 0.01, FROST_MAT, FROST, false, chestTop)
end

----------------------------------------------------------------------
-- 5. antlers: asymmetric crown -- left side full, right side broken/cracked
----------------------------------------------------------------------
local antlerBaseL, antlerMidL = pt(-0.35, 11.0, -1.9), pt(-0.9, 12.2, -1.6)
local tineL1, tineL2, tineL3 = pt(-1.6, 13.4, -1.9), pt(-1.3, 13.0, -0.9), pt(-0.6, 13.3, -1.2)
local baseL = taperedBone("LeftAntlerBase", folders.Antlers, antlerBaseL, antlerMidL, 0.22, 0.15, ANTLER_MAT, ANTLER, false, head)
taperedBone("LeftAntlerTineA", folders.Antlers, antlerMidL, tineL1, 0.13, 0.02, ANTLER_MAT, ANTLER, false, baseL)
taperedBone("LeftAntlerTineB", folders.Antlers, antlerMidL, tineL2, 0.12, 0.02, ANTLER_MAT, ANTLER, false, baseL)
taperedBone("LeftAntlerTineC", folders.Antlers, antlerMidL, tineL3, 0.11, 0.02, ANTLER_MAT, ANTLER, false, baseL)

local antlerBaseR, antlerMidR = pt(0.35, 11.0, -1.9), pt(0.85, 11.9, -1.7)
local tineR1 = pt(1.5, 12.7, -1.4)
local brokenStub = pt(0.95, 12.1, -1.95)
local baseR = taperedBone("RightAntlerBase", folders.Antlers, antlerBaseR, antlerMidR, 0.21, 0.14, ANTLER_MAT, ANTLER, false, head)
taperedBone("RightAntlerTineA", folders.Antlers, antlerMidR, tineR1, 0.12, 0.02, ANTLER_MAT, ANTLER, false, baseR)
taperedBone("RightAntlerBrokenStub", folders.Antlers, antlerMidR, brokenStub, 0.1, 0.07, ANTLER_MAT, ANTLER, false, baseR) -- blunt, snapped-off read

-- frost crystals clinging to a few tines
for i, spot in ipairs({ tineL1, tineL2, tineR1 }) do
	ball("FrostCrystal" .. i, folders.Antlers, spot, Vector3.new(0.14, 0.2, 0.14), Enum.Material.Ice, FROST, head)
end

----------------------------------------------------------------------
-- 7 (pulled forward so it can reference the antlers): egg remnants
----------------------------------------------------------------------
local function eggShell(name, position, stained, weldParent)
	local shell = ball(name, folders.EggRemnants, position, Vector3.new(0.42, 0.26, 0.36), SKIN_MAT, stained and SHELL_STAIN or SHELL, weldParent)
	shell.CFrame = CFrame.new(position) * CFrame.Angles(math.random(), math.random(), math.random())
	return shell
end

eggShell("EggShellRib1", pt(0.5, 8.6, -1.1), false, chestTop)
eggShell("EggShellRib2", pt(-0.55, 8.3, -1.0), true, chestTop)
eggShell("EggShellShoulder", pt(1.15, 9.5, -1.4), false, chestTop)

local eggString = taperedBone("EggString", folders.EggRemnants, brokenStub, brokenStub + Vector3.new(0.1, -0.5, 0), 0.02, 0.015, CLAW_MAT, Color3.fromRGB(40, 36, 30), false, baseR)
eggShell("EggShellDangling", brokenStub + Vector3.new(0.1, -0.65, 0), true, eggString)

----------------------------------------------------------------------
-- 6. arms & clawed hands -- long enough that hands nearly reach the
--    ground; the right hand is bigger and more hooked, the "egg-stealing"
--    hand
----------------------------------------------------------------------
local function buildArm(sign, shoulderPt, shoulderJoint, elbowJoint, wristJoint, big)
	local sideName = sign < 0 and "Left" or "Right"
	local elbow = pt(sign * 1.9, 6.3, -1.0)
	local wrist = pt(sign * 2.3, 2.3, -1.4)
	local handBase = pt(sign * 2.4, 1.0, -1.6)

	local upperArm = taperedBone(sideName .. "UpperArm", folders.Arms, shoulderPt, elbow, big and 0.62 or 0.5, big and 0.46 or 0.36, SKIN_MAT, SKIN, true)
	joint(shoulderJoint, chestTop, upperArm, shoulderPt)

	local lowerArm = taperedBone(sideName .. "LowerArm", folders.Arms, elbow, wrist, big and 0.46 or 0.36, big and 0.3 or 0.24, SKIN_MAT, SKIN_DARK, true)
	joint(elbowJoint, upperArm, lowerArm, elbow)

	local hand = cylinder(sideName .. "Hand", folders.Arms, wrist, handBase, big and 0.4 or 0.3, SKIN_MAT, SKIN_DARK, true)
	joint(wristJoint, lowerArm, hand, wrist)

	if big then
		streak("BloodTrailArm", folders.Details, pt(sign * 2.0, 6.0, -1.05), pt(sign * 2.2, 4.5, -1.3), 0.08, SKIN_MAT, BLOOD, upperArm)
	end

	-- four long clawed fingers; the big hand curls inward (grasping), the small hand splays
	local spread = big and 0.26 or 0.18
	local curl = big and 0.55 or 0.1
	for i = 1, 4 do
		local knuckle = handBase + Vector3.new(sign * spread * i, -0.3 - 0.05 * i, -0.2 - 0.04 * i)
		local tip = knuckle + Vector3.new(sign * (spread * i * 0.5 - curl), (big and -0.75 or -0.6), (big and -0.65 or -0.55))
		taperedBone(sideName .. "Finger" .. i, folders.Arms, knuckle, tip, big and 0.17 or 0.12, 0.025, CLAW_MAT, CLAW, false, hand)
	end
end

buildArm(-1, shL, "LeftShoulder", "LeftElbow", "LeftWrist", false)
buildArm(1, shR, "RightShoulder", "RightElbow", "RightWrist", true) -- the egg-stealing hand

----------------------------------------------------------------------
-- 1/2/3 continued: long deer-like digitigrade legs ending in clawed feet
----------------------------------------------------------------------
local function buildLeg(sign, hipPt, hipJoint, kneeJoint, ankleJoint, footJoint)
	local sideName = sign < 0 and "Left" or "Right"
	local knee = pt(sign * 0.55, 4.3, -0.5)
	local shinAnkle = pt(sign * 0.62, 2.3, 0.55)
	local cannonHeel = pt(sign * 0.68, 0.9, 0.2)
	local toe = pt(sign * 0.7, 0.12, -0.85)

	local thigh = taperedBone(sideName .. "Thigh", folders.Legs, hipPt, knee, 0.56, 0.4, SKIN_MAT, SKIN, true)
	joint(hipJoint, lowerTorso, thigh, hipPt)

	local shin = taperedBone(sideName .. "Shin", folders.Legs, knee, shinAnkle, 0.4, 0.28, SKIN_MAT, SKIN_DARK, true)
	joint(kneeJoint, thigh, shin, knee)

	local cannon = taperedBone(sideName .. "Cannon", folders.Legs, shinAnkle, cannonHeel, 0.28, 0.22, SKIN_MAT, SKIN_DARK, true)
	joint(ankleJoint, shin, cannon, shinAnkle)

	local foot = cylinder(sideName .. "Foot", folders.Legs, cannonHeel, toe, 0.3, SKIN_MAT, SKIN_DARK, true)
	joint(footJoint, cannon, foot, cannonHeel)

	for i, tip in ipairs({
		toe + Vector3.new(sign * 0.32, -0.05, -0.35),
		toe + Vector3.new(sign * 0.05, -0.08, -0.45),
		toe + Vector3.new(sign * -0.22, -0.05, -0.35),
	}) do
		taperedBone(sideName .. "ToeClaw" .. i, folders.Legs, toe, tip, 0.11, 0.02, CLAW_MAT, CLAW, false, foot)
	end

	taperedBone(sideName .. "Dewclaw", folders.Legs, shinAnkle, shinAnkle + Vector3.new(0, 0.5, 0.35), 0.08, 0.015, CLAW_MAT, CLAW, false, shin)
end

buildLeg(-1, hipL, "LeftHip", "LeftKnee", "LeftAnkle", "LeftFoot")
buildLeg(1, hipR, "RightHip", "RightKnee", "RightAnkle", "RightFoot")

----------------------------------------------------------------------
-- 10. final: drop into the world
----------------------------------------------------------------------
model.Parent = workspace
print("Wendigo_StealAnEgg built at " .. tostring(SPAWN_CFRAME.Position))
