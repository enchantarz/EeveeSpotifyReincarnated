#!/usr/bin/env python3
# Adds the strings of the recent feature ports — the SpicyLyrics karaoke view, the AMOLED black
# theme, the Jam/rating toggles (PR #152), Hysan's recovery fund and the app-icon picker — to every
# language in the tweak bundle that is missing them. Safe to re-run: only missing keys are written,
# existing translations are never touched. After writing, every touched file is linted with plutil.
import os
import re
import subprocess

BUNDLE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                                       "layout", "Library", "Application Support",
                                       "EeveeSpotify.bundle"))

# English is the source of truth; every other table only has to carry what that language wants to
# say differently. Keys already present in a language's file are skipped, so partial tables are fine.
EN = {
    "spicylyrics_description": "SpicyLyrics provides word-by-word karaoke lyrics.",
    "spicylyrics_key_missing": "No SpicyLyrics API Key",
    "spicylyrics_key_invalid": "SpicyLyrics API Key Rejected",
    "petitlyrics_description": "PetitLyrics: Offers plenty of time-synced Japanese and some international lyrics.",
    "karaoke_word_synced_button": "Custom Lyrics view",
    "amoled_theme": "AMOLED Black Theme",
    "hide_jam_from_menu": "Hide Jam from Menu",
    "hide_jam_from_menu_description": "Removes \"Start a Jam\" from track/playlist context menus, the device picker, and the queue.",
    "block_rating_dialogs": "Block App Rating Dialogs",
    "block_rating_dialogs_description": "Suppresses App Store star rating prompts and in-app review requests.",
    "hysan_recovery_fund": "Hysan's Elsa Recovery Fund",
    "hysan_recovery_fund_description": "Hysan has had a crush on Elsa since 2026 and will not stop talking about it. Every coffee here funds his recovery — and the mod. ☕",
    "appIconTitle": "Choose Icon",
    "appIconSubtitle": "iOS shows a confirmation the first time. The home screen may take a few seconds to refresh.",
    "appIconUnavailableMessage": "This Spotify was installed from the App Store, so iOS keeps its Home Screen icon inside the app's signed bundle and won't let the mod change it. Install a patched IPA build of EeveeSpotify — signed with the icons registered — and switching works.",
    "iconSelected": "Selected",
    "iconTapToApply": "Tap to apply",
    "prettifyIconNames": "Prettify Icon Names",
    "prettifyIconNamesDescription": "Converts underscores, hyphens, and camelCase into spaces",
}

DE = {
    "spicylyrics_description": "SpicyLyrics bietet Karaoke-Lyrics Wort für Wort.",
    "spicylyrics_key_missing": "Keine SpicyLyrics-API-Key",
    "spicylyrics_key_invalid": "SpicyLyrics-API-Key abgelehnt",
    "petitlyrics_description": "PetitLyrics: Bietet viele zeitlich synchronisierte japanische und einige internationale Lyrics.",
    "karaoke_word_synced_button": "Eigene Lyrics-Ansicht",
    "amoled_theme": "AMOLED-Schwarz-Design",
    "hide_jam_from_menu": "Jam im Menü ausblenden",
    "hide_jam_from_menu_description": "Entfernt \"Eine Jam starten\" aus den Kontextmenüs von Titel/Playlist, der Geräteauswahl und der Warteschlange.",
    "block_rating_dialogs": "App-Bewertungsdialoge blockieren",
    "block_rating_dialogs_description": "Unterdrückt Sterne-Bewertungsaufrufe des App Stores und In-App-Review-Anfragen.",
    "hysan_recovery_fund": "Hysans Elsa-Genesungsfond",
    "hysan_recovery_fund_description": "Hysan ist seit 2026 in Elsa verliebt und redet über nichts anderes. Jeder Kaffee hier finanziert seine Genesung — und den Mod. ☕",
    "appIconTitle": "Symbol wählen",
    "appIconSubtitle": "iOS zeigt beim ersten Mal eine Bestätigung. Der Home-Bildschirm braucht eventuell ein paar Sekunden zum Aktualisieren.",
    "appIconUnavailableMessage": "Dieses Spotify wurde aus dem App Store installiert, deshalb behält iOS sein Home-Bildschirm-Symbol innerhalb der signierten App und lässt den Mod es nicht ändern. Installiere ein gepatchtes IPA von EeveeSpotify — mit registrierten Symbolen signiert — dann funktioniert der Wechsel.",
    "iconSelected": "Ausgewählt",
    "iconTapToApply": "Zum Anwenden tippen",
    "prettifyIconNames": "Symbolnamen verschönern",
    "prettifyIconNamesDescription": "Macht aus Unterstrichen, Bindestrichen und CamelCase Leerzeichen",
}

FR = {
    "spicylyrics_description": "SpicyLyrics fournit des paroles karaoké mot par mot.",
    "spicylyrics_key_missing": "Aucune clé API SpicyLyrics",
    "spicylyrics_key_invalid": "Clé API SpicyLyrics refusée",
    "petitlyrics_description": "PetitLyrics : Propose beaucoup de paroles japonaises synchronisées et quelques internationales.",
    "karaoke_word_synced_button": "Vue de paroles personnalisées",
    "amoled_theme": "Thème noir AMOLED",
    "hide_jam_from_menu": "Masquer Jam du menu",
    "hide_jam_from_menu_description": "Retire « Lancer un Jam » des menus contextuels du morceau/de la playlist, du sélecteur d'appareil et de la file d'attente.",
    "block_rating_dialogs": "Bloquer les dialogues de notation",
    "block_rating_dialogs_description": "Supprime les demandes d'étoiles de l'App Store et les demandes d'avis intégrés.",
    "hysan_recovery_fund": "Fonds de rétablissement d'Elsa de Hysan",
    "hysan_recovery_fund_description": "Hysan a le béguin pour Elsa depuis 2026 et n'arrête pas d'en parler. Chaque café ici finance son rétablissement — et le mod. ☕",
    "appIconTitle": "Choisir l'icône",
    "appIconSubtitle": "iOS affiche une confirmation la première fois. L'écran d'accueil peut mettre quelques secondes à s'actualiser.",
    "appIconUnavailableMessage": "Ce Spotify a été installé depuis l'App Store : iOS garde son icône d'écran d'accueil dans le bundle signé de l'app et ne laisse pas le mod la changer. Installez un IPA patché d'EeveeSpotify — signé avec les icônes enregistrées — et le changement fonctionne.",
    "iconSelected": "Sélectionné",
    "iconTapToApply": "Touchez pour appliquer",
    "prettifyIconNames": "Embellir les noms d'icônes",
    "prettifyIconNamesDescription": "Convertit les traits de soulignement, tirets et camelCase en espaces",
}

