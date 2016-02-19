class Api::ApiController < ActionController::Base

  class ClientError < StandardError
    attr_accessor :message
    attr_accessor :code
    attr_accessor :key

    def initialize(message, code=400, key=nil)
      self.message = message
      self.code = code
      self.key = key || self.message.parameterize('_')
    end
  end

  protect_from_forgery with: :null_session, only: []

  rescue_from Exception, with: :exception_handler
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ClientError, with: :client_error_handler

  before_filter :init
  serialization_scope :current_user

  def app_id
    if request.headers["App-Id"]
      request.headers["App-Id"]
    else
      nil
    end
  end

  def query
    query = prepare_query

    if params[:count_only]
      render json: {count: query.count}
    else
      render json: query.to_a
    end
  end

  def prepare_query
    limit = params[:limit] || 1000
    skip = params[:skip] || 0

    if params[:relationship]
      model = params[:relationship][:type].classify.constantize
      object_id = params[:relationship][:object_id]
      relationship_name = params[:relationship][:name]
      relationship = model.reflect_on_association(relationship_name.to_sym)

      if relationship
        relationship_model = relationship.class_name.constantize
      else
        relationship_model = model
      end

      query = model.find(object_id).send(relationship_name)
    else
      query = @model_name.all
    end

    if params[:predicate]
      left = params[:predicate][:left]
      right = params[:predicate][:right]
      op = params[:predicate][:operator]

      # "in" query
      if op == 'in'
        items = right.gsub!('{', '').gsub!('}', '').split(',')
        query = query.where("#{left} IN (?)", items)
      else
        right.gsub!('"', '')
        query = query.where("#{left} #{op} ?", right)
      end
    end

    if params[:order_by] && params[:order_direction]
      query = query.order("#{params[:order_by]} #{params[:order_direction]}")
    end

    query = query.limit(limit).offset(skip)

    if relationship_model
      query = relationship_model.acl_role_company(query, current_user, app_id)
    else
      query = acl_filter(query)
    end

    return query
  end

private

  def init
    @model_name = controller_name.classify.constantize
    @table_name = controller_name.downcase.pluralize

    authorize
    parse_multipart_params
  end

  def authorize
    authenticate_or_request_with_http_token do |token, options|

      client_error('missing token in request header', 401) if token.nil?

      api_key = ApiKey.find_by_access_token(token)

      if api_key
        @current_user = api_key.user
        return true
      else
        client_error('invalid access token', 401)
      end
    end
  end

  def parse_multipart_params
    if params[:DATA]
      data = JSON.parse(params[:DATA]).with_indifferent_access
      params.deep_merge!(data)
      params.delete :DATA
      puts "multipart-params"
      puts params.inspect
    end
  end

  def required_param(name)
    params[name].blank? ? client_error("missing #{name.to_s.titleize}") : params[name]
  end

  def authorize_current_user
    client_error("#{self.action_name} requires current user", 401, 'login_required') if !current_user
  end

  def acl_filter(query)
    query # optionally implemented by subclasses
  end

  def current_user
    @current_user
  end

  def client_error(message, code=400, key=nil)
    raise ClientError.new(message, code, key)
  end

  def record_not_found
    client_error('not found', 404)
    message = 'record not found'
    logger.warn(message)
    render json: {error: {code: 404, message: message, key: 'not_found'}}, status: 404
    return false
  end

  def exception_handler(e)
    message = "unexpected error: #{e}"
    logger.error(message)
    puts e.backtrace[0] if e.backtrace && e.backtrace.length > 0
    render json: {error: {code: 500, message: message}}, status: :internal_server_error
    return false
  end

  def client_error_handler(e)
    logger.warn(e.message)
    render json: {error: {code: e.code, message: e.message, key: e.key}}, status: e.code
    return false
  end
end
