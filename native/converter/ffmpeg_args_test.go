package converter

import (
	"reflect"
	"strings"
	"testing"

	"native/models"
)

func TestBuildArgsWithInfo_RemuxHevcFlacMkvCopiesStreams(t *testing.T) {
	engine := NewFFmpegEngine()
	args, usedHardware := engine.buildArgsWithInfo(
		"input.mkv",
		"output.mkv",
		models.ConversionOptions{GPUAcceleration: true},
		true,
		map[string]bool{"hevc_nvenc": true},
		mediaInfo{
			Video: mediaStreamInfo{Codec: "hevc", Width: 1920, Height: 1080},
			Audio: mediaStreamInfo{Codec: "flac", SampleRate: "48000", Channels: 2},
		},
	)

	want := []string{"-i", "input.mkv", "-map", "0", "-c:v", "copy", "-c:a", "copy", "output.mkv"}
	if !reflect.DeepEqual(args, want) {
		t.Fatalf("unexpected args:\n got: %#v\nwant: %#v", args, want)
	}
	if usedHardware {
		t.Fatal("pure remux should not use hardware encoding")
	}
}

func TestBuildArgsWithInfo_ProbeFailureUsesCopyOnly(t *testing.T) {
	engine := NewFFmpegEngine()
	args, usedHardware := engine.buildArgsWithInfo(
		"input.mkv",
		"output.mkv",
		models.ConversionOptions{GPUAcceleration: true},
		true,
		map[string]bool{"h264_nvenc": true},
		mediaInfo{},
	)

	want := []string{"-i", "input.mkv", "-map", "0", "-c", "copy", "output.mkv"}
	if !reflect.DeepEqual(args, want) {
		t.Fatalf("unexpected args:\n got: %#v\nwant: %#v", args, want)
	}
	if usedHardware {
		t.Fatal("probe-failure remux should not use hardware encoding")
	}
}

func TestBuildArgsWithInfo_ProbeFailureForceVideoKeepsAudioCopy(t *testing.T) {
	engine := NewFFmpegEngine()
	args, usedHardware := engine.buildArgsWithInfo(
		"input.mkv",
		"output.mkv",
		models.ConversionOptions{
			ForceVideoReencode: true,
			GPUAcceleration:    true,
		},
		true,
		map[string]bool{"h264_nvenc": true},
		mediaInfo{},
	)

	want := []string{"-hwaccel", "auto", "-i", "input.mkv", "-map", "0", "-c:v", "h264_nvenc", "-c:a", "copy", "output.mkv"}
	if !reflect.DeepEqual(args, want) {
		t.Fatalf("unexpected args:\n got: %#v\nwant: %#v", args, want)
	}
	if !usedHardware {
		t.Fatal("forced video reencode should use available hardware encoder")
	}
}

func TestBuildArgsWithInfo_ProbeFailureForceAudioKeepsVideoCopy(t *testing.T) {
	engine := NewFFmpegEngine()
	args, usedHardware := engine.buildArgsWithInfo(
		"input.mkv",
		"output.mkv",
		models.ConversionOptions{
			ForceAudioReencode: true,
			GPUAcceleration:    true,
		},
		true,
		map[string]bool{"h264_nvenc": true},
		mediaInfo{},
	)

	want := []string{"-i", "input.mkv", "-map", "0", "-c:v", "copy", "-c:a", "aac", "output.mkv"}
	if !reflect.DeepEqual(args, want) {
		t.Fatalf("unexpected args:\n got: %#v\nwant: %#v", args, want)
	}
	if usedHardware {
		t.Fatal("audio-only reencode should not use hardware video encoder")
	}
}