ES = {
    "spicylyrics_description": "SpicyLyrics ofrece letras de karaoke palabra por palabra.",
    "spicylyrics_key_missing": "Sin clave API de SpicyLyrics",
    "spicylyrics_key_invalid": "Clave API de SpicyLyrics rechazada",
    "petitlyrics_description": "PetitLyrics: Ofrece muchas letras japonesas sincronizadas y algunas internacionales.",
    "karaoke_word_synced_button": "Vista de letras personalizadas",
    "amoled_theme": "Tema negro AMOLED",
    "hide_jam_from_menu": "Ocultar Jam del menú",
    "hide_jam_from_menu_description": "Elimina \"Iniciar un Jam\" de los menús contextuales de canciones/listas, del selector de dispositivos y de la cola.",
    "block_rating_dialogs": "Bloquear diálogos de valoración",
    "block_rating_dialogs_description": "Suprime las peticiones de estrellas del App Store y las solicitudes de opinión integrada.",
    "hysan_recovery_fund": "Fondo de recuperación de Elsa de Hysan",
    "hysan_recovery_fund_description": "Hysan está enamorado de Elsa desde 2026 y no para de hablar de ello. Cada café de aquí financia su recuperación — y el mod. ☕",
    "appIconTitle": "Elegir icono",
    "appIconSubtitle": "iOS muestra una confirmación la primera vez. La pantalla de inicio puede tardar unos segundos en actualizarse.",
    "appIconUnavailableMessage": "Este Spotify se instaló desde el App Store, así que iOS mantiene su icono de pantalla de inicio dentro del paquete firmado de la app y no deja que el mod lo cambie. Instala un IPA parcheado de EeveeSpotify — firmado con los iconos registrados — y el cambio funciona.",
    "iconSelected": "Seleccionado",
    "iconTapToApply": "Toca para aplicar",
    "prettifyIconNames": "Embellecer nombres de iconos",
    "prettifyIconNamesDescription": "Convierte guiones bajos, guiones y camelCase en espacios",
}

IT = {
    "spicylyrics_description": "SpicyLyrics fornisce testi karaoke parola per parola.",
    "spicylyrics_key_missing": "Nessuna chiave API SpicyLyrics",
    "spicylyrics_key_invalid": "Chiave API SpicyLyrics rifiutata",
    "petitlyrics_description": "PetitLyrics: Offre molti testi giapponesi sincronizzati e alcuni internazionali.",
    "karaoke_word_synced_button": "Vista testi personalizzati",
    "amoled_theme": "Tema nero AMOLED",
    "hide_jam_from_menu": "Nascondi Jam dal menu",
    "hide_jam_from_menu_description": "Rimuove \"Avvia un Jam\" dai menu contestuali di brano/playlist, dal selettore dispositivi e dalla coda.",
    "block_rating_dialogs": "Blocca finestre di valutazione",
    "block_rating_dialogs_description": "Sopprime le richieste di stelle dell'App Store e le recensioni in-app.",
    "hysan_recovery_fund": "Fondo di recupero di Elsa di Hysan",
    "hysan_recovery_fund_description": "Hysan ha una cotta per Elsa dal 2026 e non smette di parlarne. Ogni caffè qui finanzia la sua guarigione — e la mod. ☕",
    "appIconTitle": "Scegli l'icona",
    "appIconSubtitle": "iOS mostrerà un avviso di conferma la prima volta. La schermata Home potrebbe impiegare qualche secondo per aggiornarsi.",
    "appIconUnavailableMessage": "Questo Spotify è stato installato dall'App Store, quindi iOS mantiene la sua icona nella schermata Home dentro il bundle firmato dell'app e non lascia che la mod la cambi. Installa un IPA patchato di EeveeSpotify — firmato con le icone registrate — e il cambio funziona.",
    "iconSelected": "Selezionata",
    "iconTapToApply": "Tocca per applicare",
    "prettifyIconNames": "Abbellisci i nomi delle icone",
    "prettifyIconNamesDescription": "Converte underscore, trattini e camelCase in spazi",
}

PT = {
    "spicylyrics_description": "O SpicyLyrics fornece letras de karaoké palavra a palavra.",
    "spicylyrics_key_missing": "Sem chave API do SpicyLyrics",
    "spicylyrics_key_invalid": "Chave API do SpicyLyrics rejeitada",
    "petitlyrics_description": "PetitLyrics: Oferece muitas letras japonesas sincronizadas e algumas internacionais.",
    "karaoke_word_synced_button": "Vista de letras personalizadas",
    "amoled_theme": "Tema preto AMOLED",
    "hide_jam_from_menu": "Ocultar Jam do menu",
    "hide_jam_from_menu_description": "Remove \"Iniciar um Jam\" dos menus de contexto de música/playlist, do seletor de dispositivos e da fila.",
    "block_rating_dialogs": "Bloquear diálogos de avaliação",
    "block_rating_dialogs_description": "Suprime pedidos de estrelas da App Store e pedidos de avaliação na app.",
    "hysan_recovery_fund": "Fundo de recuperação da Elsa do Hysan",
    "hysan_recovery_fund_description": "O Hysan está apaixonado pela Elsa desde 2026 e não para de falar nisso. Cada café daqui financia a recuperação dele — e o mod. ☕",
    "appIconTitle": "Escolher ícone",
    "appIconSubtitle": "O iOS mostra uma confirmação na primeira vez. O ecrã principal pode demorar alguns segundos a atualizar.",
    "appIconUnavailableMessage": "Este Spotify foi instalado a partir da App Store, por isso o iOS mantém o ícone do ecrã principal dentro do pacote assinado da app e não deixa o mod alterá-lo. Instala uma compilação IPA corrigida do EeveeSpotify — assinada com os ícones registados — e a troca funciona.",
    "iconSelected": "Selecionado",
    "iconTapToApply": "Toque para aplicar",
    "prettifyIconNames": "Embelezar nomes de ícones",
    "prettifyIconNamesDescription": "Converte sublinhados, hífenes e camelCase em espaços",
}

PT_BR = {
    "spicylyrics_description": "O SpicyLyrics fornece letras de karaokê palavra por palavra.",
    "spicylyrics_key_missing": "Sem chave de API do SpicyLyrics",
    "spicylyrics_key_invalid": "Chave de API do SpicyLyrics rejeitada",
    "petitlyrics_description": "PetitLyrics: Oferece muitas letras japonesas sincronizadas e algumas internacionais.",
    "karaoke_word_synced_button": "Visualização de letras personalizadas",
    "amoled_theme": "Tema preto AMOLED",
    "hide_jam_from_menu": "Ocultar Jam do menu",
    "hide_jam_from_menu_description": "Remove \"Iniciar um Jam\" dos menus de contexto de música/playlist, do seletor de dispositivos e da fila.",
    "block_rating_dialogs": "Bloquear diálogos de avaliação",
    "block_rating_dialogs_description": "Suprime pedidos de estrelas da App Store e solicitações de avaliação no app.",
    "hysan_recovery_fund": "Fundo de recuperação da Elsa do Hysan",
    "hysan_recovery_fund_description": "O Hysan está apaixonado pela Elsa desde 2026 e não para de falar disso. Cada café daqui financia a recuperação dele — e o mod. ☕",
    "appIconTitle": "Escolher ícone",
    "appIconSubtitle": "O iOS mostra uma confirmação na primeira vez. A tela de início pode levar alguns segundos para atualizar.",
    "appIconUnavailableMessage": "Este Spotify foi instalado pela App Store, então o iOS mantém o ícone da tela de início dentro do pacote assinado do app e não deixa o mod alterá-lo. Instale um IPA corrigido do EeveeSpotify — assinado com os ícones registrados — e a troca funciona.",
    "iconSelected": "Selecionado",
    "iconTapToApply": "Toque para aplicar",
    "prettifyIconNames": "Embelezar nomes de ícones",
    "prettifyIconNamesDescription": "Converte sublinhados, hífenes e camelCase em espaços",
}

