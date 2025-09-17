-- Configurazione per il gioco Jigsaw Puzzle scritta in Lua utilizzando il framework LÖVE
-- Questa funzione configura le impostazioni iniziali del gioco, come dimensioni della finestra, moduli abilitati, e altre preferenze di sistema.

function love.conf(t)
    -- Directory di salvataggio: specifica il nome della cartella per i dati salvati (nil per directory predefinita)
    t.identity = nil

    -- Cerca i file nella directory sorgente prima della directory di salvataggio
    t.appendidentity = false

    -- Versione di LÖVE per cui il gioco è stato creato (imposta la compatibilità)
    t.version = "11.4"

    -- Collega una console per il debug (solo per Windows)
    t.console = true

    -- Abilita l'accelerometro come joystick su dispositivi mobili (iOS e Android)
    t.accelerometerjoystick = true

    -- Salva i file nella memoria esterna su Android
    t.externalstorage = false

    -- Abilita la correzione gamma per il rendering, se supportata
    t.gammacorrect = false

    -- Impostazioni audio
    -- Richiedi l'uso del microfono su Android
    t.audio.mic = false

    -- Continua la riproduzione musicale di sfondo quando apri LÖVE su dispositivi mobili
    t.audio.mixwithsystem = true

    -- Impostazioni finestra
    -- Titolo della finestra del gioco
    t.window.title = "Untitled"

    -- Icona della finestra (percorso del file immagine)
    t.window.icon = nil

    -- Larghezza della finestra in pixel
    t.window.width = 800

    -- Altezza della finestra in pixel
    t.window.height = 600

    -- Rimuovi i bordi della finestra (finestra senza bordura)
    t.window.borderless = false

    -- Permetti all'utente di ridimensionare la finestra
    t.window.resizable = false

    -- Larghezza minima della finestra se ridimensionabile
    t.window.minwidth = 1

    -- Altezza minima della finestra se ridimensionabile
    t.window.minheight = 1

    -- Abilita la modalità fullscreen
    t.window.fullscreen = false

    -- Tipo di fullscreen: "desktop" o "exclusive"
    t.window.fullscreentype = "desktop"

    -- Modalità sincronizzazione verticale (0 = disabilitata, 1 = abilitata)
    t.window.vsync = 1

    -- Numero di campioni per l'antialiasing multi-campione
    t.window.msaa = 0

    -- Buffer di profondità (numero di bit per campione)
    t.window.depth = nil

    -- Buffer di stencil (numero di bit per campione)
    t.window.stencil = nil

    -- Indice del monitor su cui mostrare la finestra
    t.window.display = 1

    -- Abilita la modalità high-DPI per display Retina
    t.window.highdpi = false

    -- Abilita la scalatura DPI automatica quando high-DPI è abilitato
    t.window.usedpiscale = true

    -- Coordinata X della posizione della finestra
    t.window.x = nil

    -- Coordinata Y della posizione della finestra
    t.window.y = nil

    -- Abilito i moduli LÖVE utilizzati
    -- Abilita il modulo audio per suoni e musica
    t.modules.audio = true

    -- Abilita il modulo data per la compressione e codifica dati
    t.modules.data = true

    -- Abilita il modulo event per gli eventi del sistema
    t.modules.event = true

    -- Abilita il modulo font per il rendering di testi
    t.modules.font = true

    -- Abilita il modulo graphics per il disegno 2D
    t.modules.graphics = true

    -- Abilita il modulo image per caricare e manipolare immagini
    t.modules.image = true

    -- Abilita il modulo joystick per controller di gioco
    t.modules.joystick = true

    -- Abilita il modulo keyboard per input da tastiera
    t.modules.keyboard = true

    -- Abilita il modulo math per funzioni matematiche
    t.modules.math = true

    -- Abilita il modulo mouse per input del mouse
    t.modules.mouse = true

    -- Abilita il modulo physics per fisica 2D
    t.modules.physics = true

    -- Abilita il modulo sound per suoni brevi
    t.modules.sound = true

    -- Abilita il modulo system per informazioni sul sistema
    t.modules.system = true

    -- Abilita il modulo thread per multitasking
    t.modules.thread = true

    -- Abilita il modulo timer per tempo e delta time (disabilitarlo causa delta time zero)
    t.modules.timer = true

    -- Abilita il modulo touch per input touch
    t.modules.touch = true

    -- Abilita il modulo video per video
    t.modules.video = true

    -- Abilita il modulo window per gestire la finestra
    t.modules.window = true
end
