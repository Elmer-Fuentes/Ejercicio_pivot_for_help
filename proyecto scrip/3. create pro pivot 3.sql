USE [PRATICA1];
GO

CREATE OR ALTER PROCEDURE dbo.USP_Reporte_Eventos_Pivot_Dinamico
    @AnioFiltro          INT = NULL,
    @DepartamentoFiltro  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ColumnasPivot NVARCHAR(MAX);
    DECLARE @QueryDinamico NVARCHAR(MAX);

    /* =========================================================
       1. Obtener dinámicamente los tipos de evento existentes
          N = Nacimientos
          D = Defunciones
       ========================================================= */

    SELECT @ColumnasPivot = STUFF((
        SELECT DISTINCT
            ',' + QUOTENAME(EVENTO)
        FROM dbo.REGISTRO_EVENTO
        WHERE (@AnioFiltro IS NULL OR ANIO = @AnioFiltro)
          AND (@DepartamentoFiltro IS NULL 
               OR CODIGO_DEPARTAMENTO = @DepartamentoFiltro)
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '');

    IF @ColumnasPivot IS NULL
    BEGIN
        PRINT 'No se encontraron registros con los filtros proporcionados.';
        RETURN;
    END;


    /* =========================================================
       2. Construcción del PIVOT dinámico
       ========================================================= */

    SET @QueryDinamico = '
    WITH DatosBase AS
    (
        SELECT
            R.ANIO,
            R.CODIGO_DEPARTAMENTO,
            D.DEPARTAMENTO,
            R.EVENTO,
            R.CANTIDAD
        FROM dbo.REGISTRO_EVENTO AS R
        INNER JOIN dbo.DEPARTAMENTO AS D
            ON D.CODIGO_DEPARTAMENTO = R.CODIGO_DEPARTAMENTO
        WHERE 1 = 1
          AND (@anio IS NULL OR R.ANIO = @anio)
          AND (@departamento IS NULL 
               OR R.CODIGO_DEPARTAMENTO = @departamento)
    ),
    MatrizPivot AS
    (
        SELECT
            ANIO,
            CODIGO_DEPARTAMENTO,
            DEPARTAMENTO,
            ' + @ColumnasPivot + '
        FROM DatosBase
        PIVOT
        (
            SUM(CANTIDAD)
            FOR EVENTO IN (' + @ColumnasPivot + ')
        ) AS P
    )
    SELECT
        ANIO,
        CODIGO_DEPARTAMENTO,
        DEPARTAMENTO,
        ISNULL([D], 0) AS SUMATORIA_DEFUNCIONES,
        ISNULL([N], 0) AS SUMATORIA_NACIMIENTOS,
        CAST(ISNULL([D], 0) AS DECIMAL(18,4))
            /
        NULLIF(CAST(ISNULL([N], 0) AS DECIMAL(18,4)), 0)
            AS DEFUNCIONES_ENTRE_NACIMIENTOS
    FROM MatrizPivot
    ORDER BY
        ANIO,
        DEPARTAMENTO;
    ';


    /* =========================================================
       3. Ejecución parametrizada
       ========================================================= */

    EXEC sp_executesql
        @QueryDinamico,
        N'@anio INT, @departamento INT',
        @anio = @AnioFiltro,
        @departamento = @DepartamentoFiltro;

END;
GO



/*============Esenario de pruebas=====================*/

/* 
Eso trae todos los años y departamentos.
*/

EXEC dbo.USP_Reporte_Eventos_Pivot_Dinamico;

/*
Solo 2022
*/
EXEC dbo.USP_Reporte_Eventos_Pivot_Dinamico
    @AnioFiltro = 2022;

/*
Solo Guatemala
*/
    EXEC dbo.USP_Reporte_Eventos_Pivot_Dinamico
    @DepartamentoFiltro = 1;
/*
año 2022 y guatemala
*/

    EXEC dbo.USP_Reporte_Eventos_Pivot_Dinamico
    @AnioFiltro = 2022,
    @DepartamentoFiltro = 1;