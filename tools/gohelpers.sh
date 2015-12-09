#!/usr/bin/env sh
#
# Collection of helper functions for Go Lang development
#

# ================================================================
# Helper function to recursively update package paths
# ================================================================
function go-update-import-path() {
  usage="usage: go-update-import-path OLD_PATH NEW_PATH"
  [ $1 ] || echo $usage
  [ $2 ] || echo $usage
  old="$(echo -n $1 | sed -e 's/[\/&]/\\&/g')"
  new="$(echo -n $2 | sed -e 's/[\/&]/\\&/g')"
  find . -name "*.go" -type f -exec sed -i '' -e "s/${old}/${new}/g" {} +
}

# ================================================================
# Helper function to use go 1.4
# ================================================================
function use-go14() {
  brew switch go 1.4.2 > /dev/null 2>&1
  export GOPATH=$CODEHOME/go14
  export PATH=$GOPATH/bin:$PATH:/usr/local/opt/go/libexec/bin
}

# ================================================================
# Helper function to use go 1.5
# ================================================================
function use-go15() {
  export GOPATH=$CODEHOME/go
  export PATH=$GOPATH/bin:$PATH:/usr/local/opt/go/libexec/bin
  brew switch go 1.5.2 > /dev/null 2>&1
}
