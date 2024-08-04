---
title:  "Visualization of the WOSM Fee Categories"
description: TBA
date:   2024-08-04
tags: [scouts, english]
---

Last week, the Polish organizers of the World Scout Jamboree 2027 released [their first Bulletin](https://knowledge.wsj2027.pl/display/HOC/Bulletin+1+EN), a document which gives clear instructions to the participating National Scout Organizations (NSOs) how the Jamboree will work. The bulletins are highly dependable, so the NSOs can plan their journeys and give information to the youths and ISTs/CMTs.

This bulletin also released the [fee structure for participants](https://knowledge.wsj2027.pl/display/HOC/Jamboree+Terms+and+Conditions+Extract), excluding travel costs and whatever the NSOs add to make the Jamboree memorable (preparations / get-togethers, uniforms and merchandise, administrative stuff).
For WOSM events -- adventures that all NSOs that are members of WOSM can join -- [the fees are tiered](https://treehouse.scout.org/dashboard/participation-fees) according to the _Gross National Income per Capita_ as set by the World Bank. Every few years, there is an update to the list when changes occur, the last one is from [April 2021](https://treehouse.scout.org/topic/world-scout-event-participation-fee-categories).
The goal here is that the countries with a higher GNI can co-finance the rest, and that more people have access to the bigger world events. This is used for Jamborees, as well as in World Scout Conferences (among other events).

While the list is public, it's just a big table, and I much rather work with a map.
So here, the list is shown as a leaflet map (see [see full page](/wosm-map/index.html)):

{{< iframe "/wosm-map/index.html" 500 >}}


## Attributions

The map works with Leaflet and has Open Street Map as a base. Specifically, I have followed the [Choropleth example](https://leafletjs.com/examples/choropleth/).
The color scheme is from [Bryan van Britsem](https://color.adobe.com/Summer-color-theme-17628673).
For the country lines, I have used [the following Gist from Johan](https://gist.github.com/johan/1431429?short_path=c5094ce).

## Caveats

Due to the low-poly structure of the map (the GeoJSON file is only about &frac14; MiB), some smaller NSOs that are members of WOSM are not represented on the map. These include the NSOs of:

* Hong Kong
* Kiribati
* Liechtenstein
* Macao
* Maldives
* Malta
* Monaco
* Palestine (only Gaza, the West Bank is shown)
* Saint Lucia
* Saint Vincent and the Grenadines
* San Marino
* Sao Tome and Principe
* Seychelles
* Singapore
* Timor-Leste

Also, you can see that many pieces of land are not colored. This is most probably because they are not part [of the NSOs list](https://treehouse.scout.org/dashboard/participation-fees). In the GeoJSON, those are categorized as `x`.

If you want to make use of the data or update things, please feel free to refer to [the source repository of my blog](https://github.com/jeyemwey/blog-2022-december) where the map is located in `static/wosm-map`.

I hope, this map is useful to you!