RU = {
    "spicylyrics_description": "SpicyLyrics предоставляет караоке-текст слово за словом.",
    "spicylyrics_key_missing": "Нет API-ключа SpicyLyrics",
    "spicylyrics_key_invalid": "API-ключ SpicyLyrics отклонён",
    "petitlyrics_description": "PetitLyrics: Много синхронизированных японских и некоторых международных текстов.",
    "karaoke_word_synced_button": "Пользовательский вид текста песни",
    "amoled_theme": "Чёрная тема AMOLED",
    "hide_jam_from_menu": "Скрыть Jam из меню",
    "hide_jam_from_menu_description": "Убирает \"Начать Jam\" из контекстных меню трека/плейлиста, выбора устройства и очереди.",
    "block_rating_dialogs": "Блокировать диалоги оценки",
    "block_rating_dialogs_description": "Подавляет запросы звёздного рейтинга App Store и встроенные запросы отзыва.",
    "hysan_recovery_fund": "Фонд выздоровления Хайсана из-за Эльзы",
    "hysan_recovery_fund_description": "Хайсан влюблён в Эльзу с 2026 года и без умолку об этом говорит. Каждая чашка кофе здесь оплачивает его выздоровление — и мод. ☕",
    "appIconTitle": "Выбрать значок",
    "appIconSubtitle": "iOS покажет подтверждение в первый раз. Домашнему экрану может понадобиться несколько секунд на обновление.",
    "appIconUnavailableMessage": "Этот Spotify установлен из App Store, поэтому iOS держит его значок на экране «Домой» внутри подписанного пакета приложения и не позволяет моду его менять. Установите исправленную IPA-сборку EeveeSpotify — подписанную с зарегистрированными значками — и смена заработает.",
    "iconSelected": "Выбрано",
    "iconTapToApply": "Нажмите, чтобы применить",
    "prettifyIconNames": "Приукрасить названия значков",
    "prettifyIconNamesDescription": "Превращает подчёркивания, дефисы и camelCase в пробелы",
}

UK = {
    "spicylyrics_description": "SpicyLyrics надає караоке-текст слово за словом.",
    "spicylyrics_key_missing": "Немає API-ключа SpicyLyrics",
    "spicylyrics_key_invalid": "API-ключ SpicyLyrics відхилено",
    "petitlyrics_description": "PetitLyrics: Багато синхронізованих японських і деяких міжнародних текстів.",
    "karaoke_word_synced_button": "Власний перегляд тексту пісні",
    "amoled_theme": "Чорна тема AMOLED",
    "hide_jam_from_menu": "Сховати Jam із меню",
    "hide_jam_from_menu_description": "Прибирає \"Почати Jam\" з контекстних меню треку/плейліста, вибору пристрою і черги.",
    "block_rating_dialogs": "Блокувати діалоги оцінювання",
    "block_rating_dialogs_description": "Пригнічує запити зірочного рейтингу App Store і вбудовані запити відгуку.",
    "hysan_recovery_fund": "Фонд одужання Гайсана через Ельзу",
    "hysan_recovery_fund_description": "Гайсан закоханий в Ельзу з 2026 року й без зупинки про це говорить. Кожна кава тут оплачує його одужання — і мод. ☕",
    "appIconTitle": "Вибрати значок",
    "appIconSubtitle": "iOS покаже підтвердження вперше. Домашньому екрану може знадобитися кілька секунд на оновлення.",
    "appIconUnavailableMessage": "Цей Spotify установлено з App Store, тому iOS тримає його значок екрана «Домів» у підписаному пакеті програми і не дозволяє моду змінити його. Установіть виправлену IPA-збірку EeveeSpotify — підписану із зареєстрованими значками — і заміна запрацює.",
    "iconSelected": "Вибрано",
    "iconTapToApply": "Торкніться, щоб застосувати",
    "prettifyIconNames": "Прикрасити назви значків",
    "prettifyIconNamesDescription": "Перетворює підкреслення, дефіси та camelCase на пробіли",
}

PL = {
    "spicylyrics_description": "SpicyLyrics zapewnia teksty karaoke słowo po słowie.",
    "spicylyrics_key_missing": "Brak klucza API SpicyLyrics",
    "spicylyrics_key_invalid": "Klucz API SpicyLyrics odrzucony",
    "petitlyrics_description": "PetitLyrics: Oferuje wiele zsynchronizowanych czasowo japońskich i niektóre międzynarodowe teksty.",
    "karaoke_word_synced_button": "Widok własnych tekstów",
    "amoled_theme": "Czarny motyw AMOLED",
    "hide_jam_from_menu": "Ukryj Jam z menu",
    "hide_jam_from_menu_description": "Usuwa \"Rozpocznij Jam\" z menu kontekstowych utworu/playlista, selektora urządzeń i kolejki.",
    "block_rating_dialogs": "Blokuj okna ocen",
    "block_rating_dialogs_description": "Wycisza prośby o gwiazdki z App Store i prośby o ocenę w aplikacji.",
    "hysan_recovery_fund": "Fundusz powrotu do zdrowia Hysana",
    "hysan_recovery_fund_description": "Hysan jest zakochany w Elzie od 2026 i nie przestaje o tym mówić. Każda kawa tutaj finansuje jego powrót do zdrowia — oraz moda. ☕",
    "appIconTitle": "Wybierz ikonę",
    "appIconSubtitle": "iOS wyświetli potwierdzenie przy pierwszej zmianie. Odświeżenie ekranu głównego może potrwać kilka sekund.",
    "appIconUnavailableMessage": "Ten Spotify został zainstalowany z App Store, więc iOS trzyma jego ikonę ekranu głównego w podpisanym pakiecie aplikacji i nie pozwala modowi jej zmienić. Zainstaluj poprawioną kompilację IPA EeveeSpotify — podpisaną z zarejestrowanymi ikonami — a zmiana zadziała.",
    "iconSelected": "Wybrano",
    "iconTapToApply": "Dotknij, aby zastosować",
    "prettifyIconNames": "Upiększaj nazwy ikon",
    "prettifyIconNamesDescription": "Zamienia podkreślenia, myślniki i camelCase na spacje",
}

