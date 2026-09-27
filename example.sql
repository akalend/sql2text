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
