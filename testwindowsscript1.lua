
-- โหลด Library Fluent และ Addons
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/thomahamham/power-panel-version-windows-11/refs/heads/main/InterfaceManager.lua"))()
local ScriptVersion = "1.0"
local VersionUrl = "https://raw.githubusercontent.com/thomahamham/power-panel-version-windows-11/refs/heads/main/version.txt" -- ไฟล์ version.txt บน GitHub

local function CheckForUpdate()
    local success, response = pcall(function()
        return game:HttpGet(VersionUrl)
    end)

    if not success then
        Fluent:Notify({
            Title = "อัปเดต",
            Content = "ไม่สามารถเชื่อมต่อ GitHub เพื่อตรวจสอบเวอร์ชั่นได้",
            Duration = 6
        })
        return
    end

    local latestVersion = response:match("^%s*(.-)%s*$") -- ตัดช่องว่าง

    if latestVersion and latestVersion ~= "" and latestVersion ~= ScriptVersion then
        Window:Dialog({
            Title = "🔄 มีเวอร์ชั่นใหม่!",
            Content = "เวอร์ชั่นปัจจุบัน: " .. ScriptVersion .. "\nเวอร์ชั่นล่าสุด: " .. latestVersion .. "\n\nกรุณาไปรับสคริปต์ล่าสุดจาก GitHub!",
            Buttons = {
                {
                    Title = "ไปที่ GitHub",
                    Callback = function()
                        -- เปิดลิงก์ในเบราว์เซอร์ (Roblox รองรับในบาง Executor)
                        if syn and syn.request then
                            syn.request({ Url = "https://github.com/thomahamham/power-panel-version-windows-11", Method = "GET" })
                        else
                            Fluent:Notify({ Title = "ลิงก์", Content = "https://github.com/thomahamham/power-panel-version-windows-11", Duration = 10 })
                        end
                    end
                },
                { Title = "ยกเลิก" }
            }
        })
        -- หยุดการโหลด GUI ชั่วคราว (หรือให้ผู้ใช้เลือก)
        -- return false -- ถ้าต้องการบังคับให้หยุด
    else
        Fluent:Notify({
            Title = "อัปเดต",
            Content = "คุณใช้เวอร์ชั่นล่าสุดแล้ว! (" .. ScriptVersion .. ")",
            Duration = 4
        })
    end
end

-- รันตรวจสอบทันที
CheckForUpdate()


