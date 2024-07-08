module UsersHelper

  def user_avatar(user, sizeX = 50, sizeY = nil)
    if user.avatar.attached?
      image_tag user.avatar.variant(resize_to_fill: [sizeX, sizeY]), class: "avatar"
    else
      "No avatar"
      #image_tag 'default_avatar.jpg', class: 'avatar'
    end
  end

end
