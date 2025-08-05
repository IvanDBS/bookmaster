FactoryBot.define do
  factory :service do
    association :user, factory: :user, role: 'master'
    sequence(:name) { |n| "Услуга #{n}" }
    description { "Описание услуги" }
    price { rand(1000..5000) }
    duration { rand(30..120) }
  end
end
