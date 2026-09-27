-- =====================================================================
-- Схема реляционной БД: Звёзды, Созвездия, Экзопланеты, Галактики
-- СУБД: PostgreSQL 14+
--
-- Запуск из командной строки:
--   createdb astro_db
--   psql -d astro_db -f schema.sql
-- или одной командой:
--   psql -c "CREATE DATABASE astro_db" && psql -d astro_db -f schema.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. ГАЛАКТИКИ (Galaxy)
--    Корневая сущность иерархии: галактика -> скопление -> созвездие...
-- ---------------------------------------------------------------------
CREATE TYPE galaxy_type AS ENUM ('spiral', 'barred_spiral', 'elliptical', 'lenticular', 'irregular', 'dwarf', 'unknown');

CREATE TABLE galaxy (
    galaxy_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(120) NOT NULL UNIQUE,          -- напр. «Млечный Путь»
    alt_names       TEXT[] DEFAULT '{}',                   -- альтернативные названия/обозначения (массив PostgreSQL)
    galaxy_type     galaxy_type,                           -- тип по ENUM (spiral / elliptical / ...)
    diameter_ly     NUMERIC(12,2),                         -- диаметр в световых годах
    mass_suns       NUMERIC(18,2),                         -- масса в массах Солнца
    distance_ly     NUMERIC(14,2),                         -- расстояние от Земли (св. годы)
    constellation   VARCHAR(120),                          -- созвездие, в котором наблюдается
    discovered_by   VARCHAR(120),
    discovery_year  INTEGER,
    description     TEXT,
);

-- ---------------------------------------------------------------------
-- 2. СОЗВЕЗДИЯ (Constellation)
--    Каждое созвездие относится к одной галактике (как правило — Млечный Путь).
-- ---------------------------------------------------------------------
CREATE TABLE constellation (
    constellation_id BIGINT SERIAL PRIMARY KEY,
    name             VARCHAR(120) NOT NULL,                -- напр. «Лира»
    latin_name       VARCHAR(120) NOT NULL UNIQUE,         -- Lyra
    abbr             CHAR(3) UNIQUE,                       -- Genitive abbreviation, напр. Lyr
    galaxy_id        BIGINT NOT NULL REFERENCES galaxy(galaxy_id)
                     ON DELETE RESTRICT,
    area_sq_deg      NUMERIC(7,2),                         -- площадь на небесной сфере, кв. градусы
    brightest_star   VARCHAR(120),                         -- название ярчайшей звезды
    right_ascension  VARCHAR(20),                          -- прямое восхождение (центр области)
    declination      VARCHAR(20),                          -- склонение (центр области)
    season_peak      VARCHAR(20),                          -- лучшее время наблюдения
    myth_origin      VARCHAR(60),                          -- мифологическая традиция (греч., кит. ...)
    description      TEXT,
    UNIQUE (galaxy_id, name)
);

-- ---------------------------------------------------------------------
-- 3. ЗВЁЗДЫ (Star)
--    Звезда принадлежит созвездию; у экзотических объектов созвездие
--    может отсутствовать (NULL), но галактика обязательна.
-- ---------------------------------------------------------------------
CREATE TABLE star (
    star_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name              VARCHAR(150),                        -- собственное имя (Вегa)
    bayer_designation VARCHAR(50),                         -- обозначение Байера (α Lyrae)
    catalog_id        VARCHAR(60) UNIQUE,                  -- HIP / HD / SAO номер
    constellation_id  BIGINT REFERENCES constellation(constellation_id),
    spectral_class    VARCHAR(10),                         -- O B A F G K M + светимость
    luminosity_class  VARCHAR(5),                          -- Ia, II, V ...
    mass_suns         NUMERIC(10,4),                       -- масса в массах Солнца
    radius_suns       NUMERIC(10,4),                       -- радиус в радиусах Солнца
    temperature_k     INTEGER,                             -- эффективная температура, K
    distance_ly       NUMERIC(12,4),                       -- расстояние до Земли, св. годы
    magnitude_app     NUMERIC(6,3),                        -- видимая звёздная величина
    magnitude_abs     NUMERIC(6,3),                        -- абсолютная звёздная величина
    ra_deg            NUMERIC(9,6),                        -- прямое восхождение, градусы
    dec_deg           NUMERIC(9,6),                        -- склонение, градусы
    proper_motion     NUMERIC(12,6),                       -- собственное движение, угл. сек./год
    is_variable       BOOLEAN NOT NULL DEFAULT FALSE,
    year_discovered   INTEGER,
    description       TEXT,
    CHECK (spectral_class IS NULL OR spectral_class ~ '^[OBAFGKMLWT][0-9]')
);

-- ---------------------------------------------------------------------
-- 4. ЭКЗОПЛАНЕТЫ (Exoplanet)
--    Планета обращается вокруг звезды (у некоторых — пульсара или
--    является свободно плавающей, тогда star_id = NULL).
-- ---------------------------------------------------------------------
CREATE TYPE planet_type AS ENUM ('rocky', 'super_earth', 'mini_neptune', 'neptunian', 'gas_giant', 'hot_jupiter', 'ice_giant', 'ocean', 'lava', 'unclassified');
CREATE TYPE discovery_method AS ENUM ('transit', 'radial_velocity', 'imaging', 'microlensing', 'astrometry', 'timing', 'other');

