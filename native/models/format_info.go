package models

type FormatInfo struct {
	Format     string            `json:"format"`
	Type       string            `json:"type"` // video, image, audio
	Extension  string            `json:"extension"`
	MimeType   string            `json:"mime_type"`
	Properties map[string]string `json:"properties"`
}

type FormatList struct {
	VideoFormats []FormatInfo `json:"video_formats"`
	ImageFormats []FormatInfo `json:"image_formats"`
	AudioFormats []FormatInfo `json:"audio_formats"`
}
