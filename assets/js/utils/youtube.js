// Builds the YouTube embed URL from a stored video id. Uses the privacy-
// enhanced youtube-nocookie.com domain, but otherwise leaves the player
// standard — full controls, keyboard shortcuts, and fullscreen all work
// normally. See docs/SECURITY.md for why this isn't (and can't be) real
// video DRM.

export function buildEmbedUrl(videoId, { autoplay = false } = {}) {
  const params = new URLSearchParams({
    rel: '0',              // don't show related videos from other channels
    modestbranding: '1',   // minimal YouTube logo
    controls: '1',
    fs: '1',
    playsinline: '1',
    autoplay: autoplay ? '1' : '0',
  });
  // youtube-nocookie.com avoids setting tracking cookies until playback starts.
  return `https://www.youtube-nocookie.com/embed/${encodeURIComponent(videoId)}?${params.toString()}`;
}
