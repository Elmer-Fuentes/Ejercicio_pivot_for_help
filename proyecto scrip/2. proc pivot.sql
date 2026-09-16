/*
2) Filas = DEPARTAMENTOS / Columnas = AÑOS

*/


USE [PRATICA1];
GO

CREATE OR ALTER PROCEDURE dbo.USP_Pivot_Departamento_Anio_Dinamico
    @EventoFiltro CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ColumnasPivot NVARCHAR(MAX);
    DECLARE @QueryDinamico NVARCHAR(MAX);

    /* =========================================================
       1. Obtener dinámicamente los años
       ========================================================= */

    SELECT @ColumnasPivot = STUFF((
        SELECT
            ',' + QUOTENAME(ANIO)
        FROM
        (
            SELECT DISTINCT
                ANIO
            FROM dbo.REGISTRO_EVENTO
            WHERE
                @EventoFiltro IS NULL
                OR EVENTO = @EventoFiltro
        ) AS Anios
        ORDER BY ANIO
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
        DEPARTAMENTO,
        ' + @ColumnasPivot + '
    FROM
    (
        SELECT
            D.DEPARTAMENTO,
            R.ANIO,
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
        FOR ANIO IN
        (
            ' + @ColumnasPivot + '
        )
    ) AS TablaPivot

    ORDER BY DEPARTAMENTO;
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





/*

pruebas
*/


EXEC dbo.USP_Pivot_Departamento_Anio_Dinamico;



--Solo nacimientos

EXEC dbo.USP_Pivot_Departamento_Anio_Dinamico
    @EventoFiltro = 'N';



--defunciones
EXEC dbo.USP_Pivot_Departamento_Anio_Dinamico
    @EventoFiltro = 'D';