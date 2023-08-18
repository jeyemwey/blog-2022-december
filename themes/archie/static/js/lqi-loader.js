document.addEventListener("DOMContentLoaded", () => {
    Array.from(document.querySelectorAll("img[data-hqi-src]"))
        .forEach((image, index) => {
            const hqiSrc = image.dataset.hqiSrc;

            image.loading = index === 0 ? "eager" : "lazy";
            image.onload = () => image.classList.add("loaded");

            image.src = hqiSrc;
        });
});