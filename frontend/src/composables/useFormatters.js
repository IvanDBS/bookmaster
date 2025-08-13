export function useFormatters() {
  const formatDate = (dateString) => new Date(dateString).toLocaleDateString('ru-RU')

  const formatTime = (dateString) =>
    new Date(dateString).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })

  const formatBookingDate = (dateString) => {
    if (!dateString) return ''
    const date = new Date(dateString)
    return date.toLocaleDateString('ru-RU', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    })
  }

  const formatBookingTime = (timeString) => {
    if (!timeString) return ''
    const time = timeString.includes('T')
      ? timeString.split('T')[1].substring(0, 5)
      : timeString.substring(0, 5)
    return time
  }

  const getStatusClass = (status) => {
    const classes = {
      pending: 'bg-yellow-100 text-yellow-800',
      confirmed: 'bg-green-100 text-green-800',
      cancelled: 'bg-red-100 text-red-800',
    }
    return classes[status] || 'bg-gray-100 text-gray-800'
  }

  const getStatusText = (status) => {
    const texts = {
      pending: 'Ожидает подтверждения',
      confirmed: 'Подтверждено',
      cancelled: 'Отменено',
    }
    return texts[status] || status
  }

  // Slot helpers (centralized to avoid duplication)
  const getSlotTypeText = (slotType) => {
    const texts = {
      work: 'Рабочий слот',
      lunch: 'Перерыв',
      blocked: 'Перерыв',
    }
    return texts[slotType] || slotType
  }

  const getSlotStatusClass = (slot) => {
    if (!slot) return 'bg-gray-100 text-gray-800'
    if (slot.slot_type === 'lunch') return 'bg-gray-100 text-gray-800'
    if (slot.slot_type === 'blocked') return 'bg-red-100 text-red-800'
    if (slot.booked) return 'bg-blue-100 text-blue-800'
    if (slot.is_available) return 'bg-green-100 text-green-800'
    return 'bg-gray-100 text-gray-800'
  }

  const getSlotStatusText = (slot) => {
    if (!slot) return 'Недоступно'
    if (slot.slot_type === 'lunch') return 'Перерыв'
    if (slot.slot_type === 'blocked') return 'Перерыв'
    if (slot.booked) return 'Занято'
    if (slot.is_available) return 'Свободно'
    return 'Недоступно'
  }

  const isBreak = (slot) => slot && (slot.slot_type === 'blocked' || slot.slot_type === 'lunch')

  return {
    formatDate,
    formatTime,
    formatBookingDate,
    formatBookingTime,
    getStatusClass,
    getStatusText,
    getSlotTypeText,
    getSlotStatusClass,
    getSlotStatusText,
    isBreak,
  }
}
