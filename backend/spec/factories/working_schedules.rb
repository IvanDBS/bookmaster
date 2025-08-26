FactoryBot.define do
  factory :working_schedule do
    association :user
    day_of_week { 1 } # Понедельник
    is_working { true }
    start_time { '09:00' }
    end_time { '19:00' }
    lunch_start { '13:00' }
    lunch_end { '14:00' }
    slot_duration_minutes { 60 }

    trait :non_working do
      is_working { false }
      start_time { nil }
      end_time { nil }
      lunch_start { nil }
      lunch_end { nil }
      slot_duration_minutes { nil }
    end

    trait :sunday do
      day_of_week { 0 }
    end

    trait :monday do
      day_of_week { 1 }
    end

    trait :tuesday do
      day_of_week { 2 }
    end

    trait :wednesday do
      day_of_week { 3 }
    end

    trait :thursday do
      day_of_week { 4 }
    end

    trait :friday do
      day_of_week { 5 }
    end

    trait :saturday do
      day_of_week { 6 }
    end
  end
end