TR = {
    "spicylyrics_description": "SpicyLyrics kelime kelime karaoke sözleri sağlar.",
    "spicylyrics_key_missing": "SpicyLyrics API anahtarı yok",
    "spicylyrics_key_invalid": "SpicyLyrics API anahtarı reddedildi",
    "petitlyrics_description": "PetitLyrics: Zaman senkronizli bol miktarda Japonca ve bazı uluslararası sözler sunar.",
    "karaoke_word_synced_button": "Özel Şarkı Sözleri görünümü",
    "amoled_theme": "AMOLED Siyah Tema",
    "hide_jam_from_menu": "Jam'ı menüden gizle",
    "hide_jam_from_menu_description": "Şarkı/çalma listesi bağlam menülerinden, cihaz seçiciden ve kuyruktan \"Jam Başlat\"ı kaldırır.",
    "block_rating_dialogs": "Uygulama puanlama pencerelerini engelle",
    "block_rating_dialogs_description": "App Store yıldız puanlama isteklerini ve uygulama içi inceleme isteklerini bastırır.",
    "hysan_recovery_fund": "Hysan'ın Elsa İyileşme Fonu",
    "hysan_recovery_fund_description": "Hysan 2026'dan beri Elsa'ya âşık ve bundan konuşmayı bırakmıyor. Buradaki her kahve onun iyileşmesini — ve modu — finanse ediyor. ☕",
    "appIconTitle": "Simge Seç",
    "appIconSubtitle": "iOS ilk seferde bir onay gösterir. Ana ekranın yenilenmesi birkaç saniye sürebilir.",
    "appIconUnavailableMessage": "Bu Spotify App Store'dan kuruldu, bu yüzden iOS ana ekran simgesini uygulamanın imzalı paketi içinde tutar ve modun değiştirmesine izin vermez. EeveeSpotify'nin yamalı bir IPA derlemesini kurun — simgeler kayıtlı şekilde imzalı — ve değiştirme çalışır.",
    "iconSelected": "Seçildi",
    "iconTapToApply": "Uygulamak için dokun",
    "prettifyIconNames": "Simge adlarını güzelleştir",
    "prettifyIconNamesDescription": "Alt çizgileri, tireleri ve camelCase'i boşluklara çevirir",
}

VI = {
    "spicylyrics_description": "SpicyLyrics cung cấp lời karaoke theo từng từ.",
    "spicylyrics_key_missing": "Chưa có khóa API SpicyLyrics",
    "spicylyrics_key_invalid": "Khóa API SpicyLyrics bị từ chối",
    "petitlyrics_description": "PetitLyrics: Cung cấp nhiều lời bài hát tiếng Nhật có đồng bộ thời gian và một số lời quốc tế.",
    "karaoke_word_synced_button": "Xem lời bài hát tùy chỉnh",
    "amoled_theme": "Chủ đề đen AMOLED",
    "hide_jam_from_menu": "Ẩn Jam khỏi menu",
    "hide_jam_from_menu_description": "Loại bỏ \"Bắt đầu Jam\" khỏi menu ngữ cảnh của bài hát/danh sách, bộ chọn thiết bị và hàng đợi.",
    "block_rating_dialogs": "Chặn hộp thoại đánh giá",
    "block_rating_dialogs_description": "Chặn các yêu cầu xếp hạng sao từ App Store và yêu cầu đánh giá trong ứng dụng.",
    "hysan_recovery_fund": "Quỹ hồi phục Elsa của Hysan",
    "hysan_recovery_fund_description": "Hysan đã thích Elsa từ 2026 và không ngừng nói về chuyện đó. Mỗi ly cà phê ở đây tài trợ cho sự hồi phục của cậu ấy — và của mod. ☕",
    "appIconTitle": "Chọn biểu tượng",
    "appIconSubtitle": "iOS sẽ hiển thị một pop up xác nhận trong lần đầu tiên. Màn hình chính có thể mất vài giây để cập nhật.",
    "appIconUnavailableMessage": "Spotify này được cài đặt từ App Store, nên iOS giữ biểu tượng màn hình chính bên trong gói đã ký của ứng dụng và không cho mod thay đổi. Cài đặt bản IPA đã vá của EeveeSpotify — được ký với các biểu tượng đã đăng ký — thì việc đổi sẽ hoạt động.",
    "iconSelected": "Đã chọn",
    "iconTapToApply": "Chạm để áp dụng",
    "prettifyIconNames": "Làm đẹp tên biểu tượng",
    "prettifyIconNamesDescription": "Chuyển gạch dưới, gạch nối và camelCase thành khoảng trắng",
}

ZH_CN = {
    "spicylyrics_description": "SpicyLyrics 提供逐词卡拉OK歌词。",
    "spicylyrics_key_missing": "没有 SpicyLyrics API 密钥",
    "spicylyrics_key_invalid": "SpicyLyrics API 密钥被拒绝",
    "petitlyrics_description": "PetitLyrics：提供大量时间同步的日语歌词及部分国际歌词。",
    "karaoke_word_synced_button": "自定义歌词视图",
    "amoled_theme": "AMOLED 纯黑主题",
    "hide_jam_from_menu": "在菜单中隐藏 Jam",
    "hide_jam_from_menu_description": "从曲目/播放列表上下文菜单、设备选择器和队列中移除\"发起 Jam\"。",
    "block_rating_dialogs": "屏蔽应用评分对话框",
    "block_rating_dialogs_description": "拦截 App Store 星级评分提示和应用内评价请求。",
    "hysan_recovery_fund": "Hysan 的 Elsa 康复基金",
    "hysan_recovery_fund_description": "Hysan 从 2026 年起就一直迷恋 Elsa，念叨个不停。这里的每一杯咖啡都为他的康复——以及这个插件——买单。☕",
    "appIconTitle": "选择图标",
    "appIconSubtitle": "iOS 会在首次选择时显示确认提示，主屏幕可能需要几秒钟才能刷新。",
    "appIconUnavailableMessage": "这个 Spotify 是从 App Store 安装的，iOS 会把主屏幕图标保存在应用的签名包内，不允许插件更改。安装打过补丁的 EeveeSpotify IPA 版本（签名时注册了图标）即可正常切换。",
    "iconSelected": "已选择",
    "iconTapToApply": "点按以应用",
    "prettifyIconNames": "美化图标名称",
    "prettifyIconNamesDescription": "把下划线、连字符和驼峰命名转换为空格",
}

ZH_TW = {
    "spicylyrics_description": "SpicyLyrics 提供逐字卡拉OK歌詞。",
    "spicylyrics_key_missing": "沒有 SpicyLyrics API 金鑰",
    "spicylyrics_key_invalid": "SpicyLyrics API 金鑰被拒絕",
    "petitlyrics_description": "PetitLyrics：提供大量時間同步的日語歌詞及部分國際歌詞。",
    "karaoke_word_synced_button": "自訂歌詞檢視",
    "amoled_theme": "AMOLED 純黑主題",
    "hide_jam_from_menu": "在選單中隱藏 Jam",
    "hide_jam_from_menu_description": "從曲目/播放清單內容選單、裝置選擇器與佇列中移除「開始 Jam」。",
    "block_rating_dialogs": "封鎖應用程式評分對話框",
    "block_rating_dialogs_description": "攔截 App Store 星級評分提示與應用程式內評論請求。",
    "hysan_recovery_fund": "Hysan 的 Elsa 康復基金",
    "hysan_recovery_fund_description": "Hysan 從 2026 年起就一直迷戀 Elsa，唸個不停。這裡的每一杯咖啡都為他的康復——以及這個外掛——買單。☕",
    "appIconTitle": "選擇圖示",
    "appIconSubtitle": "iOS/iPadOS 將會在第一次變更時顯示提示，主畫面可能需要一點時間來更新。",
    "appIconUnavailableMessage": "這個 Spotify 是從 App Store 安裝的，iOS 會把主畫面圖示保存在應用程式的簽名套件內，不允許外掛變更。安裝修補過的 EeveeSpotify IPA 版本（簽名時已註冊圖示）即可正常切換。",
    "iconSelected": "已選擇",
    "iconTapToApply": "點按以套用",
    "prettifyIconNames": "美化圖示名稱",
    "prettifyIconNamesDescription": "把底線、連字符和駝峰命名轉換為空格",
}

