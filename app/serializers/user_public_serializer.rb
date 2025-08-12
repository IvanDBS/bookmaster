class UserPublicSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name

  has_many :services, serializer: ServiceSerializer
end


