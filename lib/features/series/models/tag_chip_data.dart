/// A single tag chip, with everything the chip needs to paint resolved ahead of
/// time.
///
/// Resolving a tag's path/id through [MetadataService] and splitting it into
/// display parts used to happen inside the chip's `build`, so every rebuild of
/// the tags section re-did that work for every chip. The tags section now
/// resolves each tag once, off the first frame, and hands the chips this.
class TagChipData {
  /// Raw tag name as it appears on the series — what tap callbacks expect.
  final String tag;

  /// Resolved filter id for the tag, falling back to [tag] when unknown.
  final String tagId;

  /// Display label already split on ' > '; the last part is the tag itself and
  /// any leading parts are rendered as a muted breadcrumb prefix.
  final List<String> labelParts;

  const TagChipData({
    required this.tag,
    required this.tagId,
    required this.labelParts,
  });
}
