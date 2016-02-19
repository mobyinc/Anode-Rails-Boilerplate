class Api::WidgetsController < Api::ApiController
  before_filter :authorize_current_user
  before_filter :find_widget, only: [:show, :update, :destroy]

  def index
    @widgets = acl_role_company(::Widget.all).order('obsolete asc').limit(50)

    render json: @widgets
  end

  def show
    render json: @widget
  end

  def create
    @widget = ::Widget.create(widget_params)
    @widget.user = current_user

    if @widget.save
      render json: @widget
    else
      error_description = @widget.errors.full_messages.join(', ')
      client_error("validation error: #{error_description}")
    end
  end

  def update
    if @widget.update_attributes(widget_params)
      render json: @widget
    else
      client_error('validation error')
    end
  end

  def search
    query = "%#{params[:query]}%" # wrap in wildcards

    @widgets = ::Widget.where('name LIKE ?', query).limit(25)

    render json: @widgets
  end

  def destroy
    @widget.destroy
    head :ok
  end

private

  def widget_params

    params.require(:widget).permit(
      :user_id,
      :name,
      :image
    )
  end

  def find_widget
    @widget = ::Widget.find(params[:id])
    head :not_found if @widget.nil?

    return @widget
  end
end