CREATE TABLE exoplanet (
    exoplanet_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name             VARCHAR(150) NOT NULL UNIQUE,         -- Kepler-186 f
    star_id          BIGINT REFERENCES star(star_id)
                     ON DELETE CASCADE,
    planet_type      planet_type DEFAULT 'unclassified',   -- тип по ENUM
    mass_jup         NUMERIC(12,6),                        -- масса в массах Юпитера
    mass_earth       NUMERIC(14,6),                        -- масса в массах Земли
    radius_jup       NUMERIC(10,6),                        -- радиус в радиусах Юпитера
    radius_earth     NUMERIC(10,6),                        -- радиус в радиусах Земли
    orbital_period_d NUMERIC(16,6),                        -- период обращения, сутки
    semi_major_axis  NUMERIC(12,6),                        -- большая полуось, а.е.
    eccentricity     NUMERIC(6,4) CHECK (eccentricity >= 0 AND eccentricity < 1),
    inclination_deg  NUMERIC(6,3),
    eq_temperature_k INTEGER,                              -- равновесная температура, K
    discovery_year   INTEGER,
    discovery_method discovery_method,                     -- метод открытия (ENUM)
    discoverer       VARCHAR(150),
    is_habitable     BOOLEAN NOT NULL DEFAULT FALSE,       -- находится в зоне обитаемости
    confirmed        BOOLEAN NOT NULL DEFAULT TRUE,
    description      TEXT,
);


-- =====================================================================
-- ИНДЕКСЫ для частых запросов
-- =====================================================================
CREATE INDEX idx_constellation_galaxy   ON constellation (galaxy_id);
CREATE INDEX idx_star_constellation     ON star (constellation_id);
CREATE INDEX idx_star_galaxy            ON star (galaxy_id);
CREATE INDEX idx_star_spectral          ON star (spectral_class varchar_pattern_ops);
CREATE INDEX idx_exoplanet_star         ON exoplanet (star_id);
CREATE INDEX idx_exoplanet_discovery    ON exoplanet (discovery_year);
-- Частичный (partial) индекс PostgreSQL — только «обитаемые» строки:
CREATE INDEX idx_exoplanet_habitable    ON exoplanet (is_habitable) WHERE is_habitable;
-- GIN-индекс по текстовому полю описания (полнотекстовый поиск, опционально):
CREATE INDEX idx_galaxy_alt_names       ON galaxy USING GIN (alt_names);

-- =====================================================================
-- ПРЕДСТАВЛЕНИЕ: полная цепочка планета -> звезда -> созвездие -> галактика
-- =====================================================================
CREATE VIEW v_planet_full_info AS
SELECT
    ep.exoplanet_id,
    ep.name              AS planet_name,
    s.star_id,
    COALESCE(s.name, s.bayer_designation, s.catalog_id) AS star_name,
    s.spectral_class,
    s.distance_ly        AS star_distance_ly,
    c.constellation_id,
    c.name               AS constellation_name,
    c.latin_name         AS constellation_latin,
    g.galaxy_id,
    g.name               AS galaxy_name
FROM exoplanet ep
LEFT JOIN star          s ON s.star_id        = ep.star_id
LEFT JOIN constellation c ON c.constellation_id = s.constellation_id
LEFT JOIN galaxy        g ON g.galaxy_id = COALESCE(s.galaxy_id, c.galaxy_id);

-- =====================================================================
-- ПРИМЕР ЗАПОЛНЕНИЯ (демонстрационные данные)
-- =====================================================================
-- INSERT INTO galaxy (name, galaxy_type, diameter_ly, distance_ly, alt_names) VALUES
-- ('Млечный Путь', 'barred_spiral', 105700, 0,    ARRAY['Milky Way','MW']),
-- ('Андромеда',    'spiral',        220000, 2537000, ARRAY['M31','NGC 224']);

-- INSERT INTO constellation (name, latin_name, abbr, galaxy_id, area_sq_deg) VALUES
-- ('Лира',   'Lyra',   'Lyr', 1, 286.5),
-- ('Лебедь', 'Cygnus', 'Cyg', 1, 804.0);

-- INSERT INTO star (name, bayer_designation, constellation_id, galaxy_id,
--                   spectral_class, mass_suns, radius_suns, temperature_k,
--                   distance_ly, magnitude_app) VALUES
-- ('Вега',       'Alpha Lyrae',   1, 1, 'A0', 2.1, 2.4, 9602, 25.0, 0.03),
-- ('Денеб',      'Alpha Cygni',   2, 1, 'A2', 19.0, 203.0, 8500, 2615.0, 1.25),
-- ('Kepler-186', NULL,            2, 1, 'M1', 0.54, 0.50, 3788, 579.0, 14.6);

-- INSERT INTO exoplanet (name, star_id, planet_type, radius_earth, orbital_period_d,
--                        semi_major_axis, discovery_year, discovery_method, is_habitable) VALUES
-- ('Kepler-186 f', 3, 'rocky', 1.17, 129.94, 0.432, 2014, 'transit', TRUE),
-- ('Kepler-186 e', 3, 'rocky', 1.27, 22.41, 0.110, 2014, 'transit', FALSE);


COMMENT ON TABLE  stars           IS 'Звёзды';
COMMENT ON COLUMN stars.name      IS 'Полное имя звезды';
COMMENT ON COLUMN stars.shortname IS 'Краткое имя звезды';
COMMENT ON COLUMN stars.hr        IS 'Номер в каталоге HR';
COMMENT ON COLUMN stars.dblstar   IS 'Признак кратной звезды (двойные-тройные), CHAR(1)';
