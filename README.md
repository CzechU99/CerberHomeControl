<h2 align="center"><strong>Cerber Home Control</strong></h2>

<div align="center">
    <p><img alt="Status" src="https://img.shields.io/badge/status-w%20rozwoju-yellow">
    <img alt="Licencja" src="https://img.shields.io/badge/licencja-prywatna-lightgrey"></p>
    <p>
      <img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white">
      <img alt="Dart" src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white">
      <img alt="Android" src="https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white">
      <img alt="ESP32" src="https://img.shields.io/badge/ESP32-E7352C?logo=espressif&logoColor=white">
      <img alt="Arduino" src="https://img.shields.io/badge/Arduino-00878F?logo=arduino&logoColor=white">
      <img alt="PlatformIO" src="https://img.shields.io/badge/PlatformIO-F5822A?logo=platformio&logoColor=white">
      <img alt="C++" src="https://img.shields.io/badge/C++-00599C?logo=cplusplus&logoColor=white">
      <img alt="MQTT" src="https://img.shields.io/badge/MQTT-660066?logo=mqtt&logoColor=white">
    </p>
</div>

---

## 🎯 Cel projektu

**Cerber Home Control** to system do zdalnego otwierania bram, który umożliwia:

- otwieranie bram z telefonu z dowolnego miejsca z dostępem do internetu,
- podgląd w czasie rzeczywistym, czy sterownik każdej bramy jest online,
- szyfrowaną komunikację przez chmurowy broker MQTT.

Projekt składa się z aplikacji mobilnej oraz sterowników ESP32 – po jednym na bramę.

---

## 🏗 Architektura

```
┌──────────────────┐   TLS / MQTT   ┌──────────────────┐   TLS / MQTT   ┌──────────────────────┐
│  Aplikacja       │ ─────────────► │   Broker MQTT    │ ─────────────► │  ESP32 + przekaźnik  │
│  Cerber (Flutter)│ ◄───────────── │     (chmura)     │ ◄───────────── │  (osobny dla bramy)  │
└──────────────────┘     status     └──────────────────┘     status     └──────────────────────┘
```

---

## 🧱 Stack technologiczny

### Aplikacja mobilna:

- **Flutter (Dart)** – interfejs i logika aplikacji
- **mqtt_client** – połączenie z brokerem MQTT przez TLS
- **flutter_secure_storage** – bezpieczne przechowywanie danych logowania

### Sterowniki bram:

- **ESP32** – mikrokontroler z Wi-Fi
- **Arduino (C++) + PlatformIO** – wspólny firmware dla wszystkich bram
- **PubSubClient** – klient MQTT

---

## 🧩 Funkcjonalności

| Moduł                           | Opis                                                                        |
| ------------------------------- | --------------------------------------------------------------------------- |
| 🏠 **Panel bram**               | Otwieranie bram przytrzymaniem przycisku, chroniącym przed przypadkowym otwarciem. |
| ✅ **Potwierdzenie wykonania**  | Aplikacja pokazuje, czy sterownik wykonał komendę.                           |
| 📡 **Status**                   | Stan połączenia oraz podstawowe informacje diagnostyczne sterowników.        |
| ⚙️ **Ustawienia**               | Konfiguracja połączenia z brokerem bez zmian w kodzie.                       |
| 🔁 **Niezawodność**             | Automatyczne wznawianie połączeń po stronie aplikacji i sterowników.         |
| 📶 **Aktualizacja przez Wi-Fi** | Firmware sterowników można aktualizować w sieci lokalnej.                    |

---

## 📁 Struktura repozytorium

```
CerberHomeControl/
├── .github/workflows/   GitHub Actions
├── app/                 aplikacja mobilna Flutter
├── firmware/            firmware ESP32 (PlatformIO)
└── scripts/             narzędzia wydań
```

---

## 📸 Zrzuty ekranu

| Widok      | Podgląd |
| ---------- | ------- |
| Panel bram |         |
| Status     |         |
| Ustawienia |         |

---

## 🔧 Instrukcja uruchomienia

### Aplikacja mobilna

  **a) Zainstaluj Flutter SDK i w katalogu `app/` pobierz zależności:**

```bash
  flutter pub get
```

  **b) Uruchom aplikację na telefonie:**

```bash
  flutter run
```

  **c) W zakładce *Ustawienia* wpisz dane swojego brokera MQTT.**

### Sterowniki ESP32

  **a) Otwórz folder `firmware/` w VS Code z rozszerzeniem PlatformIO IDE.**

  **b) Na podstawie `firmware/include/secrets.h` utwórz plik `secrets.development.h` z własnymi danymi.**

  **c) Wgraj firmware wybranej bramy (warianty są zdefiniowane w `platformio.ini`):**

```bash
  pio run -e <brama> -t upload
```

> ⚠️ Plik `secrets.h` jest szablonem i musi pozostać pusty. Prawdziwe dane trafiają wyłącznie do `secrets.development.h`, który jest ignorowany przez Git.

---

## ⚙️ GitHub Actions

| Workflow     | Kiedy                           | Co robi                                         |
| ------------ | ------------------------------- | ----------------------------------------------- |
| **App**      | zmiany w `app/`                 | analiza i testy aplikacji                       |
| **Firmware** | zmiany w `firmware/`            | sprawdzenie kompilacji firmware (bez sekretów)  |
| **Release**  | tag `v*`                        | podpisane APK i wydanie (Release) na GitHubie   |

Wydania wymagają klucza podpisu aplikacji zapisanego w sekretach repozytorium.

---

## 🔐 Dostęp i licencja

Projekt **Cerber Home Control** ma charakter **prywatny** i służy do użytku własnego. Dostęp do kodu źródłowego można uzyskać **po indywidualnym uzgodnieniu z autorem**.

---

## 👨‍💻 Autorzy

![contributors badge](https://readme-contribs.as93.net/contributors/CzechU99/CerberHomeControl)

---

> © 2026 **Cerber Home Control**
