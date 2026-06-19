package converter

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"native/models"
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
	expectedBytes := estimateOutputSize(inputInfo.Size(), options)

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
		byteCallback(0, expectedBytes)
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
	configureBackgroundCommand(cmd)

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("cannot start ImageMagick: %w", err)
	}

	done := make(chan error, 1)
	go func() {
		done <- cmd.Wait()
	}()

	// Periodically check output file size for real progress
	ticker := time.NewTicker(200 * time.Millisecond)
	defer ticker.Stop()

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
				finalSize := expectedBytes
				if outInfo, err := os.Stat(outputPath); err == nil && outInfo.Size() > 0 {
					finalSize = outInfo.Size()
				}
				byteCallback(finalSize, finalSize)
			}
			return nil
		case <-ticker.C:
			var progress float64
			var processed int64
			if outInfo, err := os.Stat(outputPath); err == nil {
				processed = outInfo.Size()
				if processed > expectedBytes {
					expectedBytes = int64(float64(processed) / 0.95)
					if expectedBytes < processed {
						expectedBytes = processed
					}
				}
				if expectedBytes > 0 {
					progress = float64(processed) / float64(expectedBytes)
					if progress > 0.95 {
						progress = 0.95 // Cap at 95% until process completes
					}
				}
			}
			if progressCallback != nil {
				progressCallback(progress)
			}
			if byteCallback != nil {
				byteCallback(processed, expectedBytes)
			}
		}
	}
}

func (e *ImageMagickEngine) buildArgs(inputPath, outputPath string, options models.ConversionOptions) []string {
	args := []string{inputPath}

	quality := options.ImageQuality
	if quality <= 0 {
		quality = options.Quality
	}

	if options.Lossless && quality >= 100 {
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
		if quality <= 0 {
			quality = 85
		}
		args = append(args, "-quality", fmt.Sprintf("%d", quality))
		if options.CompressionAlgorithm != "" {
			args = append(args, "-compress", options.CompressionAlgorithm)
		}
	}

	if options.ImageScalePercent > 0 && options.ImageScalePercent != 100 {
		args = append(args, "-resize", fmt.Sprintf("%d%%", options.ImageScalePercent))
	}
	if colorSpace := nonSource(options.ColorSpace); colorSpace != "" {
		args = append(args, "-colorspace", colorSpace)
	}
	if !options.PreserveMetadata {
		args = append(args, "-strip")
	}

	args = append(args, outputPath)
	return args
}

func (e *ImageMagickEngine) SupportedFormats() []string {
	return []string{"JPEG", "JPG", "PNG", "WebP", "TIFF", "BMP", "GIF", "ICO", "SVG"}
}
