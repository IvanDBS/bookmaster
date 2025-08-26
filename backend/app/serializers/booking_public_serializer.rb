class BookingPublicSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :end_time, :status, :created_at, :client_name, :client_phone

  belongs_to :service, serializer: ServicePublicSerializer
  belongs_to :user, serializer: UserPublicSerializer
end
