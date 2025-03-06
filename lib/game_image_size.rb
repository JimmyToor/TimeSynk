# frozen_string_literal: true

# Defines valid image sizes for game image urls.
# - SCREENSHOT_SMALL
# - SCREENSHOT_BIG
# - SCREENSHOT_HUGE
# - COVER_BIG
# - COVER_SMALL
# - LOGO_MED
# - THUMB
# - MICRO
# - HD
# - FHD
module GameImageSize
  SCREENSHOT_SMALL = "screenshot_small"
  SCREENSHOT_BIG = "screenshot_big"
  SCREENSHOT_HUGE = "screenshot_huge"
  COVER_BIG = "cover_big"
  COVER_SMALL = "cover_small"
  LOGO_MED = "logo_med"
  THUMB = "thumb"
  MICRO = "micro"
  HD = "720p"
  FHD = "1080p"

  # Checks if the given size is a valid image size
  def self.include?(size)
    constants.include?(size)
  end
end
