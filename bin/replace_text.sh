#!/bin/zsh
# recursively replaces source text the target
# example: replaceText *.txt foo bar

replaceText () {
  grep -rl $2 $1 | xargs sed -i .bk 's/$2/$3/g'
}
