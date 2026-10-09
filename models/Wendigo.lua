-- Wendigo (Steal an Egg style) -- simple builder script.
-- Matches the plain building list exactly: 33 parts, Part/WedgePart/Cylinder
-- only, Plastic material, sickly pale-green skin, under the 45-part cap.
-- No MeshParts, no Unions, no Motor6D rig -- everything is WeldConstraint'd
-- into one rigid model, simple enough to also build by hand in Studio.
--
-- Usage: paste into Studio's Command Bar and run it, or drop into a Script
-- (e.g. ServerScriptService), run once, then delete the script -- the
-- finished "Wendigo" Model is left in Workspace.

local SPAWN_CFRAME = CFrame.new(0, 0, 0) -- where the model is built; relocate the finished Model afterwards

----------------------------------------------------------------------
-- palette
----------------------------------------------------------------------
local SKIN = Color3.fromRGB(122, 138, 108) -- sickly pale green-grey
local ANTLER = Color3.fromRGB(90, 80, 60)
local EYE_GLOW = Color3.fromRGB(190, 255, 255)
local CLAW = Color3.fromRGB(25, 22, 20)
local SHELL = Color3.fromRGB(230, 225, 200)
local MAT = Enum.Material.Plastic

----------------------------------------------------------------------
-- model + folders (matches the requested grouping)
----------------------------------------------------------------------
local model = Instance.new("Model")
model.Name = "Wendigo"

