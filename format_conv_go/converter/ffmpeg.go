package converter

import (
	"format_conv_go/models"
)

type FFmpegEngine struct{}

func NewFFmpegEngine() *FFmpegEngine {
	return &FFmpegEngine{}
}

func (e *FFmpegEngine) Convert(inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64)) error {
	if progressCallback != nil {
		progressCallback(0.0)
		progressCallback(0.5)
		progressCallback(1.0)
	}
	return nil
}

func (e *FFmpegEngine) SupportedFormats() []string {
	return []string{"MP4", "MKV", "MOV", "AVI", "WebM", "FLV", "WMV", "MPEG", "3GP", "MP3", "FLAC", "WAV", "AAC", "OGG", "WMA", "M4A", "OPUS"}
}
