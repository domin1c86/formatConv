class FormatDescription {
  final String name;
  final String description;
  final List<String> features;

  const FormatDescription({
    required this.name,
    required this.description,
    required this.features,
  });
}

const Map<String, FormatDescription> formatDescriptions = {
  // Video formats
  'MP4': FormatDescription(
    name: 'MP4',
    description:
        'Most widely supported video format. Good compression with broad compatibility.',
    features: [
      'H.264/H.265 codec',
      'Streaming support',
      'Wide device compatibility',
      'Hardware acceleration'
    ],
  ),
  'MKV': FormatDescription(
    name: 'MKV',
    description:
        'Open container format supporting multiple audio/video tracks and subtitles.',
    features: [
      'Multiple audio tracks',
      'Subtitle support',
      'Chapter markers',
      'No format restrictions'
    ],
  ),
  'MOV': FormatDescription(
    name: 'MOV',
    description: 'Apple QuickTime format, native to macOS and iOS devices.',
    features: [
      'Apple ecosystem native',
      'ProRes support',
      'High quality editing',
      'Metadata rich'
    ],
  ),
  'AVI': FormatDescription(
    name: 'AVI',
    description:
        'Legacy Microsoft format with wide compatibility but larger file sizes.',
    features: [
      'Universal compatibility',
      'Simple structure',
      'No compression overhead',
      'Legacy support'
    ],
  ),
  'WebM': FormatDescription(
    name: 'WebM',
    description:
        'Open web-optimized format by Google, ideal for online streaming.',
    features: [
      'VP8/VP9/AV1 codec',
      'Web optimized',
      'Royalty free',
      'HTML5 native'
    ],
  ),
  'FLV': FormatDescription(
    name: 'FLV',
    description: 'Flash Video format, legacy web streaming format.',
    features: [
      'Small file size',
      'Web streaming',
      'Legacy support',
      'H.264 support'
    ],
  ),
  'WMV': FormatDescription(
    name: 'WMV',
    description: 'Windows Media Video format optimized for Windows ecosystem.',
    features: [
      'Windows native',
      'DRM support',
      'Good compression',
      'WMP compatible'
    ],
  ),
  'MPEG': FormatDescription(
    name: 'MPEG',
    description: 'Standard broadcast video format with broad compatibility.',
    features: [
      'Broadcast standard',
      'DVD compatible',
      'Wide support',
      'Reliable format'
    ],
  ),
  '3GP': FormatDescription(
    name: '3GP',
    description: 'Mobile-optimized format for older mobile devices.',
    features: [
      'Small file size',
      'Mobile optimized',
      'Low bandwidth',
      'MMS compatible'
    ],
  ),
  // Image formats
  'JPEG': FormatDescription(
    name: 'JPEG',
    description:
        'Lossy compressed format, ideal for photographs and web images.',
    features: [
      'Lossy compression',
      'Small file size',
      'Universal support',
      'EXIF metadata'
    ],
  ),
  'JPG': FormatDescription(
    name: 'JPG',
    description:
        'Common JPEG file extension for photographs and web images.',
    features: [
      'Lossy compression',
      'Small file size',
      'Universal support',
      'EXIF metadata'
    ],
  ),
  'PNG': FormatDescription(
    name: 'PNG',
    description:
        'Lossless format with transparency support, ideal for graphics and screenshots.',
    features: [
      'Lossless compression',
      'Alpha transparency',
      'Sharp edges',
      'Web standard'
    ],
  ),
  'WebP': FormatDescription(
    name: 'WebP',
    description:
        'Modern format by Google with superior compression for web use.',
    features: [
      'Smaller than JPEG/PNG',
      'Lossy & lossless',
      'Alpha support',
      'Animation support'
    ],
  ),
  'TIFF': FormatDescription(
    name: 'TIFF',
    description: 'Professional lossless format for print and archival.',
    features: [
      'Lossless quality',
      'Print ready',
      'Layer support',
      'Metadata rich'
    ],
  ),
  'BMP': FormatDescription(
    name: 'BMP',
    description:
        'Uncompressed Windows bitmap format, large file size but no quality loss.',
    features: [
      'No compression',
      'Pixel perfect',
      'Windows native',
      'Simple format'
    ],
  ),
  'GIF': FormatDescription(
    name: 'GIF',
    description: 'Animated format with limited 256-color palette.',
    features: [
      'Animation support',
      '256 colors',
      'Transparency',
      'Web animations'
    ],
  ),
  'ICO': FormatDescription(
    name: 'ICO',
    description: 'Windows icon format for favicons and application icons.',
    features: [
      'Multi-size icons',
      'Windows native',
      'Favicon support',
      '16-256px'
    ],
  ),
  'SVG': FormatDescription(
    name: 'SVG',
    description: 'Scalable vector format for icons and illustrations.',
    features: [
      'Infinitely scalable',
      'Small file size',
      'CSS styleable',
      'Animation support'
    ],
  ),
  // Audio formats
  'MP3': FormatDescription(
    name: 'MP3',
    description:
        'Most popular lossy audio format with universal device support.',
    features: [
      'Lossy compression',
      'Universal support',
      'ID3 tags',
      'Streaming friendly'
    ],
  ),
  'FLAC': FormatDescription(
    name: 'FLAC',
    description: 'Lossless audio compression, preserves original quality.',
    features: [
      'Lossless quality',
      '50-60% of original size',
      'Metadata support',
      'Audiophile standard'
    ],
  ),
  'WAV': FormatDescription(
    name: 'WAV',
    description: 'Uncompressed audio format, studio quality, large file size.',
    features: [
      'No compression',
      'Studio quality',
      'Universal support',
      'Simple format'
    ],
  ),
  'AAC': FormatDescription(
    name: 'AAC',
    description: 'Advanced audio codec, successor to MP3 with better quality.',
    features: [
      'Better than MP3',
      'Apple default',
      'Streaming standard',
      'DRM capable'
    ],
  ),
  'OGG': FormatDescription(
    name: 'OGG',
    description: 'Open source audio format with excellent compression.',
    features: [
      'Open source',
      'Vorbis/Opus codec',
      'Game audio standard',
      'Patent free'
    ],
  ),
  'WMA': FormatDescription(
    name: 'WMA',
    description: 'Windows Media Audio format for Windows ecosystem.',
    features: [
      'Windows native',
      'DRM support',
      'Good compression',
      'WMP compatible'
    ],
  ),
  'M4A': FormatDescription(
    name: 'M4A',
    description: 'Apple audio format using AAC codec in MP4 container.',
    features: [
      'Apple ecosystem',
      'AAC codec',
      'iTunes compatible',
      'Metadata rich'
    ],
  ),
  'OPUS': FormatDescription(
    name: 'OPUS',
    description: 'Modern open codec optimized for internet streaming and VoIP.',
    features: [
      'Best compression',
      'Low latency',
      'WebRTC standard',
      'Open source'
    ],
  ),
};

