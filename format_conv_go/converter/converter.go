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
	StatusProcessing = 0
	StatusCompleted  = 1
	StatusFailed     = 2
	StatusCancelled  = 3
)

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
	c.mu.Unlock()

	status := &models.ConversionStatus{
		ConversionID: conversionID,
		Status:       "pending",
		OutputPath:   outputPath,
	}
	entry := &conversionEntry{status: status}

	c.mu.Lock()
	c.conversions[conversionID] = entry
	c.mu.Unlock()

	go c.executeConversion(conversionID, inputPath, outputPath, inputFormat, options, progressCallback, entry)

	return conversionID, nil
}

func (c *Converter) executeConversion(id uintptr, inputPath, outputPath string, inputFormat *models.FormatInfo, options models.ConversionOptions, progressCallback func(uintptr, float64, int64, int64, int, string), entry *conversionEntry) {
	entry.mu.Lock()
	entry.status.Status = "processing"
	entry.mu.Unlock()

	var engine ConversionEngine
	switch inputFormat.Type {
	case "video", "audio":
		engine = c.ffmpeg
	case "image":
		engine = c.imagemagick
	default:
		entry.mu.Lock()
		entry.status.Status = "failed"
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
			progressCallback(id, p, processed, total, StatusPending, "")
		}
	}

	ctx, cancel := context.WithCancel(context.Background())
	entry.mu.Lock()
	entry.cancel = cancel
	entry.mu.Unlock()

	err := engine.ConvertWithBytes(ctx, inputPath, outputPath, options, progressFunc, byteFunc)

	if ctx.Err() == context.Canceled {
		entry.mu.Lock()
		entry.status.Status = "cancelled"
		entry.mu.Unlock()
		if progressCallback != nil {
			progressCallback(id, 0, 0, 0, StatusCancelled, "")
		}
		return
	}

	if err != nil {
		entry.mu.Lock()
		entry.status.Status = "failed"
		entry.status.Error = err.Error()
		entry.mu.Unlock()
		if progressCallback != nil {
			progressCallback(id, 0, 0, 0, StatusFailed, err.Error())
		}
		return
	}

	entry.mu.Lock()
	entry.status.Status = "completed"
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
	if entry.status.Status == "processing" {
		if entry.cancel != nil {
			entry.cancel()
		}
		entry.status.Status = "cancelled"
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
