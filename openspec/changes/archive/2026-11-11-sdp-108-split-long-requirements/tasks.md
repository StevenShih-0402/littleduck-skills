# Tasks：sdp-108-split-long-requirements

## 1. 拆分需求

- [x] 1.1 為 8 條過長需求寫 MODIFIED（保留標題與全部 scenario、敘述只留主要行為）與 ADDED（拆出的行為，各附 scenario）；驗證：每條需求敘述都在 500 字以內
- [x] 1.2 確認新 scenario 描述的行為與現有 skill、hook、測試一致（lint hook 的根目錄情境已有 `tests/.claude/skills/*/hooks/post-edit-lint.test.sh` 對應）；驗證：逐條對照
- [x] 1.3 `openspec validate sdp-108-split-long-requirements --strict` 通過；歸檔後 `openspec validate --specs` 不再出現「Requirement text is very long」
