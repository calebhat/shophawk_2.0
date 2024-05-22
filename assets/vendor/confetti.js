createconfetti = 
function createConfetti(count = 20) {
    const container = document.getElementById('confetti-container');
    for (let i = 0; i < count; i++) {
      const confetti = document.createElement('div');
      confetti.classList.add('confetti');
      confetti.style.left = `${Math.random() * 100}%`; // Random starting position
      container.appendChild(confetti);
    }
  }