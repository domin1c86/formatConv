package models

type ConversionStatus struct {
	ConversionID   uintptr `json:"conversion_id"`
	Status         string  `json:"status"`   // pending, processing, completed, failed, cancelled
	Progress       float64 `json:"progress"` // 0.0 - 1.0
	ProcessedBytes int64   `json:"processed_bytes"`
	TotalBytes     int64   `json:"total_bytes"`
	Error          string  `json:"error,omitempty"`
	OutputPath     string  `json:"output_path"`
	Mode           string  `json:"mode,omitempty"`          // remux, cpu_encode, gpu_encode, audio_encode, gif_encode
	VideoEncoder   string  `json:"video_encoder,omitempty"` // copy, libx264, h264_nvenc, etc.
	ProbeWarning   string  `json:"probe_warning,omitempty"`
}

type ConversionExecutionInfo struct {
	Mode         string
	VideoEncoder string
	ProbeWarning string
	OutputPath   string
}