local folders = {}
for _, n in ipairs({ "Torso", "Head", "Antlers", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Details" }) do
	local f = Instance.new("Folder")
	f.Name = n
	f.Parent = model
	folders[n] = f
end

----------------------------------------------------------------------
-- helpers
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

local function block(name, folder, center, size, color, canCollide, weldParent, extraRotation)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = false
	part.CanCollide = canCollide ~= false
	part.Material = MAT
	part.Color = color
	part.Size = size
	part.CFrame = CFrame.new(center) * (extraRotation or CFrame.new())
	part.Parent = folder
	if weldParent then
		weld(weldParent, part)
	end
	return part
end

-- Shape=Cylinder part spanning two points; Roblox cylinders run along local X,
-- so this rotates -90 degrees about Y to point local X from p0 to p1.
local function cylinder(name, folder, p0, p1, diameter, color, canCollide, weldParent)
	local baseCF = CFrame.new(p0, p1) * CFrame.Angles(0, -math.pi / 2, 0)
	local mid = (p0 + p1) / 2
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Anchored = false
	part.CanCollide = canCollide ~= false
	part.Material = MAT
	part.Color = color
	part.Size = Vector3.new((p1 - p0).Magnitude, diameter, diameter)
	part.CFrame = CFrame.new(mid) * (baseCF - baseCF.Position)
	part.Parent = folder
	if weldParent then
		weld(weldParent, part)
	end
	return part
end

-- WedgePart tapering from a full-height `base` end to a point at `tip`.
local function wedge(name, folder, base, tip, width, height, color, canCollide, weldParent)
	local baseCF = CFrame.new(tip, base) -- local +Z ends up pointing base -> tip
	local mid = (base + tip) / 2
	local part = Instance.new("WedgePart")
	part.Name = name
	part.Anchored = false
	part.CanCollide = canCollide ~= false
	part.Material = MAT
	part.Color = color
	part.Size = Vector3.new(width, height, (tip - base).Magnitude)
	part.CFrame = CFrame.new(mid) * (baseCF - baseCF.Position)
	part.Parent = folder
	if weldParent then
		weld(weldParent, part)
	end
	return part
end

local function ball(name, folder, center, size, material, color, weldParent)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Anchored = false
	part.CanCollide = false
	part.Material = material
	part.Color = color
	part.Size = size
	part.CFrame = CFrame.new(center)
	part.Parent = folder
	if weldParent then
		weld(weldParent, part)
	end
	return part
end

----------------------------------------------------------------------
-- skeleton points (hunched forward: Z shifts negative as Y rises)
----------------------------------------------------------------------
local pelvis = pt(0, 7.0, 0)
local hipL, hipR = pt(-0.5, 7.0, 0.05), pt(0.5, 7.0, 0.05)
local chest = pt(0, 9.8, -0.6)
local shoulderL, shoulderR = pt(-1.0, 10.4, -1.0), pt(1.0, 10.4, -1.0)
local headCenter = pt(0, 11.1, -1.5)

----------------------------------------------------------------------
-- root
----------------------------------------------------------------------
local root = block("Root", model, pelvis, Vector3.new(2, 2, 1), Color3.new(1, 1, 1), false)
root.Transparency = 1
root.Anchored = true
model.PrimaryPart = root

----------------------------------------------------------------------
-- torso (2 parts)
----------------------------------------------------------------------
local lowerTorso = block("LowerTorso", folders.Torso, pt(0, 7.9, -0.1), Vector3.new(1.6, 2.6, 1.2), SKIN, true, root)
local upperTorso = block("UpperTorso", folders.Torso, chest, Vector3.new(2.0, 2.2, 1.3), SKIN, true, lowerTorso)

----------------------------------------------------------------------
-- head (4 parts: skull, jaw, 2 eyes)
----------------------------------------------------------------------
local head = block("Head", folders.Head, headCenter, Vector3.new(1.4, 1.5, 1.7), SKIN, true, upperTorso, CFrame.Angles(math.rad(15), 0, 0))
wedge("Jaw", folders.Head, pt(0, 10.85, -1.9), pt(0, 10.55, -2.5), 0.8, 0.5, SKIN, false, head)
ball("LeftEye", folders.Head, pt(-0.3, 11.2, -2.2), Vector3.new(0.25, 0.25, 0.25), Enum.Material.Neon, EYE_GLOW, head)
ball("RightEye", folders.Head, pt(0.3, 11.2, -2.2), Vector3.new(0.25, 0.25, 0.25), Enum.Material.Neon, EYE_GLOW, head)

----------------------------------------------------------------------
-- antlers (4 parts: base + tip, both sides)
----------------------------------------------------------------------
local antlerBaseL, antlerMidL, antlerTipL = pt(-0.3, 11.8, -1.1), pt(-0.9, 12.6, -1.3), pt(-1.4, 13.4, -1.0)
local leftAntlerBase = cylinder("LeftAntlerBase", folders.Antlers, antlerBaseL, antlerMidL, 0.18, ANTLER, false, head)
cylinder("LeftAntlerTip", folders.Antlers, antlerMidL, antlerTipL, 0.13, ANTLER, false, leftAntlerBase)

local antlerBaseR, antlerMidR, antlerTipR = pt(0.3, 11.8, -1.1), pt(0.9, 12.6, -1.3), pt(1.4, 13.4, -1.0)
local rightAntlerBase = cylinder("RightAntlerBase", folders.Antlers, antlerBaseR, antlerMidR, 0.18, ANTLER, false, head)
cylinder("RightAntlerTip", folders.Antlers, antlerMidR, antlerTipR, 0.13, ANTLER, false, rightAntlerBase)

----------------------------------------------------------------------
-- left arm: normal hanging arm, simple splayed claws (6 parts)
----------------------------------------------------------------------
local elbowL, wristL = pt(-1.7, 7.4, -0.8), pt(-2.1, 3.4, -1.0)
local leftUpperArm = cylinder("LeftUpperArm", folders.LeftArm, shoulderL, elbowL, 0.5, SKIN, true, upperTorso)
local leftLowerArm = cylinder("LeftLowerArm", folders.LeftArm, elbowL, wristL, 0.4, SKIN, true, leftUpperArm)
local handL = wristL + Vector3.new(0, -0.3, -0.1)
local leftHand = block("LeftHand", folders.LeftArm, handL, Vector3.new(0.6, 0.6, 0.5), SKIN, true, leftLowerArm)
wedge("LeftClaw1", folders.LeftArm, handL, handL + Vector3.new(-0.2, -0.5, -0.3), 0.15, 0.15, CLAW, false, leftHand)
wedge("LeftClaw2", folders.LeftArm, handL, handL + Vector3.new(0, -0.55, -0.35), 0.15, 0.15, CLAW, false, leftHand)
wedge("LeftClaw3", folders.LeftArm, handL, handL + Vector3.new(0.2, -0.5, -0.3), 0.15, 0.15, CLAW, false, leftHand)

----------------------------------------------------------------------
-- right arm: bigger, reaches further forward, claws curl in like it's
-- about to grab an egg (7 parts)
----------------------------------------------------------------------
local elbowR, wristR = pt(1.8, 7.3, -1.3), pt(2.3, 3.3, -1.8)
local rightUpperArm = cylinder("RightUpperArm", folders.RightArm, shoulderR, elbowR, 0.55, SKIN, true, upperTorso)
local rightLowerArm = cylinder("RightLowerArm", folders.RightArm, elbowR, wristR, 0.45, SKIN, true, rightUpperArm)
local handR = wristR + Vector3.new(0, -0.3, -0.2)
local rightHand = block("RightHand", folders.RightArm, handR, Vector3.new(0.7, 0.7, 0.6), SKIN, true, rightLowerArm)
local grabPoint = handR + Vector3.new(0, -0.1, -0.5) -- the imaginary egg the fingers curl toward
wedge("RightClaw1", folders.RightArm, handR + Vector3.new(-0.25, -0.1, -0.1), grabPoint + Vector3.new(-0.1, 0.05, 0.05), 0.18, 0.18, CLAW, false, rightHand)
wedge("RightClaw2", folders.RightArm, handR + Vector3.new(-0.08, -0.15, -0.15), grabPoint + Vector3.new(-0.03, 0.02, 0.08), 0.18, 0.18, CLAW, false, rightHand)
wedge("RightClaw3", folders.RightArm, handR + Vector3.new(0.08, -0.15, -0.15), grabPoint + Vector3.new(0.03, 0.02, 0.08), 0.18, 0.18, CLAW, false, rightHand)
wedge("RightClaw4", folders.RightArm, handR + Vector3.new(0.25, -0.1, -0.1), grabPoint + Vector3.new(0.1, 0.05, 0.05), 0.18, 0.18, CLAW, false, rightHand)

----------------------------------------------------------------------
-- legs: long and thin (3 parts each)
----------------------------------------------------------------------
local kneeL, ankleL = pt(-0.6, 3.6, -0.3), pt(-0.65, 0.5, -0.1)
local leftUpperLeg = cylinder("LeftUpperLeg", folders.LeftLeg, hipL, kneeL, 0.5, SKIN, true, lowerTorso)
local leftLowerLeg = cylinder("LeftLowerLeg", folders.LeftLeg, kneeL, ankleL, 0.4, SKIN, true, leftUpperLeg)
block("LeftFoot", folders.LeftLeg, ankleL + Vector3.new(0, -0.1, -0.4), Vector3.new(0.6, 0.4, 1.1), SKIN, true, leftLowerLeg)

local kneeR, ankleR = pt(0.6, 3.6, -0.3), pt(0.65, 0.5, -0.1)
local rightUpperLeg = cylinder("RightUpperLeg", folders.RightLeg, hipR, kneeR, 0.5, SKIN, true, lowerTorso)
local rightLowerLeg = cylinder("RightLowerLeg", folders.RightLeg, kneeR, ankleR, 0.4, SKIN, true, rightUpperLeg)
block("RightFoot", folders.RightLeg, ankleR + Vector3.new(0, -0.1, -0.4), Vector3.new(0.6, 0.4, 1.1), SKIN, true, rightLowerLeg)

----------------------------------------------------------------------
-- details: a few cracked egg shells stuck to the body/antlers (3 parts)
----------------------------------------------------------------------
ball("EggShellChest", folders.Details, pt(0.5, 9.5, -1.0), Vector3.new(0.5, 0.35, 0.4), MAT, SHELL, upperTorso)
ball("EggShellAntler", folders.Details, antlerMidL + Vector3.new(0.1, 0.1, 0), Vector3.new(0.45, 0.3, 0.35), MAT, SHELL, leftAntlerBase)
ball("EggShellShoulder", folders.Details, shoulderL + Vector3.new(0.2, 0.3, -0.1), Vector3.new(0.4, 0.3, 0.35), MAT, SHELL, upperTorso)

----------------------------------------------------------------------
-- done
----------------------------------------------------------------------
model.Parent = workspace
print("Wendigo built at " .. tostring(SPAWN_CFRAME.Position) .. " -- " .. #model:GetDescendants() .. " instances")
