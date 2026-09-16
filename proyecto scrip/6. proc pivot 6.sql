
/*
Mostrar la tasa de crecimiento en natalidad, donde
Tasa = (Sumatoria año actual - Sumatoria año anterior) / Sumatoria año actual,
colocando los años en las filas y los departamentos en las columnas.


*/


USE [PRATICA1];
GO

CREATE OR ALTER PROCEDURE dbo.USP_Reporte_TasaCrecimientoNatalidad_Pivot_Dinamico
    @AnioFiltro INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ColumnasPivot NVARCHAR(MAX);
    DECLARE @QueryDinamico NVARCHAR(MAX);

    /* =========================================================
       1. Obtener dinámicamente los departamentos
          que se convertirán en columnas
       ========================================================= */

    SELECT @ColumnasPivot = STUFF((
        SELECT
            ',' + QUOTENAME(DEPARTAMENTO)
        FROM
        (
            SELECT DISTINCT
                D.DEPARTAMENTO
            FROM dbo.REGISTRO_EVENTO AS R
            INNER JOIN dbo.DEPARTAMENTO AS D
                ON D.CODIGO_DEPARTAMENTO = R.CODIGO_DEPARTAMENTO
            WHERE R.EVENTO = 'N'
        ) AS Departamentos
        ORDER BY DEPARTAMENTO
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '');

    IF @ColumnasPivot IS NULL
    BEGIN
        PRINT 'No se encontraron departamentos con registros de nacimientos.';
        RETURN;
    END;


    /* =========================================================
       2. Construir Query dinámico
       ========================================================= */

    SET @QueryDinamico = '

    WITH Natalidad AS
    (
        SELECT
            R.ANIO,
            R.CODIGO_DEPARTAMENTO,
            D.DEPARTAMENTO,
            SUM(R.CANTIDAD) AS TOTAL_NACIMIENTOS

        FROM dbo.REGISTRO_EVENTO AS R

        INNER JOIN dbo.DEPARTAMENTO AS D
            ON D.CODIGO_DEPARTAMENTO = R.CODIGO_DEPARTAMENTO

        WHERE R.EVENTO = ''N''

        GROUP BY
            R.ANIO,
            R.CODIGO_DEPARTAMENTO,
            D.DEPARTAMENTO
    ),

    Comparacion AS
    (
        SELECT
            ANIO,
            CODIGO_DEPARTAMENTO,
            DEPARTAMENTO,
            TOTAL_NACIMIENTOS AS ANIO_ACTUAL,

            LAG(TOTAL_NACIMIENTOS) OVER
            (
                PARTITION BY CODIGO_DEPARTAMENTO
                ORDER BY ANIO
            ) AS ANIO_ANTERIOR

        FROM Natalidad
    ),

    TasaCrecimiento AS
    (
        SELECT
            ANIO,
            DEPARTAMENTO,

            CAST
            (
                (
                    CAST(ANIO_ACTUAL AS DECIMAL(18,4))
                    -
                    CAST(ANIO_ANTERIOR AS DECIMAL(18,4))
                )
                /
                NULLIF(
                    CAST(ANIO_ACTUAL AS DECIMAL(18,4)),
                    0
                )
                AS DECIMAL(18,4)
            ) AS TASA_CRECIMIENTO

        FROM Comparacion

        WHERE ANIO_ANTERIOR IS NOT NULL

          AND
          (
              @anio IS NULL
              OR ANIO = @anio
          )
    )

    SELECT
        ANIO,
        ' + @ColumnasPivot + '

    FROM TasaCrecimiento

    PIVOT
    (
        MAX(TASA_CRECIMIENTO)
        FOR DEPARTAMENTO IN
        (
            ' + @ColumnasPivot + '
        )
    ) AS TablaPivot

    ORDER BY ANIO;
    ';


    /* =========================================================
       3. Ejecutar Query parametrizado
       ========================================================= */

    EXEC sp_executesql
        @QueryDinamico,
        N'@anio INT',
        @anio = @AnioFiltro;

END;
GO


/**
ESENARIOS DE PRUEBAS
*/

---Para todos los años

EXEC dbo.USP_Reporte_TasaCrecimientoNatalidad_Pivot_Dinamico;


--para uno específico

EXEC dbo.USP_Reporte_TasaCrecimientoNatalidad_Pivot_Dinamico
    @AnioFiltro = 2024;


