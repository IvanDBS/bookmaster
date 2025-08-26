require 'rails_helper'

RSpec.describe 'Race Conditions Security', type: :request do
  let(:master) { create(:user, role: 'master') }
  let(:client) { create(:user, role: 'client') }
  let(:service) { create(:service, user: master) }
  let(:slot) { create(:time_slot, user: master, is_available: true, slot_type: 'work') }

  before do
    sign_in client
  end

  describe 'Booking creation race conditions' do
    it 'prevents double booking of the same slot' do
      # Создаем два параллельных запроса на бронирование одного слота
      threads = 2.times.map do
        Thread.new do
          post '/api/v1/bookings', params: {
            master_id: master.id,
            time_slot_id: slot.id,
            booking: {
              service_id: service.id,
              client_name: 'Test Client',
              client_email: client.email
            }
          }
        end
      end

      # Ждем завершения всех потоков
      responses = threads.map(&:value)

      # Проверяем, что только один запрос успешен
      successful_responses = responses.select { |r| r.status == 201 }
      expect(successful_responses.count).to eq(1)

      # Проверяем, что создана только одна бронь
      expect(Booking.count).to eq(1)

      # Проверяем, что слот помечен как занятый
      expect(slot.reload.is_available).to be false
      expect(slot.booking_id).to be_present
    end

    it 'handles concurrent requests for different slots' do
      slot2 = create(:time_slot, user: master, is_available: true, slot_type: 'work')

      threads = [
        Thread.new do
          post '/api/v1/bookings', params: {
            master_id: master.id,
            time_slot_id: slot.id,
            booking: {
              service_id: service.id,
              client_name: 'Client 1',
              client_email: client.email
            }
          }
        end,
        Thread.new do
          post '/api/v1/bookings', params: {
            master_id: master.id,
            time_slot_id: slot2.id,
            booking: {
              service_id: service.id,
              client_name: 'Client 2',
              client_email: 'client2@example.com'
            }
          }
        end
      ]

      responses = threads.map(&:value)

      # Оба запроса должны быть успешны
      expect(responses.map(&:status)).to all(eq(201))
      expect(Booking.count).to eq(2)
    end

    it 'prevents booking of already booked slot' do
      # Сначала бронируем слот
      post '/api/v1/bookings', params: {
        master_id: master.id,
        time_slot_id: slot.id,
        booking: {
          service_id: service.id,
          client_name: 'First Client',
          client_email: client.email
        }
      }

      expect(response).to have_http_status(:created)

      # Пытаемся забронировать тот же слот снова
      post '/api/v1/bookings', params: {
        master_id: master.id,
        time_slot_id: slot.id,
        booking: {
          service_id: service.id,
          client_name: 'Second Client',
          client_email: 'second@example.com'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']['message']).to include('недоступен')
    end
  end

  describe 'Database transaction isolation' do
    it 'maintains data consistency under concurrent load' do
      # Создаем несколько слотов
      slots = 3.times.map { create(:time_slot, user: master, is_available: true, slot_type: 'work') }

      # Пытаемся забронировать все слоты одновременно
      threads = slots.map.with_index do |slot, index|
        Thread.new do
          post '/api/v1/bookings', params: {
            master_id: master.id,
            time_slot_id: slot.id,
            booking: {
              service_id: service.id,
              client_name: "Client #{index}",
              client_email: "client#{index}@example.com"
            }
          }
        end
      end

      responses = threads.map(&:value)

      # Все запросы должны быть успешны
      expect(responses.map(&:status)).to all(eq(201))
      expect(Booking.count).to eq(3)

      # Все слоты должны быть заняты
      slots.each do |slot|
        slot.reload
        expect(slot.is_available).to be false
        expect(slot.booking_id).to be_present
      end
    end
  end
end
