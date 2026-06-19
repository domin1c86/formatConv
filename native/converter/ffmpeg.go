package converter

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"native/models"
)

type FFmpegEngine struct{}

const (
	probeAttempts = 3
	probeDelay    = 120 * time.Millisecond
)

func NewFFmpegEngine() *FFmpegEngine {
	return &FFmpegEngine{}
}

func (e *FFmpegEngine) Convert(ctx context.Context, inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64)) error {
	return e.ConvertWithBytes(ctx, inputPath, outputPath, options, progressCallback, nil)
}

func (e *FFmpegEngine) ConvertWithBytes(ctx context.Context, inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64), byteCallback func(processed, total int64)) error {
	return e.ConvertWithBytesAndInfo(ctx, inputPath, outputPath, options, progressCallback, byteCallback, nil)
}

func (e *FFmpegEngine) ConvertWithBytesAndInfo(ctx context.Context, inputPath, outputPath string, options models.ConversionOptions, progressCallback func(float64), byteCallback func(processed, total int64), infoCallback func(models.ConversionExecutionInfo)) error {
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

	encoders := map[string]bool{}
	if options.GPUAcceleration {
		encoders = e.availableEncoders(ctx, ffmpegPath)
	}
	probeInfo := e.probeMediaInfo(ctx, inputPath)
	command := e.buildCommandWithInfo(inputPath, outputPath, options, true, encoders, probeInfo)
	if infoCallback != nil {
		infoCallback(command.executionInfo())
	}
	err = e.runFFmpeg(
		ctx,
		ffmpegPath,
		command.Args,
		outputPath,
		estimateOutputSize(inputSize, options),
		progressCallback,
		byteCallback,
	)
	if err == nil || ctx.Err() != nil || !command.UsedHardware {
		return err
	}

	gpuErr := err
	_ = os.Remove(outputPath)
	cpuCommand := e.buildCommandWithInfo(inputPath, outputPath, options, false, nil, probeInfo)
	if infoCallback != nil {
		infoCallback(cpuCommand.executionInfo())
	}
	if progressCallback != nil {
		progressCallback(0)
	}
	if byteCallback != nil {
		byteCallback(0, estimateOutputSize(inputSize, options))
	}
	if err := e.runFFmpeg(
		ctx,
		ffmpegPath,
		cpuCommand.Args,
		outputPath,
		estimateOutputSize(inputSize, options),
		progressCallback,
		byteCallback,
	); err != nil {
		return fmt.Errorf("hardware ffmpeg conversion failed: %v; CPU fallback failed: %w", gpuErr, err)
	}
	return nil
}

func (e *FFmpegEngine) RunMediaOperation(ctx context.Context, options models.MediaOperationOptions, progressCallback func(float64), byteCallback func(processed, total int64), infoCallback func(models.ConversionExecutionInfo)) error {
	ffmpegPath, err := ResolveBinary("ffmpeg")
	if err != nil {
		return fmt.Errorf("ffmpeg not found: %w", err)
	}

	command, inputSize, err := e.buildMediaOperationCommand(ctx, options)
	if err != nil {
		return err
	}
	if infoCallback != nil {
		infoCallback(command.executionInfo())
	}
	outputPath := outputArg(command.Args)
	if err := e.runFFmpeg(ctx, ffmpegPath, command.Args, outputPath, inputSize, progressCallback, byteCallback); err != nil {
		return err
	}
	if strings.EqualFold(options.Operation, "split_audio") {
		if len(options.Inputs) != 1 {
			return fmt.Errorf("split audio duration validation requires exactly one input file")
		}
		return e.validateSplitAudioOutput(
			ctx,
			ffmpegPath,
			options.Inputs[0],
			outputPath,
			options.Overwrite,
			inputSize,
			progressCallback,
			byteCallback,
			infoCallback,
		)
	}
	return nil
}

func (e *FFmpegEngine) buildMediaOperationCommand(ctx context.Context, options models.MediaOperationOptions) (ffmpegCommand, int64, error) {
	switch strings.ToLower(options.Operation) {
	case "split_video":
		return e.buildSplitVideoCommand(ctx, options)
	case "split_audio":
		return e.buildSplitAudioCommand(ctx, options)
	case "merge":
		return e.buildMergeCommand(ctx, options)
	default:
		return ffmpegCommand{}, 0, fmt.Errorf("unsupported media operation: %s", options.Operation)
	}
}

func (e *FFmpegEngine) buildSplitVideoCommand(ctx context.Context, options models.MediaOperationOptions) (ffmpegCommand, int64, error) {
	if len(options.Inputs) != 1 {
		return ffmpegCommand{}, 0, fmt.Errorf("split video requires exactly one input file")
	}
	inputPath := options.Inputs[0]
	info := e.probeMediaInfo(ctx, inputPath)
	if info.Video.Codec == "" {
		return ffmpegCommand{}, 0, fmt.Errorf("no video stream found for split")
	}
	outputPath := options.OutputPath
	if outputPath == "" {
		outputPath = derivedOutputPath(inputPath, options.OutputDirectory, "_video", filepath.Ext(inputPath))
	}
	outputPath, err := prepareOutputPath(outputPath, options.Overwrite)
	if err != nil {
		return ffmpegCommand{}, 0, err
	}
	args := []string{
		"-fflags", "+genpts",
		"-i", inputPath,
		"-map", "0:v:0",
		"-c:v", "copy",
		"-an",
		"-map_metadata", "0",
		"-avoid_negative_ts", "make_zero",
	}
	if options.Overwrite {
		args = append(args, "-y")
	}
	args = append(args, outputPath)
	return ffmpegCommand{
		Args:         args,
		Mode:         "split_video",
		VideoEncoder: "copy",
		ProbeWarning: info.ProbeWarning,
	}, inputSizeOrDefault(inputPath), nil
}

