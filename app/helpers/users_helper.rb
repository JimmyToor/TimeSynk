module UsersHelper
  def user_avatar(user, size_x: 64, size_y: nil, font_size: nil, classes: "", svg_icon: nil)
    size_y ||= size_x
    font_size ||= size_x * 0.5

    avatar = if user.avatar.attached?
      image_tag(user.avatar.variant(resize_to_fill: [size_x, size_y]),
        title: "#{user.username} Avatar",
        class: "user_avatar #{classes}",
        style: "width: #{size_x}px; height: #{size_y}px;",
        alt: user.username,
        aria: {hidden: true})
    else
      initials = user.username.split.map(&:first).join[0, 2].upcase
      color = generate_color(user.username, seed: user.id)
      render(
        partial: "users/avatar",
        locals: {
          size_x: size_x,
          size_y: size_y,
          color: color,
          font_size: font_size,
          initials: initials,
          classes: classes,
          title: "#{user.username} Avatar"
        }
      ).html_safe
    end

    if svg_icon
      content_tag :div, class: "avatar-container relative #{classes} w-#{size_x}px h-#{size_y}px", "aria-hidden": true do
        avatar + image_tag("icons/#{svg_icon}", class: "absolute", style: "bottom: -#{size_y / 4}px; right: 0; width: #{size_x / 1.5}px; height: #{size_x / 1.5}px;")
      end
    else
      avatar
    end
  end

  def username_with_resource_role_icons(user, resource)
    content_tag :div, class: "relative inline-flex" do
      highest_role = user.most_permissive_cascading_role_for_resource(resource)
      unless highest_role.nil? || RoleHierarchy.role_weight(highest_role) >= RoleHierarchy::NON_PERMISSIVE_WEIGHT
        title = highest_role.resource_type.titleize + " " + highest_role.name.titleize
        concat(inline_svg("icons/star.svg", class: "absolute -left-4 h-3", title: title))
      end
      concat(content_tag(:span, user.username, class: "whitespace-break-spaces", title: user.username))
    end
  end

  private

  def generate_color(name, seed: 0)
    hue = (name.bytes.sum + seed * 15) % 360
    "hsl(#{hue}, 70%, 50%)"
  end
end