JA = {
    "spicylyrics_description": "SpicyLyrics は単語ごとのカラオケ歌詞を提供します。",
    "spicylyrics_key_missing": "SpicyLyrics API キーが未設定",
    "spicylyrics_key_invalid": "SpicyLyrics API キーが拒否されました",
    "petitlyrics_description": "PetitLyrics: タイム同期された日本語の歌詞と一部の外国語歌詞を多数提供。",
    "karaoke_word_synced_button": "カスタム歌詞ビュー",
    "amoled_theme": "AMOLED ブラックテーマ",
    "hide_jam_from_menu": "メニューから Jam を隠す",
    "hide_jam_from_menu_description": "曲/プレイリストのコンテキストメニュー、デバイス選択、キューから「Jam を開始」を取り除きます。",
    "block_rating_dialogs": "アプリ評価ダイアログをブロック",
    "block_rating_dialogs_description": "App Store の星評価の催促とアプリ内レビューの要求を抑止します。",
    "hysan_recovery_fund": "Hysan の Elsa 回復基金",
    "hysan_recovery_fund_description": "Hysan は 2026 年から Elsa に片思いしていて、その話を止めません。ここのコーヒー 1 杯ごとに、彼の回復と mod が資金援助されます。☕",
    "appIconTitle": "アイコンを選択",
    "appIconSubtitle": "初回は iOS が確認を表示します。ホーム画面の更新に数秒かかることがあります。",
    "appIconUnavailableMessage": "この Spotify は App Store からインストールされたため、iOS はホーム画面のアイコンをアプリの署名済みバンドル内に保持し、mod による変更を許しません。アイコンを登録して署名した EeveeSpotify のパッチ済み IPA をインストールすれば、切り替えが機能します。",
    "iconSelected": "選択中",
    "iconTapToApply": "タップして適用",
    "prettifyIconNames": "アイコン名を見やすく",
    "prettifyIconNamesDescription": "アンダースコア、ハイフン、camelCase を空白に変換します",
}

KO = {
    "spicylyrics_description": "SpicyLyrics는 단어별 가라오케 가사를 제공합니다.",
    "spicylyrics_key_missing": "SpicyLyrics API 키 없음",
    "spicylyrics_key_invalid": "SpicyLyrics API 키가 거부됨",
    "petitlyrics_description": "PetitLyrics: 시간 동기화된 일본어 가사와 일부 외국어 가사를 다수 제공합니다.",
    "karaoke_word_synced_button": "커스텀 가사 보기",
    "amoled_theme": "AMOLED 블랙 테마",
    "hide_jam_from_menu": "메뉴에서 Jam 숨기기",
    "hide_jam_from_menu_description": "트랙/재생목록 컨텍스트 메뉴, 기기 선택기, 대기열에서 \"Jam 시작\"을 제거합니다.",
    "block_rating_dialogs": "앱 평가 대화상자 차단",
    "block_rating_dialogs_description": "App Store 별점 요청과 앱 내 리뷰 요청을 표시하지 않습니다.",
    "hysan_recovery_fund": "Hysan의 Elsa 회복 기금",
    "hysan_recovery_fund_description": "Hysan은 2026년부터 Elsa에게 반해 그 얘기를 끊임없이 합니다. 여기의 커피 한 잔이 그의 회복과 모드를 지원합니다. ☕",
    "appIconTitle": "아이콘 선택",
    "appIconSubtitle": "처음에는 iOS가 확인을 표시합니다. 홈 화면이 새로고침되는 데 몇 초가 걸릴 수 있습니다.",
    "appIconUnavailableMessage": "이 Spotify는 App Store에서 설치되어 iOS가 홈 화면 아이콘을 앱의 서명된 번들 안에 유지하며 모드가 변경하지 못하게 합니다. 아이콘이 등록된 상태로 서명된 EeveeSpotify의 패치된 IPA를 설치하면 변경이 작동합니다.",
    "iconSelected": "선택됨",
    "iconTapToApply": "탭하여 적용",
    "prettifyIconNames": "아이콘 이름 예쁘게 표시",
    "prettifyIconNamesDescription": "밑줄, 하이픈, camelCase를 공백으로 변환합니다",
}

HU = {
    "spicylyrics_description": "A SpicyLyrics szavankénti karaoke dalszöveget biztosít.",
    "spicylyrics_key_missing": "Nincs SpicyLyrics API-kulcs",
    "spicylyrics_key_invalid": "A SpicyLyrics API-kulcs elutasítva",
    "petitlyrics_description": "PetitLyrics: Sok időszinkronizált japán és néhány nemzetközi dalszöveget kínál.",
    "karaoke_word_synced_button": "Egyéni dalszöveg-nézet",
    "amoled_theme": "AMOLED fekete téma",
    "hide_jam_from_menu": "Jam elrejtése a menüből",
    "hide_jam_from_menu_description": "Eltávolítja a \"Jam indítása\" elemet a szám/lejátszási lista helyi menüiből, az eszközválasztóból és a sorból.",
    "block_rating_dialogs": "Alkalmazás-értékelő párbeszédablakok tiltása",
    "block_rating_dialogs_description": "Elnyeli az App Store csillagos értékelésre való felkéréseit és az alkalmazáson belüli véleménykéréseket.",
    "hysan_recovery_fund": "Hysan Elsa-felépülési alapja",
    "hysan_recovery_fund_description": "Hysan 2026 óta odavan Elzáért, és nem hagyja abba a beszédet róla. Minden kávé itt az ő felépülését — és a modot — finanszírozza. ☕",
    "appIconTitle": "Ikon kiválasztása",
    "appIconSubtitle": "Az iOS először megerősítést jelenít meg. A kezdőképernyő frissítése eltarthat néhány másodpercig.",
    "appIconUnavailableMessage": "Ezt a Spotifyt az App Storeból telepítették, ezért az iOS a kezdőképernyő ikonját az alkalmazás aláírt csomagjában tartja, és nem engedi a modnak megváltoztatni. Telepítsd az EeveeSpotify javított IPA-összeállítását — a regisztrált ikonokkal aláírva —, és a váltás működni fog.",
    "iconSelected": "Kiválasztva",
    "iconTapToApply": "Koppints az alkalmazáshoz",
    "prettifyIconNames": "Ikonnevek szépítése",
    "prettifyIconNamesDescription": "Az aláhúzásokat, kötőjeleket és a camelCase-et szóközökké alakítja",
}

