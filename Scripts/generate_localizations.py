#!/usr/bin/env python3
"""Generate Localizable.xcstrings with en, cs, uk, ru, sk translations.

Sources for translations:
- Android app strings.xml (values-cs, values-uk, values-ru, values-sk) — used verbatim
  wherever iOS terminology matches Android.
- Fresh translation for iOS-only / HIG-specific strings (see Documentation/LocalizationNotes.md).
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "CharlesTranslator", "Resources", "Localizable.xcstrings")

LANGUAGES = ["en", "cs", "uk", "ru", "sk"]

# Each entry: key -> dict(lang -> value). "en" is the source-language value.
STRINGS = {
    # ---- Languages (verbatim from Android cz_label..ru_label) ----
    "language.cs": {
        "en": "Czech", "cs": "Čeština", "uk": "Чеська", "ru": "Чешский", "sk": "Čeština",
    },
    "language.en": {
        "en": "English", "cs": "Angličtina", "uk": "Англійська", "ru": "Английский", "sk": "Angličtina",
    },
    "language.fr": {
        "en": "French", "cs": "Francouzština", "uk": "Французька", "ru": "Французский", "sk": "Francúzština",
    },
    "language.pl": {
        "en": "Polish", "cs": "Polština", "uk": "Польська", "ru": "Польский", "sk": "Poľština",
    },
    "language.ru": {
        "en": "Russian", "cs": "Ruština", "uk": "Російська", "ru": "Русский", "sk": "Ruština",
    },
    "language.uk": {
        "en": "Ukrainian", "cs": "Ukrajinština", "uk": "Українська", "ru": "Украинский", "sk": "Ukrajinčina",
    },

    # ---- Language picker titles (iOS-only) ----
    "picker.sourceLanguage": {
        "en": "Translate from",
        "cs": "Přeložit z",
        "uk": "Перекласти з",
        "ru": "Перевести с",
        "sk": "Preložiť z",
    },
    "picker.targetLanguage": {
        "en": "Translate to",
        "cs": "Přeložit do",
        "uk": "Перекласти на",
        "ru": "Перевести на",
        "sk": "Preložiť do",
    },

    # ---- Speech error strings (iOS-only wording) ----
    "error.speechPermissionDenied": {
        "en": "Enable Microphone and Speech Recognition access in Settings to use voice input.",
        "cs": "Pro použití hlasového vstupu povolte v Nastavení přístup k mikrofonu a rozpoznávání řeči.",
        "uk": "Щоб використовувати голосовий ввід, увімкніть у Налаштуваннях доступ до мікрофона та розпізнавання мовлення.",
        "ru": "Чтобы использовать голосовой ввод, разрешите в Настройках доступ к микрофону и распознаванию речи.",
        "sk": "Ak chcete používať hlasový vstup, povoľte v Nastaveniach prístup k mikrofónu a rozpoznávaniu reči.",
    },
    "error.speechUnavailable": {
        "en": "Speech recognition isn't available right now.",
        "cs": "Rozpoznávání řeči momentálně není k dispozici.",
        "uk": "Розпізнавання мовлення зараз недоступне.",
        "ru": "Распознавание речи сейчас недоступно.",
        "sk": "Rozpoznávanie reči momentálne nie je k dispozícii.",
    },

    # ---- Translation error strings ----
    "error.tooLarge": {
        "en": "This text is too long to translate.",
        "cs": "Tento text je příliš dlouhý na překlad.",
        "uk": "Цей текст занадто довгий для перекладу.",
        "ru": "Этот текст слишком длинный для перевода.",
        "sk": "Tento text je príliš dlhý na preklad.",
    },
    "error.timeout": {
        "en": "Translation took too long and timed out.",
        "cs": "Překlad trval příliš dlouho a vypršel časový limit.",
        "uk": "Переклад тривав занадто довго, і час очікування вичерпано.",
        "ru": "Перевод занял слишком много времени, и время ожидания истекло.",
        "sk": "Preklad trval príliš dlho a vypršal časový limit.",
    },
    "error.unsupportedApiVersion": {
        # Android: dialog_unsupported_api_message
        "en": "This app version is no longer supported. Please update.",
        "cs": "Omlouváme se, ale je nutné aplikaci aktualizovat, jinak nebude dále fungovat.",
        "uk": "Вибачте, але додаток необхідно оновити, інакше він не зможе працювати далі.",
        "ru": "Извините, но приложение необходимо обновить, иначе оно больше не будет работать.",
        "sk": "Ospravedlňujeme sa, ale je nutné aplikáciu aktualizovať, inak nemôže ďalej fungovať.",
    },
    "error.network": {
        # Android: offline_text ("Check your internet connection")
        "en": "Couldn't reach the translation service. Check your connection.",
        "cs": "Nelze se připojit k překladové službě. Zkontrolujte připojení k internetu.",
        "uk": "Не вдалося зв'язатися зі службою перекладу. Перевірте підключення до інтернету.",
        "ru": "Не удалось связаться со службой перевода. Проверьте подключение к интернету.",
        "sk": "Nepodarilo sa pripojiť k prekladovej službe. Skontrolujte internetové pripojenie.",
    },
    "error.decoding": {
        "en": "The translation service returned an unexpected response.",
        "cs": "Překladová služba vrátila neočekávanou odpověď.",
        "uk": "Служба перекладу повернула несподівану відповідь.",
        "ru": "Служба перевода вернула неожиданный ответ.",
        "sk": "Prekladová služba vrátila neočakávanú odpoveď.",
    },
    "error.unknown": {
        # Android: api_error ("Translation failed, please try again")
        "en": "Something went wrong while translating.",
        "cs": "Při překladu se něco pokazilo.",
        "uk": "Щось пішло не так під час перекладу.",
        "ru": "Что-то пошло не так во время перевода.",
        "sk": "Počas prekladu sa niečo pokazilo.",
    },
    "error.unsupportedPair": {
        "en": "Cannot translate between these two languages.",
        "cs": "Mezi těmito dvěma jazyky nelze překládat.",
        "uk": "Неможливо перекласти між цими двома мовами.",
        "ru": "Невозможно перевести между этими двумя языками.",
        "sk": "Medzi týmito dvoma jazykmi nemožno prekladať.",
    },

    # ---- Consent sheet ----
    "Data processing": {
        # Android: dialog_data_processing_title
        "en": "Data processing",
        "cs": "Zpracování dat",
        "uk": "Опрацювання даних",
        "ru": "Обработка данных",
        "sk": "Spracovanie dát",
    },
    # Android: dialog_data_processing_message
    "I am giving the Institute of Formal and Applied Linguistics, Faculty of Mathematics and Physics, Charles University (UFAL MFF UK) consent to collect my inputs and translations. The texts will be anonymized and may be used for future development of the system.": {
        "en": "I am giving the Institute of Formal and Applied Linguistics, Faculty of Mathematics and Physics, Charles University (UFAL MFF UK) consent to collect my inputs and translations. The texts will be anonymized and may be used for future development of the system.",
        "cs": "Souhlasím s tím, aby Ústav formální a aplikované lingvistiky MFF UK ukládal vstupy a výstupy z překladače. V případě souhlasu mohou být anonymizované texty využity pro další vývoj systému.",
        "uk": "Я надаю Інституту формальної і прикладної лінгвістики, Фізико-математичного факультету Карлового університету в Празі (UFAL MFF UK) згоду на зберігання і опрацювання наданих мною текстів і отриманих перекладів. Тексти будуть анонімізовані і можуть бути використані для подальшого удосконалення системи.",
        "ru": "Я даю Институту формальной и прикладной лингвистики, физико-математического факультета Карлова университета в Праге (UFAL MFF UK) согласие на сбор и обработку моих текстов и полученных переводов. Тексты будут анонимизированы и могут быть использованы для дальнейшего развития системы.",
        "sk": "Súhlasím s tým, aby Ústav formální a aplikované lingvistiky MFF UK ukladal vstupy a výstupy z prekladača. V prípade súhlasu môžu byť anonymizované texty využité na ďalší vývoj systému.",
    },
    "You can change this decision anytime in Settings.": {
        "en": "You can change this decision anytime in Settings.",
        "cs": "Toto rozhodnutí můžete kdykoli změnit v Nastavení.",
        "uk": "Ви можете будь-коли змінити це рішення в Налаштуваннях.",
        "ru": "Вы можете изменить это решение в любое время в Настройках.",
        "sk": "Toto rozhodnutie môžete kedykoľvek zmeniť v Nastaveniach.",
    },
    "Agree": {
        # Android: dialog__data_processing_agree
        "en": "Agree",
        "cs": "Souhlasím",
        "uk": "Я надаю згоду",
        "ru": "Я даю согласие",
        "sk": "Súhlasím",
    },
    "Disagree": {
        # Android: dialog__data_processing_disagree
        "en": "Disagree",
        "cs": "Nesouhlasím",
        "uk": "Я не надаю згоду",
        "ru": "Я не даю согласие",
        "sk": "Nesúhlasím",
    },

    # ---- Translate screen ----
    "Enter text": {
        # Android: insert_text
        "en": "Enter text",
        "cs": "Napište text",
        "uk": "Введіть текст",
        "ru": "Введите текст",
        "sk": "Napíšte text",
    },
    "Stop listening": {
        "en": "Stop listening",
        "cs": "Ukončit poslech",
        "uk": "Зупинити прослуховування",
        "ru": "Остановить прослушивание",
        "sk": "Ukončiť počúvanie",
    },
    "Start voice input": {
        "en": "Start voice input",
        "cs": "Spustit hlasový vstup",
        "uk": "Почати голосовий ввід",
        "ru": "Начать голосовой ввод",
        "sk": "Spustiť hlasový vstup",
    },
    "Swap languages": {
        # Android: swap_cd
        "en": "Swap languages",
        "cs": "Prohodit jazyky",
        "uk": "Поміняти місцями мови",
        "ru": "Поменять местами языки",
        "sk": "Prehodiť jazyky",
    },
    "Done": {
        "en": "Done",
        "cs": "Hotovo",
        "uk": "Готово",
        "ru": "Готово",
        "sk": "Hotovo",
    },
    "Close": {
        "en": "Close",
        "cs": "Zavřít",
        "uk": "Закрити",
        "ru": "Закрыть",
        "sk": "Zavrieť",
    },
    "Charles Translator": {
        # App name / proper noun — identity
        "en": "Charles Translator",
        "cs": "Charles Translator",
        "uk": "Charles Translator",
        "ru": "Charles Translator",
        "sk": "Charles Translator",
    },
    "%@/%@": {
        "en": "%1$@/%2$@",
        "cs": "%1$@/%2$@",
        "uk": "%1$@/%2$@",
        "ru": "%1$@/%2$@",
        "sk": "%1$@/%2$@",
    },

    # ---- Conversation screen ----
    "Tap a microphone to start a conversation": {
        # Android: conversation_empty
        "en": "Tap a microphone to start a conversation",
        "cs": "Pro začátek konverzace klikněte na mikrofon v dolní části obrazovky",
        "uk": "Для початку розмови клацніть мікрофон внизу екрана",
        "ru": "Чтобы начать разговор, нажмите на микрофон внизу экрана",
        "sk": "Ak chcete začať konverzáciu, kliknite na mikrofón v dolnej časti obrazovky",
    },
    "Conversation": {
        # Android: conversation_title
        "en": "Conversation",
        "cs": "Konverzace",
        "uk": "Розмови",
        "ru": "Разговоры",
        "sk": "Konverzácia",
    },
    "Clear": {
        # Android: clear_cd ("vymazat text") — HIG: destructive button label
        "en": "Clear",
        "cs": "Vymazat",
        "uk": "Очистити",
        "ru": "Очистить",
        "sk": "Vymazať",
    },

    # ---- History screen ----
    "History": {
        # Android: history_title
        "en": "History",
        "cs": "Historie překladů",
        "uk": "Історія перекладів",
        "ru": "История переводов",
        "sk": "História prekladov",
    },
    "All": {
        # Android: history_bottom_all
        "en": "All",
        "cs": "Vše",
        "uk": "Всі",
        "ru": "Все",
        "sk": "Všetko",
    },
    "Favourites": {
        # Android: history_bottom_favourites
        "en": "Favourites",
        "cs": "Oblíbené",
        "uk": "Обране",
        "ru": "Избранное",
        "sk": "Obľúbené",
    },
    "History filter": {
        "en": "History filter",
        "cs": "Filtr historie",
        "uk": "Фільтр історії",
        "ru": "Фильтр истории",
        "sk": "Filter histórie",
    },
    "No history yet": {
        # Android: history_all_empty
        "en": "No history yet",
        "cs": "Během překládání se texty automaticky ukládají a zde je jejich historie.",
        "uk": "Під час перекладу тексти зберігаються автоматично. Ви можете побачити тут їхню історію.",
        "ru": "Во время перевода тексты сохраняются автоматически. Вы можете увидеть их историю здесь.",
        "sk": "V priebehu prekladania sa texty automaticky ukladajú a uvidíte tu ich históriu.",
    },
    "No favourites yet": {
        # Android: history_favourites_empty
        "en": "No favourites yet",
        "cs": "Uložte si své oblíbené překlady z historie (ikonka hvězdičky). Poté je najdete na této obrazovce.",
        "uk": "Зберігайте свої улюблені переклади з історії (іконка-зірочка). Потім ви зможете знайти їх на цьому екрані.",
        "ru": "Сохраняйте свои избранные переводы из истории (иконка-звёздочка). Затем вы сможете найти их на этом экране.",
        "sk": "Uložte si svoje obľúbené preklady z histórie (ikonka hviezdičky). Následne ich nájdete na tejto obrazovke.",
    },
    "Delete": {
        # Android: delete_cd ("smazat z historie") — HIG: destructive swipe label
        "en": "Delete",
        "cs": "Smazat",
        "uk": "Видалити",
        "ru": "Удалить",
        "sk": "Zmazať",
    },
    "Favourite": {
        # Android: add_to_favourites_cd
        "en": "Favourite",
        "cs": "Oblíbit",
        "uk": "Додати в обране",
        "ru": "Добавить в избранное",
        "sk": "Pridať do obľúbených",
    },
    "Unfavourite": {
        # Android: remove_from_favourites_cd
        "en": "Unfavourite",
        "cs": "Zrušit oblíbené",
        "uk": "Видалити з обраного",
        "ru": "Удалить из избранного",
        "sk": "Odobrať z obľúbených",
    },

    # ---- Tabs (RootView) ----
    "Translate": {
        "en": "Translate",
        "cs": "Překladač",
        "uk": "Перекладач",
        "ru": "Переводчик",
        "sk": "Prekladač",
    },
    "Settings": {
        # Android: settings_title
        "en": "Settings",
        "cs": "Nastavení",
        "uk": "Налаштування",
        "ru": "Настройки",
        "sk": "Nastavenia",
    },

    # ---- Settings screen ----
    "Allow data collection": {
        "en": "Allow data collection",
        "cs": "Povolit sběr dat",
        "uk": "Дозволити збір даних",
        "ru": "Разрешить сбор данных",
        "sk": "Povoliť zber dát",
    },
    "Privacy": {
        # Android uses settings_data_collection_title = "Data processing" for this section;
        # iOS HIG label for a data/consent section is "Privacy".
        "en": "Privacy",
        "cs": "Ochrana soukromí",
        "uk": "Конфіденційність",
        "ru": "Конфиденциальность",
        "sk": "Ochrana súkromia",
    },
    "Identification": {
        "en": "Identification",
        "cs": "Identifikace",
        "uk": "Ідентифікація",
        "ru": "Идентификация",
        "sk": "Identifikácia",
    },
    "If your organization has an agreement with us to track its traffic, provide its name here.": {
        # Android: settings_organization_name_placeholder
        "en": "If your organization has an agreement with us to track its traffic, provide its name here.",
        "cs": "Doplňte název vaší organizace, pokud jste k tomu byli vyzváni.",
        "uk": "Заповніть назву організації, якщо вас про це попросили.",
        "ru": "Укажите название организации, если вас об этом попросили.",
        "sk": "Vyplňte meno organizácie, ak ste o to boli požiadaní.",
    },
    "Organization name": {
        # Android: settings_organization_name_label ("Název organizace (volitelné)")
        "en": "Organization name",
        "cs": "Název organizace",
        "uk": "Назва організації",
        "ru": "Название организации",
        "sk": "Meno organizácie",
    },
    "About": {
        # Android: about_title
        "en": "About",
        "cs": "O aplikaci",
        "uk": "Про додаток",
        "ru": "О приложении",
        "sk": "O aplikácií",
    },
    "Version": {
        "en": "Version",
        "cs": "Verze",
        "uk": "Версія",
        "ru": "Версия",
        "sk": "Verzia",
    },
    "Contact support": {
        "en": "Contact support",
        "cs": "Kontaktovat podporu",
        "uk": "Зв'язатися з підтримкою",
        "ru": "Связаться со службой поддержки",
        "sk": "Kontaktovať podporu",
    },
    "UFAL MFF UK": {
        # Proper noun — identity
        "en": "UFAL MFF UK",
        "cs": "UFAL MFF UK",
        "uk": "UFAL MFF UK",
        "ru": "UFAL MFF UK",
        "sk": "UFAL MFF UK",
    },
    "LINDAT/CLARIAH-CZ": {
        # Proper noun — identity
        "en": "LINDAT/CLARIAH-CZ",
        "cs": "LINDAT/CLARIAH-CZ",
        "uk": "LINDAT/CLARIAH-CZ",
        "ru": "LINDAT/CLARIAH-CZ",
        "sk": "LINDAT/CLARIAH-CZ",
    },
    "Erase app data": {
        "en": "Erase app data",
        "cs": "Vymazat data aplikace",
        "uk": "Видалити дані додатку",
        "ru": "Стереть данные приложения",
        "sk": "Vymazať dáta aplikácie",
    },
    "Erase all app data?": {
        "en": "Erase all app data?",
        "cs": "Vymazat všechna data aplikace?",
        "uk": "Видалити всі дані додатку?",
        "ru": "Стереть все данные приложения?",
        "sk": "Vymazať všetky dáta aplikácie?",
    },
    "Erase": {
        "en": "Erase",
        "cs": "Vymazat",
        "uk": "Видалити",
        "ru": "Стереть",
        "sk": "Vymazať",
    },
    "Offline speech models": {
        "en": "Offline speech models",
        "cs": "Offline modely řeči",
        "uk": "Офлайн моделі мовлення",
        "ru": "Офлайн модели речи",
        "sk": "Offline modely reči",
    },
    "Indicates languages whose dictation and speech models are downloaded for offline use.": {
        "en": "Indicates languages whose dictation and speech models are downloaded for offline use.",
        "cs": "Zobrazuje jazyky, jejichž modely diktování a řeči jsou staženy pro použití offline.",
        "uk": "Показує мови, чиї моделі диктування та мовлення завантажено для використання в офлайн-режимі.",
        "ru": "Показывает языки, чьи модели диктовки и речи загружены для использования в офлайн-режиме.",
        "sk": "Zobrazuje jazyky, ktorých modely diktovania a reči sú stiahnuté na použitie offline.",
    },
    "settings.offline.dictation": {
        "en": "dictation",
        "cs": "diktování",
        "uk": "диктування",
        "ru": "диктовка",
        "sk": "diktovanie",
    },
    "settings.offline.speech": {
        "en": "speech",
        "cs": "řeč",
        "uk": "мовлення",
        "ru": "речь",
        "sk": "reč",
    },
    "settings.offline.onDevice": {
        "en": "on device",
        "cs": "na zařízení",
        "uk": "на пристрої",
        "ru": "на устройстве",
        "sk": "na zariadení",
    },
    "settings.offline.onlineOnly": {
        "en": "online only",
        "cs": "pouze online",
        "uk": "тільки онлайн",
        "ru": "только онлайн",
        "sk": "iba online",
    },
    "settings.offline.unavailable": {
        "en": "unavailable",
        "cs": "nedostupné",
        "uk": "недоступно",
        "ru": "недоступно",
        "sk": "nedostupné",
    },
    "Cancel": {
        # Android: dialog_tts_cancel
        "en": "Cancel",
        "cs": "Zrušit",
        "uk": "Скасувати",
        "ru": "Отмена",
        "sk": "Zrušiť",
    },
    "This deletes your saved history and resets your privacy choices. This can't be undone.": {
        "en": "This deletes your saved history and resets your privacy choices. This can't be undone.",
        "cs": "Tímto smažete uloženou historii a obnovíte svá nastavení ochrany soukromí. Tento krok nelze vrátit.",
        "uk": "Це видалить збережену історію та скине ваші налаштування конфіденційності. Цю дію неможливо скасувати.",
        "ru": "Это удалит сохранённую историю и сбросит ваши настройки конфиденциальности. Это действие нельзя отменить.",
        "sk": "Týmto vymažete uloženú históriu a obnovíte svoje nastavenia ochrany súkromia. Tento krok nemožno vrátiť.",
    },
}


def build_catalog():
    strings = {}
    for key, translations in STRINGS.items():
        localizations = {}
        for lang in LANGUAGES:
            value = translations.get(lang, translations["en"])
            # Mark non-source languages whose value is identical to English as
            # needing review rather than silently shipping untranslated text.
            state = "translated" if lang == "en" or value != translations["en"] else "needs_review"
            localizations[lang] = {
                "stringUnit": {"state": state, "value": value}
            }
        strings[key] = {"localizations": localizations}

    catalog = {
        "sourceLanguage": "en",
        "languages": LANGUAGES,
        "strings": strings,
        "version": "1.0",
    }
    return catalog


def main():
    catalog = build_catalog()
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Wrote {len(catalog['strings'])} keys to {OUT}")


if __name__ == "__main__":
    main()