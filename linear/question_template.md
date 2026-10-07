<!-- 讀取任務轉換成 Openspec 提案前，需要先確認任務內容是否符合此格式 --> 

# Issue Title

code: 自行定義，給 Git 建立分支的簡短英文代號
Issue description (包含內容或圖片)

---

合法範例：

# 新增回傳版本號的 API
code: version-api
在 libs/common/ignsw_common/app_templates/rbac/views/auth_view.py 新增一個「回傳後端專案版本號」的 API，序列化欄位使用 "backend_ver": "0.x.x" 這樣的格式，確保 IOA 和 LaB 的 Swagger 都有顯