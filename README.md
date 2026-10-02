# sql2text
генерация QWEN=coder 3.5


## Схема БД: Галактики · Созвездия · Звёзды · Экзопланеты

Реляционная схема в файле [`schema.sql`](./schema.sql) — **PostgreSQL 14+** (проверено на PostgreSQL 15: скрипт выполняется без ошибок).

Использованы возможности именно PostgreSQL: `GENERATED ALWAYS AS IDENTITY`, `ENUM`-типы, `TIMESTAMPTZ`, `NUMERIC`, массивы `TEXT[]`, регулярный `CHECK` (`~`), частичный индекс (`WHERE is_habitable`), GIN-индекс по массиву, триггер `BEFORE UPDATE ... EXECUTE FUNCTION` для `updated_at`, plpgsql-функция.

### Как запустить
```bash
createdb astro_db
psql -d astro_db -v ON_ERROR_STOP=1 -f schema.sql
# или через Docker:
docker run -d --name pg-astro -e POSTGRES_PASSWORD=pass -p 5432:5432 postgres:16
docker exec -i pg-astro psql -U postgres -c "CREATE DATABASE astro_db"
docker exec -i pg-astro psql -U postgres -d astro_db < schema.sql
```

### ER-диаграмма

```mermaid
erDiagram
    GALAXY        ||--o{ CONSTELLATION : "содержит"
    CONSTELLATION ||--o{ STAR          : "в созвездии"
    STAR          ||--o{ EXOPLANET     : "хост-звезда"

    GALAXY {
        bigint  galaxy_id PK
        varchar name UK "Млечный Путь"
        text    alt_names "массив TEXT[]"
        enum    galaxy_type "spiral / elliptical / irregular ..."
        numeric diameter_ly "диаметр, св. годы"
        numeric mass_suns "массы Солнца"
        numeric distance_ly "от Земли, св. годы"
        varchar constellation "наблюдается в созвездии"
        varchar discovered_by
        int     discovery_year
        text    description
    }

    CONSTELLATION {
        bigint  constellation_id PK "SERIAL"
        varchar name "Лира"
        varchar latin_name UK "Lyra"
        char    abbr UK "Lyr"
        bigint  galaxy_id FK "ON DELETE RESTRICT"
        numeric area_sq_deg "кв. градусы"
        varchar brightest_star
        varchar right_ascension
        varchar declination
        varchar season_peak
        varchar myth_origin
        text    description
    }

    STAR {
        bigint  star_id PK
        varchar name "Вега"
        varchar bayer_designation "alpha Lyrae"
        varchar catalog_id UK "HIP / HD / SAO"
        bigint  constellation_id FK "NULL вне созвездий"
        varchar spectral_class "O B A F G K M + светимость"
        varchar luminosity_class "Ia II V ..."
        numeric mass_suns
        numeric radius_suns
        int     temperature_k
        numeric distance_ly
        numeric magnitude_app "видимая зв. величина"
        numeric magnitude_abs "абсолютная зв. величина"
        numeric ra_deg
        numeric dec_deg
        numeric proper_motion
        bool    is_variable
        int     year_discovered
        text    description
    }

    EXOPLANET {
        bigint  exoplanet_id PK
        varchar name UK "Kepler-186 f"
        bigint  star_id FK "NULL свободно плавающая"
        enum    planet_type "rocky / gas_giant / hot_jupiter ..."
        numeric mass_jup
        numeric mass_earth
        numeric radius_jup
        numeric radius_earth
        numeric orbital_period_d "сутки"
        numeric semi_major_axis "а.е."
        numeric eccentricity "0 <= e < 1"
        numeric inclination_deg
        int     eq_temperature_k
        int     discovery_year
        enum    discovery_method "transit / radial_velocity ..."
        varchar discoverer
        bool    is_habitable
        bool    confirmed
        text    description
    }
```

```
galaxy (галактика)
  └── constellation (созвездие)           N:1 — созвездие наблюдается в галактике (FK, ON DELETE RESTRICT)
        └── star (звезда)                 N:1 — звезда принадлежит созвездию (constellation_id NULL допустим)
              └── exoplanet (экзопланета) N:1 — планета обращается вокруг звезды (star_id NULL допустим)
stars (каталог HR)                        независимая справочная таблица (вне схемы schema.sql)
```

Кардинальность (по `schema.sql`):
* одна **галактика** → много **созвездий**;
* одно **созвездие** → много **звёзд**;
* одна **звезда** → много **экзопланет**;
* экзопланета без хоста (`star_id = NULL`) — свободно плавающая планета;
* звезда без созвездия (`constellation_id = NULL`) допустима.

### Таблица `stars` — каталог звёзд (HR)

Независимая справочная таблица, дополняющая основную схему:

| Поле | Тип | Описание |
|---|---|---|
| `id` | `SERIAL PRIMARY KEY` | суррогатный ключ |
| `name` | `TEXT` | полное имя звезды |
| `shortname` | `TEXT` | краткое имя звезды |
| `hr` | `INTEGER` | номер звезды в каталоге HR (Harvard Revised) |
| `dblstar` | `CHAR(1)` | признак кратной звезды: двойные–тройные системы |

Примеры значений `dblstar`: `D` — двойная, `T` — тройная, `NULL` — одиночная.

Связь с таблицей `star` устанавливается по номеру каталога: `stars.hr` ↔ идентификатор звезды в каталоге HR (явного внешнего ключа нет — таблицы живут независимо).

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
