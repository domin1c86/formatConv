package tests

import (
	"os"
	"path/filepath"
	"sync/atomic"
	"testing"
	"time"

	"format_conv_go/converter"
	"format_conv_go/models"
)

func setupTestFile(t *testing.T, name string) string {
	t.Helper()
	dir := t.TempDir()
	path := filepath.Join(dir, name)
	if err := os.WriteFile(path, []byte("test data"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}
	return path
}

func waitForCompletion(t *testing.T, conv *converter.Converter, id uintptr, timeout time.Duration) *models.ConversionStatus {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		status := conv.GetConversionStatus(id)
		if status != nil && (status.Status == "completed" || status.Status == "failed" || status.Status == "cancelled") {
			return status
		}
		time.Sleep(50 * time.Millisecond)
	}
	t.Fatal("Timed out waiting for conversion to complete")
	return nil
}

func TestConvertFile_VideoToVideo(t *testing.T) {
	inputPath := setupTestFile(t, "input.mp4")
	outputPath := filepath.Join(t.TempDir(), "output.mkv")

	conv := converter.NewConverter()
	options := models.ConversionOptions{
		Lossless:  true,
		Overwrite: true,
	}

	conversionID, err := conv.ConvertFile(inputPath, outputPath, options, nil)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	if conversionID == 0 {
		t.Fatal("Expected conversion ID > 0, got 0")
	}

	status := waitForCompletion(t, conv, conversionID, 5*time.Second)
	if status == nil {
		t.Fatal("Expected non-nil status")
	}

	if status.Status != "completed" && status.Status != "failed" {
		t.Errorf("Expected status 'completed' or 'failed', got '%s'", status.Status)
	}

	if status.Status == "completed" && status.Progress != 1.0 {
		t.Errorf("Expected progress 1.0 on completion, got %f", status.Progress)
	}

	if status.Status == "failed" && status.Error == "" {
		t.Error("Expected error message when status is 'failed'")
	}
}

func TestConvertFile_WithProgressCallback(t *testing.T) {
	inputPath := setupTestFile(t, "input.mp4")
	outputPath := filepath.Join(t.TempDir(), "output.mkv")

	conv := converter.NewConverter()
	options := models.ConversionOptions{
		Lossless:  true,
		Overwrite: true,
	}

	var progressCalls atomic.Int64
	callback := func(id uintptr, progress float64, processedBytes int64, totalBytes int64, status string, errorMsg string) {
		progressCalls.Add(1)
	}

	conversionID, err := conv.ConvertFile(inputPath, outputPath, options, callback)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	if conversionID == 0 {
		t.Fatal("Expected conversion ID > 0, got 0")
	}

	waitForCompletion(t, conv, conversionID, 5*time.Second)

	if progressCalls.Load() == 0 {
		t.Error("Expected progress callback to be called at least once")
	}
}

func TestConvertFile_ByteProgressCallback(t *testing.T) {
	inputPath := setupTestFile(t, "input.mp4")
	outputPath := filepath.Join(t.TempDir(), "output.mkv")

	conv := converter.NewConverter()
	options := models.ConversionOptions{
		Lossless:  true,
		Overwrite: true,
	}

	var lastTotal atomic.Int64
	callback := func(id uintptr, progress float64, processedBytes int64, totalBytes int64, status string, errorMsg string) {
		lastTotal.Store(totalBytes)
	}

	conversionID, err := conv.ConvertFile(inputPath, outputPath, options, callback)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	waitForCompletion(t, conv, conversionID, 5*time.Second)

	status := conv.GetConversionStatus(conversionID)
	if status == nil {
		t.Fatal("Expected non-nil status")
	}

	if status.TotalBytes == 0 && status.Status != "failed" {
		t.Error("Expected total bytes to be non-zero when conversion didn't fail due to missing tools")
	}
	_ = lastTotal.Load()
}

func TestConvertFile_UnsupportedFormat(t *testing.T) {
	inputPath := setupTestFile(t, "input.xyz")
	outputPath := filepath.Join(t.TempDir(), "output.mp4")

	conv := converter.NewConverter()
	options := models.ConversionOptions{Overwrite: true}

	_, err := conv.ConvertFile(inputPath, outputPath, options, nil)
	if err == nil {
		t.Error("Expected error for unsupported format, got nil")
	}
}

func TestConvertFile_InputFileNotFound(t *testing.T) {
	conv := converter.NewConverter()
	options := models.ConversionOptions{Overwrite: true}

	_, err := conv.ConvertFile("nonexistent.mp4", "output.mkv", options, nil)
	if err == nil {
		t.Error("Expected error for nonexistent input file, got nil")
	}
}

func TestCancelConversion(t *testing.T) {
	inputPath := setupTestFile(t, "input.mp4")
	outputPath := filepath.Join(t.TempDir(), "output.mkv")

	conv := converter.NewConverter()
	options := models.ConversionOptions{
		Lossless:  true,
		Overwrite: true,
	}

	conversionID, err := conv.ConvertFile(inputPath, outputPath, options, nil)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	time.Sleep(10 * time.Millisecond)

	result := conv.CancelConversion(conversionID)
	status := waitForCompletion(t, conv, conversionID, 5*time.Second)

	if result {
		if status.Status != "cancelled" {
			t.Errorf("Expected final status 'cancelled', got '%s'", status.Status)
		}
	} else {
		if status.Status != "failed" {
			t.Errorf("Expected status 'failed' if cancel returned false, got '%s'", status.Status)
		}
	}

	result = conv.CancelConversion(9999)
	if result != false {
		t.Error("Expected cancel of non-existent conversion to return false")
	}
}

func TestGetSupportedFormats(t *testing.T) {
	conv := converter.NewConverter()
	formats := conv.GetSupportedFormats()
	if formats == nil {
		t.Fatal("Expected non-nil format list")
	}
	if len(formats.VideoFormats) == 0 {
		t.Error("Expected video formats to be non-empty")
	}
	if len(formats.ImageFormats) == 0 {
		t.Error("Expected image formats to be non-empty")
	}
	if len(formats.AudioFormats) == 0 {
		t.Error("Expected audio formats to be non-empty")
	}
}

func TestDetectFormat(t *testing.T) {
	conv := converter.NewConverter()

	info, err := conv.DetectFormat("test.mp4")
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	if info.Format != "MP4" {
		t.Errorf("Expected format 'MP4', got '%s'", info.Format)
	}

	info, err = conv.DetectFormat("test.jpg")
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	if info.Format != "JPEG" {
		t.Errorf("Expected format 'JPEG', got '%s'", info.Format)
	}

	_, err = conv.DetectFormat("test.xyz")
	if err == nil {
		t.Error("Expected error for unsupported format, got nil")
	}
}
