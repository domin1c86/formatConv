package converter

import (
	"fmt"
	"path/filepath"
	"strings"

	"native/models"
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
	d.formatMap[".mp4"] = models.FormatInfo{
		Format: "MP4", Type: "video", Extension: ".mp4", MimeType: "video/mp4",
		Properties: map[string]string{
			"codec":                 "H.264/H.265/AV1",
			"audio":                 "AAC/MP3/AC3",
			"max_resolution":        "8K",
			"streaming":             "yes",
			"hardware_acceleration": "yes",
		},
	}
	d.formatMap[".mkv"] = models.FormatInfo{
		Format: "MKV", Type: "video", Extension: ".mkv", MimeType: "video/x-matroska",
		Properties: map[string]string{
			"codec":          "H.264/H.265/VP9/AV1",
			"audio":          "AAC/FLAC/DTS/AC3",
			"max_resolution": "8K",
			"subtitle":       "multi-track",
			"chapter":        "yes",
		},
	}
	d.formatMap[".mov"] = models.FormatInfo{
		Format: "MOV", Type: "video", Extension: ".mov", MimeType: "video/quicktime",
		Properties: map[string]string{
			"codec":          "H.264/ProRes",
			"audio":          "AAC/PCM",
			"max_resolution": "8K",
			"editing":        "optimized",
			"metadata":       "rich",
		},
	}
	d.formatMap[".avi"] = models.FormatInfo{
		Format: "AVI", Type: "video", Extension: ".avi", MimeType: "video/x-msvideo",
		Properties: map[string]string{
			"codec":          "DivX/Xvid/H.264",
			"audio":          "MP3/PCM/AC3",
			"max_resolution": "4K",
			"compatibility":  "legacy",
		},
	}
	d.formatMap[".webm"] = models.FormatInfo{
		Format: "WebM", Type: "video", Extension: ".webm", MimeType: "video/webm",
		Properties: map[string]string{
			"codec":          "VP8/VP9/AV1",
			"audio":          "Vorbis/Opus",
			"max_resolution": "8K",
			"streaming":      "yes",
			"web_support":    "native",
		},
	}

	// Image formats
	d.formatMap[".jpg"] = models.FormatInfo{
		Format: "JPEG", Type: "image", Extension: ".jpg", MimeType: "image/jpeg",
		Properties: map[string]string{
			"color_depth":  "8-bit",
			"transparency": "no",
			"compression":  "lossy",
			"animation":    "no",
			"max_colors":   "16.7M",
		},
	}
	d.formatMap[".jpeg"] = models.FormatInfo{
		Format: "JPEG", Type: "image", Extension: ".jpeg", MimeType: "image/jpeg",
		Properties: map[string]string{
			"color_depth":  "8-bit",
			"transparency": "no",
			"compression":  "lossy",
			"animation":    "no",
			"max_colors":   "16.7M",
		},
	}
	d.formatMap[".png"] = models.FormatInfo{
		Format: "PNG", Type: "image", Extension: ".png", MimeType: "image/png",
		Properties: map[string]string{
			"color_depth":  "8/16-bit",
			"transparency": "yes",
			"compression":  "lossless",
			"animation":    "no",
			"max_colors":   "16.7M+",
		},
	}
	d.formatMap[".webp"] = models.FormatInfo{
		Format: "WebP", Type: "image", Extension: ".webp", MimeType: "image/webp",
		Properties: map[string]string{
			"color_depth":  "8-bit",
			"transparency": "yes",
			"compression":  "lossy/lossless",
			"animation":    "yes",
			"max_colors":   "16.7M",
		},
	}
	d.formatMap[".tiff"] = models.FormatInfo{
		Format: "TIFF", Type: "image", Extension: ".tiff", MimeType: "image/tiff",
		Properties: map[string]string{
			"color_depth":  "8/16/32-bit",
			"transparency": "yes",
			"compression":  "none/LZW/ZIP",
			"animation":    "no",
			"layers":       "yes",
		},
	}
	d.formatMap[".bmp"] = models.FormatInfo{
		Format: "BMP", Type: "image", Extension: ".bmp", MimeType: "image/bmp",
		Properties: map[string]string{
			"color_depth":  "1/4/8/24-bit",
			"transparency": "no",
			"compression":  "none/RLE",
			"animation":    "no",
			"max_colors":   "16.7M",
		},
	}
	d.formatMap[".gif"] = models.FormatInfo{
		Format: "GIF", Type: "image", Extension: ".gif", MimeType: "image/gif",
		Properties: map[string]string{
			"color_depth":  "8-bit",
			"transparency": "yes",
			"compression":  "LZW",
			"animation":    "yes",
			"max_colors":   "256",
		},
	}
	d.formatMap[".ico"] = models.FormatInfo{
		Format: "ICO", Type: "image", Extension: ".ico", MimeType: "image/x-icon",
		Properties: map[string]string{
			"color_depth":  "1/4/8/24/32-bit",
			"transparency": "yes",
			"compression":  "none/PNG",
			"animation":    "no",
			"max_size":     "256px",
		},
	}
	d.formatMap[".svg"] = models.FormatInfo{
		Format: "SVG", Type: "image", Extension: ".svg", MimeType: "image/svg+xml",
		Properties: map[string]string{
			"color_depth":  "N/A",
			"transparency": "yes",
			"compression":  "text/xml",
			"animation":    "yes",
			"scalable":     "yes",
		},
	}

	// Audio formats
	d.formatMap[".mp3"] = models.FormatInfo{
		Format: "MP3", Type: "audio", Extension: ".mp3", MimeType: "audio/mpeg",
		Properties: map[string]string{
			"bitrate":     "8-320 kbps",
			"channels":    "mono/stereo",
			"sample_rate": "8-48 kHz",
			"compression": "lossy",
			"tag_support": "ID3",
		},
	}
	d.formatMap[".flac"] = models.FormatInfo{
		Format: "FLAC", Type: "audio", Extension: ".flac", MimeType: "audio/flac",
		Properties: map[string]string{
			"bitrate":     "variable",
			"channels":    "up to 8",
			"sample_rate": "up to 655.35 kHz",
			"compression": "lossless",
			"tag_support": "Vorbis",
		},
	}
	d.formatMap[".wav"] = models.FormatInfo{
		Format: "WAV", Type: "audio", Extension: ".wav", MimeType: "audio/wav",
		Properties: map[string]string{
			"bitrate":     "uncompressed",
			"channels":    "up to 65535",
			"sample_rate": "up to 4 GHz",
			"compression": "none/PCM",
			"tag_support": "RIFF INFO",
		},
	}
	d.formatMap[".aac"] = models.FormatInfo{
		Format: "AAC", Type: "audio", Extension: ".aac", MimeType: "audio/aac",
		Properties: map[string]string{
			"bitrate":     "8-529 kbps",
			"channels":    "up to 48",
			"sample_rate": "8-96 kHz",
			"compression": "lossy",
			"tag_support": "ID3/MP4",
		},
	}
	d.formatMap[".ogg"] = models.FormatInfo{
		Format: "OGG", Type: "audio", Extension: ".ogg", MimeType: "audio/ogg",
		Properties: map[string]string{
			"bitrate":     "32-500 kbps",
			"channels":    "up to 255",
			"sample_rate": "8-192 kHz",
			"compression": "lossy",
			"tag_support": "Vorbis",
		},
	}
	d.formatMap[".wma"] = models.FormatInfo{
		Format: "WMA", Type: "audio", Extension: ".wma", MimeType: "audio/x-ms-wma",
		Properties: map[string]string{
			"bitrate":     "32-192 kbps",
			"channels":    "up to 6",
			"sample_rate": "8-48 kHz",
			"compression": "lossy/lossless",
			"tag_support": "WMA",
		},
	}
	d.formatMap[".m4a"] = models.FormatInfo{
		Format: "M4A", Type: "audio", Extension: ".m4a", MimeType: "audio/mp4",
		Properties: map[string]string{
			"bitrate":     "8-529 kbps",
			"channels":    "up to 48",
			"sample_rate": "8-96 kHz",
			"compression": "lossy/lossless",
			"tag_support": "iTunes",
		},
	}
	d.formatMap[".mka"] = models.FormatInfo{
		Format: "MKA", Type: "audio", Extension: ".mka", MimeType: "audio/x-matroska",
		Properties: map[string]string{
			"bitrate":     "codec dependent",
			"channels":    "codec dependent",
			"sample_rate": "codec dependent",
			"compression": "lossy/lossless",
			"tag_support": "Matroska",
		},
	}
	d.formatMap[".opus"] = models.FormatInfo{
		Format: "OPUS", Type: "audio", Extension: ".opus", MimeType: "audio/opus",
		Properties: map[string]string{
			"bitrate":     "6-510 kbps",
			"channels":    "up to 255",
			"sample_rate": "8-48 kHz",
			"compression": "lossy",
			"tag_support": "Vorbis",
		},
	}
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