func TestBuildArgsWithInfo_ProbeFailureGpuDoesNotUseHardwareWithoutForce(t *testing.T) {
	engine := NewFFmpegEngine()
	args, usedHardware := engine.buildArgsWithInfo(
		"input.mkv",
		"output.mkv",
		models.ConversionOptions{GPUAcceleration: true},
		true,
		map[string]bool{"h264_nvenc": true},
		mediaInfo{},
	)

	want := []string{"-i", "input.mkv", "-map", "0", "-c", "copy", "output.mkv"}
	if !reflect.DeepEqual(args, want) {
		t.Fatalf("unexpected args:\n got: %#v\nwant: %#v", args, want)
	}
	if usedHardware {
		t.Fatal("probe-failure copy path should not use hardware")
	}
}

func TestBuildArgsWithInfo_IncompatibleAudioReencodesOnlyAudio(t *testing.T) {
	engine := NewFFmpegEngine()
	args, usedHardware := engine.buildArgsWithInfo(
		"input.mkv",
		"output.mp4",
		models.ConversionOptions{GPUAcceleration: true},
		true,
		map[string]bool{"hevc_nvenc": true},
		mediaInfo{
			Video: mediaStreamInfo{Codec: "hevc"},
			Audio: mediaStreamInfo{Codec: "flac"},
		},
	)

	want := []string{"-i", "input.mkv", "-map", "0", "-c:v", "copy", "-c:a", "aac", "output.mp4"}
	if !reflect.DeepEqual(args, want) {
		t.Fatalf("unexpected args:\n got: %#v\nwant: %#v", args, want)
	}
	if usedHardware {
		t.Fatal("video copy with audio-only reencode should not use hardware encoding")
	}
}

func TestBuildCommandWithInfo_ForcedVideoReportsGpuEncoder(t *testing.T) {
	engine := NewFFmpegEngine()
	command := engine.buildCommandWithInfo(
		"input.mkv",
		"output.mp4",
		models.ConversionOptions{
			ForceVideoReencode: true,
			GPUAcceleration:    true,
		},
		true,
		map[string]bool{"hevc_nvenc": true},
		mediaInfo{
			Video: mediaStreamInfo{Codec: "hevc"},
			Audio: mediaStreamInfo{Codec: "aac"},
		},
	)

	want := []string{"-hwaccel", "auto", "-i", "input.mkv", "-map", "0", "-c:v", "hevc_nvenc", "-c:a", "copy", "output.mp4"}
	if !reflect.DeepEqual(command.Args, want) {
		t.Fatalf("unexpected args:\n got: %#v\nwant: %#v", command.Args, want)
	}
	if command.Mode != "gpu_encode" {
		t.Fatalf("expected gpu_encode mode, got %q", command.Mode)
	}
	if command.VideoEncoder != "hevc_nvenc" {
		t.Fatalf("expected hevc_nvenc encoder, got %q", command.VideoEncoder)
	}
}

func TestBuildCommandWithInfo_RemuxReportsCopyMode(t *testing.T) {
	engine := NewFFmpegEngine()
	command := engine.buildCommandWithInfo(
		"input.mkv",
		"output.mkv",
		models.ConversionOptions{GPUAcceleration: true},
		true,
		map[string]bool{"hevc_nvenc": true},
		mediaInfo{
			Video: mediaStreamInfo{Codec: "hevc"},
			Audio: mediaStreamInfo{Codec: "flac"},
		},
	)

	if command.Mode != "remux" {
		t.Fatalf("expected remux mode, got %q", command.Mode)
	}
	if command.VideoEncoder != "copy" {
		t.Fatalf("expected copy video encoder, got %q", command.VideoEncoder)
	}
	if command.UsedHardware {
		t.Fatal("remux command must not use hardware")
	}
}

