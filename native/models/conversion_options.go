package models

type ConversionOptions struct {
	Lossless             bool   `json:"lossless"`
	Quality              int    `json:"quality"`               // 0-100
	Codec                string `json:"codec"`                 // optional codec preference
	Bitrate              string `json:"bitrate"`               // optional ffmpeg bitrate, such as 192k or 4M
	CompressionAlgorithm string `json:"compression_algorithm"` // optional ImageMagick compression algorithm
	Overwrite            bool   `json:"overwrite"`             // overwrite existing output file
	GPUAcceleration      bool   `json:"gpu_acceleration"`      // use conservative ffmpeg hardware acceleration
	AudioQuality         int    `json:"audio_quality"`
	AudioCodec           string `json:"audio_codec"`
	AudioBitrate         string `json:"audio_bitrate"`
	SampleRate           string `json:"sample_rate"`
	Channels             string `json:"channels"`
	ImageQuality         int    `json:"image_quality"`
	ImageScalePercent    int    `json:"image_scale_percent"`
	ColorSpace           string `json:"color_space"`
	PreserveMetadata     bool   `json:"preserve_metadata"`
	ForceVideoReencode   bool   `json:"force_video_reencode"`
	ForceAudioReencode   bool   `json:"force_audio_reencode"`
	VideoQuality         int    `json:"video_quality"`
	VideoCodec           string `json:"video_codec"`
	Resolution           string `json:"resolution"`
	VideoBitrate         string `json:"video_bitrate"`
	FrameRate            string `json:"frame_rate"`
	GifFrameRate         string `json:"gif_frame_rate"`
	GifFrameRateCustom   string `json:"gif_frame_rate_custom"`
	GifScale             string `json:"gif_scale"`
	GifMaxColors         string `json:"gif_max_colors"`
	GifDitherAlgorithm   string `json:"gif_dither_algorithm"`
	GifLoopMode          string `json:"gif_loop_mode"`
}
