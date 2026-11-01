# 規格同步閘門（spec-sync）

> 隨 littleduck-skills 的 `issue-*`、`backend-processor`、`frontend-processor` 安裝（`issue-architect`、`issue-integrator` 經由 `issue-reader` 的相依一併帶入）。

讓專案宣告「改到哪些程式路徑，就必須一起寫哪份規格」，在變更過程中**偵測漏寫**。

- 設定檔固定放在 **`openspec/spec-sync.yaml`**；範例見同目錄的 `spec-sync.example.yaml`。
- **專案沒有這份設定檔時，整個檢查略過**，skill 的行為與沒有閘門時相同。
- 閘門只檢查「有沒有寫」，內容正不正確交給 PR 審查。
- **閘門不負責寫入主規格。** OpenSpec 格式的規格由 change 的 delta 承載，歸檔時 `/opsx:archive`（內含 `/opsx:sync`）把 delta 合併進 `openspec/specs/`；閘門只確認 delta 有寫。sync 本身抓不到漏寫——沒有 delta 時它只會看到「沒有東西要同步」。

---

## 設定檔格式

```yaml
rules:
  - name: <顯示名稱>
    paths: [<glob>, ...]
    exclude: [<glob>, ...]        # 選填
    # 目標二選一：
    capability: <capability 路徑樣板>
    # 或
    spec_dir: <規格資料夾樣板>
    spec_files: [<檔名>, ...]
    exempt_when: <允許宣告免同步的情形>
```

| 欄位 | 說明 |
|------|------|
| `name` | 顯示在問答、PR 內文與報告的規則名稱 |
| `paths` | 觸發本規則的路徑 glob（相對 repo 根目錄）。`**` 比對任意層目錄、`*` 比對單層內的任意字元；`{名稱}` 擷取單層路徑片段，供目標樣板使用 |
| `exclude` | 選填。符合者不觸發本規則（例：`**/__init__.py`） |
| `capability` | **OpenSpec 格式的規格**：`openspec/specs/` 底下的 capability 路徑（例：`apps/{app}`）。適用於以 Requirement／Scenario 撰寫、由 sync 合併的規格 |
| `spec_dir` + `spec_files` | **自由格式文件**（例：`diagrams.md`、部署說明）：受影響的資料夾，以及其中哪些檔名算「有更新」 |
| `exempt_when` | 允許 user 宣告免同步的情形，以人看得懂的文字描述 |

- 每條規則**恰好一種目標**；同時寫 `capability` 與 `spec_dir`（或兩者皆無）的規則視為設定錯誤，判為不通過並在報告點出。
- 同一個 `{名稱}` 擷取到多個值時，每個值各自換算出一個目標。一組路徑要對應多個不同的目標，就拆成多條規則（見範例的「根目錄部署腳本」）。
- 只用 `**`、`*`、`{名稱}` 三種語法，換算由 Agent 依上述規則執行；規則寫得越單純，越不容易換算錯。

---

## 判定

1. **變更路徑**：`git diff --name-only $(git merge-base HEAD origin/<預設分支>)` 加上 `git ls-files --others --exclude-standard`（未追蹤檔），含刪除與更名。
2. **換算**：每條規則以 `paths` 比對、扣掉 `exclude`，命中的路徑依樣板換算出受影響的目標。沒有任何規則命中 → 不適用，直接略過。
3. **通過條件**：

   | 目標 | 通過 |
   |------|------|
   | `capability` | 目前的 change 有 `openspec/changes/<change>/specs/<capability>/spec.md`。**直接改 `openspec/specs/` 的主規格不算**——會被之後的 sync 結果覆蓋，也繞過 delta 審查 |
   | `spec_dir` | 資料夾內的 `spec_files` 至少一份出現在變更路徑中；資料夾不存在視為不通過；`openspec/changes/` 內的 delta 不算 |

## 各 skill 的時機與處置

delta 必須在歸檔前寫好，所以檢查前移到實作階段。最終閘門在單人流程是 `issue-solver`，在多 Agent 流程是 `issue-integrator`；**免同步只在最終閘門確認**（多 Agent 流程由開發 Agent 先在 `handoff.md` 聲明，user 在檢查點 2 確認）。

| skill | 時機 | 不通過時 |
|-------|------|----------|
| `backend-processor` | 每項任務內 | 改到命中規則的路徑時，**同一項任務內**補上：`capability` 寫或更新 change 的 delta，`spec_dir` 更新文件本身，一起 commit。屬 `exempt_when` 的情形時，改在 `handoff.md` 的 backend 節逐目標寫一行：`- **規格免同步**：<目標> — <理由>`，交由最終閘門確認 |
| `frontend-processor` | 每項任務內 | 同 `backend-processor`，免同步聲明寫在 `handoff.md` 的 frontend 節 |
| `issue-architect` | 寫提案時 | 預計改到的路徑命中 `capability` 規則時，在 `specs/` 先寫 delta；命中 `spec_dir` 規則時，在 `tasks.md` 排一項更新該文件的任務 |
| `issue-processor` | `/opsx:apply` 完成後 | 以 **AskUserQuestion** 列出不通過的目標與觸發路徑，讓 user 選：**現在補上**（寫 delta 或更新文件，同屬本次實作）／**留給 issue-solver 決定** |
| `issue-solver` | `/opsx:archive` 之前（最終閘門） | 以 **AskUserQuestion** 讓 user 選：**先補規格後重跑**（本次停止、不歸檔）／**宣告免同步並提供理由**（僅限 `exempt_when` 描述的情形；逐目標記下理由並寫進 PR 內文；`handoff.md` 已有的免同步聲明一併列出供確認）／**中止**。未取得回覆前不得歸檔 |
| `issue-integrator` | 檢查段（最終閘門） | 各端依自己 repo 的設定檔判定。不通過的目標若該端 `handoff.md` 有 `- **規格免同步**：<目標> — <理由>`，放行並列進報告，由 user 在檢查點 2 確認；沒有聲明就退回該端的開發 Agent。規則設定錯誤時退回 architect |

報告逐條規則列出結果：不適用／通過（`capability` 註明「歸檔時由 sync 寫入主規格」）／免同步（目標與理由）。
