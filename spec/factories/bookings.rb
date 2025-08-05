FactoryBot.define do
  factory :booking do
    association :user, factory: :user, role: 'master'
    association :service
    start_time { 1.hour.from_now }
    end_time { 2.hours.from_now }
    status { 'pending' }
    client_name { Faker::Name.name }
    client_email { Faker::Internet.email }
    client_phone { "+7 (999) #{rand(100..999)}-#{rand(10..99)}-#{rand(10..99)}" }
  end
end
