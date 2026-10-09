-- Wendigo monster model builder.
-- Original design (not copied from any existing game asset): a tall, gaunt,
-- antlered horror-creature built from blocky parts with a Studs hide, in
-- the chunky low-poly style typical of Roblox egg/pet-chase games.
--
-- v2: pinched-waist/broad-chest torso, a pelvis + shoulder bridge so the
-- limbs read as attached rather than floating, a two-tone hide (lighter
-- upper limbs, darker weathered extremities), a jaw, a fuller antler
-- crown, forward-reaching clawed arms, a proper forward/back/forward
-- digitigrade leg bend, a slimmer foot, and a dewclaw.
--
-- Usage: paste this whole file into Studio's Command Bar and run it, or
-- drop it into a Script (e.g. in ServerScriptService), run once, then
-- delete the script -- the finished "Wendigo" Model is left in Workspace.

local SPAWN_CFRAME = CFrame.new(0, 0, 0) -- where the model is built; move the finished Model afterwards to relocate it

local HIDE_MATERIAL = Enum.Material.Studs
local HIDE_COLOR = Color3.fromRGB(52, 56, 42) -- upper limbs, torso, head, neck
local HIDE_DARK_COLOR = Color3.fromRGB(34, 36, 28) -- lower limbs, feet, jaw: weathered extremities
local BONE_MATERIAL = Enum.Material.Slate
local BONE_COLOR = Color3.fromRGB(202, 194, 158) -- ribs, antlers, claws
local EYE_COLOR = Color3.fromRGB(201, 255, 96)

local model = Instance.new("Model")
model.Name = "Wendigo"

local function pt(x, y, z)
	return (SPAWN_CFRAME * CFrame.new(x, y, z)).Position
end

local function anchorCFrame(x, y, z)
	return SPAWN_CFRAME * CFrame.new(x, y, z)
end

