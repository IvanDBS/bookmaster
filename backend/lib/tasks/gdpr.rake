namespace :gdpr do
  desc "Permanently delete users marked for deletion (older than 30 days)"
  task cleanup_deleted_users: :environment do
    users_to_delete = User.for_deletion

    puts "Found #{users_to_delete.count} users to permanently delete"

    users_to_delete.find_each do |user|
      puts "Deleting user #{user.id} (#{user.email})"
      user.permanently_delete!
    end

    puts "GDPR cleanup completed"
  end

  desc "Export user data for GDPR compliance"
  task export_user_data: :environment do |_task, args|
    user_id = args[:user_id]

    if user_id.blank?
      puts "Usage: rake gdpr:export_user_data[USER_ID]"
      exit 1
    end

    user = User.find(user_id)
    data = user.export_personal_data

    filename = "user_#{user_id}_data_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json"
    File.write(filename, JSON.pretty_generate(data))

    puts "User data exported to #{filename}"
  end

  desc "Anonymize user data for GDPR compliance"
  task anonymize_user_data: :environment do |_task, args|
    user_id = args[:user_id]

    if user_id.blank?
      puts "Usage: rake gdpr:anonymize_user_data[USER_ID]"
      exit 1
    end

    user = User.find(user_id)
    user.permanently_delete!

    puts "User #{user_id} data anonymized"
  end
end
