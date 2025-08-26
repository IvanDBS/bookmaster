module Api
  module V1
    class GdprController < Api::V1::BaseController
      # Экспорт персональных данных
      def export_data
        current_user.request_data_export!

        # Генерируем экспорт данных
        data = current_user.export_personal_data

        # Отправляем данные пользователю
        GdprDataExportJob.perform_later(current_user.id, data)

        render json: {
          message: 'Запрос на экспорт данных принят. Данные будут отправлены на ваш email в течение 30 дней.',
          requested_at: current_user.data_export_requested_at
        }
      end

      # Запрос на удаление данных
      def request_deletion
        current_user.request_data_deletion!

        render json: {
          message: 'Запрос на удаление данных принят. Ваши данные будут удалены через 30 дней.',
          deletion_date: 30.days.from_now,
          requested_at: current_user.data_deletion_requested_at
        }
      end

      # Отмена запроса на удаление
      def cancel_deletion
        current_user.update!(data_deletion_requested_at: nil)

        render json: {
          message: 'Запрос на удаление данных отменен.',
          cancelled_at: Time.current
        }
      end

      # Дать согласие на обработку персональных данных
      def give_consent
        version = params[:version] || '1.0'
        current_user.give_gdpr_consent!(version)

        render json: {
          message: 'Согласие на обработку персональных данных дано.',
          consent_at: current_user.gdpr_consent_at,
          version: current_user.gdpr_consent_version
        }
      end

      # Отозвать согласие на обработку персональных данных
      def revoke_consent
        current_user.revoke_gdpr_consent!

        render json: {
          message: 'Согласие на обработку персональных данных отозвано.',
          revoked_at: Time.current
        }
      end

      # Дать согласие на маркетинг
      def give_marketing_consent
        current_user.give_marketing_consent!

        render json: {
          message: 'Согласие на маркетинговые сообщения дано.',
          consent_at: current_user.marketing_consent_at
        }
      end

      # Отозвать согласие на маркетинг
      def revoke_marketing_consent
        current_user.revoke_marketing_consent!

        render json: {
          message: 'Согласие на маркетинговые сообщения отозвано.',
          revoked_at: Time.current
        }
      end

      # Получить статус GDPR согласий
      def consent_status
        render json: {
          gdpr_consent: {
            given: current_user.has_gdpr_consent?,
            given_at: current_user.gdpr_consent_at,
            version: current_user.gdpr_consent_version
          },
          marketing_consent: {
            given: current_user.has_marketing_consent?,
            given_at: current_user.marketing_consent_at
          },
          data_requests: {
            export_requested_at: current_user.data_export_requested_at,
            deletion_requested_at: current_user.data_deletion_requested_at,
            can_be_deleted: current_user.can_be_deleted?
          }
        }
      end
    end
  end
end
