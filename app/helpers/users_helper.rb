module UsersHelper
  def user_avatar(user, size_x: 64, size_y: nil, font_size: nil, classes: "")
    size_y ||= size_x
    font_size ||= size_x * 0.5

    if user.avatar.attached?
      image_tag user.avatar.variant(resize_to_fill: [size_x, size_y]), class: "user_avatar #{classes}", style: "width: #{size_x}px; height: #{size_y}px;"
    else
      initials = user.username.split.map(&:first).join[0, 2].upcase
      color = generate_color(user.username)
      render(
        partial: "users/avatar",
        locals:  {
          size_x:    size_x,
          size_y:    size_y,
          color:     color,
          font_size: font_size,
          initials:  initials,
          classes:   classes
        }
      ).html_safe
    end
  end

  private

  def generate_color(name)
    hue = name.bytes.sum % 360
    "hsl(#{hue}, 70%, 50%)"
  end
end