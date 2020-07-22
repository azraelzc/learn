

local M = {}

local UI_ORDER = 10000

function M.Init( self, eff, data, callback )
    self.eff = eff
    self.data = data
    self.callback = callback
    self.liveTime = data.liveTime
    self.orderInLayer = data.orderInLayer
    if self.orderInLayer == nil then
        self.orderInLayer = UI_ORDER
    end
    local renders = eff:GetComponentsInChildren( typeof(CS.UnityEngine.Renderer), true )
    for i=0,renders.Length-1 do
        local r = renders[i]
        r.sortingOrder = self.orderInLayer
    end
    if self.data.scalingMode ~= nil then
        local pss = eff:GetComponentsInChildren( typeof(CS.UnityEngine.ParticleSystem), true )
        for i=0,pss.Length-1 do
            local pmain = pss[i].main
            pmain.scalingMode = CS.UnityEngine.ParticleSystemScalingMode.__CastFrom(self.data.scalingMode);
        end
    end
    if self.data.layer ~= nil then
        local trans = eff:GetComponentsInChildren( typeof(CS.UnityEngine.Transform), true )
        for i=0,trans.Length-1 do
            local tran = trans[i]
            tran.gameObject.layer = self.data.layer
        end
    end
    if self.data.scale ~= nil then
        eff.transform.localScale = CS.UnityEngine.Vector3.one * self.data.scale
    end
    self.eff:SetActive(true)
end


function M.Update( self, delta )
    if self.liveTime <= 0 then return end

    self.liveTime = self.liveTime - delta
    if self.liveTime <= 0 then
        if self.callback ~= nil then
            self.callback()
        end
        S_UGUIManager:RemoveEff(self.eff)
    end
end


function M.new()
    local t = {
        eff = nil,
        data = nil,
        callback = nil,
        liveTime = 0,
    }
    return setmetatable(t, {__index = M})
end

return M