DA = {
    "spicylyrics_description": "SpicyLyrics leverer karaoke-tekst ord for ord.",
    "spicylyrics_key_missing": "Ingen SpicyLyrics API-nøgle",
    "spicylyrics_key_invalid": "SpicyLyrics API-nøgle afvist",
    "petitlyrics_description": "PetitLyrics: Tilbyder masser af tidssynkroniserede japanske og nogle internationale tekster.",
    "karaoke_word_synced_button": "Brugerdefineret sangtekstvisning",
    "amoled_theme": "AMOLED sort tema",
    "hide_jam_from_menu": "Skjul Jam fra menuen",
    "hide_jam_from_menu_description": "Fjerner \"Start en Jam\" fra genvejsmenuer for numre/afspilningslister, enhedsvælgeren og køen.",
    "block_rating_dialogs": "Bloker app-vurderingsdialoger",
    "block_rating_dialogs_description": "Undertrykker App Stores stjernevurderingsanmodninger og anmodninger om anmeldelse i appen.",
    "hysan_recovery_fund": "Hysans Elsa-genopretningsfond",
    "hysan_recovery_fund_description": "Hysan har været forelsket i Elsa siden 2026 og holder ikke op med at tale om det. Enhver kop kaffe her finansierer hans genopretning — og modden. ☕",
    "appIconTitle": "Vælg ikon",
    "appIconSubtitle": "iOS viser en bekræftelse første gang. Hjemmeskærmen kan tage et par sekunder om at opdatere.",
    "appIconUnavailableMessage": "Denne Spotify blev installeret fra App Store, så iOS holder sit hjemmeskærm-ikon inde i appens signede bundle og lader ikke mod ændre det. Installer en patched IPA-build af EeveeSpotify — signeret med ikonerne registreret — så skiftet virker.",
    "iconSelected": "Valgt",
    "iconTapToApply": "Tryk for at anvende",
    "prettifyIconNames": "Gør ikonnavne pæne",
    "prettifyIconNamesDescription": "Konverterer understregninger, bindestreger og camelCase til mellemrum",
}

BG = {
    "spicylyrics_description": "SpicyLyrics предоставя караоке текст дума по дума.",
    "spicylyrics_key_missing": "Няма API ключ за SpicyLyrics",
    "spicylyrics_key_invalid": "API ключът за SpicyLyrics е отхвърлен",
    "petitlyrics_description": "PetitLyrics: Предлага много синхронизирани по време японски и някои международни текстове.",
    "karaoke_word_synced_button": "Изглед с персонализиран текст",
    "amoled_theme": "Черна тема AMOLED",
    "hide_jam_from_menu": "Скрий Jam от менюто",
    "hide_jam_from_menu_description": "Премахва \"Започни Jam\" от контекстните менюта на трак/плейлист, от избора на устройство и от опашката.",
    "block_rating_dialogs": "Блокирай диалогите за оценка",
    "block_rating_dialogs_description": "Потиска исканията за звезден рейтинг от App Store и исканията за преглед в приложението.",
    "hysan_recovery_fund": "Фонд за възстановяване на Хисан заради Елза",
    "hysan_recovery_fund_description": "Хисан е влюбен в Елза от 2026 г. и не спира да говори за това. Всяко кафе тук финансира възстановяването му — и мода. ☕",
    "appIconTitle": "Изберете икона",
    "appIconSubtitle": "iOS показва потвърждение при първия път. Началният екран може да отнеме няколко секунди за обновяване.",
    "appIconUnavailableMessage": "Този Spotify е инсталиран от App Store, затова iOS пази иконата му на началния екран в подписания пакет на приложението и не позволява на мода да я променя. Инсталирайте кръпена IPA компилация на EeveeSpotify — подписана с регистрираните икони — и смяната работи.",
    "iconSelected": "Избрано",
    "iconTapToApply": "Докоснете за прилагане",
    "prettifyIconNames": "Хубави имена на икони",
    "prettifyIconNamesDescription": "Превръща долни черти, тирета и camelCase в интервали",
}

HR = {
    "spicylyrics_description": "SpicyLyrics pruža karaoke tekstove riječ po riječ.",
    "spicylyrics_key_missing": "Nema SpicyLyrics API ključa",
    "spicylyrics_key_invalid": "SpicyLyrics API ključ odbijen",
    "petitlyrics_description": "PetitLyrics: Nudi mnoštvo vremenski sinkroniziranih japanskih i neke međunarodne tekstove.",
    "karaoke_word_synced_button": "Prikaz vlastitih tekstova",
    "amoled_theme": "AMOLED crna tema",
    "hide_jam_from_menu": "Sakrij Jam iz izbornika",
    "hide_jam_from_menu_description": "Uklanja \"Započni Jam\" iz kontekstnih izbornika pjesme/popisa za reprodukciju, odabira uređaja i reda čekanja.",
    "block_rating_dialogs": "Blokiraj dijaloške okvire ocjena",
    "block_rating_dialogs_description": "Potiskuje App Store upite za zvjezdice i upite za recenziju u aplikaciji.",
    "hysan_recovery_fund": "Hysanov fond za oporavak zbog Else",
    "hysan_recovery_fund_description": "Hysan je od 2026. zaljubljen u Elsu i ne prestaje o tome pričati. Svaka kava ovdje financira njegov oporavak — i mod. ☕",
    "appIconTitle": "Odaberi ikonu",
    "appIconSubtitle": "iOS će prvi put pokazati potvrdu. Početnom zaslonu može trebati nekoliko sekundi za osvježavanje.",
    "appIconUnavailableMessage": "Ovaj Spotify je instaliran iz App Storea, pa iOS drži njegovu ikonu početnog zasluna unutar potpisanog paketa aplikacije i ne dopušta modu da je promijeni. Instalirajte zakrpljenu IPA verziju EeveeSpotifyja — potpisanu s registriranim ikonama — i zamjena radi.",
    "iconSelected": "Odabrano",
    "iconTapToApply": "Dodirnite za primjenu",
    "prettifyIconNames": "Uljepšaj nazive ikona",
    "prettifyIconNamesDescription": "Pretvara podcrtaje, crtice i camelCase u razmake",
}

RO = {
    "spicylyrics_description": "SpicyLyrics oferă versuri karaoke cuvânt cu cuvânt.",
    "spicylyrics_key_missing": "Fără cheie API SpicyLyrics",
    "spicylyrics_key_invalid": "Cheie API SpicyLyrics respinsă",
    "petitlyrics_description": "PetitLyrics: Oferă multe versuri japoneze sincronizate și unele internaționale.",
    "karaoke_word_synced_button": "Vizualizare versuri personalizate",
    "amoled_theme": "Temă neagră AMOLED",
    "hide_jam_from_menu": "Ascunde Jam din meniu",
    "hide_jam_from_menu_description": "Elimină \"Începe un Jam\" din meniurile contextuale ale piesei/playliștului, din selectorul de dispozitive și din coadă.",
    "block_rating_dialogs": "Blochează dialogurile de evaluare",
    "block_rating_dialogs_description": "Suprimă cererile de stele din App Store și cererile de recenzie din aplicație.",
    "hysan_recovery_fund": "Fondul de recuperare Elsa al lui Hysan",
    "hysan_recovery_fund_description": "Lui Hysan îi place de Elsa din 2026 și nu încetează să vorbească despre asta. Fiecare cafea de aici îi finanțează recuperarea — și modul. ☕",
    "appIconTitle": "Alege pictograma",
    "appIconSubtitle": "iOS afișează o confirmare prima dată. Ecranul principal poate dura câteva secunde să se actualizeze.",
    "appIconUnavailableMessage": "Acest Spotify a fost instalat din App Store, așa că iOS își păstrează pictograma ecranului principal în pachetul semnat al aplicației și nu lasă modul să o schimbe. Instalează o versiune IPA patch-uită a EeveeSpotify — semnată cu pictogramele înregistrate — iar schimbarea funcționează.",
    "iconSelected": "Selectat",
    "iconTapToApply": "Atinge pentru a aplica",
    "prettifyIconNames": "Înfrumusețează numele pictogramelor",
    "prettifyIconNamesDescription": "Transformă liniile de subliniere, cratimele și camelCase în spații",
}

