---
description: "ADRs in docs/adr/ schreiben, reviewen und pflegen -- gegen das arknet-Metamodell (arknet-architecture.ttl). Haelt ADRs als dauerhafte Entscheidungssaetze, nicht als Statusberichte, und ab Status Accepted unveraenderlich -- Korrekturen laufen ueber ein Nachfolge-ADR, nie ueber einen Nachtrag. Trigger: /arknet:adr, 'schreib ein ADR', 'neues ADR', 'ADR fuer X', 'review das ADR', 'pflege die ADRs', 'ist das ein gutes ADR'. NICHT triggern bei: allgemeiner Doku (asciidoc-writer), Requirements (arkreq), Code-Kommentaren."
---

# /arknet:adr -- Architecture Decision Records pflegen

You maintain arknet's Architecture Decision Records in `docs/adr/`. Your single job:
keep every ADR a record of a **durable decision and its lasting consequences** -- never a
status report, never an implementation snapshot.

Two rules override everything else in this skill, and you apply them before any other
judgement:

1. **Ab `Accepted` ist ein ADR eingefroren.** Nicht editieren, nicht ergaenzen, nicht
   nachbessern -- nur die Status-Zeile darf sich noch aendern. Ist etwas falsch oder neu:
   ein neues ADR, das das alte abloest. Siehe "Immutability".
2. **Querverweise werden einseitig geschrieben.** Nie ein zweites ADR anfassen, um einen
   Rueckverweis zu pflegen -- das Metamodell leitet die Gegenrichtung ab.

The authority is not taste. It is arknet's own metamodel:
**`arknet-ontology/src/main/resources/arknet-architecture.ttl`**, class
`arkarch:ArchitectureDecisionRecord`. arknet dogfoods it. If a sentence has no home in a
metamodel slot, it does not belong in the ADR. When in doubt, open the .ttl and check --
do not invent slots.

## The metamodel defines the ONLY allowed content

These are the slots `arkarch:ArchitectureDecisionRecord` permits. There are no others.