func TestBuildGifArgs_DefaultsToFifteenFpsAndCappedWidth(t *testing.T) {
	engine := NewFFmpegEngine()
	// All GIF options left on the default "source" sentinel: must NOT inherit
	// the source video's high frame rate / resolution, which would make the
	// 256-color per-frame GIF many times larger than the compressed input.
	args := engine.buildGifArgs(models.ConversionOptions{})
	joined := strings.Join(args, " ")
	if !strings.Contains(joined, "fps=15") {
		t.Fatalf("default GIF args must cap frame rate at 15fps, got: %v", args)
	}
	if !strings.Contains(joined, "scale=480:-1:flags=lanczos") {
		t.Fatalf("default GIF args must cap width to 480px, got: %v", args)
	}
	if !strings.Contains(joined, "palettegen=max_colors=256") {
		t.Fatalf("default GIF args must keep 256 colors, got: %v", args)
	}
	if !strings.Contains(joined, "paletteuse=dither=sierra2_4a") {
		t.Fatalf("default GIF args must keep default dither, got: %v", args)
	}
	// Regression guard: the palette split chain must be joined to the scale
	// filter with a comma. Without it "flags=lanczos" + "split" fuses into
	// "flags=lanczossplit", which ffmpeg rejects as an unknown sws_flags
	// constant and aborts the whole GIF conversion.
	if !strings.Contains(joined, "flags=lanczos,split[s0][s1]") {
		t.Fatalf("scale flags and split chain must be comma-separated, got: %v", args)
	}
	if strings.Contains(joined, "lanczossplit") {
		t.Fatalf("lanczos and split must not be fused (missing comma), got: %v", args)
	}
}

func TestBuildGifArgs_RespectsExplicitFrameRateAndScale(t *testing.T) {
	engine := NewFFmpegEngine()
	args := engine.buildGifArgs(models.ConversionOptions{
		GifFrameRate: "30",
		GifScale:     "720:-1",
		GifMaxColors: "128",
	})
	joined := strings.Join(args, " ")
	if !strings.Contains(joined, "fps=30") {
		t.Fatalf("explicit fps=30 must be honored, got: %v", args)
	}
	if strings.Contains(joined, "fps=15") {
		t.Fatalf("default fps must not override explicit fps, got: %v", args)
	}
	if !strings.Contains(joined, "scale=720:-1:flags=lanczos") {
		t.Fatalf("explicit scale must be honored, got: %v", args)
	}
	if strings.Contains(joined, "scale=480:-1") {
		t.Fatalf("default scale must not override explicit scale, got: %v", args)
	}
	if !strings.Contains(joined, "palettegen=max_colors=128") {
		t.Fatalf("explicit max_colors must be honored, got: %v", args)
	}
}

func TestBuildCommandWithInfo_GifUsesSafeDefaults(t *testing.T) {
	engine := NewFFmpegEngine()
	command := engine.buildCommandWithInfo(
		"input.mp4",
		"output.gif",
		models.ConversionOptions{},
		false,
		nil,
		mediaInfo{Video: mediaStreamInfo{Codec: "h264", FrameRate: "60000/1001"}},
	)
	joined := strings.Join(command.Args, " ")
	if command.Mode != "gif_encode" {
		t.Fatalf("expected gif_encode mode, got %q", command.Mode)
	}
	if !strings.Contains(joined, "fps=15") || !strings.Contains(joined, "scale=480:-1") {
		t.Fatalf("mp4->gif with defaults must cap fps and width, got: %v", command.Args)
	}
}

func TestParseFFmpegInputProbe(t *testing.T) {
	output := `Input #0, matroska,webm, from 'input.mkv':
  Stream #0:0: Video: hevc (Main 10), yuv420p10le(tv), 1920x1080, 29.97 fps, 29.97 tbr
  Stream #0:1: Audio: flac, 48000 Hz, stereo, s16`

	info := parseFFmpegInputProbe(output)
	if info.Video.Codec != "hevc" {
		t.Fatalf("expected video codec hevc, got %q", info.Video.Codec)
	}
	if info.Video.Width != 1920 || info.Video.Height != 1080 {
		t.Fatalf("unexpected dimensions: %dx%d", info.Video.Width, info.Video.Height)
	}
	if info.Audio.Codec != "flac" {
		t.Fatalf("expected audio codec flac, got %q", info.Audio.Codec)
	}
	if info.Audio.SampleRate != "48000" || info.Audio.Channels != 2 {
		t.Fatalf("unexpected audio info: sample_rate=%q channels=%d", info.Audio.SampleRate, info.Audio.Channels)
	}
}
