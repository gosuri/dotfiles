// Copyright 2015 Gary Burd. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"flag"
	"os"
)

func init() {
	var fs flag.FlagSet
	commands["def"] = &Command{
		fs: &fs,
		do: func(ctx *Context) { os.Exit(doDef(ctx)) },
	}
}

func doDef(ctx *Context) int {
	return 0
}
