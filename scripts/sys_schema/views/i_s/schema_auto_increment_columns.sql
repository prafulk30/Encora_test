
--
-- View: schema_auto_increment_columns
--
-- Present current auto_increment usage/capacity in all tables.
--
-- mysql> select * from schema_auto_increment_columns limit 5;
-- +-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
-- | table_schema      | table_name        | column_name | data_type | column_type | is_signed | is_unsigned | max_value           | auto_increment | auto_increment_ratio |
-- +-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
-- | test              | t1                | i           | tinyint   | tinyint(4)  |         1 |           0 |                 127 |             34 |               0.2677 |
-- | mem__advisor_text | template_meta     | hib_id      | int       | int(11)     |         1 |           0 |          2147483647 |            516 |               0.0000 |
-- | mem__advisors     | advisor_schedules | schedule_id | int       | int(11)     |         1 |           0 |          2147483647 |            249 |               0.0000 |
-- | mem__advisors     | app_identity_path | hib_id      | int       | int(11)     |         1 |           0 |          2147483647 |            251 |               0.0000 |
-- | mem__bean_config  | plists            | id          | bigint    | bigint(20)  |         1 |           0 | 9223372036854775807 |              1 |               0.0000 |
-- +-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mariadb.sys'@'localhost'
  SQL SECURITY INVOKER
VIEW schema_auto_increment_columns (
  table_schema,
  table_name,
  column_name,
  data_type,
  column_type,
  is_signed,
  is_unsigned,
  max_value,
  auto_increment,
  auto_increment_ratio
) AS
SELECT TABLE_SCHEMA,
       TABLE_NAME,
       COLUMN_NAME,
       DATA_TYPE,
       COLUMN_TYPE,
       (LOCATE('unsigned', COLUMN_TYPE) = 0) AS is_signed,
       (LOCATE('unsigned', COLUMN_TYPE) > 0) AS is_unsigned,
       (
          CASE DATA_TYPE
            WHEN 'tinyint' THEN 255
            WHEN 'smallint' THEN 65535
            WHEN 'mediumint' THEN 16777215
            WHEN 'int' THEN 4294967295
            WHEN 'bigint' THEN 18446744073709551615
          END >> IF(LOCATE('unsigned', COLUMN_TYPE) > 0, 0, 1)
       ) AS max_value,
       AUTO_INCREMENT,
       AUTO_INCREMENT / (
         CASE DATA_TYPE
           WHEN 'tinyint' THEN 255
           WHEN 'smallint' THEN 65535
           WHEN 'mediumint' THEN 16777215
           WHEN 'int' THEN 4294967295
           WHEN 'bigint' THEN 18446744073709551615
         END >> IF(LOCATE('unsigned', COLUMN_TYPE) > 0, 0, 1)
       ) AS auto_increment_ratio
  FROM INFORMATION_SCHEMA.COLUMNS
 INNER JOIN INFORMATION_SCHEMA.TABLES USING (TABLE_SCHEMA, TABLE_NAME)
 WHERE TABLE_SCHEMA NOT IN ('mysql', 'sys', 'INFORMATION_SCHEMA', 'performance_schema')
   AND TABLE_TYPE='BASE TABLE'
   AND EXTRA='auto_increment'
 ORDER BY auto_increment_ratio DESC, max_value;
