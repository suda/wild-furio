CURRENT_BG='NONE'
SEGMENT_SEPARATOR='⮀'

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$user%m"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    ZSH_THEME_GIT_PROMPT_DIRTY=' 😱'
    ZSH_THEME_GIT_PROMPT_CLEAN=' 🌷'
    ZSH_THEME_GIT_PROMPT_ADDED=' 💅'
    ZSH_THEME_GIT_PROMPT_MODIFIED=' 🍄'
    ZSH_THEME_GIT_PROMPT_DELETED=' 💥'
    ZSH_THEME_GIT_PROMPT_UNTRACKED=' 🎀'
    ZSH_THEME_GIT_PROMPT_RENAMED=' ➡'

    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="👍 $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green black
      dirty=' 👍'
    fi
    echo -n "${ref/refs\/heads\//🎩  }$dirty"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue white '%~'
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}❕ "
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment red default "$symbols"
}

prompt_time() {
  prompt_segment green black
  echo -n "%D{%H:%M:%S}"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_time
  prompt_status
  prompt_git
  prompt_dir
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt)
👉 '

TMOUT=1

TRAPALRM() {
  [ "$WIDGET" = "expand-or-complete" ] && [[ "$_lastcomp[insert]" =~ "^automenu$|^menu:" ]] || zle reset-prompt
}