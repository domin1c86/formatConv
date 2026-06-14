package tests

import (
	"os"
	"testing"
	"time"

	"format_conv_go/converter"
	"format_conv_go/models"
)

func TestIntegration_ConvertVideoFile(t *testing.T) {
	inputPath := "testdata/test_input.mp4"
	outputPath := "testdata/test_output.mkv"

	if _, err := os.Stat(inputPath); os.IsNotExist(err) {
		t.Skip("Test input file not found")
	}

	conv := converter.NewConverter()
	options := models.ConversionOptions{
		Lossless:  true,
		Overwrite: true,
	}

	conversionID, err := conv.ConvertFile(inputPath, outputPath, options, nil)
	if err != nil {
		t.Fatalf("Failed to start conversion: %v", err)
	}

	for {
		status := conv.GetConversionStatus(conversionID)
		if status == nil {
			t.Fatal("Conversion status not found")
		}

		if status.Status == "completed" {
			break
		} else if status.Status == "failed" {
			t.Fatalf("Conversion failed: %s", status.Error)
		}

		time.Sleep(100 * time.Millisecond)
	}

	if _, err := os.Stat(outputPath); os.IsNotExist(err) {
		t.Fatal("Output file was not created")
	}

	os.Remove(outputPath)
}
