function setTheme(mode) {
    localStorage.setItem("theme-storage", mode);
    if (mode === "dark") {
        document.getElementById("darkModeStyle").disabled = false;
        document.getElementById("dark-mode-toggle").innerHTML = "<i data-feather=\"sun\"></i>";
        feather.replace()
    } else if (mode === "light") {
        document.getElementById("darkModeStyle").disabled = true;
        document.getElementById("dark-mode-toggle").innerHTML = "<i data-feather=\"moon\"></i>";
        feather.replace()
    }
    window.initMermaid();
}

function toggleTheme() {
    if (localStorage.getItem("theme-storage") === "light") {
        setTheme("dark");
    } else if (localStorage.getItem("theme-storage") === "dark") {
        setTheme("light");
    }
}

const browserAsksForDarkMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
setTheme(browserAsksForDarkMode ? "dark" : "light");

window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', event => {
    setTheme(event.matches ? "dark" : "light");
});