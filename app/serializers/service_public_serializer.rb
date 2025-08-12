class ServicePublicSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :price, :duration, :service_type
end


