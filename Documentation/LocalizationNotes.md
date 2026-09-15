# Localization Notes

The iOS app is fully localized in **English (en), Czech (cs), Ukrainian (uk),
Russian (ru), Slovak (sk)**.

Wherever the iOS screen maps 1:1 to an equivalent Android screen, the translation is
copied **verbatim** from the [Charles Translator Android app](https://github.com/ufal/charles-translator-android)
(`app/src/main/res/values-{cs,uk,ru,sk}/strings.xml`), which is the approved wording
from UFAL MFF UK.

This file logs every string where the iOS build **does not** use the Android string
verbatim — either because the terminology differs (HIG/platform-specific), or because
the string only exists in iOS. These are the strings a human translator should review
before public release.

> **Note on Russian in the Android repo:** the `values-ru/strings.xml` file in the
> Android repo is (in its current state) actually written in Ukrainian. The Russian
> translations here were produced fresh against the English/Czech originals rather than
> copied from that file.

---

## Strings translated fresh for iOS (no Android equivalent, or different platform terminology)

### HIG / platform terminology

| iOS key | English | Why it diverges | cs | uk | ru | sk |
|---|---|---|---|---|---|---|
| `Clear` (Conversation toolbar) | Clear | Android only has a *content-description* `clear_cd` ("vymazat text"). iOS uses a short destructive button label. | Vymazat | Очистити | Очистить | Vymazať |
| `Delete` (History swipe) | Delete | Android `delete_cd` is a content-description ("smazat z historie"); iOS swipe-action needs a short verb. | Smazat | Видалити | Удалить | Zmazať |
| `Favourite` / `Unfavourite` (History swipe) | Favourite / Unfavourite | Android has `add_to_favourites_cd`/`remove_from_favourites_cd` (content descriptions). iOS uses compact action verbs. | Oblíbit / Zrušit oblíbené | Додати в обране / Видалити з обраного | Добавить в избранное / Удалить из избранного | Pridať do obľúbených / Odobrať z obľúbených |
| `Done` (keyboard toolbar) | Done | Android has no keyboard toolbar. | Hotovo | Готово | Готово | Hotovo |
| `Close` (language picker) | Close | Android has no sheet dismiss button. | Zavřít | Закрити | Закрыть | Zavrieť |
| `Settings` (tab label + title) | Settings | Matches Android `settings_title`; included for completeness. | Nastavení | Налаштування | Настройки | Nastavenia |
| `Translate` (tab label) | Translate | Android has no tab label (icon cluster). | Překladač | Перекладач | Переводчик | Prekladač |
| `Privacy` (Settings section header) | Privacy | Android labels this section `settings_data_collection_title` = "Data processing". iOS HIG uses "Privacy" for a consent/data section header. | Ochrana soukromí | Конфіденційність | Конфиденциальность | Ochrana súkromia |
| `Erase app data` / `Erase all app data?` / `Erase` | Erase… | iOS-only destructive confirmation (Android has no equivalent "erase all data" flow). | Vymazat data aplikace / Vymazat všechna data aplikace? / Vymazat | Видалити дані додатку / Видалити всі дані додатку? / Видалити | Стереть данные приложения / Стереть все данные приложения? / Стереть | Vymazať dáta aplikácie / Vymazať všetky dáta aplikácie? / Vymazať |
| `Cancel` (confirmation dialog) | Cancel | Matches Android `dialog_tts_cancel`. | Zrušit | Скасувати | Отмена | Zrušiť |
| `This deletes your saved history…` | This deletes your saved history and resets your privacy choices. This can't be undone. | iOS-only erase-confirmation message. | … | … | … | … |

### iOS-only strings (no Android counterpart)

| iOS key | English | cs | uk | ru | sk |
|---|---|---|---|---|---|
| `picker.sourceLanguage` | Translate from | Přeložit z | Перекласти з | Перевести с | Preložiť z |
| `picker.targetLanguage` | Translate to | Přeložit do | Перекласти на | Перевести на | Preložiť do |
| `error.speechPermissionDenied` | Enable Microphone and Speech Recognition access in Settings to use voice input. | … | … | … | … |
| `error.speechUnavailable` | Speech recognition isn't available right now. | … | … | … | … |
| `error.tooLarge` | This text is too long to translate. | … | … | … | … |
| `error.timeout` | Translation took too long and timed out. | … | … | … | … |
| `error.decoding` | The translation service returned an unexpected response. | … | … | … | … |
| `error.unknown` | Something went wrong while translating. | … | … | … | … |
| `error.unsupportedPair` | Cannot translate between these two languages. | … | … | … | … |
| `Start voice input` / `Stop listening` | Accessibility labels for the mic button. | Spustit hlasový vstup / Ukončit poslech | Почати голосовий ввід / Зупинити прослуховування | Начать голосовой ввод / Остановить прослушивание | Spustiť hlasový vstup / Ukončiť počúvanie |
| `History filter` | Segmented picker label. | Filtr historie | Фільтр історії | Фильтр истории | Filter histórie |
| `Version` | About screen row. | Verze | Версія | Версия | Verzia |
| `Contact support` | About screen mailto link. | Kontaktovat podporu | Зв'язатися з підтримкою | Связаться со службой поддержки | Kontaktovať podporu |
| `You can change this decision anytime in Settings.` | Consent sheet footnote. | … | … | … | … |

---

## Strings reused verbatim from Android

These match Android exactly and should **not** be re-reviewed:

- Language names (`language.cs` … `language.uk`) ← `cz_label` … `ru_label`
- `Data processing` ← `dialog_data_processing_title`
- Long consent paragraph ← `dialog_data_processing_message`
- `Agree` / `Disagree` ← `dialog__data_processing_agree` / `_disagree`
- `Enter text` ← `insert_text`
- `Swap languages` ← `swap_cd`
- `Tap a microphone to start a conversation` ← `conversation_empty`
- `Conversation` ← `conversation_title`
- `History` ← `history_title`
- `All` / `Favourites` ← `history_bottom_all` / `history_bottom_favourites`
- `No history yet` / `No favourites yet` ← `history_all_empty` / `history_favourites_empty`
- `If your organization…` ← `settings_organization_name_placeholder`
- `About` ← `about_title`
- `error.network` ← guided by `offline_text`
- `error.unsupportedApiVersion` ← guided by `dialog_unsupported_api_message`

---

## Proper nouns (kept as identity, not translated)

`Charles Translator`, `UFAL MFF UK`, `LINDAT/CLARIAH-CZ`.