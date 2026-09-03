# Sistem preporuke aktivnosti

Ovaj dokument opisuje algoritam preporuke aktivnosti implementiran u `ActiveTogether.Services.Services.RecommendationService`. Sistem je **hibridni** — kombinuje **content-based** (na osnovu ponašanja korisnika) i **popularity-based** (na osnovu ukupne popularnosti aktivnosti na platformi) pristup, uz posebnu obradu za nove korisnike (cold-start problem).

## 1. Ulazni signali korisnika

Sistem prati tri vrste korisničkog ponašanja, svaka sa svojom težinom u finalnom izračunu preferencija:

| Signal | Težina | Opis |
|---|---|---|
| Rezervacija aktivnosti | 3.0 | Najjači signal interesovanja — korisnik je stvarno rezervisao aktivnost |
| Pregled aktivnosti (view) | 2.0 | Korisnik je otvorio detalje aktivnosti |
| Pretraga (search) | 1.0 | Korisnik je pretraživao po kategoriji/gradu |

Za svakog korisnika se iz ovih signala agregiraju dvije mape težina:
- **Preferencija kategorije** (`categoryWeights`) — zbir težina svih interakcija po kategoriji aktivnosti.
- **Preferencija grada** (`cityWeights`) — zbir težina svih interakcija po gradu lokacije aktivnosti.

Dodatno se računa da li korisnik preferira besplatne ili plaćene aktivnosti (`freeWeight` vs `premiumWeight`), na osnovu istih signala.

## 2. Cold-start problem

Ako korisnik nema nijedan zabilježen signal koji stvarno ulazi u scoring (nema rezervacija, pregleda, niti pretrage sa odabranom kategorijom/gradom — pretraga samo po nazivu se ne broji, jer ne doprinosi category/city preferencijama), sistem prelazi u **cold-start mod**: preporuke se baziraju isključivo na popularnosti (vidi tačku 3), bez ličnog konteksta. Razlog prikazan korisniku je tada "Aktivnost u tvom gradu" (ako se poklapa grad korisnika — čisto lokacijska činjenica, popularityScore nije računat po gradu) ili "Popularno na platformi".

## 3. Popularity Score

Za svaku kandidat-aktivnost računaju se četiri normalizovane komponente (0-1):

- **reservedNorm** — broj rezervacija te aktivnosti / maksimalan broj rezervacija među kandidatima.
- **ratingNorm** — prosječna ocjena aktivnosti / 5.
- **trendNorm** — broj rezervacija u posljednjih 14 dana / maksimalan broj takvih rezervacija među kandidatima (mjeri trenutni "trend").
- **fillRatio** — popunjenost kapaciteta (broj rezervacija / kapacitet).

```
popularityScore = 0.4 * reservedNorm + 0.3 * ratingNorm + 0.2 * trendNorm + 0.1 * fillRatio
```

## 4. Content Score (samo ako korisnik ima signale)

- **categoryComponent** — koliko se kategorija aktivnosti poklapa sa korisnikovim najjačim preferencijama kategorije (normalizovano na maksimum).
- **cityComponent** — isto, ali za grad lokacije aktivnosti.
- **priceComponent** — 1.0 ako se tip aktivnosti (besplatna/plaćena) poklapa sa korisnikovom preferencijom, inače 0. Ako korisnik nema nijedan free/premium signal (`freeWeight == premiumWeight == 0`), komponenta je uvijek 0 — bez toga bi default `preferFree = true` neopravdano favorizovao besplatne aktivnosti.

```
contentScore = 0.5 * categoryComponent + 0.3 * cityComponent + 0.2 * priceComponent
```

## 5. Finalni score

```
finalScore = isColdStart
    ? popularityScore
    : 0.6 * contentScore + 0.4 * popularityScore
```

Aktivnosti se sortiraju silazno po `finalScore`, a zatim se primjenjuje paginacija (`Page`, `PageSize`, max `PageSize = 100`).

## 6. Filtriranje kandidata

Prije rangiranja, iz skupa kandidata se izbacuju:
- aktivnosti koje nisu u statusu `Active`,
- aktivnosti koje su već prošle (`DateTime <= UtcNow`),
- aktivnosti koje je kreirao sam korisnik (kao organizator),
- aktivnosti koje je korisnik već rezervisao (aktivna, ne-otkazana rezervacija),
- aktivnosti koje su popunjene do kapaciteta.

## 7. Objašnjenje preporuke (Reason)

Svakoj preporučenoj aktivnosti se dodjeljuje kratko tekstualno objašnjenje ("Reason") koje se prikazuje korisniku u aplikaciji:
- **Cold-start:** "Aktivnost u tvom gradu" (ako se grad poklapa — lokacijska činjenica, ne izračunata popularnost po gradu) ili "Popularno na platformi".
- **Sa signalima:** ako je uticaj preferencije kategorije dominantan → "Na osnovu tvojih aktivnosti u kategoriji {naziv}"; ako je uticaj preferencije grada dominantan → "Popularno u tvom gradu"; inače → "Popularno na platformi".

## 8. Endpoint

`GET /api/recommendations` (`RecommendationsController`) — vraća `PagedResult<RecommendedActivityResponse>` za trenutno prijavljenog korisnika, na osnovu `RecommendationSearchObject` (Page, PageSize).
