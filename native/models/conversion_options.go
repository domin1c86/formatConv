package models

type ConversionOptions struct {
	Lossless  bool   `json:"lossless"`
	Quality   int    `json:"quality"`   // 0-100, only for lossy
	Codec     string `json:"codec"`     // optional codec preference
	Overwrite bool   `json:"overwrite"` // overwrite existing output file
}
