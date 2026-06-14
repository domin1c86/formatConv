package tests

import (
	"testing"
	"time"

	"format_conv_go/converter"
	"format_conv_go/models"
)

func TestConvertFile_VideoToVideo(t *testing.T) {
	conv := converter.NewConverter()
	options := models.ConversionOptions{
		Lossless:  true,
		Overwrite: true,
	}

	conversionID, err := conv.ConvertFile("testdata/input.mp4", "testdata/output.mkv", options, nil)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	if conversionID == 0 {
		t.Fatal("Expected conversion ID > 0, got 0")
	}

	// Wait for async conversion to complete (stub is fast)
	time.Sleep(100 * time.Millisecond)

	status := conv.GetConversionStatus(conversionID)
	if status == nil {
		t.Fatal("Expected non-nil status")
	}
	if status.Status != "completed" {
		t.Errorf("Expected status 'completed', got '%s'", status.Status)
	}
	if status.Progress != 1.0 {
		t.Errorf("Expected progress 1.0, got %f", status.Progress)
	}
}

func TestConvertFile_WithProgressCallback(t *testing.T) {
	conv := converter.NewConverter()
	options := models.ConversionOptions{
		Lossless:  true,
		Overwrite: true,
	}

	progressCalls := 0
	callback := func(id uintptr, progress float64, processedBytes int64, totalBytes int64, status int, errorMsg string) {
		progressCalls++
	}

	conversionID, err := conv.ConvertFile("testdata/input.mp4", "testdata/output.mkv", options, callback)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	if conversionID == 0 {
		t.Fatal("Expected conversion ID > 0, got 0")
	}

	// Wait for async conversion
	time.Sleep(100 * time.Millisecond)

	if progressCalls == 0 {
		t.Error("Expected progress callback to be called at least once")
	}
}

func TestCancelConversion(t *testing.T) {
	conv := converter.NewConverter()
	options := models.ConversionOptions{
		Lossless:  true,
		Overwrite: true,
	}

	conversionID, err := conv.ConvertFile("testdata/input.mp4", "testdata/output.mkv", options, nil)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	// Wait a bit for conversion to start
	time.Sleep(10 * time.Millisecond)

	// Try to cancel (may succeed or fail depending on timing)
	result := conv.CancelConversion(conversionID)
	_ = result // Just verify it doesn't panic

	// Cancel a non-existent conversion
	result = conv.CancelConversion(9999)
	if result != false {
		t.Error("Expected cancel of non-existent conversion to return false")
	}
}