func (e *FFmpegEngine) buildSplitAudioCommand(ctx context.Context, options models.MediaOperationOptions) (ffmpegCommand, int64, error) {
	if len(options.Inputs) != 1 {
		return ffmpegCommand{}, 0, fmt.Errorf("split audio requires exactly one input file")
	}
	inputPath := options.Inputs[0]
	info := e.probeMediaInfo(ctx, inputPath)
	if info.Audio.Codec == "" {
		return ffmpegCommand{}, 0, fmt.Errorf("no audio stream found for split")
	}
	outputPath := options.OutputPath
	if outputPath == "" {
		outputPath = derivedOutputPath(inputPath, options.OutputDirectory, "_audio", audioExtensionForCodec(info.Audio.Codec))
	}
	outputPath, err := prepareOutputPath(outputPath, options.Overwrite)
	if err != nil {
		return ffmpegCommand{}, 0, err
	}
	args := []string{
		"-fflags", "+genpts",
		"-i", inputPath,
		"-map", "0:a:0",
		"-c:a", "copy",
		"-vn",
		"-map_metadata", "0",
		"-avoid_negative_ts", "make_zero",
	}
	if strings.EqualFold(filepath.Ext(outputPath), ".m4a") {
		args = append(args, "-movflags", "+faststart")
	}
	if options.Overwrite {
		args = append(args, "-y")
	}
	args = append(args, outputPath)
	return ffmpegCommand{
		Args:         args,
		Mode:         "split_audio",
		VideoEncoder: "none",
		ProbeWarning: info.ProbeWarning,
	}, inputSizeOrDefault(inputPath), nil
}

func (e *FFmpegEngine) buildMergeCommand(ctx context.Context, options models.MediaOperationOptions) (ffmpegCommand, int64, error) {
	videoPath, audioPath, err := classifyMergeInputs(options.Inputs)
	if err != nil {
		return ffmpegCommand{}, 0, err
	}
	videoInfo := e.probeMediaInfo(ctx, videoPath)
	audioInfo := e.probeMediaInfo(ctx, audioPath)
	if videoInfo.Video.Codec == "" {
		return ffmpegCommand{}, 0, fmt.Errorf("no video stream found in source video")
	}
	if audioInfo.Audio.Codec == "" {
		return ffmpegCommand{}, 0, fmt.Errorf("no audio stream found in source audio")
	}
	outputPath := options.OutputPath
	if outputPath == "" {
		outputPath = derivedOutputPath(videoPath, options.OutputDirectory, "_merged", filepath.Ext(videoPath))
	}
	outputPath, err = prepareOutputPath(outputPath, options.Overwrite)
	if err != nil {
		return ffmpegCommand{}, 0, err
	}

	ext := strings.ToLower(filepath.Ext(videoPath))
	spec := containerSpecFor(ext)
	videoDuration := e.getVideoDuration(ctx, videoPath)
	if videoDuration <= 0 {
		return ffmpegCommand{}, 0, fmt.Errorf(
			"cannot determine source video duration; merge stopped to avoid an invalid output timeline",
		)
	}

	audioCodec := mergeAudioEncoder(audioInfo.Audio.Codec, spec)
	durationText := strconv.FormatFloat(videoDuration, 'f', 6, 64)
	audioFilter := fmt.Sprintf(
		"[1:a:0]atrim=duration=%s,asetpts=PTS-STARTPTS,apad=whole_dur=%s[external_audio]",
		durationText,
		durationText,
	)
	keepSourceAudio := !options.RemoveSourceAudio && videoInfo.Audio.Codec != ""
	args := []string{
		"-fflags", "+genpts",
		"-i", videoPath,
		"-i", audioPath,
		"-filter_complex", audioFilter,
		"-map", "0:v:0",
	}
	if keepSourceAudio {
		args = append(args, "-map", "0:a:0?")
	}
	args = append(args, "-map", "[external_audio]", "-c:v", "copy")
	if keepSourceAudio {
		args = append(args, "-c:a:0", "copy")
		args = append(args, "-c:a:1", audioCodec)
	} else {
		args = append(args, "-c:a", audioCodec)
	}
	args = append(
		args,
		"-map_metadata", "0",
		"-map_chapters", "0",
		"-t", durationText,
		"-avoid_negative_ts", "make_zero",
	)
	if ext == ".mp4" || ext == ".mov" {
		args = append(args, "-movflags", "+faststart")
	}
	if options.Overwrite {
		args = append(args, "-y")
	}
	args = append(args, outputPath)
	return ffmpegCommand{
		Args:         args,
		Mode:         "merge_audio_encode",
		VideoEncoder: "copy",
		ProbeWarning: strings.TrimSpace(strings.Join([]string{videoInfo.ProbeWarning, audioInfo.ProbeWarning}, " ")),
	}, inputSizeOrDefault(videoPath), nil
}

func (e *FFmpegEngine) runFFmpeg(ctx context.Context, ffmpegPath string, args []string, outputPath string, initialExpectedSize int64, progressCallback func(float64), byteCallback func(processed, total int64)) error {
	cmd := exec.CommandContext(ctx, ffmpegPath, args...)
	configureBackgroundCommand(cmd)

	stderr, err := cmd.StderrPipe()
	if err != nil {
		return fmt.Errorf("cannot create stderr pipe: %w", err)
	}
	var stderrBuffer bytes.Buffer
	stderrDone := make(chan struct{})
	go func() {
		defer close(stderrDone)
		_, _ = io.Copy(&stderrBuffer, stderr)
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
	expectedSize := initialExpectedSize
	if byteCallback != nil {
		byteCallback(0, expectedSize)
	}

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case err := <-done:
			<-stderrDone
			if err != nil {
				details := strings.TrimSpace(stderrBuffer.String())
				if details != "" {
					return fmt.Errorf("ffmpeg conversion failed: %w: %s", err, shortenError(details))
				}
				return fmt.Errorf("ffmpeg conversion failed: %w", err)
			}
			if progressCallback != nil {
				progressCallback(1.0)
			}
			if byteCallback != nil {
				finalSize := expectedSize
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
				if processed > expectedSize {
					expectedSize = int64(float64(processed) / 0.95)
					if expectedSize < processed {
						expectedSize = processed
					}
				}
				if expectedSize > 0 {
					progress = float64(processed) / float64(expectedSize)
					if progress > 0.95 {
						progress = 0.95 // Cap at 95% until process completes
					}
				}
			}
			if progressCallback != nil {
				progressCallback(progress)
			}
			if byteCallback != nil {
				byteCallback(processed, expectedSize)
			}
		}
	}
}

type ffmpegCommand struct {
	Args         []string
	UsedHardware bool
	Mode         string
	VideoEncoder string
	ProbeWarning string
}

func (c ffmpegCommand) executionInfo() models.ConversionExecutionInfo {
	return models.ConversionExecutionInfo{
		Mode:         c.Mode,
		VideoEncoder: c.VideoEncoder,
		ProbeWarning: c.ProbeWarning,
		OutputPath:   outputArg(c.Args),
	}
}

