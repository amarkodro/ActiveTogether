# ActiveTogether

Platforma za organizaciju sportskih i rekreativnih aktivnosti.

Seminarski rad iz predmeta Razvoj softvera II, FIT.
Autor: Amar Kodro - IB220221, Akademska 2025/2026.

## Arhitektura

| Uloga | Interfejs | Odgovornosti |
|---|---|---|
| Korisnik | Mobilna aplikacija (Flutter) | Pretraga, rezervacija, plaćanje, ocjenjivanje aktivnosti |
| Organizator | Desktop + Mobilna aplikacija | Kreiranje i upravljanje aktivnostima, rezervacijama, učesnicima |
| Admin | Desktop aplikacija (Flutter Windows) | Upravljanje korisnicima, aktivnostima, izvještaji |

### Ključna infrastruktura
- Backend API - .NET (C#), REST arhitektura
- Baza podataka - SQL Server
- Messaging - RabbitMQ (asinhrone notifikacije)
- Sistem preporuke - hibridni (content-based + popularity-based)
- Kontejnerizacija - Docker + Docker Compose
- Auth - JWT
- Plaćanje - Stripe (sandbox)

## Pokretanje aplikacije

_Popuniti nakon što backend i docker-compose budu spremni (Dio 12/13)._

## Test nalozi

_Popuniti nakon implementacije auth-a (Dio 3)._

## Sistem preporuke

Vidi [recommender-dokumentacija.md](./recommender-dokumentacija.md).
