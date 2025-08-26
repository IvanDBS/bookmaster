FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2025-08-05 17:04:11" }
  end
end