func (e *FFmpegEngine) buildArgs(ctx context.Context, inputPath, outputPath string, options models.ConversionOptions, useHardware bool, encoders map[string]bool) ([]string, bool) {
	command := e.buildCommand(ctx, inputPath, outputPath, options, useHardware, encoders)
	return command.Args, command.UsedHardware
}

func (e *FFmpegEngine) buildCommand(ctx context.Context, inputPath, outputPath string, options models.ConversionOptions, useHardware bool, encoders map[string]bool) ffmpegCommand {
	info := e.probeMediaInfo(ctx, inputPath)
	return e.buildCommandWithInfo(inputPath, outputPath, options, useHardware, encoders, info)
}

func (e *FFmpegEngine) buildArgsWithInfo(inputPath, outputPath string, options models.ConversionOptions, useHardware bool, encoders map[string]bool, info mediaInfo) ([]string, bool) {
	command := e.buildCommandWithInfo(inputPath, outputPath, options, useHardware, encoders, info)
	return command.Args, command.UsedHardware
}

func (e *FFmpegEngine) buildCommandWithInfo(inputPath, outputPath string, options models.ConversionOptions, useHardware bool, encoders map[string]bool, info mediaInfo) ffmpegCommand {
	ext := strings.ToLower(filepath.Ext(outputPath))
	hasProbeInfo := info.Video.Codec != "" || info.Audio.Codec != ""
	args := []string{}
	args = append(args, "-i", inputPath)

	if options.Overwrite {
		args = append(args, "-y")
	}

	if ext == ".gif" {
		args = append(args, e.buildGifArgs(options)...)
		args = append(args, outputPath)
		return ffmpegCommand{Args: args, Mode: "gif_encode", VideoEncoder: "gif", ProbeWarning: info.ProbeWarning}
	}

	if isAudioOutput(outputPath) {
		args = append(args, "-vn")
		audioCodec := chooseAudioCodecForOutput(ext, info.Audio.Codec, options.AudioCodec)
		args = append(args, "-c:a", audioCodec)
		args = appendAudioArgs(args, options)
		args = append(args, outputPath)
		return ffmpegCommand{Args: args, Mode: "audio_encode", VideoEncoder: "none", ProbeWarning: info.ProbeWarning}
	}

	usedHardware := false
	videoEncoder := "copy"
	videoReencoded := false
	audioReencoded := false
	spec := containerSpecFor(ext)
	args = append(args, "-map", "0")

	if !hasProbeInfo && !options.ForceVideoReencode && !options.ForceAudioReencode {
		args = append(args, "-c", "copy", outputPath)
		return ffmpegCommand{Args: args, Mode: "remux", VideoEncoder: "copy", ProbeWarning: info.ProbeWarning}
	}

	if info.Video.Codec != "" {
		if options.ForceVideoReencode || !codecAllowed(info.Video.Codec, spec.VideoCodecs) {
			codec := chooseCodec(options.VideoCodec, info.Video.Codec, spec.DefaultVideoCodec, spec.VideoCodecs)
			if options.GPUAcceleration && useHardware {
				if hardwareCodec, ok := chooseHardwareEncoder(codec, encoders); ok {
					codec = hardwareCodec
					usedHardware = true
				}
			}
			args = append(args, "-c:v", codec)
			videoEncoder = codec
			videoReencoded = true
			if options.VideoQuality > 0 && options.VideoQuality < 100 && !usedHardware {
				args = append(args, "-crf", strconv.Itoa(51-options.VideoQuality/2))
			} else if options.VideoQuality > 0 && options.VideoQuality < 100 && usedHardware {
				args = append(args, hardwareQualityArgs(codec, options.VideoQuality)...)
			}
			if value := nonSource(options.Resolution); value != "" {
				args = append(args, "-s", mapResolution(value))
			}
			if value := nonSource(options.FrameRate); value != "" {
				args = append(args, "-r", value)
			}
			if value := nonSource(options.VideoBitrate); value != "" {
				args = append(args, "-b:v", value)
			}
		} else {
			args = append(args, "-c:v", "copy")
		}
	} else if options.ForceVideoReencode {
		codec := chooseCodec(options.VideoCodec, "", spec.DefaultVideoCodec, spec.VideoCodecs)
		if options.GPUAcceleration && useHardware {
			if hardwareCodec, ok := chooseHardwareEncoder(codec, encoders); ok {
				codec = hardwareCodec
				usedHardware = true
			}
		}
		args = append(args, "-c:v", codec)
		videoEncoder = codec
		videoReencoded = true
	} else if !hasProbeInfo {
		args = append(args, "-c:v", "copy")
	}

	if info.Audio.Codec != "" {
		if options.ForceAudioReencode || !codecAllowed(info.Audio.Codec, spec.AudioCodecs) {
			codec := chooseCodec(options.AudioCodec, info.Audio.Codec, spec.DefaultAudioCodec, spec.AudioCodecs)
			args = append(args, "-c:a", codec)
			args = appendAudioArgs(args, options)
			audioReencoded = true
		} else {
			args = append(args, "-c:a", "copy")
		}
	} else if options.ForceAudioReencode {
		codec := chooseCodec(options.AudioCodec, "", spec.DefaultAudioCodec, spec.AudioCodecs)
		args = append(args, "-c:a", codec)
		args = appendAudioArgs(args, options)
		audioReencoded = true
	} else if !hasProbeInfo {
		args = append(args, "-c:a", "copy")
	}

	if usedHardware {
		args = append([]string{"-hwaccel", "auto"}, args...)
	}

	args = append(args, outputPath)
	mode := "remux"
	if videoReencoded || audioReencoded {
		mode = "cpu_encode"
	}
	if usedHardware {
		mode = "gpu_encode"
	}
	return ffmpegCommand{
		Args:         args,
		UsedHardware: usedHardware,
		Mode:         mode,
		VideoEncoder: videoEncoder,
		ProbeWarning: info.ProbeWarning,
	}
}

