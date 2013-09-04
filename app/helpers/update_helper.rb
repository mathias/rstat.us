module UpdateHelper
  def current_user_is_author?(update)
    if (current_user &&
        current_user.author &&
        update &&
        update.author)

      current_user.author.id == update.author.id
    end
  end
end