local function block(name, partCFrame, size, material, color, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = false
	part.CanCollide = canCollide ~= false
	part.Material = material
	part.Color = color
	part.Size = size
	part.CFrame = partCFrame
	part.Parent = model
	return part
end

-- a part stretched between two points, used for limbs/antlers/ribs/claws
local function beam(name, p0, p1, width, depth, material, color, canCollide)
	local dist = (p1 - p0).Magnitude
	local segCFrame = CFrame.new(p0, p1) * CFrame.new(0, 0, -dist / 2)
	return block(name, segCFrame, Vector3.new(width, depth, dist), material, color, canCollide)
end

local root = block("HumanoidRootPart", anchorCFrame(0, 5.0, 0), Vector3.new(1, 1, 1), Enum.Material.Plastic, Color3.new(1, 1, 1), false)
root.Transparency = 1
model.PrimaryPart = root

-- key skeleton points, shared between torso/pelvis/shoulders and the limbs
local hip = pt(0, 5.0, 0)
local waist = pt(0, 6.8, -0.05)
local chest = pt(0, 8.6, -0.1)
local neckPt = pt(0, 9.3, -0.05)
local leftHip, rightHip = pt(-0.62, 5.0, 0.05), pt(0.62, 5.0, 0.05)
local leftShoulder, rightShoulder = pt(-1.05, 8.3, -0.15), pt(1.05, 8.3, -0.15)

-- torso: narrow gaunt waist flaring out to both the pelvis and the chest
beam("TorsoLower", hip, waist, 1.0, 0.75, HIDE_MATERIAL, HIDE_COLOR)
beam("TorsoUpper", waist, chest, 1.5, 1.0, HIDE_MATERIAL, HIDE_COLOR)
beam("Neck", chest, neckPt, 0.5, 0.5, HIDE_MATERIAL, HIDE_COLOR)

-- pelvis/shoulder bridges so the limbs read as attached, not floating
beam("Pelvis", leftHip, rightHip, 0.4, 0.4, HIDE_MATERIAL, HIDE_COLOR)
beam("Shoulders", leftShoulder, rightShoulder, 0.35, 0.35, HIDE_MATERIAL, HIDE_COLOR)

-- head, jaw, tapering snout
local headCenter = anchorCFrame(0, 10.05, -0.05)
block("Head", headCenter, Vector3.new(0.82, 1.15, 1.3), HIDE_MATERIAL, HIDE_COLOR)
block("Jaw", anchorCFrame(0, 9.55, -0.68), Vector3.new(0.56, 0.22, 0.68), HIDE_MATERIAL, HIDE_DARK_COLOR)
beam("Snout", pt(0, 9.95, -0.7), pt(0, 9.85, -1.25), 0.38, 0.3, HIDE_MATERIAL, HIDE_COLOR, false)

-- glowing eyes
local function eye(name, x)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = anchorCFrame(x, 10.15, -0.68)
	part.Material = Enum.Material.Neon
	part.Color = EYE_COLOR
	part.CanCollide = false
	part.Parent = model

	local light = Instance.new("PointLight")
	light.Color = EYE_COLOR
	light.Range = 8
	light.Brightness = 2
	light.Parent = part

	return part
end
eye("LeftEye", -0.25)
eye("RightEye", 0.25)

-- exposed ribs across the upper chest, following the torso's taper
for i, y in ipairs({ 7.0, 7.5, 8.0, 8.4 }) do
	local halfSpan = 0.45 + (y - 7.0) / 1.4 * 0.27
	beam("Rib" .. i, pt(-halfSpan, y, -0.6), pt(halfSpan, y, -0.6), 0.13, 0.13, BONE_MATERIAL, BONE_COLOR, false)
end

-- a fuller antler crown: a base plus three branching tines
local function antler(side)
	local sign = side == "Left" and -1 or 1
	local base = pt(sign * 0.28, 10.6, -0.05)
	local mid = pt(sign * 0.95, 11.6, 0.2)
	local tineA = pt(sign * 1.6, 12.6, -0.1)
	local tineB = pt(sign * 1.4, 12.3, 0.75)
	local tineC = pt(sign * 0.6, 12.6, 0.55)

	beam(side .. "AntlerBase", base, mid, 0.2, 0.2, BONE_MATERIAL, BONE_COLOR, false)
	beam(side .. "AntlerTineA", mid, tineA, 0.13, 0.13, BONE_MATERIAL, BONE_COLOR, false)
	beam(side .. "AntlerTineB", mid, tineB, 0.13, 0.13, BONE_MATERIAL, BONE_COLOR, false)
	beam(side .. "AntlerTineC", mid, tineC, 0.12, 0.12, BONE_MATERIAL, BONE_COLOR, false)
end
antler("Left")
antler("Right")

-- long gaunt arms reaching forward, clawed hands
local function arm(side)
	local sign = side == "Left" and -1 or 1
	local shoulder = side == "Left" and leftShoulder or rightShoulder
	local elbow = pt(sign * 1.55, 5.9, 0.4)
	local wrist = pt(sign * 1.9, 3.5, -0.45)

	beam(side .. "UpperArm", shoulder, elbow, 0.4, 0.4, HIDE_MATERIAL, HIDE_COLOR)
	beam(side .. "LowerArm", elbow, wrist, 0.3, 0.3, HIDE_MATERIAL, HIDE_DARK_COLOR)

	local claws = {
		pt(sign * 2.35, 2.85, -1.15),
		pt(sign * 2.0, 2.65, -1.35),
		pt(sign * 1.65, 2.8, -1.2),
	}
	for i, tip in ipairs(claws) do
		beam(side .. "Claw" .. i, wrist, tip, 0.09, 0.09, BONE_MATERIAL, BONE_COLOR, false)
	end
end
arm("Left")
arm("Right")

-- digitigrade legs: thigh leans forward, shin tucks back, foot plants forward
local function leg(side)
	local sign = side == "Left" and -1 or 1
	local hipPt = side == "Left" and leftHip or rightHip
	local knee = pt(sign * 0.78, 2.7, -0.42)
	local ankle = pt(sign * 0.84, 1.0, 0.22)
	local toe = pt(sign * 0.88, 0.15, -0.68)

	beam(side .. "UpperLeg", hipPt, knee, 0.46, 0.46, HIDE_MATERIAL, HIDE_COLOR)
	beam(side .. "LowerLeg", knee, ankle, 0.34, 0.34, HIDE_MATERIAL, HIDE_DARK_COLOR)
	beam(side .. "Foot", ankle, toe, 0.3, 0.26, HIDE_MATERIAL, HIDE_DARK_COLOR)

	local toeClaws = {
		pt(sign * 1.1, 0.08, -1.18),
		pt(sign * 0.88, 0.04, -1.28),
		pt(sign * 0.66, 0.08, -1.16),
	}
	for i, tip in ipairs(toeClaws) do
		beam(side .. "ToeClaw" .. i, toe, tip, 0.08, 0.08, BONE_MATERIAL, BONE_COLOR, false)
	end

	beam(side .. "Dewclaw", ankle, pt(sign * 0.86, 0.78, 0.6), 0.06, 0.06, BONE_MATERIAL, BONE_COLOR, false)
end
leg("Left")
leg("Right")

-- rigidly weld every part to the root so the whole creature moves as one
for _, part in ipairs(model:GetDescendants()) do
	if part:IsA("BasePart") and part ~= root then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = root
	end
end

model.Parent = workspace
print("Wendigo built at " .. tostring(SPAWN_CFRAME.Position))