CA = {
    "spicylyrics_description": "SpicyLyrics ofereix lletres de karaoke paraula per paraula.",
    "spicylyrics_key_missing": "Sense clau API de SpicyLyrics",
    "spicylyrics_key_invalid": "Clau API de SpicyLyrics rebutjada",
    "petitlyrics_description": "PetitLyrics: Ofereix moltes lletres japoneses sincronitzades i algunes internacionals.",
    "karaoke_word_synced_button": "Vista de lletres personalitzades",
    "amoled_theme": "Tema negre AMOLED",
    "hide_jam_from_menu": "Amaga Jam del menú",
    "hide_jam_from_menu_description": "Elimina \"Inicia un Jam\" dels menús contextuals de cançó/llista, del selector de dispositius i de la cua.",
    "block_rating_dialogs": "Bloca els diàlegs de valoració",
    "block_rating_dialogs_description": "Suprimeix les peticions d'estrelles de l'App Store i les peticions de ressenya integrades.",
    "hysan_recovery_fund": "Fons de recuperació de l'Elsa d'en Hysan",
    "hysan_recovery_fund_description": "En Hysan està enamorat de l'Elsa des del 2026 i no para de parlar-hi. Cada cafè d'aquí finança la seva recuperació — i el mod. ☕",
    "appIconTitle": "Tria la icona",
    "appIconSubtitle": "L'iOS mostra una confirmació el primer cop. La pantalla d'inici pot trigar uns segons a actualitzar-se.",
    "appIconUnavailableMessage": "Aquest Spotify s'ha instal·lat des de l'App Store, així que l'iOS manté la seva icona de la pantalla d'inici dins del paquet signat de l'aplicació i no deixa que el mod la canviï. Instal·la un IPA parchejat d'EeveeSpotify — signat amb les icones registrades — i el canvi funciona.",
    "iconSelected": "Seleccionada",
    "iconTapToApply": "Toca per aplicar",
    "prettifyIconNames": "Embelleix els noms de les icones",
    "prettifyIconNamesDescription": "Converteix guions baixos, guions i camelCase en espais",
}

AZ = {
    "spicylyrics_description": "SpicyLyrics söz-söz karaoke mətnləri təqdim edir.",
    "spicylyrics_key_missing": "SpicyLyrics API açarı yoxdur",
    "spicylyrics_key_invalid": "SpicyLyrics API açarı rədd edildi",
    "petitlyrics_description": "PetitLyrics: Çoxlu sayda vaxtla sinxronlaşdırılmış yapon və bəzi beynəlxalq mətnlər təklif edir.",
    "karaoke_word_synced_button": "Fərdi mətn görünüşü",
    "amoled_theme": "AMOLED qara teması",
    "hide_jam_from_menu": "Jam-ı menüden gizlət",
    "hide_jam_from_menu_description": "Trek/pleylist kontekst menyularından, cihaz seçicisindən və növbədən \"Jam Başlat\"ı çıxarır.",
    "block_rating_dialogs": "Tətbiq reytinq dialoqlarını blokla",
    "block_rating_dialogs_description": "App Store ulduz reytinq sorğularını və tətbiq daxili rəy sorğularını basır.",
    "hysan_recovery_fund": "Hysanın Elsa sağalma fondu",
    "hysan_recovery_fund_description": "Hysan 2026-cı ildən bəri Elsa'ya aşiqdir və bundan danışmağı dayandırmır. Buradaki hər fincan qəhvə onun sağalmasını — və modu maliyyələşdirir. ☕",
    "appIconTitle": "İşarə seç",
    "appIconSubtitle": "iOS ilk dəfə təsdiq göstərəcək. Ana ekranın yenilənməsi bir neçə saniyə çəkə bilər.",
    "appIconUnavailableMessage": "Bu Spotify App Store-dan quraşdırılıb, ona görə iOS ana ekran işarəsini tətbiqin imzalanmış paketində saxlayır və modun dəyişməsinə icazə vermir. EeveeSpotify-nin yamalanmış IPA qurasdırın — işarələr qeydiyyatlı imzalanmış — və dəyişmə işləyir.",
    "iconSelected": "Seçilib",
    "iconTapToApply": "Tətbiq etmək üçün toxun",
    "prettifyIconNames": "İşarə adlarını gözəlləşdir",
    "prettifyIconNamesDescription": "Alt xəttləri, defisləri və camelCase-i boşluqlara çevirir",
}

NP = {
    "spicylyrics_description": "SpicyLyrics शब्द-शब्द क्याराओके गीतहरू उपलब्ध गर्छ।",
    "spicylyrics_key_missing": "SpicyLyrics API कुञ्जी छैन",
    "spicylyrics_key_invalid": "SpicyLyrics API कुञ्जी अस्वीकृत भयो",
    "petitlyrics_description": "PetitLyrics: समय-समकालिक धेरै जापानी र केही अन्तर्राष्ट्रिय गीतहरू प्रदान गर्छ।",
    "karaoke_word_synced_button": "अनुकूलन गीत दृश्य",
    "amoled_theme": "AMOLED कालो थिम",
    "hide_jam_from_menu": "मेनुबाट Jam लुकाउनुहोस्",
    "hide_jam_from_menu_description": "गीत/प्ले सूचीका सन्दर्भ मेनु, यन्त्र छनोट र लाइनबाट \"Jam सुरु गर्नुहोस्\" हटाउँछ।",
    "block_rating_dialogs": "एप मूल्याङ्कन संवाद रोक्नुहोस्",
    "block_rating_dialogs_description": "App Store का तारा मूल्याङ्कन अनुरोध र एपभित्रका समीक्षा अनुरोध दबाउँछ।",
    "hysan_recovery_fund": "हिसानको एल्सा स्वास्थ्य कोष",
    "hysan_recovery_fund_description": "हिसान २०२६ देखि एल्सामाथि मोहित छ र त्यसैको कुरा गर्न छोड्दैन। यहाँको हरेक कफीले उसको स्वास्थ्य — र मोड — को खर्च बोक्छ। ☕",
    "appIconTitle": "आइकन छान्नुहोस्",
    "appIconSubtitle": "iOS ले पहिलो पटक पुष्टि देखाउँछ। गृह स्क्रिन रिफ्रेस हुन केही सेकेन्ड लाग्न सक्छ।",
    "appIconUnavailableMessage": "यो Spotify App Store बाट स्थापना भएको हुनाले iOS ले गृह स्क्रिन आइकन एपको हस्ताक्षरित बन्डलभित्रै राख्छ र मोडले बदल्न दिँदैन। EeveeSpotify को प्याच गरिएको IPA भर्सन — दर्ता आइकनसहित हस्ताक्षरित — स्थापना गर्नुहोस्, अनि परिवर्तनले काम गर्छ।",
    "iconSelected": "छानिएको",
    "iconTapToApply": "लागू गर्न थिच्नुहोस्",
    "prettifyIconNames": "आइकन नाम सुन्दर बनाउनुहोस्",
    "prettifyIconNamesDescription": "अन्डरस्कोर, हाइफन र camelCase लाई खाली ठाउँमा बदल्छ",
}

