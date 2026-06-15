package tests

import (
	"testing"

	"native/converter"
)

func TestDetectFormat_VideoFile(t *testing.T) {
	detector := converter.NewFormatDetector()
	info, err := detector.DetectFormat("testdata/sample.mp4")
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	if info.Type != "video" {
		t.Errorf("Expected type 'video', got '%s'", info.Type)
	}
	if info.Format != "MP4" {
		t.Errorf("Expected format 'MP4', got '%s'", info.Format)
	}
}
