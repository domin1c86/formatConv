package converter

import (
	"context"
	"fmt"
	"os"
	"sync"

	"format_conv_go/models"
)

const (
	StatusPending    = 0
	StatusProcessing = 1
	StatusCompleted  = 2
	StatusFailed     = 3
	StatusCancelled  = 4
)

func statusToString(s int) string {
	switch s {
	case StatusPending:
		return "pending"
	case StatusProcessing:
		return "processing"
	case StatusCompleted:
		return "completed"
	case StatusFailed:
		return "failed"
	case StatusCancelled:
		return "cancelled"
	default:
		return "unknown"
	}
}

type ConversionEngine interface {
	Convert(ctx context.Context, inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64)) error
	ConvertWithBytes(ctx context.Context, inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64), byteCallback func(processed, total int64)) error
	SupportedFormats() []string
}

type Converter struct {
	detector    *FormatDetector
	ffmpeg      *FFmpegEngine
	imagemagick *ImageMagickEngine
	conversions map[uintptr]*conversionEntry
	nextID      uintptr
	mu          sync.RWMutex
}

type conversionEntry struct {
	status *models.ConversionStatus
	cancel func()
	mu     sync.RWMutex
}

func NewConverter() *Converter {
	return &Converter{
		detector:    NewFormatDetector(),
		ffmpeg:      NewFFmpegEngine(),
		imagemagick: NewImageMagickEngine(),
		conversions: make(map[uintptr]*conversionEntry),
		nextID:      1,
	}
}

func (c *Converter) ConvertFile(inputPath, outputPath string, options models.ConversionOptions, progressCallback func(uintptr, float64, int64, int64, int, string)) (uintptr, error) {
	if _, err := os.Stat(inputPath); os.IsNotExist(err) {
		return 0, fmt.Errorf("input file does not exist: %s", inputPath)
	}

	inputFormat, err := c.detector.DetectFormat(inputPath)
	if err != nil {
		return 0, err
	}

	c.mu.Lock()
	conversionID := c.nextID
	c.nextID++
	status := &models.ConversionStatus{
		ConversionID: conversionID,
		Status:       statusToString(StatusPending),
		OutputPath:   outputPath,
	}
	entry := &conversionEntry{status: status}
	c.conversions[conversionID] = entry
	c.mu.Unlock()

	go c.executeConversion(conversionID, inputPath, outputPath, inputFormat, options, progressCallback, entry)

	return conversionID, nil
}

func (c *Converter) executeConversion(id uintptr, inputPath, outputPath string, inputFormat *models.FormatInfo, options models.ConversionOptions, progressCallback func(uintptr, float64, int64, int64, int, string), entry *conversionEntry) {
	ctx, cancel := context.WithCancel(context.Background())
	entry.mu.Lock()
	entry.cancel = cancel
	entry.status.Status = statusToString(StatusProcessing)
	entry.mu.Unlock()

	var engine ConversionEngine
	switch inputFormat.Type {
	case "video", "audio":
		engine = c.ffmpeg
	case "image":
		engine = c.imagemagick
	default:
		entry.mu.Lock()
		entry.status.Status = statusToString(StatusFailed)
		entry.status.Error = "unsupported format type"
		entry.mu.Unlock()
		if progressCallback != nil {
			progressCallback(id, 0, 0, 0, StatusFailed, "unsupported format type")
		}
		return
	}

	progressFunc := func(progress float64) {
		entry.mu.Lock()
		entry.status.Progress = progress
		entry.mu.Unlock()
	}

	byteFunc := func(processed, total int64) {
		entry.mu.Lock()
		entry.status.ProcessedBytes = processed
		entry.status.TotalBytes = total
		p := entry.status.Progress
		entry.mu.Unlock()
		if progressCallback != nil {
			progressCallback(id, p, processed, total, StatusProcessing, "")
		}
	}

	err := engine.ConvertWithBytes(ctx, inputPath, outputPath, options, progressFunc, byteFunc)

	if ctx.Err() == context.Canceled {
		entry.mu.Lock()
		entry.status.Status = statusToString(StatusCancelled)
		entry.mu.Unlock()
		if progressCallback != nil {
			progressCallback(id, 0, 0, 0, StatusCancelled, "")
		}
		return
	}

	if err != nil {
		entry.mu.Lock()
		entry.status.Status = statusToString(StatusFailed)
		entry.status.Error = err.Error()
		entry.mu.Unlock()
		if progressCallback != nil {
			progressCallback(id, 0, 0, 0, StatusFailed, err.Error())
		}
		return
	}

	entry.mu.Lock()
	entry.status.Status = statusToString(StatusCompleted)
	entry.status.Progress = 1.0
	pb := entry.status.ProcessedBytes
	tb := entry.status.TotalBytes
	entry.mu.Unlock()
	if progressCallback != nil {
		progressCallback(id, 1.0, pb, tb, StatusCompleted, "")
	}
}

func (c *Converter) GetConversionStatus(id uintptr) *models.ConversionStatus {
	c.mu.RLock()
	entry, ok := c.conversions[id]
	c.mu.RUnlock()
	if !ok {
		return nil
	}
	entry.mu.RLock()
	defer entry.mu.RUnlock()
	copy := *entry.status
	return &copy
}

func (c *Converter) CancelConversion(id uintptr) bool {
	c.mu.RLock()
	entry, ok := c.conversions[id]
	c.mu.RUnlock()
	if !ok {
		return false
	}
	entry.mu.Lock()
	defer entry.mu.Unlock()
	if entry.status.Status == statusToString(StatusProcessing) {
		entry.cancel()
		entry.status.Status = statusToString(StatusCancelled)
		return true
	}
	return false
}

func (c *Converter) GetSupportedFormats() *models.FormatList {
	return c.detector.GetSupportedFormats()
}

func (c *Converter) DetectFormat(filePath string) (*models.FormatInfo, error) {
	return c.detector.DetectFormat(filePath)
}