FA = {
    "spicylyrics_description": "SpicyLyrics متن کارائوئه کلمه‌به‌کلمه ارائه می‌دهد.",
    "spicylyrics_key_missing": "کلید API اسپایسی‌لیریکس وجود ندارد",
    "spicylyrics_key_invalid": "کلید API اسپایسی‌لیریکس رد شد",
    "petitlyrics_description": "PetitLyrics: تعداد زیادی متن ژاپنی همگام‌شده با زمان و برخی متن‌های بین‌المللی ارائه می‌دهد.",
    "karaoke_word_synced_button": "نمای متن سفارشی",
    "amoled_theme": "تم سیاه AMOLED",
    "hide_jam_from_menu": "مخفی کردن Jam از منو",
    "hide_jam_from_menu_description": "گزینه «شروع Jam» را از منوهای متنی آهنگ/پلی‌لیست، انتخابگر دستگاه و صف حذف می‌کند.",
    "block_rating_dialogs": "مسدود کردن پنجره‌های امتیازدهی",
    "block_rating_dialogs_description": "درخواست‌های ستاره‌دهی اپ استور و درخواست‌های بازخورد درون‌برنامه‌ای را سرکوب می‌کند.",
    "hysan_recovery_fund": "صندوق بهبودی السای هیسان",
    "hysan_recovery_fund_description": "هیسان از سال ۲۰۲۶ عاشق الساست و مدام درباره‌اش حرف می‌زند. هر قهوه اینجا هزینه بهبودی او — و مود — را تأمین می‌کند. ☕",
    "appIconTitle": "انتخاب آیکون",
    "appIconSubtitle": "در اولین تغییر، iOS یک پیام تأیید نمایش می‌دهد. ممکن است چند ثانیه طول بکشد تا صفحه اصلی به‌روزرسانی شود.",
    "appIconUnavailableMessage": "این اسپاتیفای از اپ استور نصب شده، بنابراین iOS آیکون صفحه اصلی را درون بسته امضاشده برنامه نگه می‌دارد و اجازه تغییر به مود نمی‌دهد. نسخه IPA وصله‌شده EeveeSpotify را نصب کنید — با آیکون‌های ثبت‌شده امضا شده — و تغییر کار می‌کند.",
    "iconSelected": "انتخاب شده",
    "iconTapToApply": "برای اعمال لمس کنید",
    "prettifyIconNames": "زیباسازی نام آیکون‌ها",
    "prettifyIconNamesDescription": "زیرخط‌ها، خط تیره‌ها و camelCase را به فاصله تبدیل می‌کند",
}

AR_EG = {
    "spicylyrics_description": "SpicyLyrics بيقدّم كلمات كاريوكي كلمة كلمة.",
    "spicylyrics_key_missing": "مفيش مفتاح API لـ SpicyLyrics",
    "spicylyrics_key_invalid": "مفتاح API بتاع SpicyLyrics اتردّ",
    "petitlyrics_description": "PetitLyrics: بيقدّم كلام ياباني متزامن بالوقت كتير وكمان شوية كلام عالمي.",
    "karaoke_word_synced_button": "شاشة كلمات مخصصة",
    "amoled_theme": "ثيم أسود AMOLED",
    "hide_jam_from_menu": "اخفي Jam من المنيو",
    "hide_jam_from_menu_description": "بيشيل \"ابدأ Jam\" من منيو الأغنية/البليليست، ومن اختيار الجهاز، ومن الكيو.",
    "block_rating_dialogs": "اقفل رسائل تقييم التطبيق",
    "block_rating_dialogs_description": "بيمنع طلبات النجوم من اب ستور وطلبات المراجعة جوه التطبيق.",
    "hysan_recovery_fund": "صندوق شفاء هيسان من إلسا",
    "hysan_recovery_fund_description": "هيسان واقع في حب إلسا من 2026 ومش بيسكت عن الكلام في الموضوع ده. كل قهوة هنا بتموّل شفاه — والمود. ☕",
    "appIconTitle": "اختار الأيقونة",
    "appIconSubtitle": "نظام iOS/iPadOS هيطلعلك رسالة أول ما تغير الأيقونة، والشاشة الرئيسية ممكن تاخد وقت شوية عقبال ما تتحدث.",
    "appIconUnavailableMessage": "السبوتيفاي ده متسطب من اب ستور، فـ iOS بيحتفظ بأيقونة الشاشة الرئيسية جوه باكدج التطبيق الموقّع ومش هيسيب المود يغيّرها. سطب نسخة IPA مترقّعة من EeveeSpotify — موقّعة بالأيقونات متسجلة — وساعتها التغيير هيشتغل.",
    "iconSelected": "مختار",
    "iconTapToApply": "دوس علشان تطبّق",
    "prettifyIconNames": "شوّف أسماء الأيقونات",
    "prettifyIconNamesDescription": "بيحوّل الشرطات السفلية والشرطات وcamelCase لمسافات",
}

TABLES = {
    "en": EN, "de": DE, "de-CH": DE, "fr": FR, "es": ES, "it": IT,
    "pt": PT, "pt-BR": PT_BR, "ru": RU, "uk": UK, "pl": PL, "tr": TR,
    "vi": VI, "zh-CN": ZH_CN, "zh-TW": ZH_TW, "ja": JA, "ko": KO, "hu": HU,
    "da": DA, "bg": BG, "hr": HR, "ro": RO, "ca": CA, "az": AZ, "np": NP,
    "fa": FA, "ar-EG": AR_EG,
}

HEADER = "// Ported features: the SpicyLyrics karaoke view, the AMOLED black theme, the Jam/rating\n// toggles, Hysan's recovery fund, and the app-icon picker.\n"

KEY_RE = re.compile(r'^\s*"?([A-Za-z0-9_.]+)"?\s*=\s*"')


def file_keys(path):
    have = set()
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = KEY_RE.match(line)
            if m:
                have.add(m.group(1))
    return have


def escape(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


changed = []
for lang, table in TABLES.items():
    path = os.path.join(BUNDLE, lang + ".lproj", "Localizable.strings")
    have = file_keys(path)
    missing = [(k, v) for k, v in table.items() if k not in have]
    if not missing:
        continue
    with open(path, encoding="utf-8") as f:
        content = f.read()
    if content and not content.endswith("\n"):
        content += "\n"
    content += "\n" + HEADER
    for key, value in missing:
        content += f'{key} = "{escape(value)}";\n'
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    lint = subprocess.run(["plutil", "-lint", path], capture_output=True, text=True)
    if lint.returncode != 0:
        sys_exit = lint.stdout + lint.stderr
        raise SystemExit(f"{lang}: lint failed:\n{sys_exit}")
    changed.append(f"{lang:8s} +{len(missing)}")

print("\n".join(changed) if changed else "nothing to do")
