---
title:  "Train ICS Converter"
description: Zugverbindungen in Deinem Kalender abspeichern, revisited in 2022
date:   2022-12-08
tags: [tech, travel]
---

Nachdem [mein Zugdaten-nach-ICS-Konvertierer]({{< ref "2016-02-23-train2ics-zugverbindungen-in-deinem-kalendar-abspeichern.md" >}}) längere Zeit offline war, habe ich die Software im letzten Jahr noch einmal von Grund auf neugeschrieben. Sie ist nun unter [train-ics.ipv4.rocks](https://train-ics.ipv4.rocks) zu erreichen.

Die wichtigsten geänderten Features:

* Die Software [ist open-source](https://github.com/jeyemwey/train-ics-converter) und wird automatisch über Google Cloud Run deployed. Das macht es ein wenig einfacher, die Seite zu hosten.
* Es wird die Deutsche Bahn/Hafas-API mit [db-rest](https://github.com/derhuerst/db-rest) verwendet und nicht mehr die Open Data-Schnittstelle der SBB. Dadurch können zumindest innert Deutschlands nun auch Busse, Straßenbahnen, usw. verwendet werden.
* Automatischer Dark Mode auf der Webseite
* Verbesserte Auskunft in der Event-Beschreibung. Dazu gehören die Zwischenhalte mit Ankunft und Abfahrtszeit, optional Links zu [Träwelling](https://traewelling.de), [Travelynx](http://travelynx.de) und [bahn.expert](https://bahn.expert), und zusätzliche Hinweise, welche von der API mitgegeben werden:

> 🚅 ICE 621: Düsseldorf Hbf (Gl. 15) → Nürnberg Hbf (Gl. 9)
> 
> Betreiber: DB Fernverkehr AG
> 
> Zwischenstops: Köln Messe/Deutz Gl.11-12 (an: 09:33, ab: 09:44), Frankfurt(M) Flughafen Fernbf (an: 10:33, ab: 10:34), Frankfurt(Main)Hbf (an: 10:48, ab: 10:53), Aschaffenburg Hbf (an: 11:22, ab: 11:23), Würzburg Hbf (an: 12:01, ab: 12:04)
>
> Hinweise:
> 
> 🧸 Komfort Check-in possible (visit bahn.de/kci for more information)
> 
> 🤿 Please wear an FFP2 mask. You are legally required to do so
> 
> 🍴 Bordrestaurant
> 
> ♿ vehicle-mounted access aid

Wer Verbesserungsvorschläge oder Bugs hat, darf gerne ein [Issue auf GitHub](https://github.com/jeyemwey/train-ics-converter/issues) eröffnen. Bis dahin, allzeit gute Fahrt!