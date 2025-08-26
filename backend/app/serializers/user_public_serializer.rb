class UserPublicSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name

  # Публичный профиль не должен раскрывать вложенного пользователя у услуги,
  # поэтому используем облегчённый сериализатор услуги
  has_many :services, serializer: ServicePublicSerializer
end
