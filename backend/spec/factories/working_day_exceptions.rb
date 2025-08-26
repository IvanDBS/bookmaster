FactoryBot.define do
  factory :working_day_exception do
    user
    date { Date.current + 1.day }
    is_working { false }
    reason { "Manual override" }
  end
end
