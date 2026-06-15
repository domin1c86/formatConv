package converter

import (
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"testing"
)

func TestResolveBinary_FromEnvToolsDir(t *testing.T) {
	dir := t.TempDir()
	name := "testbin_env"
	binPath := filepath.Join(dir, name)
	if runtime.GOOS == "windows" {
		binPath += ".exe"
	}
	if err := os.WriteFile(binPath, []byte("#!/bin/sh\n"), 0755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("FORMAT_CONV_TOOLS_DIR", dir)

	resolved, err := ResolveBinary("testbin_env")
	if err != nil {
		t.Fatalf("expected to find binary via FORMAT_CONV_TOOLS_DIR, got error: %v", err)
	}
	if resolved != binPath {
		t.Errorf("expected %s, got %s", binPath, resolved)
	}
}

func TestResolveBinary_FromExeToolsDir(t *testing.T) {
	t.Setenv("FORMAT_CONV_TOOLS_DIR", "")

	exePath, err := os.Executable()
	if err != nil {
		t.Skip("cannot determine executable path")
	}
	exeDir := filepath.Dir(exePath)
	toolsDir := filepath.Join(exeDir, "tools")
	if err := os.MkdirAll(toolsDir, 0755); err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(toolsDir)

	name := "testbin_exe"
	binPath := filepath.Join(toolsDir, name)
	if runtime.GOOS == "windows" {
		binPath += ".exe"
	}
	if err := os.WriteFile(binPath, []byte("#!/bin/sh\n"), 0755); err != nil {
		t.Fatal(err)
	}

	resolved, err := ResolveBinary("testbin_exe")
	if err != nil {
		t.Fatalf("expected to find binary in exe tools dir, got error: %v", err)
	}
	if resolved != binPath {
		t.Errorf("expected %s, got %s", binPath, resolved)
	}
}

func TestResolveBinary_FallbackToPath(t *testing.T) {
	t.Setenv("FORMAT_CONV_TOOLS_DIR", "")

	goPath := "go"
	if runtime.GOOS == "windows" {
		goPath = "go.exe"
	}
	if _, err := exec.LookPath(goPath); err != nil {
		t.Skip("'go' not on PATH, cannot test PATH fallback")
	}

	resolved, err := ResolveBinary("go")
	if err != nil {
		t.Fatalf("expected to find 'go' via PATH fallback, got error: %v", err)
	}
	if _, err := exec.LookPath(resolved); err != nil {
		t.Errorf("resolved path %s is not valid on PATH", resolved)
	}
}

func TestResolveBinary_NotFound(t *testing.T) {
	t.Setenv("FORMAT_CONV_TOOLS_DIR", "")
	_, err := ResolveBinary("nonexistent_binary_xyz_12345")
	if err == nil {
		t.Error("expected error for nonexistent binary, got nil")
	}
}
