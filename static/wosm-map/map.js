function getColor(category) {
  switch (category) {
    case "a":
      return "#D89253";
    case "b":
      return "#88C7F0";
    case "c":
      return "#DAD257";
    case "d":
      return "#F07A78";
    default:
      return "#F2F2F2";
  }
}

window.onload = async () => {
  const countries = await fetch("./world-countries.json").then((res) =>
    res.json(),
  );
  var map = L.map("map").setView([15, 30], 2);

  var tiles = L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 8,
    attribution:
      '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
  }).addTo(map);

  L.geoJson(countries, {
    style: (feature) => ({
      fillColor: getColor(feature.properties.category),
      weight: 2,
      opacity: 1,
      color: "white",
      dashArray: "3",
      fillOpacity: 0.7,
    }),
  }).addTo(map);

  var legend = L.control({ position: "bottomright" });

  legend.onAdd = function (map) {
    var div = L.DomUtil.create("div", "info legend"),
      grades = ["a", "b", "c", "d", "unknown"],
      labels = [];
    // loop through our density intervals and generate a label with a colored square for each interval
    for (var i = 0; i < grades.length; i++) {
      div.innerHTML +=
        grades[i] +
        '<i style="background:' +
        getColor(grades[i]) +
        '"></i> ' +
        "<br>";
    }

    return div;
  };

  legend.addTo(map);
};
