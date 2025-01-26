---
title: "Wie sind eigentlich die deutschen Postleitzahlen verteilt?"
description: "Spaß mit Distribution Graphes."
slug: zip-distribution
date: 2025-01-25
tags: [tech]
---

Manchmal sitzt man abends rum und fragt sich: "Der deutsche Postleitzahlenbereich ist mit _theoretisch_ einhunderttausend Kombinationen in `00000-99999` gar nicht so groß, wie viele Ziffern davon sind eigentlich in Benutzung?" Und dann liest man über die Wikipedia-Seite für Postleitzahlen, [amüsiert sich über Systeme mit führenden Nullen im Postleitzahlfeld](https://de.wikipedia.org/wiki/Datei:PLZ_fehlende_Fuehrungsnull.png), und stellt fest, dass sich da schon Leute ein System für ausgedacht haben.

Außerdem scheint es [super viele PLZ-Abschnitte zu geben](https://de.wikipedia.org/wiki/Postleitzahl_(Deutschland)#Postleitzahlenarten), die gar keinem Ort zugewiesen sind (Haus&shy;zu&shy;stell&shy;ungs&shy;post&shy;leit&shy;zahl, wie die Rapper sagen), sondern für Postfächer und Großempfänger wie Firmen reserviert sind.
Nach ein bisschen Wikidata-Massieren, ein wenig scrapen, ein bisschen googlen, bin ich dann aber zumindest über eine Liste der aktuell genutzten Haus&shy;zu&shy;stell&shy;ungs&shy;post&shy;leit&shy;zahlen gestolpert.

![Animation über alle zehn Postleitzahlbereiche](./loop.invertable.gif)

Jedes Quadrat-Bild bildet einen Zehntausender-Block ab, jede _Zeile_ ist ein Hunderter-Bereich, zum Beispiel von `12300` bis `12399`. Hier sind noch einmal die einzelnen Graphen für die Blöcke:

{{< toc >}}

## 0xxxx
![Verteilungsbild für den Bereich 0xxxx](./0.invertable.png)

## 1xxxx
![Verteilungsbild für den Bereich 1xxxx](./1.invertable.png)

## 2xxxx
![Verteilungsbild für den Bereich 2xxxx](./2.invertable.png)

## 3xxxx
![Verteilungsbild für den Bereich 3xxxx](./3.invertable.png)

## 4xxxx
![Verteilungsbild für den Bereich 4xxxx](./4.invertable.png)

## 5xxxx
![Verteilungsbild für den Bereich 5xxxx](./5.invertable.png)

## 6xxxx
![Verteilungsbild für den Bereich 6xxxx](./6.invertable.png)

## 7xxxx
![Verteilungsbild für den Bereich 7xxxx](./7.invertable.png)

## 8xxxx
![Verteilungsbild für den Bereich 8xxxx](./8.invertable.png)

## 9xxxx
![Verteilungsbild für den Bereich 9xxxx](./9.invertable.png)


Es ist visualisiert, und [in den Zahlen sieht man es auch](https://de.wikipedia.org/wiki/Postleitzahl_(Deutschland)#Postleitzahlenarten), es sind nur etwa 8% des Postleitzahlenbereiches als Hauszustellungspostleitzahlen und nur etwa 28% überhaupt verwendet. Über eine Erschöpfung des Zahlenraums muss man sich wohl keine Gedanken machen. Yay!

Leider enthalten die Postleitzahlen keine Fehler&shy;korr&shy;ektur&shy;funk&shy;tionen wie bei IBANs oder IMEI-Nummern, mit denen man die Korrektheit einer PLZ kontrollieren kann. In den meisten Fällen würde eine falsche Postleitzahl jedoch sowieso nur eine _Service Degradation_ (sprich: Jemand müsste eine Postleitzahl manuell nachkodieren und das verzögert den Empfang) und keinen _Service Loss_ (der Brief wird gar nicht zugestellt) bedeuten, sodass eine kürzere Zahlenfolge nach&shy;voll&shy;zieh&shy;barer&shy;weise präferiert wird.


