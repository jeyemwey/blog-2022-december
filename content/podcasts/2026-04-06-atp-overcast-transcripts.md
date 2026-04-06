---
podcast: Accidental Tech Podcast
title: "683: I Didn’t Want to Melt My Rug"
link: "https://atp.fm/683"
date: 2026-04-06
---

Marco von ATP hat darüber gesprochen, wie er Transkripte für Podcasts für seine Podcast-App Overcast generiert hat. Apple hat eine Transkripte-API, die auf aktuellen Mac Minis etwa mit `100x` läuft (also: in 1min Wall-Clock werden 100min Audio transkribiert), die er benutzt. Durch Zusammenschalten von mehreren Rechnern via [beanstalkd](https://beanstalkd.github.io/) konnte er so "jeden Podcast in Overcast mit mehr als einer Hörer\*in" (also fast alles außer Abo-Feed-Podcasts) transkribieren.

Ich glaube, dass er mit 46 Macs etwas überprovisioniert hat, weil er jetzt halt _richtig viel_ Kapital im Rechenzentrum hat, für die er nun noch sehr viele andere Aufgaben suchen muss. Aber das bleibt bestimmt spannend :)