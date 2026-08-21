# ActiveTogether

Platforma za organizaciju sportskih i rekreativnih aktivnosti.

Seminarski rad iz predmeta Razvoj softvera II, FIT.
Autor: Amar Kodro - IB220221, Akademska 2025/2026.

## Arhitektura

| Uloga       | Interfejs                            | Odgovornosti                                                    |
| ----------- | ------------------------------------ | --------------------------------------------------------------- |
| Korisnik    | Mobilna aplikacija (Flutter)         | Pretraga, rezervacija, plaćanje, ocjenjivanje aktivnosti        |
| Organizator | Desktop + Mobilna aplikacija         | Kreiranje i upravljanje aktivnostima, rezervacijama, učesnicima |
| Admin       | Desktop aplikacija (Flutter Windows) | Upravljanje korisnicima, aktivnostima, izvještaji               |

### Ključna infrastruktura

- Backend API - .NET (C#), REST arhitektura
- Baza podataka - SQL Server
- Messaging - RabbitMQ (asinhrone notifikacije)
- Sistem preporuke - hibridni (content-based + popularity-based)
- Kontejnerizacija - Docker + Docker Compose
- Auth - JWT
- Plaćanje - Stripe (sandbox)

## Pokretanje aplikacije

### Preduslovi

- Docker Desktop
- Flutter SDK (za pokretanje ili build desktop/mobilne aplikacije)
- Android Studio / emulator ili fizički uređaj (za mobilnu aplikaciju)

### Backend (Docker Compose)

1. U folderu `activetogether-backend` postaviti `.env` fajl (dobija se raspakivanjem `.env-tajne.zip`).
2. Pokrenuti:

cd activetogether-backend
docker compose up --build

3. API je dostupan na `http://localhost:5027`, RabbitMQ management konzola na `http://localhost:15672` (guest/guest).

### Desktop aplikacija (Windows)

- Iz gotovog build-a: preuzeti i pokrenuti `.exe` iz GitHub Release.
- Iz izvornog koda:

cd activetogether-frontend/activetogether_desktop
flutter pub get
flutter run -d windows

- API URL je već podešen na `http://localhost:5027`, nije potrebna dodatna konfiguracija.

### Mobilna aplikacija (Android)

- Iz gotovog build-a: instalirati `app-release.apk` iz GitHub Release na emulator ili fizički uređaj.
- Iz izvornog koda (Android emulator):

cd activetogether-frontend/activetogether_mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5027

- Napomena: `10.0.2.2` je specijalna adresa Android emulatora koja pokazuje na `localhost` host mašine. Na fizičkom uređaju treba koristiti IP adresu računara u lokalnoj mreži.

## Test nalozi

| Kontekst                                  | Korisničko ime | Lozinka |
| ----------------------------------------- | -------------- | ------- |
| Desktop verzija                           | desktop        | test    |
| Mobilna verzija                           | mobile         | test    |
| Organizator (dostupan na obje aplikacije) | organizator    | test    |

## Sistem preporuke

Vidi [recommender-dokumentacija.md](./recommender-dokumentacija.md).
