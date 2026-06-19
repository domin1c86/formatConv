package models

type MediaOperationOptions struct {
	Operation         string   `json:"operation"`
	SplitVideo        bool     `json:"split_video"`
	SplitAudio        bool     `json:"split_audio"`
	AutoMerge         bool     `json:"auto_merge"`
	RemoveSourceAudio bool     `json:"remove_source_audio"`
	Inputs            []string `json:"inputs"`
	OutputDirectory   string   `json:"output_directory"`
	OutputPath        string   `json:"output_path"`
	Overwrite         bool     `json:"overwrite"`
}
