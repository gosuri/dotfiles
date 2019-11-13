#!/usr/bin/env sh
#
# Collection of helper functions for Go Lang development
#

# ================================================================
# Helper function to recursively update package paths
# ================================================================
#
# Example:
#  go-update-import-path github.com/ovrclk/walker go.ovrclk.com/walker
#
function go-update-import-path() {
  usage="usage: go-update-import-path OLD_PATH NEW_PATH"
  [ $1 ] || echo $usage
  [ $2 ] || echo $usage
  old="$(echo -n $1 | sed -e 's/[\/&]/\\&/g')"
  new="$(echo -n $2 | sed -e 's/[\/&]/\\&/g')"
  find . -name "*.go" -type f -exec sed -i '' -e "s/${old}/${new}/g" {} +
}


function flush-dns {
  sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder
}

function clean-ds-store {
	find . -name ".DS_Store" -depth -exec rm {} \;
}

# ================================================================
# Helper function to delete active deployments on Akash
# ================================================================
function deldeps {
  for d in $(akash query deployment | grep ACTIVE | awk '{print $1}') ; do akash deployment close $d ; done
}
