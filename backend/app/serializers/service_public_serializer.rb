class ServicePublicSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :price, :duration, :service_type
  belongs_to :user, serializer: UserMinimalSerializer
end
