class GdprMailer < ApplicationMailer
  def data_export(user, file_path)
    @user = user
    @export_date = Time.current

    attachments["gdpr_export_#{user.id}.json"] = File.read(file_path)

    mail(
      to: user.email,
      subject: 'Экспорт ваших персональных данных - BookMaster'
    )
  end

  def deletion_notification(user)
    @user = user
    @deletion_date = 30.days.from_now

    mail(
      to: user.email,
      subject: 'Уведомление об удалении данных - BookMaster'
    )
  end

  def consent_reminder(user)
    @user = user

    mail(
      to: user.email,
      subject: 'Напоминание о согласии на обработку данных - BookMaster'
    )
  end
end
