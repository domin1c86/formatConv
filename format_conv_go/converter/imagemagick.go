package converter

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"format_conv_go/models"
)

type ImageMagickEngine struct{}

func NewImageMagickEngine() *ImageMagickEngine {
	return &ImageMagickEngine{}
}

func (e *ImageMagickEngine) Convert(ctx context.Context, inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64)) error {
	return e.ConvertWithBytes(ctx, inputPath, outputPath, options, progressCallback, nil)
}

func (e *ImageMagickEngine) ConvertWithBytes(ctx context.Context, inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64), byteCallback func(processed, total int64)) error {
	inputInfo, err := os.Stat(inputPath)
	if err != nil {
		return fmt.Errorf("cannot stat input file: %w", err)
	}
	totalBytes := inputInfo.Size()

	if !options.Overwrite {
		if _, err := os.Stat(outputPath); err == nil {
			return fmt.Errorf("output file already exists: %s", outputPath)
		}
	}

	if err := os.MkdirAll(filepath.Dir(outputPath), 0755); err != nil {
		return fmt.Errorf("cannot create output directory: %w", err)
	}

	if progressCallback != nil {
		progressCallback(0.0)
	}
	if byteCallback != nil {
		byteCallback(0, totalBytes)
	}

	magickPath, err := ResolveBinary("magick")
	if err != nil {
		magickPath, err = ResolveBinary("convert")
		if err != nil {
			return fmt.Errorf("neither 'magick' nor 'convert' command found: ImageMagick is not installed")
		}
	}

	args := e.buildArgs(inputPath, outputPath, options)

	cmd := exec.CommandContext(ctx, magickPath, args...)

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("cannot start ImageMagick: %w", err)
	}

	done := make(chan error, 1)
	go func() {
		done <- cmd.Wait()
	}()

	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	progress := 0.0
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case err := <-done:
			if err != nil {
				return fmt.Errorf("ImageMagick conversion failed: %w", err)
			}
			if progressCallback != nil {
				progressCallback(1.0)
			}
			if byteCallback != nil {
				if outInfo, err := os.Stat(outputPath); err == nil {
					byteCallback(outInfo.Size(), totalBytes)
				} else {
					byteCallback(totalBytes, totalBytes)
				}
			}
			return nil
		case <-ticker.C:
			progress += 0.05
			if progress > 0.9 {
				progress = 0.9
			}
			if progressCallback != nil {
				progressCallback(progress)
			}
			if byteCallback != nil {
				processed := int64(float64(totalBytes) * progress)
				byteCallback(processed, totalBytes)
			}
		}
	}
}

func (e *ImageMagickEngine) buildArgs(inputPath, outputPath string, options models.ConversionOptions) []string {
	args := []string{inputPath}

	if options.Lossless {
		ext := strings.ToLower(filepath.Ext(outputPath))
		switch ext {
		case ".png":
			args = append(args, "-quality", "0")
		case ".tiff":
			args = append(args, "-compress", "LZW")
		case ".bmp":
			// BMP is inherently lossless
		case ".webp":
			args = append(args, "-quality", "100", "-define", "webp:lossless=true")
		default:
			// For JPEG, lossless is not truly possible, but use max quality
			args = append(args, "-quality", "100")
		}
	} else {
		quality := options.Quality
		if quality <= 0 {
			quality = 85
		}
		args = append(args, "-quality", fmt.Sprintf("%d", quality))
	}

	args = append(args, outputPath)
	return args
}

func (e *ImageMagickEngine) SupportedFormats() []string {
	return []string{"JPEG", "PNG", "WebP", "TIFF", "BMP", "GIF", "ICO", "SVG"}
}
