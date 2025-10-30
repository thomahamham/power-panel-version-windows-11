-- God Mode Script for 99 Nights in the Forest
-- โดยใช้ RemoteEvent DamagePlayer เพื่อ heal infinite

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DamagePlayer = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("DamagePlayer")

-- Loop เพื่อส่ง damage -1/0 (infinity heal) ทุก 0.1 วินาที
spawn(function()
    while true do
        DamagePlayer:FireServer(-1/0)  -- หรือลอง -math.huge ถ้า -1/0 ไม่เวิร์ค
        wait(0.1)  -- ปรับ delay ถ้าล้าเกิน
    end
end)

print("God Mode Activated! คุณไม่ตายจาก damage หรือ hunger แล้ว")
