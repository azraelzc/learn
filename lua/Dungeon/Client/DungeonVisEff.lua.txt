local Utils = require("Utils")
local csv = require("Dungeon.LuaCallCsvData")
local dungeonDefine = require("Dungeon.DungeonDefine")

local ERId = require("ERId")

local M = {}


-- ui effect
M.UIEff = {
    OpenGrid = {
        path="Prefab/Effects/Dungeon/Event/FX_Dungeon_Plaid",
        data={ liveTime=1 },
    },
    PlayBuffEff = {
        path="Prefab/Effects/Dungeon/Event/FX_Dungeon_PositiveEvent",
        data={ liveTime=2 },
    },
    PlayDeBuffEff = {
        path="Prefab/Effects/Dungeon/Event/FX_Dungeon_NegativeEvent",
        data={ liveTime=2 },
    },
    EnterMaze = {
        path="Prefab/Effects/Dungeon/Event/FX_Dungeon_EnterTheMaze",
        data={ liveTime=2 },
    },
    LeaveMaze = {
        path="Prefab/Effects/Dungeon/Event/FX_Dungeon_LeaveTheMaze",
        data={ liveTime=2 },
    },

    EventResultWin = {
        path="Prefab/Effects/Dungeon/Event/UI/FX_UI_Dungeon_EventSuccess",
        data={ liveTime=0, layer=5, orderInLayer=0, scale=1, scalingMode=0},
    },
    ActivationGain = {
        path="Prefab/Effects/Dungeon/Event/UI/FX_UI_Dungeon_ActivationGain",
        data={ liveTime=2, layer=5, orderInLayer=0, scale=1, scalingMode=0},
    },
    ActivateDeduction = {
        path="Prefab/Effects/Dungeon/Event/UI/FX_UI_Dungeon_ActivateDeduction",
        data={ liveTime=2, layer=5, orderInLayer=0, scale=1, scalingMode=0},
    },
    DungeonClear = {
        path="Prefab/Effects/Dungeon/Event/UI/FX_UI_Dungeon_Clear",
        data={ liveTime=0, layer=5, orderInLayer=0, scale=1, scalingMode=0},
    },
    DungeonPortal = {
        path="Prefab/Effects/Dungeon/Event/FX_Dungeon_Portal",
        data={ liveTime=0, layer=30, scale=26, scalingMode=0},
    },
    DungeonPortalActivation = {
        path="Prefab/Effects/Dungeon/Event/FX_Dungeon_PortalActivation",
        data={ liveTime=0, layer=30, scale=26, scalingMode=0},
    },

    -- DragonBall
    DragonBallRedActive = {
        path = "Prefab/Effects/Dungeon/Event/UI/FX_UI_Dungeon_BallActivation_Red",
        data={ liveTime=2, layer=5, scale=26, scalingMode=0 },
    },
    DragonBallYellowActive = {
        path = "Prefab/Effects/Dungeon/Event/UI/FX_UI_Dungeon_BallActivation_Yellow",
        data={ liveTime=2, layer=5, scale=26, scalingMode=0 },
    },
    DragonBallBlueActive = {
        path = "Prefab/Effects/Dungeon/Event/UI/FX_UI_Dungeon_BallActivation_Blue",
        data={ liveTime=2, layer=5, scale=26, scalingMode=0 },
    },
    DragonBallRedInlay = {
        path = "Prefab/Effects/Dungeon/Event/UI/FX_UI_Dungeon_BallInlay_Red",
        data={ liveTime=2, layer=5, scale=26, scalingMode=0 },
    },
    DragonBallYellowInlay = {
        path = "Prefab/Effects/Dungeon/Event/UI/FX_UI_Dungeon_BallInlay_Yellow",
        data={ liveTime=2, layer=5, scale=26, scalingMode=0 },
    },
    DragonBallBlueInlay = {
        path = "Prefab/Effects/Dungeon/Event/UI/FX_UI_Dungeon_BallInlay_Blue",
        data={ liveTime=2, layer=5, scale=26, scalingMode=0 },
    },
}
M.UILua = "Dungeon.DungeonUIEffect"

function M.InitPrefab(path, parent)
    local prefab = CS.Joywinds.ResourceMgr.Load(path, ".prefab")
    if prefab then
        local go = Utils.AddChild(parent.gameObject, prefab)
        return go
    end
    print("Error: The path is nil :" .. path)
    return nil
    -- local go = CS.UnityEngine.GameObject.Instantiate(prefab)
    -- if go ~= nil then
    --     go.transform.parent = parent
    -- end
end

function M.PlayUIEffByName(prefabName, parent, pos, callback, isNGUI)
    local effTab = {
        path = "Prefab/Effects/Dungeon/Event/" .. prefabName,
        data = {liveTime=1},
    }
    return M.PlayUIEffByData(effTab, parent, pos, callback, isNGUI)
end

function M.PlayUIEff( key, parent, pos, callback, isNGUI)
    local effTab = M.UIEff[key]
    return M.PlayUIEffByData(effTab, parent, pos, callback, isNGUI)
end

