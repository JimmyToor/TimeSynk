module UsersHelper

  def user_avatar(user, sizeX = 50, sizeY = nil)
    if user.avatar.attached?
      image_tag user.avatar.variant(resize_to_fill: [sizeX, sizeY]), class: "avatar"
    else
      #"no avatar"
      inline_svg_tag "icons/default_avatar.svg", size: "#{sizeX}x#{sizeY}", class: "avatar"
    end
  end

end
