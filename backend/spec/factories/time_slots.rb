FactoryBot.define do
  factory :time_slot do
    association :user, factory: :user
    date { Date.tomorrow }
    start_time { "09:00" }
    end_time { "10:00" }
    is_available { true }
    slot_type { "work" }

    trait :unavailable do
      is_available { false }
    end

    trait :break do
      slot_type { "break" }
    end

    trait :today do
      date { Time.zone.today }
    end

    trait :yesterday do
      date { Date.yesterday }
    end
  end
end
