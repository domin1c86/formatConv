package converter

import (
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
)

func ResolveBinary(name string) (string, error) {
	if toolsDir := os.Getenv("FORMAT_CONV_TOOLS_DIR"); toolsDir != "" {
		candidate := filepath.Join(toolsDir, name)
		if runtime.GOOS == "windows" {
			candidate += ".exe"
		}
		if _, err := os.Stat(candidate); err == nil {
			return candidate, nil
		}
	}

	exePath, err := os.Executable()
	if err == nil {
		exeDir := filepath.Dir(exePath)
		toolsDir := filepath.Join(exeDir, "tools")
		candidate := filepath.Join(toolsDir, name)
		if runtime.GOOS == "windows" {
			candidate += ".exe"
		}
		if _, err := os.Stat(candidate); err == nil {
			return candidate, nil
		}
	}

	if runtime.GOOS == "windows" {
		candidate := name + ".exe"
		if _, err := exec.LookPath(candidate); err == nil {
			return candidate, nil
		}
	}

	return exec.LookPath(name)
}
