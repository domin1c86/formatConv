//go:build !windows

package converter

import "os/exec"

func configureBackgroundCommand(cmd *exec.Cmd) {}
