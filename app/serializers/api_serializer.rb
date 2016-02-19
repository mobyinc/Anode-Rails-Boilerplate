class ApiSerializer < ActiveModel::Serializer
  attributes :__type, :id, :created_at, :updated_at

  def __type
    object.class.name.underscore
  end
end