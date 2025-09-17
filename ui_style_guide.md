# Guida Stile UI – Jigsaw

Questa guida raccoglie tutte le regole e le linee guida per replicare lo stile dell'interfaccia grafica del gioco Jigsaw in altri progetti, garantendo coerenza visiva e di esperienza utente.

---

## 1. Palette Colori

- **Colore principale:** #2C2C2C (sfondo scuro, neutro)
- **Colore secondario:** #F5F5F5 (testi e icone chiare)
- **Colore accento:** #F9B233 (bottoni, highlight, selezioni)
- **Colore errore:** #E74C3C (messaggi di errore, pulsanti annulla)
- **Colore successo:** #27AE60 (conferme, messaggi positivi)
- **Colore disabilitato:** #BDBDBD (elementi non attivi)

> **Nota:** I colori possono essere adattati in base al tema, ma mantenere sempre un contrasto elevato per l'accessibilità.

## 1bis. Gradienti

- **Utilizzo:**
  - I gradienti vengono usati per sfondi di schermate principali, pulsanti speciali, highlight di selezione e popup.
  - Servono a dare profondità e modernità all'interfaccia, senza appesantire la leggibilità.
- **Esempi di gradienti:**
  - **Sfumatura principale:**
    - Da #2C2C2C (alto) a #434343 (basso) – per sfondi generali
  - **Accento caldo:**
    - Da #F9B233 a #FFDD87 – per pulsanti o highlight
  - **Popup:**
    - Da #FFFFFF (trasparente) a #2C2C2C (semi-trasparente) – per overlay
- **Direzione:**
  - Di solito verticale (dall'alto verso il basso), ma può essere orizzontale per elementi particolari.
- **Consigli:**
  - Non usare più di due colori per gradiente.
  - Mantenere sempre coerenza con la palette principale.

---

## 2. Tipografia

- **Font principale:** Caviar Dreams (`assets/caviar.ttf`)
- **Dimensioni:**
  - Titoli: 48px
  - Sottotitoli: 32px
  - Testo normale: 24px
  - Testo secondario/piccolo: 18px
- **Stile:**
  - Tutti i testi sono in maiuscolo per i titoli, normali per i testi descrittivi.
  - Colore testo: preferibilmente chiaro su sfondo scuro.

---

## 3. Iconografia e Immagini

- **Icone:**
  - Utilizzare immagini PNG trasparenti per bandiere, loghi, ecc. (es. `assets/flag_en.png`, `assets/flag_it.png`, `assets/logo.png`)
  - Le icone devono essere semplici, facilmente riconoscibili e coerenti nello stile (flat, senza ombre eccessive).
- **Immagini di gioco:**
  - Le immagini dei puzzle sono fotografiche, ad alta risoluzione, suddivise per categorie (`img/animali/`, `img/paesaggi/`, ecc.).
  - Le immagini devono essere luminose, colorate e prive di watermark.

---

## 4. Pulsanti e Interazioni

- **Forma:** Rettangolare con angoli leggermente arrotondati (radius 8px)
- **Colore:**
  - Default: accento (#F9B233)
  - Hover: accento più chiaro
  - Premuto: accento più scuro
  - Disabilitato: grigio chiaro
- **Testo:** Maiuscolo, centrato, ben leggibile
- **Feedback:**
  - Suono di selezione (`sounds/select1.ogg`)
  - Animazione di pressione (leggera riduzione di scala)

---

## 5. Layout e Spaziature

- **Margini esterni:** 32px
- **Padding interno elementi:** 16px
- **Spaziatura tra elementi UI:** 24px
- **Allineamento:**
  - Elementi centrati orizzontalmente e verticalmente dove possibile
  - Liste e menu con allineamento a sinistra
- **Contenitori:**
  - Box con sfondo leggermente più scuro rispetto allo sfondo principale
  - Bordo sottile o ombra leggera per separare dal resto

---

## 6. Animazioni e Transizioni

- **Transizioni tra schermate:** Dissolvenza in entrata/uscita (fade in/out, durata 0.5s)
- **Animazioni pulsanti:** Riduzione di scala al click (0.1s), ritorno rapido
- **Popup:** Appaiono con effetto di scala e fade

---

## 7. Suoni UI

- **Selezione:** `sounds/select1.ogg`, `sounds/select2.ogg`
- **Errore:** `sounds/error1.ogg`
- **Apertura popup:** `sounds/popup_open1.ogg`
- **Chiusura popup:** `sounds/popup_close1.ogg`
- **Navigazione cursore:** `sounds/cursor1.ogg` – `sounds/cursor5.ogg`
- **Annulla:** `sounds/cancel1.ogg`, `sounds/cancel2.ogg`

---

## 8. Altri Elementi Distintivi

- **Logo:** Sempre visibile nella schermata principale, centrato in alto
- **Lingua:** Icone bandiera per selezione lingua
- **Leaderboard:** Tabella con righe alternate di colore per leggibilità
- **Popup:** Sfondo semi-trasparente dietro popup per focus

---

## 9. Consigli Generali

- Mantenere semplicità e pulizia visiva
- Usare sempre la stessa palette e font
- Garantire feedback visivo e sonoro per ogni interazione
- Testare la leggibilità su diversi dispositivi e risoluzioni

---

**Questa guida va aggiornata se vengono introdotti nuovi elementi UI o cambiamenti di stile.** 