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

  return {
    formatDate,
    formatTime,
    formatBookingDate,
    formatBookingTime,
    getStatusClass,
    getStatusText,
  }
}


