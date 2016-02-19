class Api::UsersController < Api::ApiController
  before_filter :find_user, only: [:show, :update, :generate_token]
  skip_before_filter :init, only: [:validate_token]

  def create
    @user = ::User.new(user_params)

    @user.password_confirmation = @user.password

    if @user.save
      render json: @user
    else
      error_description = @user.errors.full_messages.join(', ')
      client_error error_description, 400, 'user_validation_error'
    end
  end

  def update
    authorize_current_user
    client_error("not allowed", 401) if current_user.id != @user.id

    @user.assign_attributes(user_params)

    @user.password_confirmation = @user.password if (@user.password)

    if @user.save
      render json: @user
    else
      error_description = @user.errors.full_messages.join(', ')
      client_error error_description, 400, 'user_validation_error'
    end
  end

  def login
    if params[:username]
      @user = ::User.find_by_username(params[:username])

      if @user && @user.authenticate(params[:password])
        @current_user = @user
        render json: @user
      else
        client_error "invalid login information", 400, "invalid_login_info"
      end
    elsif current_user
      current_user.last_login = DateTime.now
      current_user.save!
      render json: current_user
    else
      client_error "missing login information", 400, "invalid_login_info"
    end
  end

  def reset_password
    username = required_param(:username)
    @user = ::User.find_by_username(username)

    if @user
      @user.reset_password!

      head :ok
    else
      client_error("no user with username #{username}", 400, 'password_reset_username_not_found')
    end
  end

  def register_device_token
    authorize_current_user
    client_error("missing device token") if !params[:device_token]

    device_token = params[:device_token]
    platform = params[:platform] || "iOS"
    installation = Installation.find_by_device_token(device_token)

    if installation
      installation.user = current_user
      installation.save!
    else
      installation = Installation.create(device_token: device_token, user: current_user, platform: platform)
    end

    render json: installation
  end

  def generate_token
    client_error('not allowed', 401) unless @user.id == current_user.id
    @user.generate_token!
    render json: { token: @user.token }
  end

  def validate_token
    token = Token.find_by_value(params[:token])
    client_error('not allowed', 401) unless token
    token.destroy
    client_error('not allowed', 401) if token.expires_at < Time.now
    client_error('not allowed', 401) if token.user.status == User::STATUS_INACTIVE

    render json: { id: token.user.id, email: token.user.email, first_name: token.user.first_name, last_name: token.user.last_name }
  end

  def index
    client_error('not allowed', 401)
  end

  def show
    client_error('not allowed', 401) if @user.id != current_user.id
    render json: @user
  end

private

  def find_user
    @user = ::User.find(params[:id])
  end

  def user_params
    params.require(:user).permit( :username,
                                  :password)
  end
end