func (e *FFmpegEngine) buildGifArgs(options models.ConversionOptions) []string {
	filters := []string{}
	// GIF is a per-frame 256-color lossless LZW format, the opposite of an
	// inter-frame compressed codec like H.264. Letting a "source" (unset)
	// frame rate and scale pass through means the GIF inherits the source
	// video's full frame rate (often 30/60 fps) and full resolution, which
	// balloons the output to many times the input size. Default to sane
	// animation values when the user leaves them on "source".
	fps := gifFrameRate(options)
	if fps == "" {
		fps = "15"
	}
	filters = append(filters, "fps="+fps)
	scale := nonSource(options.GifScale)
	if scale == "" {
		scale = "480:-1"
	}
	filters = append(filters, "scale="+scale+":flags=lanczos")
	maxColors := nonSource(options.GifMaxColors)
	if maxColors == "" {
		maxColors = "256"
	}
	dither := nonSource(options.GifDitherAlgorithm)
	if dither == "" {
		dither = "sierra2_4a"
	}
	filterPrefix := strings.Join(filters, ",")
	// Join the prelude (fps, scale) to the palette split chain with a comma.
	// Forgetting it fuses "flags=lanczos" + "split" into "flags=lanczossplit",
	// which ffmpeg rejects as an unknown sws_flags constant.
	filter := filterPrefix + ",split[s0][s1];[s0]palettegen=max_colors=" + maxColors + "[p];[s1][p]paletteuse=dither=" + dither
	args := []string{"-an", "-vf", filter}
	if loop := nonSource(options.GifLoopMode); loop != "" {
		if loop == "none" {
			args = append(args, "-loop", "-1")
		} else {
			args = append(args, "-loop", "0")
		}
	}
	return args
}

func (e *FFmpegEngine) availableEncoders(ctx context.Context, ffmpegPath string) map[string]bool {
	cmd := exec.CommandContext(ctx, ffmpegPath, "-hide_banner", "-encoders")
	configureBackgroundCommand(cmd)
	output, err := cmd.Output()
	if err != nil {
		return map[string]bool{}
	}
	encoders := map[string]bool{}
	for _, line := range strings.Split(string(output), "\n") {
		fields := strings.Fields(line)
		if len(fields) >= 2 && strings.Contains(fields[0], "V") {
			encoders[fields[1]] = true
		}
	}
	return encoders
}

func chooseHardwareEncoder(codec string, encoders map[string]bool) (string, bool) {
	if len(encoders) == 0 {
		return "", false
	}
	candidates := hardwareEncoderCandidates(codec)
	for _, candidate := range candidates {
		if encoders[candidate] {
			return candidate, true
		}
	}
	return "", false
}

func hardwareEncoderCandidates(codec string) []string {
	switch normalizeCodec(codec) {
	case "h264":
		return []string{"h264_nvenc", "h264_qsv", "h264_amf"}
	case "hevc":
		return []string{"hevc_nvenc", "hevc_qsv", "hevc_amf"}
	case "av1":
		return []string{"av1_nvenc", "av1_qsv", "av1_amf"}
	default:
		return nil
	}
}

func hardwareQualityArgs(codec string, quality int) []string {
	if quality <= 0 || quality >= 100 {
		return nil
	}
	value := strconv.Itoa(mapHardwareQuality(quality))
	switch {
	case strings.HasSuffix(codec, "_nvenc"), strings.HasSuffix(codec, "_qsv"):
		return []string{"-cq", value}
	default:
		return nil
	}
}

func mapHardwareQuality(quality int) int {
	if quality < 1 {
		quality = 1
	}
	if quality > 100 {
		quality = 100
	}
	return 51 - quality/2
}

func shortenError(message string) string {
	message = strings.ReplaceAll(message, "\r", "\n")
	lines := strings.Split(message, "\n")
	kept := make([]string, 0, 8)
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		kept = append(kept, line)
		if len(kept) >= 8 {
			break
		}
	}
	return strings.Join(kept, " | ")
}

func outputArg(args []string) string {
	if len(args) == 0 {
		return ""
	}
	return args[len(args)-1]
}

func inputSizeOrDefault(path string) int64 {
	info, err := os.Stat(path)
	if err != nil || info.Size() <= 0 {
		return 1
	}
	return info.Size()
}

func prepareOutputPath(outputPath string, overwrite bool) (string, error) {
	if outputPath == "" {
		return "", fmt.Errorf("output path is empty")
	}
	if err := os.MkdirAll(filepath.Dir(outputPath), 0755); err != nil {
		return "", fmt.Errorf("cannot create output directory: %w", err)
	}
	if overwrite {
		return outputPath, nil
	}
	if _, err := os.Stat(outputPath); os.IsNotExist(err) {
		return outputPath, nil
	}

	ext := filepath.Ext(outputPath)
	base := strings.TrimSuffix(outputPath, ext)
	for suffix := 1; suffix < 10000; suffix++ {
		candidate := fmt.Sprintf("%s_%d%s", base, suffix, ext)
		if _, err := os.Stat(candidate); os.IsNotExist(err) {
			return candidate, nil
		}
	}
	return "", fmt.Errorf("cannot find available output path for: %s", outputPath)
}

func derivedOutputPath(inputPath, outputDirectory, suffix, ext string) string {
	if ext == "" {
		ext = filepath.Ext(inputPath)
	}
	dir := outputDirectory
	if strings.TrimSpace(dir) == "" {
		dir = filepath.Dir(inputPath)
	}
	return filepath.Join(dir, filepath.Base(strings.TrimSuffix(filepath.Base(inputPath), filepath.Ext(inputPath)))+suffix+ext)
}

func audioExtensionForCodec(codec string) string {
	switch normalizeCodec(codec) {
	case "flac":
		return ".flac"
	case "aac":
		return ".m4a"
	case "mp3":
		return ".mp3"
	case "opus":
		return ".opus"
	case "vorbis":
		return ".ogg"
	case "pcm_s16le", "pcm_s24le", "pcm_s32le", "pcm_f32le", "pcm_f64le":
		return ".wav"
	case "alac":
		return ".m4a"
	default:
		return ".mka"
	}
}

func mergeAudioEncoder(sourceCodec string, spec containerSpec) string {
	if !codecAllowed(sourceCodec, spec.AudioCodecs) {
		return spec.DefaultAudioCodec
	}
	switch normalizeCodec(sourceCodec) {
	case "aac":
		return "aac"
	case "mp3":
		return "libmp3lame"
	case "flac":
		return "flac"
	case "opus":
		return "libopus"
	case "vorbis":
		return "libvorbis"
	case "alac":
		return "alac"
	case "ac3":
		return "ac3"
	case "pcm_s16le", "pcm_s24le", "pcm_s32le", "pcm_f32le", "pcm_f64le":
		return normalizeCodec(sourceCodec)
	case "wmav2":
		return "wmav2"
	case "mp2":
		return "mp2"
	default:
		return spec.DefaultAudioCodec
	}
}

