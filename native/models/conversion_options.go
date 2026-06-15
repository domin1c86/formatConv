package models

type ConversionOptions struct {
	Lossless             bool   `json:"lossless"`
	Quality              int    `json:"quality"`               // 0-100
	Codec                string `json:"codec"`                 // optional codec preference
	Bitrate              string `json:"bitrate"`               // optional ffmpeg bitrate, such as 192k or 4M
	CompressionAlgorithm string `json:"compression_algorithm"` // optional ImageMagick compression algorithm
	Overwrite            bool   `json:"overwrite"`             // overwrite existing output file
	GPUAcceleration      bool   `json:"gpu_acceleration"`      // use conservative ffmpeg hardware acceleration
}
