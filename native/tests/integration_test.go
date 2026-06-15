package tests

import (
	"os"
	"path/filepath"
	"testing"
	"time"

	"native/converter"
	"native/models"
)

func TestIntegration_ConvertVideoFile(t *testing.T) {
	inputPath := "testdata/test_input.mp4"
	outputPath := "testdata/test_output.mkv"

	if _, err := os.Stat(inputPath); os.IsNotExist(err) {
		t.Skip("Test input file not found")
	}

	t.Cleanup(func() { os.Remove(outputPath) })

	conv := converter.NewConverter()
	options := models.ConversionOptions{
		Overwrite: true,
	}

	conversionID, err := conv.ConvertFile(inputPath, outputPath, options, nil)
	if err != nil {
		t.Fatalf("Failed to start conversion: %v", err)
	}

	status := waitForCompletion(t, conv, conversionID, 30*time.Second)
	if status == nil {
		t.Fatal("Expected non-nil status")
	}

	if status.Status == "failed" {
		t.Fatalf("Conversion failed: %s", status.Error)
	}

	if status.Status == "completed" {
		if _, err := os.Stat(outputPath); os.IsNotExist(err) {
			t.Fatal("Output file was not created")
		}
	}
}

func TestIntegration_UnsupportedFormat(t *testing.T) {
	inputPath := setupTestFile(t, "input.xyz")
	outputPath := filepath.Join(t.TempDir(), "output.mp4")

	conv := converter.NewConverter()
	options := models.ConversionOptions{Overwrite: true}

	_, err := conv.ConvertFile(inputPath, outputPath, options, nil)
	if err == nil {
		t.Error("Expected error for unsupported format, got nil")
	}
}

func TestIntegration_InputNotFound(t *testing.T) {
	outputPath := filepath.Join(t.TempDir(), "output.mkv")

	conv := converter.NewConverter()
	options := models.ConversionOptions{Overwrite: true}

	_, err := conv.ConvertFile("nonexistent_file.mp4", outputPath, options, nil)
	if err == nil {
		t.Error("Expected error for nonexistent input, got nil")
	}
}

func TestIntegration_ConversionFailsGracefully(t *testing.T) {
	inputPath := setupTestFile(t, "bad_input.mp4")
	outputPath := filepath.Join(t.TempDir(), "output.mkv")

	conv := converter.NewConverter()
	options := models.ConversionOptions{Overwrite: true}

	conversionID, err := conv.ConvertFile(inputPath, outputPath, options, nil)
	if err != nil {
		t.Fatalf("ConvertFile returned unexpected error: %v", err)
	}

	status := waitForCompletion(t, conv, conversionID, 10*time.Second)
	if status == nil {
		t.Fatal("Expected non-nil status")
	}

	if status.Status == "failed" && status.Error == "" {
		t.Error("Expected error message when conversion fails")
	}

	if status.Status == "completed" {
		if status.Progress != 1.0 {
			t.Errorf("Expected progress 1.0 on completion, got %f", status.Progress)
		}
	}
}
