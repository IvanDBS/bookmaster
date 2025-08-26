export function useToast() {
  const show = (message, color = 'green') => {
    if (typeof document === 'undefined') return
    const el = document.createElement('div')
    el.textContent = message
    el.className = `fixed top-4 right-4 z-[9999] px-4 py-2 rounded text-white shadow transition-opacity duration-300 ${
      color === 'green' ? 'bg-green-600' : color === 'red' ? 'bg-red-600' : 'bg-gray-800'
    }`
    document.body.appendChild(el)
    setTimeout(() => {
      el.style.opacity = '0'
      setTimeout(() => el.remove(), 300)
    }, 2000)
  }

  return { show }
}
