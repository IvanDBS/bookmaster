import { ref } from 'vue'
import api from '../services/api'

export function useClientMasters(authStore) {
  const myMasters = ref([])
  const isLoadingMasters = ref(false)
  const selectedMasterForBooking = ref(null)

  const loadMyMasters = async () => {
    try {
      isLoadingMasters.value = true
      const bookings = await api.getBookings(authStore.token)
      const mastersMap = new Map()
      bookings.forEach((booking) => {
        if (booking.user && !mastersMap.has(booking.user.id)) {
          mastersMap.set(booking.user.id, {
            id: booking.user.id,
            first_name: booking.user.first_name,
            last_name: booking.user.last_name,
            services: [],
          })
        }
      })
      const mastersArray = Array.from(mastersMap.values())
      await Promise.all(
        mastersArray.map(async (master) => {
          try {
            master.services = await api.getServices({ master_id: master.id }, authStore.token)
          } catch {
            master.services = []
          }
        }),
      )
      myMasters.value = mastersArray
    } catch {
      myMasters.value = []
    } finally {
      isLoadingMasters.value = false
    }
  }

  const selectMasterForBooking = (master) => {
    selectedMasterForBooking.value = master
  }

  const cancelMasterSelection = () => {
    selectedMasterForBooking.value = null
  }

  return {
    myMasters,
    isLoadingMasters,
    selectedMasterForBooking,
    loadMyMasters,
    selectMasterForBooking,
    cancelMasterSelection,
  }
}
