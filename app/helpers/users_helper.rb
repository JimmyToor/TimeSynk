module UsersHelper
  def user_avatar(user, size_x: 64, size_y: nil, font_size: nil, classes: "", svg_icon: nil)
    size_y ||= size_x
    font_size ||= size_x * 0.5

    avatar = if user.avatar.attached?
      image_tag user.avatar.variant(resize_to_fill: [size_x, size_y]), class: "user_avatar #{classes}", style: "width: #{size_x}px; height: #{size_y}px;"
    else
      initials = user.username.split.map(&:first).join[0, 2].upcase
      color = generate_color(user.username)
      render(
        partial: "users/avatar",
        locals: {
          size_x: size_x,
          size_y: size_y,
          color: color,
          font_size: font_size,
          initials: initials,
          classes: classes
        }
      ).html_safe
    end

    if svg_icon
      content_tag :div, class: "avatar-container relative #{classes} w-#{size_x}px h-#{size_y}px" do
        avatar + image_tag("icons/#{svg_icon}", class: "checkmark absolute", style: "bottom: -#{size_y / 4}px; right: 0; width: #{size_x/1.5}px; height: #{size_x/1.5}px;")
      end
    else
      avatar
    end
  end

  private

  def generate_color(name)
    hue = name.bytes.sum % 360
    "hsl(#{hue}, 70%, 50%)"
  end
end