const Map<String, List<String>> formatCodecs = {
  // Video
  'MP4': ['H.264', 'H.265/HEVC', 'MPEG-4'],
  'MKV': ['H.264', 'H.265/HEVC', 'VP8', 'VP9', 'AV1'],
  'MOV': ['H.264', 'H.265/HEVC', 'ProRes'],
  'AVI': ['MPEG-4', 'DivX', 'Xvid'],
  'WebM': ['VP8', 'VP9', 'AV1'],
  'FLV': ['H.264', 'VP6'],
  'WMV': ['WMV3', 'WMV9'],
  'MPEG': ['MPEG-2', 'MPEG-4'],
  '3GP': ['H.263', 'H.264', 'MPEG-4'],
  // Image
  'JPEG': ['Baseline', 'Progressive'],
  'JPG': ['Baseline', 'Progressive'],
  'PNG': ['Deflate'],
  'WebP': ['Lossy', 'Lossless'],
  'TIFF': ['LZW', 'Deflate', 'Uncompressed'],
  // Audio
  'MP3': ['CBR', 'VBR', 'ABR'],
  'FLAC': ['FLAC'],
  'WAV': ['PCM', 'ADPCM'],
  'AAC': ['AAC-LC', 'HE-AAC', 'AAC-LD'],
  'OGG': ['Vorbis', 'Opus'],
  'WMA': ['WMA Standard', 'WMA Pro', 'WMA Lossless'],
  'M4A': ['AAC', 'ALAC'],
  'OPUS': ['Opus'],
};