| Metamodell-Slot | Bedeutung (rdfs:comment) | Markdown-Abschnitt |
|-----------------|--------------------------|--------------------|
| `dcterms:identifier` | Nummer (Pflicht, genau 1) | Dateiname + Titel |
| `arkarch:adrStatus` | genau 1: Proposed / Accepted / Rejected / Deprecated / Superseded | `- Status:` Zeile |
| `arkarch:decisionDate` | Datum der Entscheidung | Datum in `- Status:` Zeile |
| `arkarch:adrContext` | "Warum musste entschieden werden? Kraefte und Rahmenbedingungen." | `## Kontext` |
| `arkarch:adrDecision` | "Die getroffene Entscheidung." | `## Entscheidung` |
| `arkarch:adrConsequences` | "Positive und negative Folgen der Entscheidung." | `## Konsequenzen` |
| `arkarch:adrAlternatives` | "Erwogene, aber verworfene Optionen mit Begruendung." | `## Alternativen` |
| `arkarch:relatedTo` | loser Querverweis -- **einseitig** geschrieben | `- Verwandt:` Zeile |
| `arkarch:supersedes` | dieses ADR loest ein aelteres ab -- steht **nur hier**, im neuen ADR | `- Loest ab:` Zeile |
| `arkarch:supersededBy` | Inverse von `supersedes`, wird **abgeleitet, nie gepflegt** | Status-Zeile des abgeloesten ADR |
| `arkarch:addressesRequirement` | Traceability zu einem Requirement (#17) | optional in Kontext/Entscheidung |
| `arkarch:affectsContext` | betroffener Bounded Context | optional in Kontext/Entscheidung |

If you catch yourself writing an "Offene Punkte", "Umsetzung", "Status", "TODO", "Aktueller
Stand", "Nachtrag", "Ergaenzung" or "Naechste Schritte" section -- **stop**. No such slot
exists. That content belongs elsewhere (see below).

## The Litmus Test (apply to every sentence)

> **Veraltet dieser Satz, sobald jemand Code aendert?**
> Ja  -> raus. Es ist Verdrahtungsstand, kein Entscheidungsinhalt.
> Nein -> es ist eine dauerhafte Konsequenz und darf bleiben.

Worked example (this exact edit was made to ADR-001):

- RAUS (Schnappschuss): "der aktuelle MCP-Bau pinnt sie auf `WorkspaceId.DEFAULT`, arbeitet
  also faktisch auf einem Workspace." -- veraltet, sobald jemand die Provenance verdrahtet.
- BLEIBT (dauerhafte Konsequenz): "Kein Workspace-Management und keine festgelegte Herkunft
  der WorkspaceId je Session -- bewusst offen, bis der Bedarf konkret ist."

Same decision, but one form is a decision record and the other is a status line pretending
to be one.

Der Test greift **beim Schreiben**, solange das ADR `Proposed` ist. Ab `Accepted` ist er nur
noch ein Diagnose-, kein Reparaturwerkzeug: du benennst den Schnappschuss, aber du entfernst
ihn nicht mehr aus dem Record. Siehe "Immutability".

## Anti-Patterns -- the failure class to guard against

The recurring mistake is smuggling transient implementation state into a durable document.
Concretely, NEVER put these in an ADR:

1. **Implementierungs-Schnappschuss** -- "pinnt gerade auf X", "aktuell per lokalem Override
   in pom.xml geloest", "z.Zt. nur ein Adapter verdrahtet". Wiring state, not decision.
2. **Offene-Punkte- / TODO-Liste** -- offene Arbeit ist ein Issue, kein ADR-Abschnitt.
   (Eine *bewusst deferred* Konsequenz mit Begruendung ist erlaubt -- das ist eine Folge der
   Entscheidung, kein Arbeitszettel.)
3. **Commit-Refs / PR-Nummern / Datei-Zeilen** -- "siehe Commit fcfaf29", "in
   ModelLoader.java Zeile 42". Fluechtig; gehoert in Git/Issue, nicht ins ADR.
4. **Nachtrag / Ergaenzung / Update-Abschnitt** -- `## Nachtrag 2026-07-18: dritter Konsument
   (Issue #66, PR #133)` haelt fest, dass eine Entscheidung *erneut angewendet* wurde. Das
   ist Fortschritt, nicht Entscheidung. Entweder praezisiert es die Entscheidung wirklich
   -- dann ist es ein **eigenes ADR**, das das alte abloest -- oder es gehoert in den
   Tracker. Ein drittes Fach gibt es nicht. Siehe "Immutability".
5. **"Umsetzung" / "Status" / "Naechste Schritte"-Sektion** -- kein Metamodell-Slot.
6. **Der Agent entscheidet selbst** -- ein ADR haelt die Entscheidung *des Nutzers* fest, nicht deine.
   Ist die Entscheidung noch nicht getroffen: Status `Proposed` und im Kontext offen benennen
   -- nicht eine Entscheidung erfinden, um den Slot zu fuellen.
7. **Leere / Pflicht-Alternativen** -- "Keine Alternativen erwogen" ist ein Geruch. Wenn
   wirklich alternativlos, kurz begruenden *warum* der Moeglichkeitsraum leer war.
8. **Marketing-Prosa / Fuellwoerter** -- nuechtern, dicht, ein Gedanke pro Satz.

## Wohin der ausgeschlossene Inhalt gehoert

Schnappschuss rausnehmen heisst nicht Information wegwerfen -- nur am richtigen Ort ablegen:

- **Verdrahtungsstand / "warum steht der Code so"** -> Javadoc am betroffenen Typ.
- **Offene Arbeit** -> der Issue-Tracker des Projekts.
- **Projekt-Fortschritt / "erledigt in Commit X"** -> Git-Historie, Release Notes, projekteigene
  Notizen (z.B. `CLAUDE.md`).
- **"Entscheidung jetzt auch auf Y angewendet"** -> der Issue/PR, der es getan hat. Eine
  Entscheidung, die greift, braucht keinen Beleg im ADR -- sie greift ja.

Wenn du einen Schnappschuss aus einem `Proposed` ADR entfernst, pruefe kurz, ob er anderswo
schon festgehalten ist; wenn nicht, weise darauf hin (nicht stillschweigend loeschen). Aus
einem `Accepted` ADR entfernst du nichts mehr -- dort nennst du nur den Zielort.

## Template (Hausstil, deckt sich mit ADR-001..004)

```markdown
# ADR-NNN: <praegnanter Entscheidungstitel>

- Status: <Proposed|Accepted|Rejected|Deprecated|Superseded> (JJJJ-MM-TT)
- Verwandt: ADR-XXX, ADR-YYY        # weglassen, wenn keine; einseitig, kein Gegeneintrag drueben
- Loest ab: ADR-MMM                 # nur wenn dieses ADR ein aelteres abloest

## Kontext

Warum musste entschieden werden? Kraefte und Rahmenbedingungen. Verweise auf verwandte ADRs
und -- falls zutreffend -- auf das adressierte Requirement / den betroffenen Bounded Context.

## Entscheidung

Die getroffene Entscheidung, praezise und im Aktiv. Bei mehreren Teilen nummerieren.

## Konsequenzen

**Positiv:** dauerhafte Vorteile, die aus der Entscheidung folgen.

**Negativ / bewusst deferred (YAGNI):** dauerhafte Kosten und bewusst offengelassene Punkte
*mit Begruendung*. Kein Arbeitszettel, kein Schnappschuss.

## Alternativen

- **<Verworfene Option>.** Ein Satz, warum verworfen. `Verworfen.` / `Vorerst verworfen
  (revidierbar).`
```

Regeln zum Template:
- **Dateiname:** `adr-NNN-<kebab-title>.md`, NNN dreistellig (`001`), fortlaufend. Vor
  Vergabe der Nummer: `ls docs/adr/` -- hoechste vorhandene + 1.
- **ASCII only**, keine Unicode-Sonderzeichen (Projekt-Konvention).
- **Sprache Deutsch** (die bestehenden ADRs sind Deutsch).
- Nur die vier `##`-Abschnitte oben. Keine weiteren Ueberschriften erfinden -- insbesondere
  kein `## Nachtrag`, `## Ergaenzung`, `## Update`.

## Immutability -- ein `Accepted` ADR wird nicht mehr angefasst

Das ist eine harte Regel, keine Empfehlung. Mit `Accepted` ist der Inhalt
eingefroren: `## Kontext`, `## Entscheidung`, `## Konsequenzen`, `## Alternativen` werden
danach **nie wieder** editiert -- nicht praezisiert, nicht ergaenzt, nicht "kurz
klargestellt", nicht umformuliert. Ein ADR haelt fest, was damals entschieden wurde und
warum; wer es nachtraeglich glaettet, faelscht das Protokoll.

**Die einzige erlaubte Aenderung ist die Status-Zeile**, und nur in diese Richtungen:

```
- Status: Superseded (2026-07-28), abgeloest durch ADR-042
- Status: Deprecated (2026-07-28)
```

Warum die Status-Zeile beweglich bleibt, obwohl alles andere friert: ADRs werden aus dem
Code heraus referenziert (im arknet-Korpus hunderte Male aus Javadoc). Wer aus einer
Java-Datei in `adr-006-*.md` springt, muss dort sehen, dass die Entscheidung tot ist --
ohne vorher einen Index zu befragen. Eine tote Entscheidung, die sich unveraendert
`Accepted` nennt, ist gefaehrlicher als jeder Formatverstoss.

Was das fuer dich als Reviewer heisst -- diese Reparaturen darfst du bei einem `Accepted`
ADR **nicht** vorschlagen und nicht anwenden:

- "Nachtrag zurueck in den Entscheidungssatz falten"
- "Konsequenz X noch ergaenzen, die ist inzwischen klar geworden"
- "Formulierung praezisieren / Schnappschuss rausnehmen"

Der Fix ist in allen drei Faellen derselbe: **ein neues ADR**, das das alte abloest. Benenne
den Verstoss, sag dass das alte Record so stehen bleibt, und biete das Nachfolge-ADR an.

Nur bei `Proposed` ist der Inhalt frei editierbar -- da ist noch nichts protokolliert.
Findest du einen Verstoss in einem `Accepted` ADR, ist der Befund trotzdem wertvoll: er
gehoert in das Nachfolge-ADR, nicht in eine Korrektur.

## Status-Lifecycle

- Neue Entscheidung, noch nicht final beschlossen -> `Proposed`. Datum = heute. **Die
  Bedingung fuer den Uebergang explizit nennen** (Beispiel ADR-002: "wird Accepted, sobald
  die OSS-Lizenz festgelegt ist"). Ein `Proposed` ohne Uebergangsbedingung ist ein Geruch.
- Beschlossen -> `Accepted`. Ab hier gilt "Immutability" (Abschnitt oben).
- Wird von einem neuen ADR abgeloest: das **neue** ADR nennt "loest ADR-MMM ab"
  (`supersedes`); im alten ADR aendert sich **ausschliesslich die Status-Zeile** auf
  `Superseded (Datum), abgeloest durch ADR-NNN`. Kein Nachtrag, keine Notiz, kein Eintrag
  in `- Verwandt:`.
- `Rejected` = erwogen und verworfen (bleibt als Dokumentation stehen).
- `Deprecated` = ueberholt ohne konkreten Nachfolger.
- Status nie ruecklos aendern: ein abgeloestes ADR wird nicht so umgeschrieben, als waere
  die alte Entscheidung nie getroffen worden.

## Cross-ADR-Konsistenz

Ein einzelnes gutes ADR reicht nicht -- das Korpus muss in sich stimmig sein. Beim Schreiben
eines neuen und beim Reviewen eines bestehenden ADR die *anderen* ADRs gegenlesen
(`ls docs/adr/`, dann lesen). Pruefe:

1. **Inhaltliche Widersprueche.** Trifft dieses ADR eine Entscheidung, die einem anderen
   `Accepted`/`Proposed` ADR widerspricht? Wenn ja: nicht stillschweigend beides
   stehenlassen -- den Konflikt benennen. Entweder loest das neue das alte ab (Superseded,
   siehe unten) oder einer der beiden ist falsch.
2. **Superseding steht im neuen ADR.** Loest dieses ADR ein aelteres ab? Dann nennt das
   **neue** ADR "loest ADR-MMM ab"; im alten aendert sich nur die Status-Zeile (siehe
   "Immutability"). Das ist die ganze Pflicht -- kein Rueckverweis, keine Notiz im alten
   Record.
3. **Superseded/Deprecated ADRs sagen nichts mehr als gueltig.** Ein abgeloestes ADR bleibt
   als Historie stehen, darf aber nicht so klingen, als sei seine Entscheidung noch in Kraft
   -- die Status-Zeile muss das klarstellen. Sie ist dafuer auch das einzige Mittel: der
   Fliesstext bleibt unveraendert stehen und redet weiter im Praesens.
4. **Verweise sind einseitig.** Ein Querverweis wird genau einmal geschrieben -- in dem
   Record, der die Aussage macht. Das *zitierende* ADR nennt das verwandte unter
   `- Verwandt:`; das genannte ADR bekommt **keinen** Gegeneintrag. Ein fehlender
   Rueckverweis ist kein Befund.
   Warum: das Metamodell leitet die Gegenrichtung selbst ab -- `arkarch:supersededBy` ist
   `owl:inverseOf arkarch:supersedes`, `arkarch:relatedTo` ist eine `owl:SymmetricProperty`.
   Ein handgepflegter Rueckverweis waere also redundant, und er wuerde erzwingen, was
   "Immutability" verbietet: das Editieren eines eingefrorenen Records.
   Was bleibt: Verweise muessen auf **existierende** Nummern zeigen. Verwaiste Nummern sind
   weiterhin ein Befund.
5. **Keine Doppelung.** Zwei ADRs, die dieselbe Entscheidung treffen, sind ein Geruch --
   zusammenfuehren (nur solange beide `Proposed` sind) oder das aeltere als `Superseded`
   markieren.

Bei einem gefundenen Widerspruch: melden, welche zwei ADRs kollidieren und worin, und einen
Aufloesungsvorschlag machen (ablosen / korrigieren / zusammenfuehren) -- nicht raten.

## Modus: Schreiben vs. Reviewen

**Neues ADR schreiben:**
1. Nummer bestimmen (`ls docs/adr/`).
2. Ist die Entscheidung wirklich getroffen? Wenn nein -> `Proposed`, Offenheit im Kontext
   benennen, NICHT erfinden.
3. Template fuellen, Litmus-Test auf jeden Satz anwenden.
4. Verwandte ADRs verlinken -- **nur hier, einseitig**. Die verlinkten Records bleiben
   unangetastet.
5. Cross-ADR-Konsistenz pruefen (siehe Abschnitt oben): widerspricht/abloest es ein
   bestehendes ADR? Loest es ab, dann am alten Record **ausschliesslich die Status-Zeile**
   auf `Superseded (Datum), abgeloest durch ADR-NNN` setzen -- sonst nichts.

**Bestehendes ADR reviewen.** Schritt 0 ist immer derselbe: **Status lesen.** Er entscheidet,
welche Reparatur ueberhaupt zur Debatte steht.

- `Proposed` -> Inhalt ist frei editierbar. Befunde direkt fixen.
- `Accepted` / `Superseded` / `Deprecated` / `Rejected` -> eingefroren. Befunde **melden,
  nicht reparieren**; der Fix ist ein Nachfolge-ADR. Einzige erlaubte Aenderung an der Datei
  ist die Status-Zeile. Siehe "Immutability".

Checkliste:
- [ ] Genau die vier Abschnitte, keine erfundenen (Offene Punkte / Umsetzung / Status /
      Nachtrag / Ergaenzung)?
- [ ] Keine Spur einer Nach-Accepted-Bearbeitung: kein Nachtrag, kein "Update", keine
      Issue-/PR-Nummer im Text? (Fehlerklasse: Fortschritt statt Entscheidung)
- [ ] Jeder Satz uebersteht den Litmus-Test (kein Schnappschuss, keine Commit-Ref)?
- [ ] Status + Datum gesetzt, genau ein Status?
- [ ] Bei `Proposed`: ist die Bedingung fuer den Uebergang nach `Accepted` benannt?
- [ ] Bei `Superseded`: nennt die Status-Zeile das abloesende ADR?
- [ ] Enthaelt `## Konsequenzen` echte *Folgen* (nicht Wiederholung der Entscheidung)?
- [ ] Sind `## Alternativen` substanziell (nicht "keine erwogen")?
- [ ] Nummer eindeutig, Dateiname `adr-NNN-<kebab>.md`, ASCII, Deutsch?
- [ ] Querverweise auf existierende Nummern -- und *einseitig*, also ohne handgepflegten
      Rueckverweis im anderen Record?
- [ ] Cross-ADR-Konsistenz: kein Widerspruch zu anderen ADRs, Superseding im neuen Record
      benannt, keine Doppelung (siehe Abschnitt "Cross-ADR-Konsistenz")?

Bei Verstoss: nie kommentarlos umschreiben -- den Verstoss benennen (welche Fehlerklasse),
und dann nach Status verzweigen. Bei `Proposed`: Fix vorschlagen bzw. anwenden und sagen,
wohin der entfernte Inhalt gehoert. Bei allem ab `Accepted`: sagen, dass das Record so
stehen bleibt, und ein Nachfolge-ADR anbieten -- auch dann, wenn der Fix ein Einzeiler
waere. Gerade dann.

## Referenz -- Gold-Beispiele

Die vorhandenen ADRs sind der Massstab. Lies sie, bevor du schreibst:

- `docs/adr/adr-001-local-client-and-swappable-store.md` -- vorbildlicher YAGNI-Konsequenz-
  Abschnitt (bewusst deferred *mit Begruendung*, kein Schnappschuss).
- `docs/adr/adr-002-open-core-editions.md` -- Status mit expliziter Uebergangsbedingung.
- `docs/adr/adr-003-adapter-b-remote-store.md` -- Richtungsentscheidung ("kein Code, bis X").
- `docs/adr/adr-004-spring-ai-mcp-tech-line.md` -- Tech-Linie gesetzt, saubere Alternativen.

Metamodell: `arknet-ontology/src/main/resources/arknet-architecture.ttl` (Abschnitt 4-6).
