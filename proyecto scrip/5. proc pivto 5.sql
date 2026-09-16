/*
HACER UN QUERY DONDE DESPLIEGUE LAS 5 CAUSAS DE MUERTE QUE MÁS SUMAN POR DEPARTAMENTO POR AÑO CON LAS COLUMNAS 
AÑO, DEPARTAMENTO, CAUSA DE MUERTE, SUMATORIA HOMBRES, SUMATORIA MUJERES, SUMATORIA TOTAL.
*/

USE [PRATICA1];
GO

CREATE OR ALTER PROCEDURE dbo.USP_Reporte_TopCausasMuerte_Departamento
    @AnioFiltro          INT = NULL,
    @DepartamentoFiltro  INT = NULL,
    @TopCantidad         INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    /* =========================================================
       1. Sumatoria de defunciones por Año, Departamento
          y Causa de Muerte
       ========================================================= */

    WITH CausasPorDepartamento AS
    (
        SELECT
            R.ANIO,
            R.CODIGO_DEPARTAMENTO,
            D.DEPARTAMENTO,
            R.CODIGO_CAUSA,
            C.DESCRIPCION_CAUSA AS CAUSA_MUERTE,

            SUM(
                CASE
                    WHEN R.SEXO = 'M'
                    THEN R.CANTIDAD
                    ELSE 0
                END
            ) AS SUMATORIA_HOMBRES,

            SUM(
                CASE
                    WHEN R.SEXO = 'F'
                    THEN R.CANTIDAD
                    ELSE 0
                END
            ) AS SUMATORIA_MUJERES,

            SUM(R.CANTIDAD) AS SUMATORIA_TOTAL

        FROM dbo.REGISTRO_EVENTO AS R

        INNER JOIN dbo.DEPARTAMENTO AS D
            ON D.CODIGO_DEPARTAMENTO = R.CODIGO_DEPARTAMENTO

        INNER JOIN dbo.CAUSA_MUERTE AS C
            ON C.CODIGO_CAUSA = R.CODIGO_CAUSA

        WHERE R.EVENTO = 'D'

          AND
          (
              @AnioFiltro IS NULL
              OR R.ANIO = @AnioFiltro
          )

          AND
          (
              @DepartamentoFiltro IS NULL
              OR R.CODIGO_DEPARTAMENTO = @DepartamentoFiltro
          )

        GROUP BY
            R.ANIO,
            R.CODIGO_DEPARTAMENTO,
            D.DEPARTAMENTO,
            R.CODIGO_CAUSA,
            C.DESCRIPCION_CAUSA
    ),

    /* =========================================================
       2. Ranking de las causas dentro de cada
          Año + Departamento
       ========================================================= */

    RankingCausas AS
    (
        SELECT
            ANIO,
            CODIGO_DEPARTAMENTO,
            DEPARTAMENTO,
            CODIGO_CAUSA,
            CAUSA_MUERTE,
            SUMATORIA_HOMBRES,
            SUMATORIA_MUJERES,
            SUMATORIA_TOTAL,

            ROW_NUMBER() OVER
            (
                PARTITION BY
                    ANIO,
                    CODIGO_DEPARTAMENTO

                ORDER BY
                    SUMATORIA_TOTAL DESC,
                    CODIGO_CAUSA
            ) AS POSICION

        FROM CausasPorDepartamento
    )

    /* =========================================================
       3. Mostrar únicamente las primeras 5 causas
          de cada Departamento y Año
       ========================================================= */

    SELECT
        ANIO,
        DEPARTAMENTO,
        CAUSA_MUERTE,
        SUMATORIA_HOMBRES,
        SUMATORIA_MUJERES,
        SUMATORIA_TOTAL

    FROM RankingCausas

    WHERE POSICION <= @TopCantidad

    ORDER BY
        ANIO,
        DEPARTAMENTO,
        POSICION;

END;
GO



/* TEST DE PRUEBAS*/


--probar las 5 causas principales de todos los departamentos y todos los años
EXEC dbo.USP_Reporte_TopCausasMuerte_Departamento;


--Solo para 2022

EXEC dbo.USP_Reporte_TopCausasMuerte_Departamento
    @AnioFiltro = 2022;


    --Solo Guatemala
    EXEC dbo.USP_Reporte_TopCausasMuerte_Departamento
    @DepartamentoFiltro = 1;


--Guatemala en 2022
EXEC dbo.USP_Reporte_TopCausasMuerte_Departamento
    @AnioFiltro = 2022,
    @DepartamentoFiltro = 1;