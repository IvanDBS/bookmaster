export function createCalendarStyleUtils() {
  const getDateHoverBgClass = (date) => {
    if (date.isPast) return 'hover:bg-gray-100'
    if (date.loadLevel === 'non_working') return 'hover:bg-gray-100'
    if (date.totalSlots > 0 && date.availableSlots === 0) return 'hover:bg-red-100'
    if (date.bookedSlots > 0) return 'hover:bg-orange-100'
    return 'hover:bg-green-50'
  }

  const getDateBgClass = (date) => {
    if (date.isPast) return 'bg-gray-50 border-gray-200'
    if (date.loadLevel === 'non_working') return 'bg-gray-100 border-gray-300 cursor-not-allowed'
    if (date.totalSlots > 0 && date.availableSlots === 0) return 'bg-red-100 border-red-300'
    if (date.bookedSlots > 0) return 'bg-orange-100 border-orange-300'
    return 'bg-green-50 border-green-300'
  }

  const getDateBorderClass = (date) => {
    if (date.isPast) return 'border-gray-200'
    if (date.loadLevel === 'non_working') return 'border-gray-300'
    if (date.totalSlots > 0 && date.availableSlots === 0) return 'border-red-300'
    if (date.bookedSlots > 0) return 'border-orange-300'
    return 'border-green-300'
  }

  const getBookingDotClass = (date) => {
    if (date.loadLevel === 'non_working') return 'bg-gray-400'
    if (date.totalSlots > 0 && date.availableSlots === 0) return 'bg-red-400'
    if (date.bookedSlots > 0) return 'bg-orange-400'
    return 'bg-green-400'
  }

  return { getDateHoverBgClass, getDateBgClass, getDateBorderClass, getBookingDotClass }
}
