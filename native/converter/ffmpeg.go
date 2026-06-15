package converter

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"native/models"
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
	inputSize := inputInfo.Size()

	if !options.Overwrite {
		if _, err := os.Stat(outputPath); err == nil {
			return fmt.Errorf("output file already exists: %s", outputPath)
		}
	}

	if err := os.MkdirAll(filepath.Dir(outputPath), 0755); err != nil {
		return fmt.Errorf("cannot create output directory: %w", err)
	}

	ffmpegPath, err := ResolveBinary("ffmpeg")
	if err != nil {
		return fmt.Errorf("ffmpeg not found: %w", err)
	}

	args := e.buildArgs(inputPath, outputPath, options)
	cmd := exec.CommandContext(ctx, ffmpegPath, args...)

	// Drain stderr in background to prevent pipe blocking
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return fmt.Errorf("cannot create stderr pipe: %w", err)
	}
	go func() {
		buf := make([]byte, 4096)
		for {
			if _, err := stderr.Read(buf); err != nil {
				return
			}
		}
	}()

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("cannot start ffmpeg: %w", err)
	}

	done := make(chan error, 1)
	go func() {
		done <- cmd.Wait()
	}()

	// Periodically check output file size for real progress
	ticker := time.NewTicker(200 * time.Millisecond)
	defer ticker.Stop()

	if progressCallback != nil {
		progressCallback(0.0)
	}
	if byteCallback != nil {
		byteCallback(0, inputSize)
	}

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case err := <-done:
			if err != nil {
				return fmt.Errorf("ffmpeg conversion failed: %w", err)
			}
			if progressCallback != nil {
				progressCallback(1.0)
			}
			if byteCallback != nil {
				byteCallback(inputSize, inputSize)
			}
			return nil
		case <-ticker.C:
			var progress float64
			var processed int64
			if outInfo, err := os.Stat(outputPath); err == nil {
				processed = outInfo.Size()
				if inputSize > 0 {
					progress = float64(processed) / float64(inputSize)
					if progress > 0.95 {
						progress = 0.95 // Cap at 95% until process completes
					}
				}
			}
			if progressCallback != nil {
				progressCallback(progress)
			}
			if byteCallback != nil {
				byteCallback(processed, inputSize)
			}
		}
	}
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
			if isAudioOutput(outputPath) {
				args = append(args, "-c:a", mapCodecName(options.Codec))
			} else {
				args = append(args, "-c:v", mapCodecName(options.Codec))
			}
		}
		if options.Quality > 0 {
			args = append(args, "-crf", strconv.Itoa(51-options.Quality/2))
		}
		if options.Bitrate != "" {
			if isAudioOutput(outputPath) {
				args = append(args, "-b:a", options.Bitrate)
			} else {
				args = append(args, "-b:v", options.Bitrate)
			}
		}
	}

	if options.Overwrite {
		args = append(args, "-y")
	}

	args = append(args, outputPath)
	return args
}

func isAudioOutput(outputPath string) bool {
	switch strings.ToLower(filepath.Ext(outputPath)) {
	case ".mp3", ".flac", ".wav", ".aac", ".ogg", ".wma", ".m4a", ".opus":
		return true
	default:
		return false
	}
}

func mapCodecName(uiName string) string {
	codecMap := map[string]string{
		"H.264":      "libx264",
		"H.265/HEVC": "libx265",
		"MPEG-4":     "mpeg4",
		"VP8":        "libvpx",
		"VP9":        "libvpx-vp9",
		"AV1":        "libaom-av1",
		"ProRes":     "prores_ks",
		"DivX":       "mpeg4",
		"Xvid":       "mpeg4",
		"VP6":        "vp6_flv",
		"WMV3":       "wmv3",
		"WMV9":       "wmv3",
		"MPEG-2":     "mpeg2video",
		"H.263":      "h263",
		"libmp3lame": "libmp3lame",
		"aac":        "aac",
		"libvorbis":  "libvorbis",
		"libopus":    "libopus",
		"flac":       "flac",
		"pcm_s16le":  "pcm_s16le",
	}
	if mapped, ok := codecMap[uiName]; ok {
		return mapped
	}
	return uiName
}

func (e *FFmpegEngine) getDuration(ctx context.Context, inputPath string) float64 {
	ffprobePath, err := ResolveBinary("ffprobe")
	if err != nil {
		return 0
	}
	cmd := exec.CommandContext(ctx, ffprobePath,
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
