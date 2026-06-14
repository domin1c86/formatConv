package converter

import (
	"format_conv_go/models"
)

type ConversionEngine interface {
	Convert(inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64)) error
	SupportedFormats() []string
}

type Converter struct {
	detector    *FormatDetector
	ffmpeg      *FFmpegEngine
	imagemagick *ImageMagickEngine
	conversions map[uintptr]*models.ConversionStatus
	nextID      uintptr
}

func NewConverter() *Converter {
	return &Converter{
		detector:    NewFormatDetector(),
		ffmpeg:      NewFFmpegEngine(),
		imagemagick: NewImageMagickEngine(),
		conversions: make(map[uintptr]*models.ConversionStatus),
		nextID:      1,
	}
}

func (c *Converter) ConvertFile(inputPath, outputPath string, options models.ConversionOptions, progressCallback func(uintptr, float64, int64, int64, int, string)) (uintptr, error) {
	inputFormat, err := c.detector.DetectFormat(inputPath)
	if err != nil {
		return 0, err
	}

	outputFormat, err := c.detector.DetectFormat(outputPath)
	if err != nil {
		return 0, err
	}

	conversionID := c.nextID
	c.nextID++

	status := &models.ConversionStatus{
		ConversionID: conversionID,
		Status:       "pending",
		OutputPath:   outputPath,
	}
	c.conversions[conversionID] = status

	go c.executeConversion(conversionID, inputPath, outputPath, inputFormat, outputFormat, options, progressCallback)

	return conversionID, nil
}

func (c *Converter) executeConversion(id uintptr, inputPath, outputPath string, inputFormat, outputFormat *models.FormatInfo, options models.ConversionOptions, progressCallback func(uintptr, float64, int64, int64, int, string)) {
	status := c.conversions[id]
	status.Status = "processing"

	var engine ConversionEngine
	switch inputFormat.Type {
	case "video", "audio":
		engine = c.ffmpeg
	case "image":
		engine = c.imagemagick
	default:
		status.Status = "failed"
		status.Error = "unsupported format type"
		if progressCallback != nil {
			progressCallback(id, 0, 0, 0, 2, "unsupported format type")
		}
		return
	}

	progressFunc := func(progress float64) {
		status.Progress = progress
		if progressCallback != nil {
			progressCallback(id, progress, 0, 0, 0, "")
		}
	}

	err := engine.Convert(inputPath, outputPath, options, progressFunc)
	if err != nil {
		status.Status = "failed"
		status.Error = err.Error()
		if progressCallback != nil {
			progressCallback(id, 0, 0, 0, 2, err.Error())
		}
		return
	}

	status.Status = "completed"
	status.Progress = 1.0
	if progressCallback != nil {
		progressCallback(id, 1.0, 0, 0, 1, "")
	}
}

func (c *Converter) GetConversionStatus(id uintptr) *models.ConversionStatus {
	return c.conversions[id]
}

func (c *Converter) CancelConversion(id uintptr) bool {
	if status, ok := c.conversions[id]; ok {
		if status.Status == "processing" {
			status.Status = "cancelled"
			return true
		}
	}
	return false
}
