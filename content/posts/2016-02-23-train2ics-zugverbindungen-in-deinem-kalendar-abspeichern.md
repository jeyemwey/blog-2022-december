---
title:  "Train2ICS"
description: Zugverbindungen in Deinem Kalender abspeichern
date:   2016-02-23
tags: [tech, travel]
---


![Bild vom Programm im Browser](/images/train2ics_screenshot.png)

Mit [Train2ICS](https://train-ics.ipv4.rocks) ist es möglich, Zugverbindungen in mehreren Einträgen in Deinem Kalendar festzuhalten. Alles, was Du machen musst, ist Deine Reise zu suchen, die Ergebnisse mit Deinen Zugnummern zu vergleichen, und die Kalendardatei (`ics`) herunterzuladen. In deinem Kalendar erscheinen dann die einzelnen Züge mit Bahnsteig und Abfahrtsbahnhof als Ort. So [könnte](https://discussions.apple.com/thread/5820160) Siri/kann Google Now dich auch rechtzeitig zum Bahnhof bringen. Top, oder?

## Warum dafür eine extra Software?

![Doppeltermine Bahn vs meine Einträge](/images/train2ics_cal.png)

Ich mag es, wenn ich nicht lange nach Informationen suchen muss. Mit der ICS-Datei, die die Bahn mitliefert (linker Termin), bin ich hinterher aber nicht schlauer. Dass ich an dem Tag von Hannover nach Hause möchte, weiß ich auch so. Auf welches Gleis muss ich? Welche Zugnummer hat mein Zug? Wie lange habe ich Aufenthalt in Dortmund? Mit den Daten (rechts) aus [Train2ICS](https://train-ics.ipv4.rocks) sehe ich alles auf einen Blick und das ohne die Bahn-App zu öffnen.


## Technicalities

* Die "App" spricht mit [transport.opendata.ch](https://transport.opendata.ch). Warum mit der Schweiz und nicht direkt mit der DB? Nunja, die Deutsche Bahn hat leider keine öffentliche API, weil die Schweizer Bundesbahn (SBB) jedoch auch für Deutschland (und ganz Europa) Zugtickets verkauft und die Schweizer ein bisschen loyaler bezüglich der Offenheit sind, nutze ich halt deren Service.
* Für das Erstellen der Kalendar-Einträge nach [RFC 5545](https://tools.ietf.org/html/rfc5545) nutze ich die PHP-Bibliothek (shame on me!) [github.com/eluceo/ical](https://github.com/eluceo/ical) und bin ziemlich zufrieden damit.
* Outlook is a bitch. Aber Thunderbird/Lightning nicht weniger. Darum wird beim Importieren mehrerer Termine (Ach was, eine Reise kann mehrere Züge und Umsteigen beinhalten?) ein neuer Kalendar mit dem Dateinamen als Titel erstellt. Momentan befinden sich also etwa 30 Test-Kalendar in meinem Thunderbird-Client. **Modernere Kalendar-Software wie [Google Calendar](https://www.google.com/calendar)** macht das nicht. Dafür gibt es dort kein Drag- und drop. Meh.
* Die API-Abfrage ist je nach Tagesform extrem langsam (normalerweise immer 0.5-2sek, manchmal aber auch 10sek). Ich versuche die meisten Abfragen daher per AJAX-Call zu holen, sodass die Webseite nicht unnötig lange weiß bleibt.

## Hintergrund

In der [Freakshow #171](http://freakshow.fm/fs171-invasion) wurde sich über Kalendar-Software, deren Standards und die Deutsche Bahn ausgelassen. Besonders im Gedächtnis blieb mir der Satz: 

> Es kann doch nicht so schwer sein, für eine Reise mit mehreren Zügen **mehr als einen** acht Stunden langen Termin in den Kalendar zu batzen!
> (Tim Pritlove, sinngemäß, irgendwann in der Folge.)

Naja, dieses Thema sollte ja jetzt gelöst sein, Tim :) Abgesehen davon mag ich es, alle Termine an einem Ort zu haben und Bahnfahrten gehören eben auch dazu.