func (e *FFmpegEngine) validateSplitAudioOutput(
	ctx context.Context,
	ffmpegPath string,
	inputPath string,
	outputPath string,
	overwrite bool,
	inputSize int64,
	progressCallback func(float64),
	byteCallback func(processed, total int64),
	infoCallback func(models.ConversionExecutionInfo),
) error {
	sourceDuration := e.getAudioDuration(ctx, inputPath)
	if sourceDuration <= 0 {
		sourceDuration = e.getVideoDuration(ctx, inputPath)
	}
	if sourceDuration <= 0 {
		_ = os.Remove(outputPath)
		return fmt.Errorf("cannot verify split audio duration because the source timeline is unavailable")
	}

	outputDuration := e.getAudioDuration(ctx, outputPath)
	if audioDurationsMatch(sourceDuration, outputDuration) {
		return nil
	}

	reason := fmt.Sprintf(
		"split audio duration mismatch: source %.3fs, output %.3fs",
		sourceDuration,
		outputDuration,
	)
	_ = os.Remove(outputPath)

	copyArgs := []string{
		"-fflags", "+genpts+igndts",
		"-i", inputPath,
		"-map", "0:a:0",
		"-c:a", "copy",
		"-vn",
		"-map_metadata", "0",
		"-avoid_negative_ts", "make_zero",
	}
	if strings.EqualFold(filepath.Ext(outputPath), ".m4a") {
		copyArgs = append(copyArgs, "-movflags", "+faststart")
	}
	copyArgs = append(copyArgs, "-y", outputPath)
	if infoCallback != nil {
		infoCallback(models.ConversionExecutionInfo{
			Mode:         "split_audio_timestamp_repair",
			VideoEncoder: "none",
			ProbeWarning: reason + "; rebuilding timestamps in the codec's preferred container",
			OutputPath:   outputPath,
		})
	}
	copyErr := e.runFFmpeg(
		ctx,
		ffmpegPath,
		copyArgs,
		outputPath,
		inputSize,
		progressCallback,
		byteCallback,
	)
	if copyErr == nil {
		repairedDuration := e.getAudioDuration(ctx, outputPath)
		if audioDurationsMatch(sourceDuration, repairedDuration) {
			return nil
		}
	}
	if ctx.Err() != nil {
		_ = os.Remove(outputPath)
		return ctx.Err()
	}
	_ = os.Remove(outputPath)

	fallbackPath, err := prepareAudioFallbackPath(outputPath, overwrite)
	if err != nil {
		return fmt.Errorf("%s; cannot prepare Matroska fallback output: %w", reason, err)
	}
	mkaCopyArgs := []string{
		"-fflags", "+genpts+igndts",
		"-i", inputPath,
		"-map", "0:a:0",
		"-c:a", "copy",
		"-vn",
		"-map_metadata", "0",
		"-avoid_negative_ts", "make_zero",
		"-y",
		fallbackPath,
	}
	if infoCallback != nil {
		infoCallback(models.ConversionExecutionInfo{
			Mode:         "split_audio_container_fallback",
			VideoEncoder: "none",
			ProbeWarning: reason + "; preferred container is still invalid, retrying in Matroska audio",
			OutputPath:   fallbackPath,
		})
	}
	mkaCopyErr := e.runFFmpeg(
		ctx,
		ffmpegPath,
		mkaCopyArgs,
		fallbackPath,
		inputSize,
		progressCallback,
		byteCallback,
	)
	if mkaCopyErr == nil {
		fallbackDuration := e.getAudioDuration(ctx, fallbackPath)
		if audioDurationsMatch(sourceDuration, fallbackDuration) {
			return nil
		}
	}
	if ctx.Err() != nil {
		_ = os.Remove(fallbackPath)
		return ctx.Err()
	}
	_ = os.Remove(fallbackPath)

	rebuildArgs := []string{
		"-fflags", "+genpts",
		"-i", inputPath,
		"-map", "0:a:0",
		"-af", "asetpts=N/SR/TB",
		"-c:a", "flac",
		"-vn",
		"-map_metadata", "0",
		"-avoid_negative_ts", "make_zero",
		"-y",
		fallbackPath,
	}
	if infoCallback != nil {
		infoCallback(models.ConversionExecutionInfo{
			Mode:         "split_audio_timestamp_rebuild",
			VideoEncoder: "none",
			ProbeWarning: reason + "; rebuilding a continuous lossless audio timeline",
			OutputPath:   fallbackPath,
		})
	}
	if err := e.runFFmpeg(
		ctx,
		ffmpegPath,
		rebuildArgs,
		fallbackPath,
		inputSize,
		progressCallback,
		byteCallback,
	); err != nil {
		_ = os.Remove(fallbackPath)
		return fmt.Errorf("%s; timestamp rebuild failed: %w", reason, err)
	}

	repairedDuration := e.getAudioDuration(ctx, fallbackPath)
	if !audioDurationsMatch(sourceDuration, repairedDuration) {
		_ = os.Remove(fallbackPath)
		return fmt.Errorf(
			"%s; rebuilt output duration is still invalid: %.3fs",
			reason,
			repairedDuration,
		)
	}
	return nil
}

func prepareAudioFallbackPath(outputPath string, overwrite bool) (string, error) {
	basePath := strings.TrimSuffix(outputPath, filepath.Ext(outputPath)) + ".mka"
	if strings.EqualFold(basePath, outputPath) {
		if overwrite {
			return basePath, nil
		}
		if _, err := os.Stat(basePath); os.IsNotExist(err) {
			return basePath, nil
		}
	}
	return prepareOutputPath(basePath, overwrite)
}

func audioDurationsMatch(sourceDuration, outputDuration float64) bool {
	if sourceDuration <= 0 || outputDuration <= 0 {
		return false
	}
	tolerance := sourceDuration * 0.01
	if tolerance < 1 {
		tolerance = 1
	}
	difference := sourceDuration - outputDuration
	if difference < 0 {
		difference = -difference
	}
	return difference <= tolerance
}

