/*

HACER UN QUERY DONDE DESPLIEGUE LOS 5 DEPARTAMENTOS QUE HAN TENIDO MÁS NACIMIENTOS POR AÑO CON LAS COLUMNAS AÑO, DEPARTAMENTO, SUMATORIA HOMBRES, SUMATORIA MUJERES, SUMATORIA TOTAL.

*/



USE [PRATICA1];
GO

CREATE OR ALTER PROCEDURE dbo.USP_Reporte_TopDepartamentos_Nacimientos
    @AnioFiltro INT = NULL,
    @TopCantidad INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    /* =========================================================
       1. Sumatoria de nacimientos por Año y Departamento
       ========================================================= */
    WITH NacimientosPorDepartamento AS
    (
        SELECT
            R.ANIO,
            R.CODIGO_DEPARTAMENTO,
            D.DEPARTAMENTO,

            SUM(
                CASE 
                    WHEN R.SEXO = 'M' THEN R.CANTIDAD 
                    ELSE 0 
                END
            ) AS SUMATORIA_HOMBRES,

            SUM(
                CASE 
                    WHEN R.SEXO = 'F' THEN R.CANTIDAD 
                    ELSE 0 
                END
            ) AS SUMATORIA_MUJERES,

            SUM(R.CANTIDAD) AS SUMATORIA_TOTAL

        FROM dbo.REGISTRO_EVENTO AS R
        INNER JOIN dbo.DEPARTAMENTO AS D
            ON D.CODIGO_DEPARTAMENTO = R.CODIGO_DEPARTAMENTO

        WHERE R.EVENTO = 'N'
          AND (
                @AnioFiltro IS NULL
                OR R.ANIO = @AnioFiltro
              )

        GROUP BY
            R.ANIO,
            R.CODIGO_DEPARTAMENTO,
            D.DEPARTAMENTO
    ),

    /* =========================================================
       2. Numeramos los Departamentos de mayor a menor
          dentro de cada año
       ========================================================= */
    RankingDepartamentos AS
    (
        SELECT
            ANIO,
            CODIGO_DEPARTAMENTO,
            DEPARTAMENTO,
            SUMATORIA_HOMBRES,
            SUMATORIA_MUJERES,
            SUMATORIA_TOTAL,

            ROW_NUMBER() OVER
            (
                PARTITION BY ANIO
                ORDER BY SUMATORIA_TOTAL DESC
            ) AS POSICION

        FROM NacimientosPorDepartamento
    )

    /* =========================================================
       3. Mostrar únicamente los primeros departamentos
          de cada año
       ========================================================= */
    SELECT
        ANIO,
        DEPARTAMENTO,
        SUMATORIA_HOMBRES,
        SUMATORIA_MUJERES,
        SUMATORIA_TOTAL
    FROM RankingDepartamentos
    WHERE POSICION <= @TopCantidad
    ORDER BY
        ANIO,
        POSICION;

END;
GO



/*
 TEST DE PRUEBAS */


-- 5 DEPARTAMENTOS 
EXEC dbo.USP_Reporte_TopDepartamentos_Nacimientos;



-- Solo para 2022:
EXEC dbo.USP_Reporte_TopDepartamentos_Nacimientos
    @AnioFiltro = 2022;


    --Solo para 2023

    EXEC dbo.USP_Reporte_TopDepartamentos_Nacimientos
    @AnioFiltro = 2023;