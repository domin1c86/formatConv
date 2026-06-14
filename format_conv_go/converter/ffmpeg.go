package converter

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"format_conv_go/models"
)

type FFmpegEngine struct{}

func NewFFmpegEngine() *FFmpegEngine {
	return &FFmpegEngine{}
}

func (e *FFmpegEngine) Convert(ctx context.Context, inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64)) error {
	return e.ConvertWithBytes(ctx, inputPath, outputPath, options, progressCallback, nil)
}

func (e *FFmpegEngine) ConvertWithBytes(ctx context.Context, inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64), byteCallback func(processed, total int64)) error {
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

	args := e.buildArgs(inputPath, outputPath, options)

	cmd := exec.CommandContext(ctx, "ffmpeg", args...)

	stderr, err := cmd.StderrPipe()
	if err != nil {
		return fmt.Errorf("cannot create stderr pipe: %w", err)
	}

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("cannot start ffmpeg: %w", err)
	}

	duration := e.getDuration(inputPath)

	scanner := bufio.NewScanner(stderr)
	for scanner.Scan() {
		line := scanner.Text()

		if duration > 0 {
			if currentTime := e.parseTime(line); currentTime > 0 {
				progress := currentTime / duration
				if progress > 1.0 {
					progress = 1.0
				}
				if progressCallback != nil {
					progressCallback(progress)
				}
				if byteCallback != nil {
					processed := int64(float64(totalBytes) * progress)
					byteCallback(processed, totalBytes)
				}
			}
		} else if strings.Contains(line, "size=") {
			if outputSize := e.parseOutputSize(line); outputSize > 0 {
				if byteCallback != nil {
					byteCallback(outputSize, totalBytes)
				}
				if progressCallback != nil && totalBytes > 0 {
					progress := float64(outputSize) / float64(totalBytes)
					if progress > 1.0 {
						progress = 1.0
					}
					progressCallback(progress)
				}
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("error reading ffmpeg output: %w", err)
	}

	if err := cmd.Wait(); err != nil {
		return fmt.Errorf("ffmpeg conversion failed: %w", err)
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
}

func (e *FFmpegEngine) buildArgs(inputPath, outputPath string, options models.ConversionOptions) []string {
	args := []string{"-i", inputPath}

	if options.Lossless {
		ext := strings.ToLower(filepath.Ext(outputPath))
		switch ext {
		case ".mp4", ".mkv", ".mov":
			args = append(args, "-c:v", "ffv1", "-level", "3")
			args = append(args, "-c:a", "flac")
		case ".flac":
			args = append(args, "-c:a", "flac")
		case ".wav":
			args = append(args, "-c:a", "pcm_s16le")
		default:
			args = append(args, "-c:v", "copy", "-c:a", "copy")
		}
	} else {
		if options.Codec != "" {
			args = append(args, "-c:v", options.Codec)
		}
		if options.Quality > 0 {
			args = append(args, "-crf", strconv.Itoa(51-options.Quality/2))
		}
	}

	if options.Overwrite {
		args = append(args, "-y")
	}

	args = append(args, outputPath)
	return args
}

func (e *FFmpegEngine) getDuration(inputPath string) float64 {
	cmd := exec.Command("ffprobe",
		"-v", "error",
		"-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		inputPath,
	)
	output, err := cmd.Output()
	if err != nil {
		return 0
	}
	duration, err := strconv.ParseFloat(strings.TrimSpace(string(output)), 64)
	if err != nil {
		return 0
	}
	return duration
}

func (e *FFmpegEngine) parseTime(line string) float64 {
	idx := strings.Index(line, "time=")
	if idx < 0 {
		return 0
	}
	timeStr := line[idx+5:]
	if spaceIdx := strings.Index(timeStr, " "); spaceIdx >= 0 {
		timeStr = timeStr[:spaceIdx]
	}

	parts := strings.Split(timeStr, ":")
	if len(parts) != 3 {
		return 0
	}
	hours, _ := strconv.ParseFloat(parts[0], 64)
	minutes, _ := strconv.ParseFloat(parts[1], 64)
	seconds, _ := strconv.ParseFloat(parts[2], 64)

	return hours*3600 + minutes*60 + seconds
}

func (e *FFmpegEngine) parseOutputSize(line string) int64 {
	idx := strings.Index(line, "size=")
	if idx < 0 {
		return 0
	}
	sizeStr := line[idx+5:]
	if spaceIdx := strings.Index(sizeStr, " "); spaceIdx >= 0 {
		sizeStr = sizeStr[:spaceIdx]
	}

	sizeStr = strings.TrimSpace(sizeStr)
	multiplier := int64(1)
	if strings.HasSuffix(sizeStr, "kB") {
		multiplier = 1024
		sizeStr = strings.TrimSuffix(sizeStr, "kB")
	} else if strings.HasSuffix(sizeStr, "MB") {
		multiplier = 1024 * 1024
		sizeStr = strings.TrimSuffix(sizeStr, "MB")
	} else if strings.HasSuffix(sizeStr, "GB") {
		multiplier = 1024 * 1024 * 1024
		sizeStr = strings.TrimSuffix(sizeStr, "GB")
	} else if strings.HasSuffix(sizeStr, "bytes") {
		sizeStr = strings.TrimSuffix(sizeStr, "bytes")
	}

	size, err := strconv.ParseFloat(strings.TrimSpace(sizeStr), 64)
	if err != nil {
		return 0
	}
	return int64(size) * multiplier
}

func (e *FFmpegEngine) SupportedFormats() []string {
	return []string{"MP4", "MKV", "MOV", "AVI", "WebM", "FLV", "WMV", "MPEG", "3GP", "MP3", "FLAC", "WAV", "AAC", "OGG", "WMA", "M4A", "OPUS"}
}
