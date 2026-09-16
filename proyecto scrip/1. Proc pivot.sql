/*
Filas = AÑOS / Columnas = DEPARTAMENTOS
*/

USE [PRATICA1];
GO

CREATE OR ALTER PROCEDURE dbo.USP_Pivot_Anio_Departamento_Dinamico
    @EventoFiltro CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ColumnasPivot NVARCHAR(MAX);
    DECLARE @QueryDinamico NVARCHAR(MAX);

    /* =========================================================
       1. Obtener dinámicamente los departamentos
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
            WHERE
                @EventoFiltro IS NULL
                OR R.EVENTO = @EventoFiltro
        ) AS Departamentos
        ORDER BY DEPARTAMENTO
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '');

    IF @ColumnasPivot IS NULL
    BEGIN
        PRINT 'No se encontraron datos para generar el PIVOT.';
        RETURN;
    END;


    /* =========================================================
       2. Construcción del PIVOT dinámico
       ========================================================= */

    SET @QueryDinamico = '
    SELECT
        ANIO,
        ' + @ColumnasPivot + '
    FROM
    (
        SELECT
            R.ANIO,
            D.DEPARTAMENTO,
            R.CANTIDAD
        FROM dbo.REGISTRO_EVENTO AS R
        INNER JOIN dbo.DEPARTAMENTO AS D
            ON D.CODIGO_DEPARTAMENTO = R.CODIGO_DEPARTAMENTO
        WHERE
            @evento IS NULL
            OR R.EVENTO = @evento
    ) AS DatosBase

    PIVOT
    (
        SUM(CANTIDAD)
        FOR DEPARTAMENTO IN
        (
            ' + @ColumnasPivot + '
        )
    ) AS TablaPivot

    ORDER BY ANIO;
    ';


    /* =========================================================
       3. Ejecución
       ========================================================= */

    EXEC sp_executesql
        @QueryDinamico,
        N'@evento CHAR(1)',
        @evento = @EventoFiltro;

END;
GO



--todo

EXEC dbo.USP_Pivot_Anio_Departamento_Dinamico;

--Solo nacimientos
EXEC dbo.USP_Pivot_Anio_Departamento_Dinamico
    @EventoFiltro = 'N';

--Solo defunciones
EXEC dbo.USP_Pivot_Anio_Departamento_Dinamico
    @EventoFiltro = 'D';