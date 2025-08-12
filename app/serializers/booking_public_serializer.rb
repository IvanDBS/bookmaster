class BookingPublicSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :end_time, :status, :created_at

  belongs_to :service, serializer: ServicePublicSerializer
  belongs_to :user, serializer: UserPublicSerializer
end


