FactoryBot.define do
  factory :booking do
    start_time { "2025-08-05 17:02:00" }
    end_time { "2025-08-05 17:02:00" }
    status { "MyString" }
    user { nil }
    service { nil }
    client_name { "MyString" }
    client_email { "MyString" }
    client_phone { "MyString" }
  end
end