func classifyMergeInputs(inputs []string) (string, string, error) {
	var videoPath string
	var audioPath string
	for _, input := range inputs {
		switch fileTypeByExtension(input) {
		case "video":
			if videoPath != "" {
				return "", "", fmt.Errorf("merge requires exactly one video file")
			}
			videoPath = input
		case "audio":
			if audioPath != "" {
				return "", "", fmt.Errorf("merge requires exactly one audio file")
			}
			audioPath = input
		default:
			return "", "", fmt.Errorf("merge only supports video and audio files: %s", filepath.Base(input))
		}
	}
	if videoPath == "" || audioPath == "" {
		return "", "", fmt.Errorf("merge requires one video file and one audio file")
	}
	return videoPath, audioPath, nil
}

func fileTypeByExtension(path string) string {
	switch strings.ToLower(filepath.Ext(path)) {
	case ".mp4", ".mkv", ".mov", ".avi", ".webm", ".flv", ".wmv", ".mpeg", ".mpg", ".3gp":
		return "video"
	case ".mp3", ".flac", ".wav", ".aac", ".ogg", ".wma", ".m4a", ".mka", ".opus":
		return "audio"
	default:
		return ""
	}
}

type mediaStreamInfo struct {
	Codec      string
	Width      int
	Height     int
	FrameRate  string
	BitRate    string
	SampleRate string
	Channels   int
}

type mediaInfo struct {
	Video         mediaStreamInfo
	Audio         mediaStreamInfo
	ProbeSource   string
	ProbeAttempts int
	ProbeWarning  string
}

func (i mediaInfo) hasStreams() bool {
	return i.Video.Codec != "" || i.Audio.Codec != ""
}

type ffprobeStream struct {
	CodecType  string `json:"codec_type"`
	CodecName  string `json:"codec_name"`
	Width      int    `json:"width"`
	Height     int    `json:"height"`
	FrameRate  string `json:"r_frame_rate"`
	BitRate    string `json:"bit_rate"`
	SampleRate string `json:"sample_rate"`
	Channels   int    `json:"channels"`
}

type ffprobeResult struct {
	Streams []ffprobeStream `json:"streams"`
}

func (e *FFmpegEngine) probeMediaInfo(ctx context.Context, inputPath string) mediaInfo {
	failures := []string{}
	ffprobePath, err := ResolveBinary("ffprobe")
	if err != nil {
		failures = append(failures, "ffprobe not found: "+err.Error())
	} else {
		for attempt := 1; attempt <= probeAttempts; attempt++ {
			info, err := e.probeWithFFprobeEntries(ctx, ffprobePath, inputPath)
			if err == nil && info.hasStreams() {
				info.ProbeSource = "ffprobe_entries"
				info.ProbeAttempts = attempt
				info.ProbeWarning = probeWarning(failures)
				return info
			}
			if err == nil {
				err = fmt.Errorf("ffprobe returned no video or audio streams")
			}
			failures = append(failures, fmt.Sprintf("ffprobe entries attempt %d/%d: %v", attempt, probeAttempts, err))
			if !sleepBeforeProbeRetry(ctx, attempt) {
				return mediaInfo{ProbeWarning: probeWarning(failures)}
			}
		}

		info, err := e.probeWithFFprobeStreams(ctx, ffprobePath, inputPath)
		if err == nil && info.hasStreams() {
			info.ProbeSource = "ffprobe_show_streams"
			info.ProbeAttempts = probeAttempts + 1
			info.ProbeWarning = probeWarning(failures)
			return info
		}
		if err == nil {
			err = fmt.Errorf("ffprobe -show_streams returned no video or audio streams")
		}
		failures = append(failures, "ffprobe show_streams fallback: "+err.Error())
	}

	ffmpegPath, err := ResolveBinary("ffmpeg")
	if err != nil {
		failures = append(failures, "ffmpeg not found: "+err.Error())
		return mediaInfo{ProbeWarning: probeWarning(failures)}
	}
	info, err := e.probeWithFFmpegInput(ctx, ffmpegPath, inputPath)
	if err == nil && info.hasStreams() {
		info.ProbeSource = "ffmpeg_input_stderr"
		info.ProbeAttempts = probeAttempts + 2
		info.ProbeWarning = probeWarning(failures)
		return info
	}
	if err == nil {
		err = fmt.Errorf("ffmpeg input fallback returned no video or audio streams")
	}
	failures = append(failures, "ffmpeg input fallback: "+err.Error())
	return mediaInfo{ProbeWarning: probeWarning(failures)}
}

func (e *FFmpegEngine) probeWithFFprobeEntries(ctx context.Context, ffprobePath, inputPath string) (mediaInfo, error) {
	return runFFprobeJSON(ctx, ffprobePath, inputPath,
		"-v", "error",
		"-show_entries", "stream=codec_type,codec_name,width,height,r_frame_rate,bit_rate,sample_rate,channels",
		"-of", "json",
	)
}

func (e *FFmpegEngine) probeWithFFprobeStreams(ctx context.Context, ffprobePath, inputPath string) (mediaInfo, error) {
	return runFFprobeJSON(ctx, ffprobePath, inputPath,
		"-v", "error",
		"-show_streams",
		"-of", "json",
	)
}

func runFFprobeJSON(ctx context.Context, ffprobePath, inputPath string, args ...string) (mediaInfo, error) {
	probeCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	fullArgs := append([]string{}, args...)
	fullArgs = append(fullArgs, inputPath)
	cmd := exec.CommandContext(probeCtx, ffprobePath, fullArgs...)
	configureBackgroundCommand(cmd)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	output, err := cmd.Output()
	if probeCtx.Err() == context.DeadlineExceeded {
		return mediaInfo{}, fmt.Errorf("probe timed out")
	}
	if err != nil {
		details := strings.TrimSpace(stderr.String())
		if details != "" {
			return mediaInfo{}, fmt.Errorf("%w: %s", err, shortenError(details))
		}
		return mediaInfo{}, err
	}
	var result ffprobeResult
	if err := json.Unmarshal(output, &result); err != nil {
		return mediaInfo{}, fmt.Errorf("cannot parse ffprobe json: %w", err)
	}
	return mediaInfoFromProbeResult(result), nil
}

func mediaInfoFromProbeResult(result ffprobeResult) mediaInfo {
	info := mediaInfo{}
	for _, stream := range result.Streams {
		switch stream.CodecType {
		case "video":
			if info.Video.Codec == "" {
				info.Video = mediaStreamInfo{
					Codec:     stream.CodecName,
					Width:     stream.Width,
					Height:    stream.Height,
					FrameRate: stream.FrameRate,
					BitRate:   stream.BitRate,
				}
			}
		case "audio":
			if info.Audio.Codec == "" {
				info.Audio = mediaStreamInfo{
					Codec:      stream.CodecName,
					BitRate:    stream.BitRate,
					SampleRate: stream.SampleRate,
					Channels:   stream.Channels,
				}
			}
		}
	}
	return info
}

