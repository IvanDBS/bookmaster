class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :phone, :role, :bio, :address, :full_name, :display_name

  delegate :full_name, to: :object

  delegate :display_name, to: :object
end
