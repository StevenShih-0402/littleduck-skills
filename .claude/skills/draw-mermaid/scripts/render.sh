#!/bin/bash
# 渲染 markdown 內所有 mermaid 區塊（default 與 dark 主題各一份 SVG），可選擇輸出指定區塊的 PNG 供目視檢查。
# 用法：render.sh <md 絕對路徑> <輸出目錄> [PNG 的區塊編號，例如 b03 b16]
# 區塊依出現順序編號為 b01、b02…；任一區塊渲染失敗即以非零退出碼結束。
set -u

if [ $# -lt 2 ]; then
    echo "用法：$0 <md 絕對路徑> <輸出目錄> [b01 b02 …]" >&2
    exit 2
fi

md=$1
out=$2
shift 2
image=minlag/mermaid-cli:11.4.2

rm -rf "$out"
mkdir -p "$out"

# 抽出每個 mermaid 區塊成獨立檔案
python3 -I - "$md" "$out" <<'PY'
import re
import sys

source = open(sys.argv[1], encoding="utf-8").read()
blocks = re.findall(r"```mermaid\n(.*?)```", source, re.S)
for index, block in enumerate(blocks, 1):
    with open(f"{sys.argv[2]}/b{index:02d}.mmd", "w", encoding="utf-8") as handle:
        handle.write(block)
print(f"共 {len(blocks)} 個 mermaid 區塊")
PY

render() {
    # $1 區塊名、$2 輸出副檔名、其餘為 mermaid-cli 參數
    local name=$1 ext=$2
    shift 2
    docker run --rm -u "$(id -u):$(id -g)" -v "$out":/data "$image" \
        -i "/data/$name.mmd" -o "/data/$name.$ext" "$@" >/dev/null 2>"$out/$name-$ext.err"
}

fail=0
for file in "$out"/*.mmd; do
    name=$(basename "$file" .mmd)
    for theme in default dark; do
        if ! render "$name" "$theme.svg" -t "$theme"; then
            echo "失敗：$name（$theme）"
            head -5 "$out/$name-$theme.svg.err"
            fail=1
        fi
    done
done
echo "SVG：$(ls "$out"/*.svg 2>/dev/null | wc -l) 份"

for name in "$@"; do
    if render "$name" png -s 1.5 -b white; then
        echo "PNG：$out/$name.png"
    else
        echo "PNG 失敗：$name"
        fail=1
    fi
done

# 靜態檢查：寫死的顏色與代碼式節點 ID
if grep -nE '#[0-9a-fA-F]{3,6}\b|fill:|stroke:|color:|classDef|linkStyle|%%\{init' "$md"; then
    echo "發現寫死的顏色設定"
    fail=1
fi
if grep -nE '^\s+([A-Z]|[A-Z][0-9]+|[A-Z]{1,2}[0-9])\s*(-->|==>|-\.->|--\s")' "$md"; then
    echo "發現代碼式節點 ID"
    fail=1
fi

exit $fail
