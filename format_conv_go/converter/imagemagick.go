package converter

import (
	"format_conv_go/models"
)

type ImageMagickEngine struct{}

func NewImageMagickEngine() *ImageMagickEngine {
	return &ImageMagickEngine{}
}

func (e *ImageMagickEngine) Convert(inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64)) error {
	if progressCallback != nil {
		progressCallback(0.0)
		progressCallback(0.5)
		progressCallback(1.0)
	}
	return nil
}

func (e *ImageMagickEngine) SupportedFormats() []string {
	return []string{"JPEG", "PNG", "WebP", "TIFF", "BMP", "GIF", "ICO", "SVG"}
}
