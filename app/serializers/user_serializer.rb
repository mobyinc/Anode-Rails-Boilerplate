class UserSerializer < ApiSerializer
  attributes :__token, :username, :last_login

  def filter(keys)
    if scope.present?
      keys
    else
      keys - [:__token]
    end
  end

  def __token
    api_key = current_user.api_keys.first
    api_key ? api_key.access_token : nil
  end
end