func (e *FFmpegEngine) probeWithFFmpegInput(ctx context.Context, ffmpegPath, inputPath string) (mediaInfo, error) {
	probeCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	cmd := exec.CommandContext(probeCtx, ffmpegPath, "-hide_banner", "-i", inputPath)
	configureBackgroundCommand(cmd)
	output, err := cmd.CombinedOutput()
	if probeCtx.Err() == context.DeadlineExceeded {
		return mediaInfo{}, fmt.Errorf("ffmpeg input probe timed out")
	}
	text := string(output)
	info := parseFFmpegInputProbe(text)
	if info.hasStreams() {
		return info, nil
	}
	if err != nil {
		return mediaInfo{}, fmt.Errorf("%w: %s", err, shortenError(text))
	}
	return mediaInfo{}, fmt.Errorf("no stream lines in ffmpeg input output")
}

func parseFFmpegInputProbe(output string) mediaInfo {
	info := mediaInfo{}
	for _, line := range strings.Split(output, "\n") {
		line = strings.TrimSpace(line)
		switch {
		case strings.Contains(line, "Video:") && info.Video.Codec == "":
			info.Video = parseVideoStreamLine(line)
		case strings.Contains(line, "Audio:") && info.Audio.Codec == "":
			info.Audio = parseAudioStreamLine(line)
		}
	}
	return info
}

func parseVideoStreamLine(line string) mediaStreamInfo {
	stream := mediaStreamInfo{Codec: codecAfterLabel(line, "Video:")}
	if match := regexp.MustCompile(`\b(\d{2,5})x(\d{2,5})\b`).FindStringSubmatch(line); len(match) == 3 {
		stream.Width, _ = strconv.Atoi(match[1])
		stream.Height, _ = strconv.Atoi(match[2])
	}
	if match := regexp.MustCompile(`\b([0-9]+(?:\.[0-9]+)?)\s*fps\b`).FindStringSubmatch(line); len(match) == 2 {
		stream.FrameRate = match[1]
	}
	if match := regexp.MustCompile(`\b([0-9]+)\s*kb/s\b`).FindStringSubmatch(line); len(match) == 2 {
		stream.BitRate = match[1] + "k"
	}
	return stream
}

func parseAudioStreamLine(line string) mediaStreamInfo {
	stream := mediaStreamInfo{Codec: codecAfterLabel(line, "Audio:")}
	if match := regexp.MustCompile(`\b([0-9]+)\s*Hz\b`).FindStringSubmatch(line); len(match) == 2 {
		stream.SampleRate = match[1]
	}
	stream.Channels = parseChannelCount(line)
	if match := regexp.MustCompile(`\b([0-9]+)\s*kb/s\b`).FindStringSubmatch(line); len(match) == 2 {
		stream.BitRate = match[1] + "k"
	}
	return stream
}

func codecAfterLabel(line, label string) string {
	idx := strings.Index(line, label)
	if idx < 0 {
		return ""
	}
	rest := strings.TrimSpace(line[idx+len(label):])
	if comma := strings.Index(rest, ","); comma >= 0 {
		rest = rest[:comma]
	}
	fields := strings.Fields(rest)
	if len(fields) == 0 {
		return ""
	}
	return strings.Trim(fields[0], " ,")
}

func parseChannelCount(line string) int {
	lower := strings.ToLower(line)
	switch {
	case strings.Contains(lower, "7.1"):
		return 8
	case strings.Contains(lower, "5.1"):
		return 6
	case strings.Contains(lower, "stereo"):
		return 2
	case strings.Contains(lower, "mono"):
		return 1
	}
	if match := regexp.MustCompile(`\b([0-9]+)\s*channels?\b`).FindStringSubmatch(lower); len(match) == 2 {
		channels, _ := strconv.Atoi(match[1])
		return channels
	}
	return 0
}

func sleepBeforeProbeRetry(ctx context.Context, attempt int) bool {
	if attempt >= probeAttempts {
		return true
	}
	timer := time.NewTimer(probeDelay)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return false
	case <-timer.C:
		return true
	}
}

func probeWarning(failures []string) string {
	if len(failures) == 0 {
		return ""
	}
	return "media probe warnings: " + shortenError(strings.Join(failures, "\n"))
}

type containerSpec struct {
	VideoCodecs       []string
	AudioCodecs       []string
	DefaultVideoCodec string
	DefaultAudioCodec string
}

func containerSpecFor(ext string) containerSpec {
	switch ext {
	case ".mp4":
		return containerSpec{[]string{"h264", "hevc", "h265", "mpeg4", "av1"}, []string{"aac", "mp3", "ac3", "alac"}, "libx264", "aac"}
	case ".mkv":
		return containerSpec{[]string{"h264", "hevc", "h265", "mpeg4", "vp8", "vp9", "av1", "ffv1"}, []string{"aac", "mp3", "ac3", "dts", "flac", "opus", "vorbis"}, "libx264", "aac"}
	case ".mov":
		return containerSpec{[]string{"h264", "hevc", "h265", "prores"}, []string{"aac", "pcm_s16le"}, "libx264", "aac"}
	case ".avi":
		return containerSpec{[]string{"mpeg4", "h264", "msmpeg4v3"}, []string{"mp3", "pcm_s16le", "ac3"}, "mpeg4", "libmp3lame"}
	case ".webm":
		return containerSpec{[]string{"vp8", "vp9", "av1"}, []string{"opus", "vorbis"}, "libvpx-vp9", "libopus"}
	case ".flv":
		return containerSpec{[]string{"h264", "vp6f", "flv1"}, []string{"aac", "mp3"}, "libx264", "aac"}
	case ".wmv":
		return containerSpec{[]string{"wmv3", "wmv2"}, []string{"wmav2"}, "wmv2", "wmav2"}
	case ".mpeg", ".mpg":
		return containerSpec{[]string{"mpeg1video", "mpeg2video"}, []string{"mp2", "ac3"}, "mpeg2video", "mp2"}
	case ".3gp":
		return containerSpec{[]string{"h263", "h264", "mpeg4"}, []string{"aac", "amr_nb"}, "libx264", "aac"}
	default:
		return containerSpec{[]string{"h264"}, []string{"aac"}, "libx264", "aac"}
	}
}

