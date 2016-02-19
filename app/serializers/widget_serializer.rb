class WidgetSerializer < ApiSerializer
  attributes :name, :image

  def image
    { original: object.image.url }
  end
end
