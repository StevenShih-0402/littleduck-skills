# completions/install.bash
# littleduck-skills install.sh 的 bash tab 補齊；在 ~/.bashrc 加入 `source <本 repo>/completions/install.bash` 啟用。

_littleduck_install_repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

_littleduck_install() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=()
  case $COMP_CWORD in
    1)
      # 第一個參數：可選項由 install.sh --list 依 repo 內容產生
      COMPREPLY=($(compgen -W "$("$_littleduck_install_repo/install.sh" --list) --list --help" -- "$cur"))
      ;;
    2)
      # 第二個參數：目標專案目錄
      COMPREPLY=($(compgen -d -- "$cur"))
      ;;
  esac
}

complete -F _littleduck_install install.sh ./install.sh "$_littleduck_install_repo/install.sh"
