class BookingSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :end_time, :status, :client_name, :client_email, :client_phone, 
             :formatted_start_time, :formatted_end_time, :can_be_confirmed, :can_be_cancelled, :created_at

  belongs_to :user, serializer: UserSerializer
  belongs_to :service, serializer: ServiceSerializer

  delegate :formatted_start_time, to: :object

  delegate :formatted_end_time, to: :object

  def can_be_confirmed
    object.can_be_confirmed?
  end

  def can_be_cancelled
    object.can_be_cancelled?
  end
end
