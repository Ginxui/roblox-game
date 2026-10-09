-- Wendigo monster model builder.
-- Original design (not copied from any existing game asset): a tall, gaunt,
-- antlered horror-creature built from simple blocky parts with a Studs hide,
-- in the chunky low-poly style typical of Roblox egg/pet-chase games.
--
-- Usage: paste this whole file into Studio's Command Bar and run it, or drop
-- it into a Script (e.g. in ServerScriptService), run once, then delete the
-- script -- the finished "Wendigo" Model is left behind in Workspace.

local SPAWN_CFRAME = CFrame.new(0, 0, 0) -- where the model is built; move the finished Model afterwards to relocate it

local HIDE_COLOR = Color3.fromRGB(58, 56, 52)
local HIDE_MATERIAL = Enum.Material.Studs
local BONE_COLOR = Color3.fromRGB(214, 208, 188)
local BONE_MATERIAL = Enum.Material.Slate
local EYE_COLOR = Color3.fromRGB(196, 255, 92)

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

-- spine
local hip = pt(0, 5.0, 0)
local chest = pt(0, 8.6, -0.1)
local neckPt = pt(0, 9.3, -0.05)
beam("Torso", hip, chest, 1.4, 0.9, HIDE_MATERIAL, HIDE_COLOR)
beam("Neck", chest, neckPt, 0.55, 0.55, HIDE_MATERIAL, HIDE_COLOR)

-- head + snout
block("Head", anchorCFrame(0, 10.0, -0.1), Vector3.new(1.0, 1.3, 1.1), HIDE_MATERIAL, HIDE_COLOR)
beam("Snout", pt(0, 9.85, -0.55), pt(0, 9.75, -1.0), 0.5, 0.42, HIDE_MATERIAL, HIDE_COLOR, false)

-- glowing eyes
local function eye(name, x)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = anchorCFrame(x, 10.05, -0.62)
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
eye("LeftEye", -0.28)
eye("RightEye", 0.28)

-- exposed ribs across the chest
for i, y in ipairs({ 6.0, 6.6, 7.2, 7.8 }) do
	beam("Rib" .. i, pt(-0.65, y, -0.5), pt(0.65, y, -0.5), 0.14, 0.14, BONE_MATERIAL, BONE_COLOR, false)
end

-- branching antlers
local function antler(side)
	local sign = side == "Left" and -1 or 1
	local base = pt(sign * 0.3, 10.6, 0)
	local mid = pt(sign * 1.0, 11.7, 0.25)
	local tineA = pt(sign * 1.7, 12.8, 0)
	local tineB = pt(sign * 1.5, 12.4, 0.9)

	beam(side .. "AntlerBase", base, mid, 0.22, 0.22, BONE_MATERIAL, BONE_COLOR, false)
	beam(side .. "AntlerTineA", mid, tineA, 0.14, 0.14, BONE_MATERIAL, BONE_COLOR, false)
	beam(side .. "AntlerTineB", mid, tineB, 0.14, 0.14, BONE_MATERIAL, BONE_COLOR, false)
end
antler("Left")
antler("Right")

-- long gaunt arms with clawed hands
local function arm(side)
	local sign = side == "Left" and -1 or 1
	local shoulder = pt(sign * 1.0, 8.5, -0.1)
	local elbow = pt(sign * 1.4, 6.2, 0.2)
	local wrist = pt(sign * 1.6, 3.6, 0.1)

	beam(side .. "UpperArm", shoulder, elbow, 0.42, 0.42, HIDE_MATERIAL, HIDE_COLOR)
	beam(side .. "LowerArm", elbow, wrist, 0.34, 0.34, HIDE_MATERIAL, HIDE_COLOR)

	local claws = {
		pt(sign * 1.9, 2.7, -0.3),
		pt(sign * 1.6, 2.6, -0.55),
		pt(sign * 1.35, 2.75, -0.35),
	}
	for i, tip in ipairs(claws) do
		beam(side .. "Claw" .. i, wrist, tip, 0.08, 0.08, BONE_MATERIAL, BONE_COLOR, false)
	end
end
arm("Left")
arm("Right")

-- thin digitigrade legs
local function leg(side)
	local sign = side == "Left" and -1 or 1
	local hipPt = pt(sign * 0.7, 5.0, 0)
	local knee = pt(sign * 0.8, 2.6, 0.3)
	local ankle = pt(sign * 0.8, 0.3, -0.3)
	local toe = pt(sign * 0.8, 0.15, -1.0)

	beam(side .. "UpperLeg", hipPt, knee, 0.5, 0.5, HIDE_MATERIAL, HIDE_COLOR)
	beam(side .. "LowerLeg", knee, ankle, 0.4, 0.4, HIDE_MATERIAL, HIDE_COLOR)
	beam(side .. "Foot", ankle, toe, 0.5, 1.0, HIDE_MATERIAL, HIDE_COLOR)

	local toeClaws = {
		pt(sign * 1.1, 0.1, -1.4),
		pt(sign * 0.8, 0.1, -1.5),
		pt(sign * 0.5, 0.1, -1.4),
	}
	for i, tip in ipairs(toeClaws) do
		beam(side .. "ToeClaw" .. i, toe, tip, 0.08, 0.08, BONE_MATERIAL, BONE_COLOR, false)
	end
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
