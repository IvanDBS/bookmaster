FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { password }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone { "+7 (999) #{rand(100..999)}-#{rand(10..99)}-#{rand(10..99)}" }
    role { "client" }

    trait :confirmed do
      confirmed_at { Time.current }
    end
  end
end
