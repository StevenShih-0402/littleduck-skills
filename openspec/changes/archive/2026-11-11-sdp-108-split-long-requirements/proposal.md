# Proposal：拆分敘述過長的需求（SDP-108 後續）

## Why

SDP-108 歸檔後，`openspec validate --specs` 對 8 條需求報「Requirement text is very long (>500 characters)」；其中 5 條是 SDP-108 加長的，3 條原本就超過。一條需求同時描述好幾個行為，不好對照 scenario，也會讓 `--strict` 驗證失敗。

## What Changes

- 把 8 條過長的需求各拆成「一條只描述一個行為」：原需求以 MODIFIED 保留標題與所有 scenario、敘述只留主要行為，拆出去的行為各自以 ADDED 新增需求並附 scenario。
- **只改規格文字，不改任何行為**：拆出的需求與新 scenario 描述的都是現有 skill／hook 已經做到的事。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `backend-processor-skill`：Post-edit lint hook 拆出「在最近的 lint 設定目錄執行」「編輯 model 時提醒 migration」。
- `frontend-processor-skill`：Inputs are verified 拆出分支檢查；Post-edit lint hook 拆出「在最近的 eslint 設定目錄執行」。
- `custom-review-skill`：評級欄位與「只有高嚴重度且高信心才建議退回」分開。
- `gen-story-skill`：唯讀與版面檢查分開，版面檢查的 playwright 來源另列。
- `issue-architect-skill`：tasks 標記與 design.md 的圖分開。
- `issue-integrator-skill`：檢查拆出執行驗證與「服務由 user 啟動」；收尾拆出「帶 lease 推送並開一個 PR」。

## Impact

只動 `openspec/specs/` 的六份主規格（歸檔時同步）。skill、hook、測試都不變。