-- หน้าต่างหลัก
local Window = Fluent:CreateWindow({
    Title = "Power Panel Windows 11 English " .. ScriptVersion .. " (เวอร์ชั่นสำรอง " .. Fluent.Version .. ")",
    SubTitle = "power panel ver " .. ScriptVersion,
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- สร้างแท็บทั้งหมด
local Tabs = {
    user = Window:AddTab({ Title = "user", Icon = "" }),
    tp = Window:AddTab({ Title = "tp", Icon = "" }),
    night = Window:AddTab({ Title = "99 night other script", Icon = "" }),
    other = Window:AddTab({ Title = "other script", Icon = "" }),
    up = Window:AddTab({ Title = "update", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "" }),
    cradit = Window:AddTab({ Title = "credit", Icon = "" }),
    Main = Window:AddTab({ Title = "fordeveloper", Icon = "" }),
}

-- ตัวแปรหลัก
local Player = game.Players.LocalPlayer
local Flying = false

--------------------------------------------------------------------------------------------------------------
-- USER TAB
--------------------------------------------------------------------------------------------------------------
do
    Tabs.user:AddParagraph({
        Title = "วิธีใช้งานแท็บ User",
        Content = 
            "• เปิด/ปิด การบิน → กด Toggle แล้วใช้ WASD + Space (ขึ้น) / LeftShift (ลง)\n"..
            "• ความเร็วบิน → ลาก Slider เพื่อปรับความเร็วขณะบิน (คูณ 10 อัตโนมัติ)\n"..
            "• ความเร็ววิ่ง → ลาก Slider เพื่อปรับ WalkSpeed (มีผลเมื่อไม่ได้บิน)\n"..
            "• เปิด/ปิด noclip → ทำให้ตัวละครทะลุกำแพงได้\n"..
            "• เปิด/ปิด inf jump → กระโดดได้ไม่จำกัดจำนวนครั้ง"
    })

    local ToggleFlight = Tabs.user:AddToggle("ToggleFlight", { Title = "เปิด/ปิด การบิน", Default = false })
    local SliderFlySpeed = Tabs.user:AddSlider("SliderFlySpeed", {
        Title = "ความเร็วบิน",
        Description = "อยากบินเร็วแค่ไหนก็ลากเลยยย",
        Default = 5, Min = 0.5, Max = 10, Rounding = 1
    })
    local SliderRunSpeed = Tabs.user:AddSlider("SliderRunSpeed", {
        Title = "ความเร็ววิ่ง",
        Description = "อยากวิ่งเร็วแค่ไหนก็ลากเลยย",
        Default = 16, Min = 16, Max = 1000, Rounding = 1
    })
    local ToggleNoClip = Tabs.user:AddToggle("ToggleNoClip", { Title = "เปิด/ปิด noclip", Default = false })
    local ToggleInfJump = Tabs.user:AddToggle("ToggleInfJump", { Title = "เปิด/ปิด inf jump", Default = false })

    local noclipConn, infJumpConn, flyLoopConn, flyBV

    local function SetupCharacter(Char)
        local Humanoid = Char:WaitForChild("Humanoid")
        local HRP = Char:WaitForChild("HumanoidRootPart")

        if not Flying then
            Humanoid.WalkSpeed = SliderRunSpeed.Value
        end

        if ToggleInfJump.Value then
            if infJumpConn then infJumpConn:Disconnect() end
            infJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
                if Humanoid then Humanoid:ChangeState("Jumping") end
            end)
        end

        if ToggleNoClip.Value then
            if noclipConn then noclipConn:Disconnect() end
            noclipConn = game:GetService("RunService").Stepped:Connect(function()
                for _, part in pairs(Char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end

        if ToggleFlight.Value then
            Flying = true
            Humanoid.PlatformStand = true
            if flyBV then flyBV:Destroy() end
            flyBV = Instance.new("BodyVelocity")
            flyBV.Name = "FlyBodyVelocity"
            flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            flyBV.Velocity = Vector3.new(0, 0, 0)
            flyBV.Parent = HRP

            if flyLoopConn then flyLoopConn:Disconnect() end
            flyLoopConn = game:GetService("RunService").Heartbeat:Connect(function()
                if not Flying then return end
                local uis = game:GetService("UserInputService")
                local camera = workspace.CurrentCamera
                local moveDir = Vector3.new()

                if uis:IsKeyDown(Enum.KeyCode.W) then moveDir += Vector3.new(0, 0, -1) end
                if uis:IsKeyDown(Enum.KeyCode.S) then moveDir += Vector3.new(0, 0, 1) end
                if uis:IsKeyDown(Enum.KeyCode.A) then moveDir += Vector3.new(-1, 0, 0) end
                if uis:IsKeyDown(Enum.KeyCode.D) then moveDir += Vector3.new(1, 0, 0) end
                if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
                if uis:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir += Vector3.new(0, -1, 0) end

                local speed = SliderFlySpeed.Value * 10
                if moveDir.Magnitude > 0 then
                    local camCF = camera.CFrame
                    local moveWorld = (camCF.RightVector * moveDir.X) + (camCF.LookVector * -moveDir.Z)
                    local flyVelocity = Vector3.new(moveWorld.X, moveDir.Y, moveWorld.Z) * speed
                    flyBV.Velocity = flyVelocity
                    if moveDir.Z ~= 0 then
                        local targetLook = Vector3.new(moveWorld.X, 0, moveWorld.Z).Unit
                        local lookCFrame = CFrame.lookAt(HRP.Position, HRP.Position + targetLook)
                        HRP.CFrame = CFrame.new(HRP.Position) * lookCFrame.Rotation
                    end
                else
                    flyBV.Velocity = Vector3.new(0, 0, 0)
                end
            end)
        end
    end

    if Player.Character then SetupCharacter(Player.Character) end
    Player.CharacterAdded:Connect(SetupCharacter)

    if Player.Character then
        local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.Died:Connect(function()
                if noclipConn then noclipConn:Disconnect() noclipConn = nil end
                if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
                if flyLoopConn then flyLoopConn:Disconnect() flyLoopConn = nil end
                if flyBV then flyBV:Destroy() flyBV = nil end
                Flying = false
            end)
        end
    end

    ToggleFlight:OnChanged(function(Value)
        local Char = Player.Character
        if not Char then return end
        if Value then
            SetupCharacter(Char)
        else
            Flying = false
            local Humanoid = Char:FindFirstChildOfClass("Humanoid")
            local HRP = Char:FindFirstChild("HumanoidRootPart")
            if Humanoid then Humanoid.PlatformStand = false end
            if HRP then HRP.Velocity = Vector3.new(0, 0, 0) end
            if flyBV then flyBV:Destroy() flyBV = nil end
            if flyLoopConn then flyLoopConn:Disconnect() flyLoopConn = nil end
        end
    end)

    SliderRunSpeed:OnChanged(function(Value)
        local Char = Player.Character
        if Char and not Flying then
            local Humanoid = Char:FindFirstChildOfClass("Humanoid")
            if Humanoid then Humanoid.WalkSpeed = Value end
        end
    end)

    ToggleNoClip:OnChanged(function(Value)
        local Char = Player.Character
        if not Char then return end
        if Value then
            SetupCharacter(Char)
        else
            if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        end
    end)

    ToggleInfJump:OnChanged(function(Value)
        local Char = Player.Character
        if not Char then return end
        if Value then
            SetupCharacter(Char)
        else
            if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
        end
    end)

    SliderFlySpeed:OnChanged(function() end)
end

--------------------------------------------------------------------------------------------------------------
-- TP TAB - Teleport to Friend
--------------------------------------------------------------------------------------------------------------
do
    Tabs.tp:AddParagraph({
        Title = "วิธีใช้งานแท็บ TP (Teleport)",
        Content = 
            "1. เลือกชื่อเพื่อนจาก Dropdown\n"..
            "2. กดปุ่ม 'วาปหาเพื่อน'\n"..
            "→ จะวาปไปยืนด้านหน้าผู้เล่น 3 หน่วย\n"..
            "รายชื่อจะอัปเดตอัตโนมัติทุก 5 วินาที"
    })

    local selectedPlayer = nil
    local DropdownFriends = Tabs.tp:AddDropdown("DropdownFriends", {
        Title = "เลือกเพื่อน",
        Description = "เลือกผู้เล่นที่ต้องการวาปไปหา",
        Values = {}, Multi = false, Default = nil,
    })

    local ButtonTeleport = Tabs.tp:AddButton({
        Title = "วาปหาเพื่อน",
        Description = "กดเพื่อวาปไปหาเพื่อนที่เลือก",
        Callback = function()
            if not selectedPlayer then
                Fluent:Notify({ Title = "ผิดพลาด", Content = "กรุณาเลือกผู้เล่นก่อน!", Duration = 3 })
                return
            end
            local Character = Player.Character or Player.CharacterAdded:Wait()
            local HRP = Character:FindFirstChild("HumanoidRootPart")
            if not HRP then
                Fluent:Notify({ Title = "ผิดพลาด", Content = "ไม่พบ HumanoidRootPart!", Duration = 3 })
                return
            end
            local TargetChar = selectedPlayer.Character
            if not TargetChar then
                Fluent:Notify({ Title = "ผิดพลาด", Content = "ผู้เล่นยังไม่มีตัวละคร!", Duration = 3 })
                return
            end
            local TargetHRP = TargetChar:FindFirstChild("HumanoidRootPart")
            if not TargetHRP then
                Fluent:Notify({ Title = "ผิดพลาด", Content = "ไม่พบ HumanoidRootPart ของเป้าหมาย!", Duration = 3 })
                return
            end
            HRP.CFrame = TargetHRP.CFrame * CFrame.new(0, 0, -3)
            Fluent:Notify({ Title = "สำเร็จ!", Content = "วาปไปหา " .. selectedPlayer.DisplayName .. " เรียบร้อย!", Duration = 3 })
        end
    })

    local function UpdatePlayerList()
        local playerNames = {}
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= Player then
                table.insert(playerNames, p.DisplayName .. " (@" .. p.Name .. ")")
            end
        end
        DropdownFriends:SetValues(playerNames)
        if #playerNames == 0 then
            DropdownFriends:SetValue(nil)
            selectedPlayer = nil
        end
    end

    DropdownFriends:OnChanged(function(Value)
        if Value then
            for _, p in pairs(game.Players:GetPlayers()) do
                if p.DisplayName .. " (@" .. p.Name .. ")" == Value then
                    selectedPlayer = p
                    break
                end
            end
        else
            selectedPlayer = nil
        end
    end)

    game.Players.PlayerAdded:Connect(UpdatePlayerList)
    game.Players.PlayerRemoving:Connect(UpdatePlayerList)
    UpdatePlayerList()
    task.spawn(function()
        while task.wait(5) do
            UpdatePlayerList()
        end
    end)
end

--------------------------------------------------------------------------------------------------------------
-- NIGHT TAB
--------------------------------------------------------------------------------------------------------------
do
    Tabs.night:AddParagraph({
        Title = "วิธีใช้งานแท็บ 99 Night Scripts",
        Content = 
            "คำเตือน: กด Confirm เพียง 1 ครั้งเท่านั้น!\n"..
            "• รัน somtank → สคริปต์หลักสำหรับ 99 Nights in the Forest\n"..
            "• รัน power panel godmode → Godmode สำหรับ Power Panel\n"..
            "• รัน foxname → Foxname Hub (อาจมีฟีเจอร์เสริม)\n"..
            "หลังรันแล้ว GUI ใหม่จะโหลดทับ"
    })

    Tabs.night:AddButton({
        Title = "รัน somtank",
        Description = "Very important button",
        Callback = function()
            Window:Dialog({
                Title = "ยืนยันการรันสคริปต์",
                Content = "หากกด Confirm ให้กดเพียงแค่ 1 ครั้ง",
                Buttons = {
                    { Title = "Confirm", Callback = function()
                        loadstring(game:HttpGet('https://raw.githubusercontent.com/MQPS7/99-Night-in-the-Forset/refs/heads/main/99v3'))()
                    end },
                    { Title = "Cancel" }
                }
            })
        end
    })

    Tabs.night:AddButton({
        Title = "รัน power panel godmode",
        Callback = function()
            Window:Dialog({
                Title = "ยืนยันการรันสคริปต์",
                Content = "หากกด Confirm ให้กดเพียงแค่ 1 ครั้ง",
                Buttons = {
                    { Title = "Confirm", Callback = function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/thomahamham/power-panel-version-windows-11/refs/heads/main/godmode.lua"))()
                    end },
                    { Title = "Cancel" }
                }
            })
        end
    })

    Tabs.night:AddButton({
        Title = "รัน foxname",
        Callback = function()
            Window:Dialog({
                Title = "ยืนยันการรันสคริปต์",
                Content = "หากกด Confirm ให้กดเพียงแค่ 1 ครั้ง",
                Buttons = {
                    { Title = "Confirm", Callback = function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/caomod2077/Script/refs/heads/main/FoxnameHub.lua"))()
                    end },
                    { Title = "Cancel" }
                }
            })
        end
    })
end

--------------------------------------------------------------------------------------------------------------
-- OTHER SCRIPT TAB (รวม freecam)
--------------------------------------------------------------------------------------------------------------
do
    Tabs.other:AddParagraph({
        Title = "วิธีใช้งานแท็บ Other Script",
        Content = 
            "คำเตือน: กด Confirm เพียง 1 ครั้งเท่านั้น!\n"..
            "• รัน freecam → กล้องอิสระ (ใช้สำรวจแมพ)\n"..
            "หลังรันแล้ว GUI ใหม่จะโหลดทับ"
    })

    Tabs.other:AddButton({
        Title = "รัน freecam",
        Callback = function()
            Window:Dialog({
                Title = "ยืนยันการรันสคริปต์",
                Content = "หากกด Confirm ให้กดเพียงแค่ 1 ครั้ง",
                Buttons = {
                    { Title = "Confirm", Callback = function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/thomahamham/power-panel-version-windows-11/refs/heads/main/freecam"))()
                    end },
                    { Title = "Cancel" }
                }
            })
        end
    })
end

--------------------------------------------------------------------------------------------------------------
-- UPDATE TAB
--------------------------------------------------------------------------------------------------------------
do
    Tabs.up:AddParagraph({
        Title = "วิธีใช้งานแท็บ Update",
        Content = "แจ้งเตือนอัปเดตและแพทช์ต่าง ๆ\n"..
                 "ลิงก์ดาวน์โหลดเวอร์ชันล่าสุด:\n"..
                 "   • GitHub: [ยังไม่มี]\n"..
                 "   • Discord: [ยังไม่มี]\n"..
                 "ตรวจสอบเวอร์ชันล่าสุดเสมอ!"
    })

    Tabs.up:AddParagraph({
        Title = "อัพเดต 10/30/2025 5:37 หลังเที่ยง",
        Content = "แก้ไขบิน\n"..
                  "แก้ไขวิ่ง\n"..
                  "แก้ไขสคริปต์ทะลุ\n"..
                  "แก้ไขบัคตกแมพ\n"..
                  "เพิ่ม tpหาเพื่อน\n"..
                  "เพิ่ม free cam\n"..
                  "เพิ่ม godmode\n"..
                  "เพิ่ม หน้าต่าง credit\n"..
                  "แก้บัคหน้าต่างui"
    })
end

--------------------------------------------------------------------------------------------------------------
-- CREDIT TAB
--------------------------------------------------------------------------------------------------------------
do
    Tabs.cradit:AddParagraph({
        Title = "เครดิต",
        Content = 
		    "owner: พี่แมน livezala"..	
            "Developer: thomahamham\n"..
            "Special Thanks:\n"..
            "   • MQPS7 (somtank script)\n"..
            "   • Voidware Team\n"..
            "   • Foxname Hub\n"..
            "   • All testers & supporters\n"..
            "   ラッキー エグゼ | MOBILE TESTER"
    })
end

--------------------------------------------------------------------------------------------------------------
-- MAIN TAB (สำหรับนักพัฒนา)
--------------------------------------------------------------------------------------------------------------
do
    Tabs.Main:AddParagraph({
        Title = "สำหรับนักพัฒนา",
        Content = 
            "แท็บนี้สำหรับ debug และทดสอบฟีเจอร์ใหม่\n"..
            "• ใช้ Print() หรือ warn() เพื่อดู log\n"..
            "• ทดสอบฟีเจอร์ก่อนปล่อยจริง\n"..
            "ปัจจุบัน: ทดสอบระบบบิน + noclip"
    })

    Tabs.Main:AddParagraph({ 
        Title = "Paragraph", 
        Content = "This is a paragraph.\nSecond line!" 
    })
end

--------------------------------------------------------------------------------------------------------------
-- SYSTEM CONFIG
--------------------------------------------------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

Fluent:Notify({
    Title = "Power Panel",
    Content = "The script has been fully loaded.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
