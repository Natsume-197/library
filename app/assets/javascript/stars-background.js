document.addEventListener("DOMContentLoaded", () => {
  ensureStarFieldExists();
  generateStars();
});

// Función para regenerar estrellas después de búsquedas AJAX o cambios dinámicos
document.addEventListener("ajax:complete", () => {
  generateStars();
});

function ensureStarFieldExists() {
  let starField = document.querySelector(".star-field");
  if (!starField) {
    starField = document.createElement("div");
    starField.classList.add("star-field");
    document.body.appendChild(starField);
  }
}

function generateStars() {
  const numStars = 1000; // Número total de estrellas
  const totalAnimationDuration = 10; // Duración total de la animación en segundos

  const starField = document.querySelector(".star-field");

  // Limpia las estrellas previas
  if (starField) {
    starField.innerHTML = "";
  }

  // Crear las estrellas
  for (let i = 0; i < numStars; i++) {
    const star = document.createElement("div");
    star.classList.add("star");
    star.style.left = `${Math.random() * 100}%`; // Posición horizontal
    star.style.top = `${Math.random() * 100}%`; // Posición vertical

    // Opacidad aleatoria para cada estrella
    star.style.opacity = Math.random();

    // Colores aleatorios para un 10% de las estrellas
    if (Math.random() < 0.1) {
      star.classList.add("colored-star");
      const colors = ["yellow", "blue", "green", "purple", "pink"];
      const randomColor = colors[Math.floor(Math.random() * colors.length)];
      star.style.backgroundColor = randomColor;
    }

    // Duración aleatoria de animación entre 1 y 4 segundos
    star.style.animationDuration = `${Math.random() * 3 + 1}s`;

    // Retraso aleatorio de animación entre 0 y 10 segundos
    star.style.animationDelay = `${Math.random() * totalAnimationDuration}s`;

    starField.appendChild(star);
  }
}