function M.PlayUIEffByData(effTab, parent, pos, callback, isNGUI)
    pos = pos or CS.UnityEngine.Vector3(0,0,0)
    
    if effTab == nil then
        printT(" Play UI Eff Key  Nil.")
        return
    end
    local eff = M.InitPrefab(effTab.path, parent)
    if eff == nil then
        printT(" Play UI Eff = Nil.")
        return
    end
    eff.transform.localPosition = pos
    eff.transform.localScale = CS.UnityEngine.Vector3.one
    if isNGUI == nil or isNGUI == false then
        eff.transform.localRotation = CS.UnityEngine.Quaternion.Euler(45,0,0)
    end
    -- if DEBUG then
    --     package.loaded[M.UILua] = nil
    -- end
    local lua = require(M.UILua)
    lua = lua.new()
    S_UGUIManager:CreateEff(eff, lua, effTab.data, callback )
    return eff
end

M.EffEff = {
    [ERId.DUNGEON_EFFECT_HPBOOST_1] = {
        path = "Prefab/Effects/Dungeon/FX_HP_Increase_PotionS",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_HPBOOST_2] = {
        path = "Prefab/Effects/Dungeon/FX_HP_Increase_PotionM",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_HPBOOST_3] = {
        path = "Prefab/Effects/Dungeon/FX_HP_Increase_PotionL",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_SPBOOST_1] = {
        path = "Prefab/Effects/Dungeon/FX_SP_Increase_PotionL",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_RELIEVE_DEBUFF_1] = {
        path = "Prefab/Effects/Dungeon/FX_Puri_Potion",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_IMMUNE_DEBUFF_1] = {
        path = "Prefab/Effects/Dungeon/FX_Puri_Potion",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_SEAL_ABILITY_1] = {
        path = "Prefab/Effects/Dungeon/FX_Seal_Scroll",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_SEAL_ABILITY_2] = {
        path = "Prefab/Effects/Dungeon/FX_Seal_Scroll",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_ATTACK_1] = {
        path = "Prefab/Effects/Dungeon/FX_Essence_Of_Fire",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_RESURRECTION_1] = {
        path = "Prefab/Effects/Dungeon/FX_Leaf_Of_Yggdrasil",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_ITEM_UP_ATK_1] = {
        path = "Prefab/Effects/Dungeon/FX_Upg_Dagger",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_ITEM_UP_MATK_1] = {
        path = "Prefab/Effects/Dungeon/FX_Lacryma_Stick",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_ITEM_UP_DEF_1] = {
        path = "Prefab/Effects/Dungeon/FX_Valkyrie_Armor",
        data={ liveTime=2 },
    },
    -- [ERId.DUNGEON_EFFECT_ITEM_UP_MDEF_1] = {
    --     path = "Prefab/Effects/Dungeon/FX_HP_Increase_PotionS",
    --     data={ liveTime=2 },
    -- },
    [ERId.DUNGEON_EFFECT_ITEM_UP_INCOMINGDMGREDUCE_1] = {
        path = "Prefab/Effects/Dungeon/FX_Ex_Def_Potion",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_ITEM_HPREDUCE_1] = {
        path = "Prefab/Effects/Dungeon/FX_High_Purity_Energy_Xtal",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_ITEM_HPREDUCE_2] = {
        path = "Prefab/Effects/Dungeon/FX_Elemental_Sword",
        data={ liveTime=2 },
    },
    [ERId.DUNGEON_EFFECT_ITEM_HPREDUCE_3] = {
        path = "Prefab/Effects/Dungeon/FX_Poison_Bottle",
        data={ liveTime=2 },
    },
}


function M.PlayEffEff( effect, parent, pos, callback )
    pos = pos or CS.UnityEngine.Vector3(0,0,0)
    local fxPaths = CS.JumpCSV.DungeonEffectCsvData.FxPathArray(effect.id)
    local path = ""
    if fxPaths.Length >= effect.level then
        path = fxPaths[effect.level-1]
    elseif fxPaths.Length > 0 then
        path = fxPaths[fxPaths.Length-1]
    end
    local effTab = nil
    if path and path ~= "" then
        local duration = CS.JumpCSV.DungeonEffectCsvData.FxDurationFromArray(effect.id,effect.level-1)
        effTab = {}
        effTab.path = "Prefab/Effects/Dungeon/" .. path
        effTab.data = {}
        effTab.data.liveTime = duration / 1000
    else
        -- effTab = M.EffEff[id]
    end
    if effTab == nil then
        return
    end
    local eff = M.InitPrefab(effTab.path, parent)
    if eff == nil then
        printT(" Play Eff Eff = Nil.")
        return
    end
    eff.transform.localPosition = pos
    eff.transform.localScale = CS.UnityEngine.Vector3.one
    eff.transform.localRotation = CS.UnityEngine.Quaternion.Euler(45,0,0)
    -- if DEBUG then
    --     package.loaded[M.UILua] = nil
    -- end
    local lua = require(M.UILua)
    lua = lua.new()
    S_UGUIManager:CreateEff(eff, lua, effTab.data, callback )
    return eff
end

return M