func appendAudioArgs(args []string, options models.ConversionOptions) []string {
	if value := nonSource(options.AudioBitrate); value != "" {
		args = append(args, "-b:a", value)
	}
	if value := nonSource(options.SampleRate); value != "" {
		args = append(args, "-ar", value)
	}
	if value := nonSource(options.Channels); value != "" {
		args = append(args, "-ac", mapChannels(value))
	}
	return args
}

func chooseAudioCodecForOutput(ext, sourceCodec, selected string) string {
	spec := audioOutputSpec(ext)
	return chooseCodec(selected, sourceCodec, spec.DefaultAudioCodec, spec.AudioCodecs)
}

func audioOutputSpec(ext string) containerSpec {
	switch ext {
	case ".mp3":
		return containerSpec{AudioCodecs: []string{"mp3"}, DefaultAudioCodec: "libmp3lame"}
	case ".flac":
		return containerSpec{AudioCodecs: []string{"flac"}, DefaultAudioCodec: "flac"}
	case ".wav":
		return containerSpec{AudioCodecs: []string{"pcm_s16le"}, DefaultAudioCodec: "pcm_s16le"}
	case ".aac":
		return containerSpec{AudioCodecs: []string{"aac"}, DefaultAudioCodec: "aac"}
	case ".ogg":
		return containerSpec{AudioCodecs: []string{"vorbis", "opus"}, DefaultAudioCodec: "libvorbis"}
	case ".m4a":
		return containerSpec{AudioCodecs: []string{"aac", "alac"}, DefaultAudioCodec: "aac"}
	case ".opus":
		return containerSpec{AudioCodecs: []string{"opus"}, DefaultAudioCodec: "libopus"}
	default:
		return containerSpec{AudioCodecs: []string{"aac"}, DefaultAudioCodec: "aac"}
	}
}

func chooseCodec(selected, sourceCodec, defaultCodec string, allowed []string) string {
	if value := nonSource(selected); value != "" {
		return mapCodecName(value)
	}
	if sourceCodec != "" && codecAllowed(sourceCodec, allowed) {
		return sourceCodec
	}
	return defaultCodec
}

func codecAllowed(codec string, allowed []string) bool {
	normalized := normalizeCodec(codec)
	for _, item := range allowed {
		if normalized == normalizeCodec(item) {
			return true
		}
	}
	return false
}

func normalizeCodec(codec string) string {
	codec = strings.ToLower(strings.TrimSpace(codec))
	codec = strings.TrimPrefix(codec, "lib")
	switch codec {
	case "x264":
		return "h264"
	case "x265":
		return "hevc"
	case "h265":
		return "hevc"
	case "mp3lame":
		return "mp3"
	case "vorbis":
		return "vorbis"
	case "vpx-vp9":
		return "vp9"
	case "vpx":
		return "vp8"
	case "aom-av1":
		return "av1"
	default:
		return codec
	}
}

func nonSource(value string) string {
	if value == "" || strings.EqualFold(value, "source") {
		return ""
	}
	return value
}

func mapResolution(value string) string {
	switch value {
	case "720p":
		return "1280x720"
	case "1080p":
		return "1920x1080"
	case "1440p":
		return "2560x1440"
	case "2160p":
		return "3840x2160"
	default:
		return value
	}
}

func mapChannels(value string) string {
	switch value {
	case "mono":
		return "1"
	case "stereo":
		return "2"
	case "5.1":
		return "6"
	case "7.1":
		return "8"
	default:
		return value
	}
}

func gifFrameRate(options models.ConversionOptions) string {
	if options.GifFrameRate == "custom" {
		return strings.TrimSpace(options.GifFrameRateCustom)
	}
	return nonSource(options.GifFrameRate)
}

func isAudioOutput(outputPath string) bool {
	switch strings.ToLower(filepath.Ext(outputPath)) {
	case ".mp3", ".flac", ".wav", ".aac", ".ogg", ".wma", ".m4a", ".mka", ".opus":
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

func (e *FFmpegEngine) getVideoDuration(ctx context.Context, inputPath string) float64 {
	return e.getStreamDuration(ctx, inputPath, "v:0")
}

func (e *FFmpegEngine) getAudioDuration(ctx context.Context, inputPath string) float64 {
	return e.getStreamDuration(ctx, inputPath, "a:0")
}

func (e *FFmpegEngine) getStreamDuration(ctx context.Context, inputPath, streamSelector string) float64 {
	ffprobePath, err := ResolveBinary("ffprobe")
	if err != nil {
		return 0
	}

	for attempt := 1; attempt <= probeAttempts; attempt++ {
		probeCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
		cmd := exec.CommandContext(
			probeCtx,
			ffprobePath,
			"-v", "error",
			"-select_streams", streamSelector,
			"-show_entries", "stream=duration:format=duration",
			"-of", "json",
			inputPath,
		)
		configureBackgroundCommand(cmd)
		output, commandErr := cmd.Output()
		cancel()
		if commandErr == nil {
			var result struct {
				Streams []struct {
					Duration string `json:"duration"`
				} `json:"streams"`
				Format struct {
					Duration string `json:"duration"`
				} `json:"format"`
			}
			if json.Unmarshal(output, &result) == nil {
				for _, stream := range result.Streams {
					if duration := positiveDuration(stream.Duration); duration > 0 {
						return duration
					}
				}
				if duration := positiveDuration(result.Format.Duration); duration > 0 {
					return duration
				}
			}
		}
		if !sleepBeforeProbeRetry(ctx, attempt) {
			return 0
		}
	}
	return 0
}

func positiveDuration(value string) float64 {
	duration, err := strconv.ParseFloat(strings.TrimSpace(value), 64)
	if err != nil || duration <= 0 {
		return 0
	}
	return duration
}

func estimateOutputSize(inputSize int64, options models.ConversionOptions) int64 {
	if inputSize <= 0 {
		return 1
	}
	quality := options.Quality
	if options.VideoQuality > 0 && options.VideoQuality < quality {
		quality = options.VideoQuality
	}
	if options.AudioQuality > 0 && options.AudioQuality < quality {
		quality = options.AudioQuality
	}
	if options.Lossless || quality >= 100 {
		return inputSize
	}
	if quality <= 0 {
		return inputSize
	}
	estimated := int64(float64(inputSize) * float64(quality) / 100.0)
	if estimated < 1 {
		return 1
	}
	return estimated
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
