class ServiceSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :price, :duration, :service_type, :formatted_price, :formatted_duration,
             :master_name

  belongs_to :user, serializer: UserSerializer

  delegate :formatted_price, to: :object

  delegate :formatted_duration, to: :object

  delegate :master_name, to: :object
end
