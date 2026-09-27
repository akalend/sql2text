-- sql2text: тестовая астрономическая БД
-- Таблица звёзд

CREATE TABLE IF NOT EXISTS stars (
    id        SERIAL PRIMARY KEY,          -- суррогатный ключ
    name      TEXT,                        -- полнгое имя
    shortname TEXT,                        -- краткое имя
    hr        INTEGER                      -- связь с каталогом HR
);

COMMENT ON TABLE  stars           IS 'Звёзды';
COMMENT ON COLUMN stars.name      IS 'Полное имя звезды';
COMMENT ON COLUMN stars.shortname IS 'Краткое имя звезды';
COMMENT ON COLUMN stars.hr        IS 'Номер в каталоге HR';
