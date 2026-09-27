# sql2text
тестовый, астрономическая БД

## Схема БД: Звёзды · Созвездия · Экзопланеты · Галактики

Реляционная схема в файле [`schema.sql`](./schema.sql) (диалект PostgreSQL).

### ER-диаграмма

```mermaid
erDiagram
    GALAXY        ||--o{ CONSTELLATION : "содержит"
    GALAXY        ||--o{ STAR           : "в галактике"
    CONSTELLATION ||--o{ STAR           : "в созвездии"
    STAR          ||--o{ EXOPLANET      : "хост-звезда"

    GALAXY {
        int     galaxy_id PK
        string  name UK "Млечный Путь"
        string  galaxy_type "spiral / elliptical / irregular"
        numeric diameter_ly
        numeric mass_suns
        numeric distance_ly
    }

    CONSTELLATION {
        int     constellation_id PK
        string  name "Лира"
        string  latin_name UK "Lyra"
        char    abbr UK "Lyr"
        int     galaxy_id FK
        numeric area_sq_deg
        string  brightest_star
    }

    STAR {
        int     star_id PK
        string  name "Вега"
        string  bayer_designation "Alpha Lyrae"
        string  catalog_id UK "HIP / HD"
        int     constellation_id FK "NULL для объектов вне созвездий"
        int     galaxy_id FK
        string  spectral_class "O B A F G K M"
        numeric mass_suns
        numeric radius_suns
        int     temperature_k
        numeric distance_ly
        numeric magnitude_app
    }

    EXOPLANET {
        int     exoplanet_id PK
        string  name UK "Kepler-186 f"
        int     star_id FK "NULL для свободно плавающих"
        string  planet_type "rocky / gas_giant / hot_jupiter"
        numeric mass_earth
        numeric radius_earth
        numeric orbital_period_d
        numeric semi_major_axis "а.е."
        int     discovery_year
        string  discovery_method
        bool    is_habitable
    }
```

### Текстовая иерархия связей

```
galaxy (галактика)
  └── constellation (созвездие)           N:1 — созвездие наблюдается в галактике
        └── star (звезда)                 N:1 — звезда принадлежит созвездию
              └── exoplanet (экзопланета) N:1 — планета обращается вокруг звезды
star → galaxy                             N:1 — прямая ссылка на галактику
```

Кардинальность:
* одна **галактика** → много **созвездий** и **звёзд**;
* одно **созвездие** → много **звёзд**;
* одна **звезда** → много **экзопланет**;
* экзопланета без хоста (`star_id = NULL`) — свободно плавающая планета;
* звезда без созвездия (`constellation_id = NULL`) допустима.

### Ключевые решения

| Решение | Обоснование |
|---|---|
| `ON DELETE RESTRICT` для galaxy | нельзя удалить галактику, пока в ней есть объекты |
| `ON DELETE SET NULL` для constellation у звезды | созвездие — условная проекция на небесную сферу |
| `ON DELETE CASCADE` для star → exoplanet | планеты существуют только вместе со своей звездой |
| `CHECK (spectral_class ~ '^[OBAFGKMLWT][0-9]')` | валидация спектрального класса |
| Частичный индекс `WHERE is_habitable` | быстрый поиск обитаемых планет |
| Представление `v_planet_full_info` | готовая цепочка планета → звезда → созвездие → галактика |

### Примеры запросов

Все экзопланеты одного созвездия с их звёздами:

```sql
SELECT c.name AS constellation, s.name AS star, ep.name AS planet
FROM exoplanet ep
JOIN star s ON s.star_id = ep.star_id
JOIN constellation c ON c.constellation_id = s.constellation_id
WHERE c.latin_name = 'Cygnus';
```

Количество подтверждённых планет по типам звёзд:

```sql
SELECT LEFT(s.spectral_class, 1) AS spectral_type, COUNT(*) AS planets
FROM exoplanet ep JOIN star s USING (star_id)
GROUP BY 1 ORDER BY 2 DESC;
```
