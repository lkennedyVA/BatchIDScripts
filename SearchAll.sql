-- Query for columns in tables and views with SMALLINT datatype
SELECT 
    t.type_desc AS ObjectType,
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    OBJECT_NAME(c.object_id) AS ObjectName,
    SCHEMA_NAME(t.schema_id) + '.' + OBJECT_NAME(c.object_id) AS FullObjectName,
    c.name AS ColumnName,
    TYPE_NAME(c.system_type_id) AS DataType
FROM 
    sys.columns c
JOIN 
    sys.objects t ON c.object_id = t.object_id
WHERE 
    TYPE_NAME(c.system_type_id) = 'smallint'
    AND c.name LIKE '%batch%id%'
    AND t.type IN ('U')  -- U = Table

UNION ALL

SELECT 
    t.type_desc AS ObjectType,
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    OBJECT_NAME(c.object_id) AS ObjectName,
    SCHEMA_NAME(t.schema_id) + '.' + OBJECT_NAME(c.object_id) AS FullObjectName,
    c.name AS ColumnName,
    TYPE_NAME(c.system_type_id) AS DataType
FROM 
    sys.columns c
JOIN 
    sys.objects t ON c.object_id = t.object_id
WHERE 
    TYPE_NAME(c.system_type_id) = 'smallint'
    AND c.name LIKE '%batch%id%'
    AND t.type IN ('V')  -- V = View

UNION ALL

-- Query for parameters in stored procedures and functions
SELECT 
    o.type_desc AS ObjectType,
    SCHEMA_NAME(o.schema_id) AS SchemaName,
    OBJECT_NAME(p.object_id) AS ObjectName,
    SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(p.object_id) AS FullObjectName,
    p.name AS ParameterName,
    TYPE_NAME(p.system_type_id) AS DataType
FROM 
    sys.parameters p
JOIN 
    sys.objects o ON p.object_id = o.object_id
WHERE 
    TYPE_NAME(p.system_type_id) = 'smallint'
    AND p.name LIKE '%batch%id%'
    AND o.type IN ('P')  -- P = Procedure

UNION ALL

SELECT 
    o.type_desc AS ObjectType,
    SCHEMA_NAME(o.schema_id) AS SchemaName,
    OBJECT_NAME(p.object_id) AS ObjectName,
    SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(p.object_id) AS FullObjectName,
    p.name AS ParameterName,
    TYPE_NAME(p.system_type_id) AS DataType
FROM 
    sys.parameters p
JOIN 
    sys.objects o ON p.object_id = o.object_id
WHERE 
    TYPE_NAME(p.system_type_id) = 'smallint'
    AND p.name LIKE '%batch%id%'
    AND o.type IN ('FN', 'IF', 'TF', 'TR')  -- FN = Scalar Function, IF = Inline Table-Valued Function, TF = Table-Valued Function --

	UNION ALL 

-- Query for locally declared variables in stored procedures and functions (only scalar variables)
SELECT DISTINCT
    o.type_desc AS ObjectType,
    SCHEMA_NAME(o.schema_id) AS SchemaName,
    OBJECT_NAME(o.object_id) AS ObjectName,
    SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(o.object_id) AS FullObjectName,
    LTRIM(RTRIM(SUBSTRING(m.definition, 
                          CHARINDEX('@', m.definition, CHARINDEX('DECLARE @', m.definition)), 
                          CHARINDEX(' ', m.definition, CHARINDEX('@', m.definition, CHARINDEX('DECLARE @', m.definition))) 
                          - CHARINDEX('@', m.definition, CHARINDEX('DECLARE @', m.definition))))) AS VariableName,
    'smallint' AS DataType
FROM 
    sys.sql_modules m
JOIN 
    sys.objects o ON m.object_id = o.object_id
WHERE 
    m.definition LIKE '%DECLARE @%batch%id% smallint%' -- Look for declared variables matching the pattern
    AND o.type IN ('P', 'FN', 'IF', 'TF')  -- Only include stored procedures and functions
    AND NOT m.definition LIKE '%DECLARE @%TABLE%' -- Exclude table variables

union all

SELECT 
    o.type_desc AS ObjectType,
    SCHEMA_NAME(o.schema_id) AS SchemaName,
    OBJECT_NAME(o.object_id) AS ObjectName,
    SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(o.object_id) AS FullObjectName,
    'smallint' AS DataType,
    SUBSTRING(m.definition, 
              CHARINDEX('#', m.definition, CHARINDEX('CREATE TABLE', m.definition)), 
              CHARINDEX('(', m.definition, CHARINDEX('#', m.definition, CHARINDEX('CREATE TABLE', m.definition))) 
              - CHARINDEX('#', m.definition, CHARINDEX('CREATE TABLE', m.definition))) AS TempTableName
FROM 
    sys.sql_modules m
JOIN 
    sys.objects o ON m.object_id = o.object_id
WHERE 
    m.definition LIKE '%CREATE TABLE #%'
    AND m.definition LIKE '%smallint%'
    AND m.definition LIKE '%Batch%id%' -- Look for smallint columns with name pattern
    AND o.type IN ('P', 'FN', 'IF', 'TF')  -- P = Procedure, FN = Scalar Function, IF = Inline Table-Valued Function, TF = Table-Valued Function
ORDER BY 
    ObjectType, SchemaName, ObjectName, FullObjectName;

