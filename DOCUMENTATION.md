# Jenkins Build Pipeline

Für die Build Pipeline verwenden wir Jenkins. Die Konfiguration der Jobs
erfolgt über ein `Jenkinsfile`, das in jedem Repository hinterlegt ist.

Um mehrere Packete mit einem `Jenkinsfile` zu verarbeiten, wird `meta` verwendet.
Mithilfe von `meta exec` werden dann die einzelnen Schritte für jedes Packet
durchgeführt.

## Konfiguration

Im Kopf der Datei wird jeweils die zu verwende Node Version konfiguriert:

```groovy
tools {
  nodejs "node-lts"
}
```

In dieses Fall wird `node-lts` verwendet. Welche Node Versionen verwendet werden
können wird im Jenkins global konfiguriert unter:

`Jenkins verwalten > Konfiguration der Hilfsprogramme > NodeJS Installationen`

Dort können mehrere NodeJS Versionen parallel installiert werden.

Nachfolgend ist der Build Prozess in mehrere Schritte aufgeteilt:

1. prepare

   In diesem Schritt werden alle notwendigen Abhängigkeiten installiert. Ebenfalls können
   hier weitere vorbereitende Aufgaben durchgeführt werden:

   ```groovy
   run_meta_exec_command 'npm install --ignore-scripts'
   ```

2. lint

   In diesem Schritt wird geprüft ob der Quelltext der
   [tslint-config](https://github.com/essential-projects/tslint-config)
   entspricht. Standartmäßig lässt ein fehlschlagen dieses Schrittes den Build **nicht**
   fehlschlagen.

   ```groovy
   /* we do not want the linting to cause a failed build */
   run_meta_exec_command 'npm run lint || true'
   ```

   Soll das Verhalten geändert werden - und bei jedem Fehlschlag den gesamten Build
   fehlschlagen lassen - muss nur das `|| true` entfernt werden.

3. build

   In diesem Schritt wird das Paket gebaut. Für TypeScript Pakete bedeutet dies:

   - den TypeScript Compiler ausführen
   - die TypeScript Schemas erstellen
   - die Dokumentation erstellen

   Alle anderen Pakete können hier eigene Schritte definieren, z.B. für Aurelia
   Anwendungen `au build --prod`.

   ```groovy
   run_meta_exec_command 'npm run build'
   run_meta_exec_command 'npm run build-schemas'
   run_meta_exec_command 'npm run build-doc'
   ```

4. test

   In diesem Schritt wird das Paket getestet. Je nach Typ von Paket variiert dieser
   Schritt stark. Standartmäßig wird `npm run test` ausgeführt.

   ```groovy
   run_meta_exec_command 'npm run test'
   ```

5. publish

   Der **publish** Schritt unterscheidet in verschiedene Fälle:

   - Wenn auf der `master` Branch **und**
   - ein neuer `Commit` seit dem letzen Build gepusht wurde **und**
   - die zu veröffentlichende Version nicht der bereits veröffentlichten entspricht

   Wird die Version mit `npm publish` veröffentlicht. Als `tag` wird
   standartmäßig `latest` verwendet.

   **oder**

   - Nicht auf der `master` Branch

   Wird ein neuer Versions String der aus folgenden Strings generiert:

   - Die alte Version, meist `1.2.3` oder `1.2.3-rc2`
   - Den aktuellen siebenstelligen Commit Hash
   - Der Build Number

   Wird die Version mit `npm publish` veröffentlicht. Als `tag` wird der Name der
   Branch verwendet, dabei werden `/` mit `~` ersetzt.

   ```groovy
   run_meta_exec_command 'npm publish --ignore-scripts'
   ```

## Infrastruktur

Um den Konfigurationsaufwand im Jenkins zu reduzieren, wird im Jenkins keine
Job Konfiguration hinterlegt. Diese befindet sich ausschließlich im Jenkinsfile.

Damit der Jenkins alle GitHub Repositories findet, wurde für jede der drei
Organisationen jeweils zwei GitHub Organization Jobs erstellt.

Es müssen immer zwei Jobs pro Organisation erstellt werden, damit beide
Jenkinsfiles benutzt werden können. Es gibt einen Job für Node LTS und für Node v7.

Der GitHub Organization Job scannt alle Projekte der Organisation und legt dafür
Multibranch Pipeline Jobs an. Die Multibranch Pipeline Jobs legen wiederrum
einen Job für jede Branch an.

An den GitHub Organisationen wurden WebHooks konfiguriert, so dass Jenkins bei
Erstellen von neuen Repositories, pushen von Commits und löschen von Repositories
direkt eine Information bekommt.
