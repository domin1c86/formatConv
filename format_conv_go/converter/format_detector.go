package converter

import (
	"fmt"
	"path/filepath"
	"strings"

	"format_conv_go/models"
)

type FormatDetector struct {
	formatMap map[string]models.FormatInfo
}

func NewFormatDetector() *FormatDetector {
	d := &FormatDetector{
		formatMap: make(map[string]models.FormatInfo),
	}
	d.initFormats()
	return d
}

func (d *FormatDetector) initFormats() {
	// Video formats
	d.formatMap[".mp4"] = models.FormatInfo{Format: "MP4", Type: "video", Extension: ".mp4", MimeType: "video/mp4"}
	d.formatMap[".mkv"] = models.FormatInfo{Format: "MKV", Type: "video", Extension: ".mkv", MimeType: "video/x-matroska"}
	d.formatMap[".mov"] = models.FormatInfo{Format: "MOV", Type: "video", Extension: ".mov", MimeType: "video/quicktime"}
	d.formatMap[".avi"] = models.FormatInfo{Format: "AVI", Type: "video", Extension: ".avi", MimeType: "video/x-msvideo"}
	d.formatMap[".webm"] = models.FormatInfo{Format: "WebM", Type: "video", Extension: ".webm", MimeType: "video/webm"}

	// Image formats
	d.formatMap[".jpg"] = models.FormatInfo{Format: "JPEG", Type: "image", Extension: ".jpg", MimeType: "image/jpeg"}
	d.formatMap[".jpeg"] = models.FormatInfo{Format: "JPEG", Type: "image", Extension: ".jpeg", MimeType: "image/jpeg"}
	d.formatMap[".png"] = models.FormatInfo{Format: "PNG", Type: "image", Extension: ".png", MimeType: "image/png"}
	d.formatMap[".webp"] = models.FormatInfo{Format: "WebP", Type: "image", Extension: ".webp", MimeType: "image/webp"}
	d.formatMap[".tiff"] = models.FormatInfo{Format: "TIFF", Type: "image", Extension: ".tiff", MimeType: "image/tiff"}

	// Audio formats
	d.formatMap[".mp3"] = models.FormatInfo{Format: "MP3", Type: "audio", Extension: ".mp3", MimeType: "audio/mpeg"}
	d.formatMap[".flac"] = models.FormatInfo{Format: "FLAC", Type: "audio", Extension: ".flac", MimeType: "audio/flac"}
	d.formatMap[".wav"] = models.FormatInfo{Format: "WAV", Type: "audio", Extension: ".wav", MimeType: "audio/wav"}
	d.formatMap[".aac"] = models.FormatInfo{Format: "AAC", Type: "audio", Extension: ".aac", MimeType: "audio/aac"}
	d.formatMap[".ogg"] = models.FormatInfo{Format: "OGG", Type: "audio", Extension: ".ogg", MimeType: "audio/ogg"}
}

func (d *FormatDetector) DetectFormat(filePath string) (*models.FormatInfo, error) {
	ext := strings.ToLower(filepath.Ext(filePath))
	if info, ok := d.formatMap[ext]; ok {
		return &info, nil
	}
	return nil, fmt.Errorf("unsupported format: %s", ext)
}

func (d *FormatDetector) GetSupportedFormats() *models.FormatList {
	list := &models.FormatList{}
	for _, info := range d.formatMap {
		switch info.Type {
		case "video":
			list.VideoFormats = append(list.VideoFormats, info)
		case "image":
			list.ImageFormats = append(list.ImageFormats, info)
		case "audio":
			list.AudioFormats = append(list.AudioFormats, info)
		}
	}
	return list
}
