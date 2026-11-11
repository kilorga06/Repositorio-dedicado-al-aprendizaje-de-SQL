


-- 1. LIMPIEZA DE TABLAS (Orden inverso de dependencia)

DROP TABLE IF EXISTS tab_pagos ;
DROP TABLE IF EXISTS tab_det_compra ;
DROP TABLE IF EXISTS tab_enc_compra ;
DROP TABLE IF EXISTS tab_det_orden ;
DROP TABLE IF EXISTS tab_orden_compra ;
DROP TABLE IF EXISTS tab_prod_prov ;
DROP TABLE IF EXISTS tab_prov ;
DROP TABLE IF EXISTS tab_areas ;
DROP TABLE IF EXISTS tab_prod ;
DROP TABLE IF EXISTS tab_ciud ;
DROP TABLE IF EXISTS tab_dptos ;
DROP TABLE IF EXISTS tab_pmtros ;


-- 2. CREACIÓN DE TABLAS


-- 1. tab parametros

CREATE TABLE tab_pmtros
(
 id_empresa             DECIMAL(10,0)           NOT NULL,
 dia_pagos1             SMALLINT                NOT NULL, 
 dia_pagos2             SMALLINT                NOT NULL,
 dia_pagos3             SMALLINT                NOT NULL,
 num_orden              DECIMAL(6,0)            NOT NULL,
 CONSTRAINT pk_pmtros PRIMARY KEY (id_empresa),
 CONSTRAINT ck_pmtros_id CHECK (id_empresa > 0),
 CONSTRAINT ck_pmtros_dias CHECK (dia_pagos1 BETWEEN 1 AND 7
 AND dia_pagos2 BETWEEN 1 AND 7
 AND dia_pagos3 BETWEEN 1 AND 7
 AND dia_pagos1 < dia_pagos2
 AND dia_pagos2 < dia_pagos3),
 CONSTRAINT ck_pmtros_orden CHECK (num_orden > 0)
);

-- 2. tab departamentos
CREATE TABLE tab_dptos
(
 id_dpto VARCHAR(10) NOT NULL,
 nom_dpto VARCHAR(30) NOT NULL,
 CONSTRAINT pk_dptos PRIMARY KEY (id_dpto),
 CONSTRAINT uq_dptos_nombre UNIQUE (nom_dpto),
 CONSTRAINT ck_dptos_id CHECK (id_dpto ~ '^[0-9]{2}$'),
 CONSTRAINT ck_dptos_nombre CHECK (BTRIM(nom_dpto) <> '')
);

-- 3. tab ciudades 
CREATE TABLE tab_ciud
(
 id_ciud            VARCHAR(5)                      NOT NULL,
 nom_ciud           VARCHAR(15)                     NOT NULL,
 id_dpto            VARCHAR(10)                     NOT NULL,
 CONSTRAINT pk_ciud PRIMARY KEY (id_ciud),
 CONSTRAINT fk_ciud_dpto FOREIGN KEY (id_dpto)
 REFERENCES tab_dptos (id_dpto)
 ON UPDATE CASCADE ON DELETE RESTRICT,
 CONSTRAINT uq_ciud_nombre UNIQUE (id_dpto, nom_ciud),
 CONSTRAINT ck_ciud_id CHECK (id_ciud ~ '^[0-9]{5}$'),
 CONSTRAINT ck_ciud_prefijo CHECK (LEFT(id_ciud, 2) = id_dpto),
 CONSTRAINT ck_ciud_nombre CHECK (BTRIM(nom_ciud) <> '')
);



-- 4. Proveedores 
CREATE TABLE tab_prov
(
 id_prov        DECIMAL(10,0)       NOT NULL,
 nom_prov       VARCHAR(30)         NOT NULL,
 ape1_prov      VARCHAR(30)         NOT NULL,
 ape2_prov      VARCHAR(30),
 nom_comp       VARCHAR(50)         GENERATED ALWAYS AS
 (nom_prov || ' ' || ape1_prov || COALESCE(' ' || ape2_prov, ''))
 STORED,
 dir_prov       VARCHAR(30)         NOT NULL,
 tel_prov       VARCHAR(10)         NOT NULL,
 email_prov     VARCHAR(20)         NOT NULL,
 id_ciud        VARCHAR(5)          NOT NULL,
 val_cupocre    DECIMAL(12,0)       NOT NULL DEFAULT 0,
 val_puntos     DECIMAL(3,0)        NOT NULL DEFAULT 0,
 num_fact       DECIMAL(6,0)        NOT NULL,
 ind_estado     BOOLEAN             NOT NULL DEFAULT TRUE,
 CONSTRAINT pk_id_prov PRIMARY KEY (id_prov),
 CONSTRAINT fk_prov_ciud FOREIGN KEY (id_ciud)	
 REFERENCES tab_ciud (id_ciud)
 ON UPDATE CASCADE ON DELETE RESTRICT,
 CONSTRAINT uq_prov_email UNIQUE (email_prov),
 CONSTRAINT ck_prov_id CHECK (id_prov > 0),
 CONSTRAINT ck_prov_tel CHECK (tel_prov ~ '^(60[124-8]|3[0-9]{2})[0-9]{7}$'),
 CONSTRAINT ck_prov_email CHECK (email_prov ~* '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'),
 CONSTRAINT ck_prov_cupo CHECK (val_cupocre >= 0),
 CONSTRAINT ck_prov_puntos CHECK (val_puntos BETWEEN 0 AND 100),
 CONSTRAINT ck_prov_fact CHECK (num_fact > 0)
);

-- 5. tab productos
CREATE TABLE tab_prod
(
 id_prod            SMALLINT            NOT NULL,
 id_ref             VARCHAR(10)         NOT NULL,
 nom_prod           VARCHAR(30)         NOT NULL,
 ind_estado         BOOLEAN             NOT NULL DEFAULT TRUE,
 CONSTRAINT pk_prod PRIMARY KEY (id_prod),
 CONSTRAINT uq_prod_ref UNIQUE (id_ref),
 CONSTRAINT ck_prod_id CHECK (id_prod > 0),
 CONSTRAINT ck_prod_ref CHECK (id_ref ~ '^PROD[0-9]{3}$'),
 CONSTRAINT ck_prod_nombre CHECK (BTRIM(nom_prod) <> '')
);

-- 6. tab areas
CREATE TABLE tab_areas
(
 id_area DECIMAL(2,0) NOT NULL,
 nom_area VARCHAR(60) NOT NULL,
 nom_encarg VARCHAR() NOT NULL,
 CONSTRAINT pk_areas PRIMARY KEY (id_area),
 CONSTRAINT uq_areas_nombre UNIQUE (nom_area),
 CONSTRAINT ck_areas_id CHECK (id_area > 0)
);

-- 7. rm productos y proveedores (Nota: Clave primaria compuesta para permitir múltiples productos por proveedor)
CREATE TABLE tab_prod_prov
(
 id_prov        DECIMAL(10,0)           NOT NULL,
 id_prod        SMALLINT                NOT NULL,
 val_prod       DECIMAL(10,0)           NOT NULL,
 ind_disp       BOOLEAN                 NOT NULL DEFAULT TRUE,
 CONSTRAINT pk_prod_prov PRIMARY KEY (id_prov, id_prod),
 CONSTRAINT fk_id_prodprov_prov FOREIGN KEY (id_prov)
 REFERENCES tab_prov (id_prov) ON DELETE RESTRICT,
 CONSTRAINT fk_prodprov_prod FOREIGN KEY (id_prod)
 REFERENCES tab_prod (id_prod) ON DELETE RESTRICT,
 CONSTRAINT ck_prodprov_valor CHECK (val_prod > 0)
);

-- 8. tab orden de compra
CREATE TABLE tab_orden_compra
(
 id_orden           DECIMAL(6,0)            NOT NULL,
 fec_orden          TIMESTAMP               NOT NULL DEFAULT CURRENT_TIMESTAMP,
 id_area            DECIMAL(2,0)            NOT NULL,
 CONSTRAINT pk_orden PRIMARY KEY (id_orden),
 CONSTRAINT fk_orden_area FOREIGN KEY (id_area)
 REFERENCES tab_areas (id_area) ON DELETE RESTRICT,
 CONSTRAINT ck_orden_id CHECK (id_orden > 0)
);

-- 9. tab detalle de orden
CREATE TABLE tab_det_orden
(
 id_orden           DECIMAL(6,0)            NOT NULL,
 id_prod            SMALLINT                NOT NULL,
 val_cant           SMALLINT                NOT NULL,
 CONSTRAINT pk_det_orden PRIMARY KEY (id_orden, id_prod),
 CONSTRAINT fk_detorden_orden FOREIGN KEY (id_orden)
 REFERENCES tab_orden_compra (id_orden) ON DELETE CASCADE,
 CONSTRAINT fk_detorden_prod FOREIGN KEY (id_prod)
 REFERENCES tab_prod (id_prod) ON DELETE RESTRICT,
 CONSTRAINT ck_detorden_cant CHECK (val_cant > 0)
);

-- 10. Facturas de compra: encabezado
CREATE TABLE tab_enc_compra
(
 id_factura             DECIMAL(6,0)            NOT NULL,
 fec_factura            DATE                    NOT NULL DEFAULT CURRENT_DATE,
 id_prov                DECIMAL(10,0)           NOT NULL,
 id_ciud_entrega        VARCHAR(5)              NOT NULL, 
 val_observa            TEXT,
 CONSTRAINT pk_enc_compra PRIMARY KEY (id_factura),
 CONSTRAINT fk_enc_prov FOREIGN KEY (id_prov)
 REFERENCES tab_prov (id_prov) ON DELETE RESTRICT,
 CONSTRAINT fk_enc_ciud FOREIGN KEY (id_ciud_entrega)
 REFERENCES tab_ciud (id_ciud) ON DELETE RESTRICT,
 CONSTRAINT ck_enc_id CHECK (id_factura > 0),
 CONSTRAINT ck_enc_fecha CHECK (fec_factura >= DATE '2000-01-01')
);

-- 11. Facturas de compra: detalle
CREATE TABLE tab_det_compra
(
 id_factura                 DECIMAL(6,0)            NOT NULL,
 id_prod                    SMALLINT                NOT NULL,
 val_cant                   SMALLINT                NOT NULL,
 val_unit                   DECIMAL(10,0)           NOT NULL,
 val_descu                  DECIMAL(12,0)           NOT NULL DEFAULT 0,
 porc_iva                   DECIMAL(4,2)            NOT NULL DEFAULT 19,
 val_bruto                  DECIMAL(12,0)           GENERATED ALWAYS AS (val_cant * val_unit) STORED,
 val_iva                    DECIMAL(12,0)           GENERATED ALWAYS AS
 (ROUND((val_cant * val_unit - val_descu) * porc_iva / 100)) STORED,
 val_neto                   DECIMAL(12,0)           GENERATED ALWAYS AS
 (val_cant * val_unit - val_descu
 + ROUND((val_cant * val_unit - val_descu) * porc_iva / 100)) STORED,
 CONSTRAINT pk_det_compra PRIMARY KEY (id_factura, id_prod),
 CONSTRAINT fk_detcomp_enc FOREIGN KEY (id_factura)
 REFERENCES tab_enc_compra (id_factura) ON DELETE CASCADE,
 CONSTRAINT fk_detcomp_prod FOREIGN KEY (id_prod)
 REFERENCES tab_prod (id_prod) ON DELETE RESTRICT,
 CONSTRAINT ck_detcomp_cant CHECK (val_cant > 0),
 CONSTRAINT ck_detcomp_unit CHECK (val_unit > 0),
 CONSTRAINT ck_detcomp_descu CHECK (val_descu >= 0
 AND val_descu <= val_cant * val_unit),
 CONSTRAINT ck_detcomp_iva CHECK (porc_iva IN (0, 5, 19))
);

-- 12. Pagos
CREATE TABLE tab_pagos
(
 id_factura             DECIMAL(6,0)            NOT NULL,
 id_pago                SMALLINT                NOT NULL,
 fec_pago               DATE                    NOT NULL,
 val_pago               DECIMAL(12,0)           NOT NULL, -- Ampliado para soportar pagos grandes
 CONSTRAINT pk_pagos PRIMARY KEY (id_factura, id_pago),
 CONSTRAINT fk_pagos_enc FOREIGN KEY (id_factura)
 REFERENCES tab_enc_compra (id_factura) ON DELETE RESTRICT,
 CONSTRAINT ck_pagos_id CHECK (id_pago > 0),
 CONSTRAINT ck_pagos_valor CHECK (val_pago > 0)
);

BEGIN;


-- 1. TABLA: tab_pmtros (10 registros de configuración por empresa)

INSERT INTO tab_pmtros (id_empresa, dia_pagos1, dia_pagos2, dia_pagos3, num_orden) VALUES
(1, 1, 3, 5, 100031),
(2, 2, 4, 6, 100032),
(3, 1, 4, 7, 100033),
(4, 3, 5, 7, 100034),
(5, 2, 5, 6, 100035),
(6, 1, 2, 5, 100036),
(7, 3, 4, 6, 100037),
(8, 2, 3, 7, 100038),
(9, 1, 5, 7, 100039),
(10, 4, 5, 6, 100040);


-- 2. TABLA: tab_dptos (10 departamentos con código id_dpto de 2 dígitos)

INSERT INTO tab_dptos (id_dpto, nom_dpto) VALUES
('05', 'Antioquia'),
('08', 'Atlántico'),
('11', 'Bogotá, D.C.'),
('13', 'Bolívar'),
('15', 'Boyacá'),
('17', 'Caldas'),
('18', 'Caquetá'),
('19', 'Cauca'),
('20', 'Cesar'),
('23', 'Córdoba'),
('25', 'Cundinamarca'),
('27', 'Chocó'),
('41', 'Huila'),
('44', 'La Guajira'),
('47', 'Magdalena'),
('50', 'Meta'),
('52', 'Nariño'),
('54', 'Norte de Santander'),
('63', 'Quindío'),
('66', 'Risaralda'),
('68', 'Santander'),
('70', 'Sucre'),
('73', 'Tolima'),
('76', 'Valle del Cauca'),
('81', 'Arauca'),
('85', 'Casanare'),
('86', 'Putumayo'),
('88', 'San Andrés y Providencia'),
('91', 'Amazonas'),
('94', 'Guainía'),
('95', 'Guaviare'),
('97', 'Vaupés'),
('99', 'Vichada');

-- 3. TABLA: tab_ciud (10 ciudades; id_ciud de 5 dígitos iniciando con id_dpto)

INSERT INTO tab_ciud (id_ciud, nom_ciud, id_dpto) VALUES

('05001', 'Medellín', '05'),
('08001', 'Barranquilla', '08'),
('11001', 'Bogotá, D.C.', '11'),
('13001', 'Cartagena de Indias', '13'),
('15001', 'Tunja', '15'),
('17001', 'Manizales', '17'),
('18001', 'Florencia', '18'),
('19001', 'Popayán', '19'),
('20001', 'Valledupar', '20'),
('23001', 'Montería', '23'),
('25001', 'Agua de Dios', '25'), 
('27001', 'Quibdó', '27'),
('41001', 'Neiva', '41'),
('44001', 'Riohacha', '44'),
('47001', 'Santa Marta', '47'),
('50001', 'Villavicencio', '50'),
('52001', 'Pasto', '52'),
('54001', 'Cúcuta', '54'),
('63001', 'Armenia', '63'),
('66001', 'Pereira', '66'),
('68001', 'Bucaramanga', '68'),
('70001', 'Sincelejo', '70'),
('73001', 'Ibagué', '73'),
('76001', 'Cali', '76'),
('81001', 'Arauca', '81'),
('85001', 'Yopal', '85'),
('86001', 'Mocoa', '86'),
('88001', 'San Andrés', '88'),
('91001', 'Leticia', '91'),
('94001', 'Inírida', '94'),
('95001', 'San José del Guaviare', '95'),
('97001', 'Mitú', '97'),
('99001', 'Puerto Carreño', '99');


ROLLBACK


-- 4. TABLA: tab_areas (10 áreas organizacionales)

INSERT INTO tab_areas (id_area, nom_area, nom_encarg) VALUES
(1, 'Jurídica', 'Paula Ríos'),
(2, 'Compras', 'Alberto Gómez'),
(3, 'Tecnología', 'Carlos Ruiz'),
(4, 'Ventas', 'Lucía Torres'),
(5, 'Operaciones', 'Mario Pérez'),
(6, 'Finanzas', 'Elena Blanco'),
(7, 'Recursos Humanos', 'Diana Morales'),
(8, 'Logística', 'Javier Ramos'),
(9, 'Calidad', 'Sofia Castro'),
(10, 'Mantenimiento', 'Andrés Mendoza');


-- 5. TABLA: tab_prod (10 productos con referencia PRODxxx)
	
	INSERT INTO tab_prod (id_prod, id_ref, nom_prod, ind_estado) VALUES
	(1, 'PROD001', 'Laptop Gamer', TRUE),
	(2, 'PROD002', 'Mouse Inalámbrico', FALSE),
	(3, 'PROD003', 'Teclado Mecánico', TRUE),
	(4, 'PROD004', 'Monitor 24"', TRUE),
	(5, 'PROD005', 'Impresora Láser', FALSE ),
	(6, 'PROD006', 'Tablet 10"', TRUE),
	(7, 'PROD007', 'Disco Duro SSD 1TB', TRUE),
	(8, 'PROD008', 'Silla Ergonómica', TRUE),
	(9, 'PROD009', 'Auriculares Bluetooth', TRUE),
	(10, 'PROD010', 'Cámara Web HD', TRUE);


ROLLBACK

-- 6. TABLA: tab_prov (10 proveedores con indicativos y correos válidos)


INSERT INTO tab_prov (
    id_prov, nom_prov, ape1_prov, ape2_prov, 
    dir_prov, tel_prov, email_prov, id_ciud, 
    val_cupocre, val_puntos, num_fact, ind_estado
) VALUES 
(1000000001, 'Carlos', 'Gómez', 'Hernández', 'Calle 100 #45-20', '6011234567', 'carlos@tecnosum.com', '08001', 5000000, 95, 1000, TRUE),
(1000000002, 'Ana', 'Martínez', 'López', 'Carrera 50 #10-15', '6041234567', 'ana.martinez@proveedores.com', '02001', 6000000, 90, 1001, TRUE),
(1000000003, 'Luis', 'Rodríguez', 'Pérez', 'Avenida 30 #20-30', '6071234567', 'luis.rodriguez@tecnologia.com', '09001', 8000000, 92, 1002, TRUE),
(1000000004, 'María', 'Fernández', 'Sánchez', 'Calle 72 #12-40', '6051234567', 'maria.fernandez@suministros.com', '04001', 4500000, 88, 1003, TRUE),
(1000000005, 'Jorge', 'Ramírez', 'Díaz', 'Carrera 15 #80-10', '6019876543', 'jorge.ramirez@distribuciones.com', '08001', 7000000, 94, 1004, TRUE),
(1000000006, 'Sofia', 'Hernández', 'Torres', 'Calle 45 #23-11', '6021234567', 'sofia.hernandez@importaciones.com', '02002', 5500000, 91, 1005, TRUE),
(1000000007, 'Pedro', 'Vargas', 'Morales', 'Avenida 6 #15-30', '6061234567', 'pedro.vargas@comercial.com', '06001', 3000000, 85, 1006, TRUE),
(1000000008, 'Laura', 'Castro', 'Rojas', 'Carrera 27 #34-50', '6079876543', 'laura.castro@equipos.com', '09001', 9000000, 97, 1007, TRUE),
(1000000009, 'Diego', 'Navarro', 'Suárez', 'Calle 10 #5-20', '6059876543', 'diego.navarro@global.com', '05001', 6500000, 89, 1008, TRUE),
(1000000010, 'Elena', 'Blanco', 'García', 'Carrera 9 #18-25', '3101234567', 'elena.blanco@sistemas.com', '07001', 4000000, 87, 1009, TRUE);


-- 7. TABLA: tab_prod_prov (10 registros de catálogo de precios por proveedor)

INSERT INTO tab_prod_prov (id_prov, id_prod, val_prod, ind_disp) VALUES
(1000000001, 1, 2500000, TRUE),
(1000000001, 2, 85000, TRUE),
(1000000002, 3, 120000, TRUE),
(1000000002, 4, 800000, TRUE),
(1000000003, 5, 650000, TRUE),
(1000000003, 6, 1100000, TRUE),
(1000000004, 7, 350000, TRUE),
(1000000004, 8, 450000, TRUE),
(1000000005, 9, 150000, TRUE),
(1000000005, 10, 200000, TRUE);


-- 8. TABLA: tab_orden_compra (10 órdenes de compra)

INSERT INTO tab_orden_compra (id_orden, fec_orden, id_area) VALUES
(100011, '2024-01-25 08:30:00', 3),
(100012, '2024-01-26 10:00:00', 5),
(100013, '2024-01-27 11:15:00', 2),
(100014, '2024-01-28 14:30:00', 8),
(100015, '2024-01-29 09:45:00', 1),
(100016, '2024-01-30 16:20:00', 4),
(100017, '2024-01-31 12:00:00', 7),
(100018, '2024-02-01 08:15:00', 9),
(100019, '2024-02-02 10:45:00', 6),
(100020, '2024-02-03 15:10:00', 10),
(100021, '2024-02-04 09:30:00', 3),
(100022, '2024-02-05 11:00:00', 2),
(100023, '2024-02-06 14:15:00', 5),
(100024, '2024-02-07 16:45:00', 1),
(100025, '2024-02-08 08:00:00', 8),
(100026, '2024-02-09 10:20:00', 4),
(100027, '2024-02-10 13:30:00', 7),
(100028, '2024-02-11 15:00:00', 9),
(100029, '2024-02-12 09:15:00', 6),
(100030, '2024-02-13 11:45:00', 10);


-- 9. TABLA: tab_det_orden (10 líneas de detalle asociadas a las órdenes)

INSERT INTO tab_det_orden (id_orden, id_prod, val_cant) VALUES
(100001, 1, 2),
(100001, 2, 10),
(100002, 3, 5),
(100003, 4, 3),
(100004, 5, 2),
(100005, 6, 4),
(100006, 7, 6),
(100007, 8, 8),
(100008, 9, 12),
(100009, 10, 4);


-- 10. TABLA: tab_enc_compra (10 facturas de compra)

INSERT INTO tab_enc_compra (id_factura, fec_factura, id_prov, id_ciud_entrega, val_observa) VALUES
(200001, '2024-01-25', 1000000001, '08001', 'Compra de equipos de cómputo'),
(200002, '2024-01-26', 1000000001, '08001', 'Periféricos para área comercial'),
(200003, '2024-01-27', 1000000002, '02001', 'Suministro de teclados mecánicos'),
(200004, '2024-01-28', 1000000002, '02001', 'Monitores de alta definición'),
(200005, '2024-01-29', 1000000003, '09001', 'Impresoras de oficina'),
(200006, '2024-01-30', 1000000003, '09001', 'Tablets para ejecutivos'),
(200007, '2024-02-01', 1000000004, '04001', 'Unidades de almacenamiento SSD'),
(200008, '2024-02-02', 1000000004, '04001', 'Mobiliario y sillas ergonómicas'),
(200009, '2024-02-03', 1000000005, '08001', 'Auriculares de diadema'),
(200010, '2024-02-04', 1000000005, '08001', 'Cámaras web para videoconferencia');


-- 11. TABLA: tab_det_compra (10 detalles de facturas)


INSERT INTO tab_det_compra (id_factura, id_prod, val_cant, val_unit, val_descu, porc_iva) VALUES
(200001, 1, 2, 2500000, 250000, 19),
(200002, 2, 10, 85000, 42500, 19),
(200003, 3, 5, 120000, 30000, 19),
(200004, 4, 3, 800000, 120000, 19),
(200005, 5, 2, 650000, 50000, 19),
(200006, 6, 4, 1100000, 200000, 19),
(200007, 7, 6, 350000, 100000, 19),
(200008, 8, 8, 450000, 180000, 19),
(200009, 9, 12, 150000, 90000, 19),
(200010, 10, 4, 200000, 40000, 19);


-- 12. TABLA: tab_pagos (10 abonos o cuotas de pago a las facturas)

INSERT INTO tab_pagos (id_factura, id_pago, fec_pago, val_pago) VALUES
(200001, 1, '2024-02-10', 2000000),
(200001, 2, '2024-02-20', 2000000),
(200002, 1, '2024-02-12', 500000),
(200003, 1, '2024-02-15', 600000),
(200004, 1, '2024-02-18', 1500000),
(200005, 1, '2024-02-22', 1000000),
(200006, 1, '2024-02-25', 2500000),
(200007, 1, '2024-02-28', 1200000),
(200008, 1, '2024-03-02', 2000000),
(200009, 1, '2024-03-05', 1000000);

COMMIT;
--seleccionar todos los campos y registros de la tabla de proveedores (tab_prov).
select *
from tab_prov;

--Obtenga todos los productos (tab_prod) cuyo estado (ind_estado) se encuentre activo (true).

SELECT ind_estado, nom_prod
FROM tab_prod
WHERE ind_estado = TRUE;

--Liste los proveedores de la tabla tab_prov ordenados alfabéticamente de forma ascendente por su primer nombre.
SELECT * 
FROM tab_prov
ORDER BY nom_prov ASC;

--Muestre únicamente los primeros 10 registros de la tabla de ciudades (tab_ciud), proyectando su ID y nombre.

SELECT id_ciud, nom_ciud
FROM tab_ciud
LIMIT 10;
--Obtenga el número total de órdenes de compra (tab_orden_compra) registradas en el sistema.

SELECT COUNT(*) AS total_ordenes
FROM tab_orden_compra;


--Calcule el monto total acumulado del valor neto (val_neto) facturado en la tabla de detalle de compra (tab_det_compra).

SELECT SUM(val_neto) AS total_acumulado_neto
FROM tab_det_compra;


--Determine el valor promedio del cupo de crédito (val_cupocre) otorgado a los proveedores en tab_prov.

SELECT AVG(val_cupocre) AS promedio_cupo_credito
FROM tab_prov;

--Muestre la cantidad total de ciudades registradas por cada departamento en la tabla tab_ciud.
SELECT d.nom_dpto, COUNT(c.id_ciud) AS total_ciudades
FROM tab_dptos d
LEFT JOIN tab_ciud c ON c.id_dpto = d.id_dpto
GROUP BY d.nom_dpto
ORDER BY total_ciudades DESC;

--Escriba la sentencia para insertar una nueva área en tab_areas con ID 9, nombre 'Auditoría' y encargada 'Elena Beltrán'.
INSERT INTO tab_areas (id_area, nom_area, nom_encarg) 
VALUES (12, 'Auditoría', 'Elena Beltrán');

--Actualice la cantidad de puntos (val_puntos) a 98 para el proveedor con ID 1000000001 en tab_prov.

UPDATE tab_prov
SET val_puntos = 98
WHERE id_prov = 1000000001;

--Elimine el registro de la orden de compra en tab_orden_compra cuyo id_orden sea 100030.

DELETE FROM tab_orden_compra 
WHERE id_orden = 100010;

--Realice una consulta que combine tab_ciud y tab_dptos para mostrar el nombre de la ciudad y el nombre de su respectivo departamento


SELECT 
    c.nom_ciud AS nom_ciud, 
    d.nom_dpto AS nom_dpto
	
FROM tab_ciud c
INNER JOIN tab_dptos d ON c.id_dpto = d.id_dpto;



--Seleccione todos los productos de tab_prod cuyos IDs estén presentes en tab_prod_prov con un valor del producto (val_prod) superior a 2,000,000

SELECT * 
FROM tab_prod 
WHERE id_prod IN (
    SELECT id_prod 
    FROM tab_prod_prov 
    WHERE val_prod > 2000000);

 --Clasifique a los proveedores según su cupo de crédito: 'Cupo Alto' (>= 5,000,000), 'Cupo Medio' (3,000,000 a 4,999,999) y 'Cupo Bajo' (< 3,000,000)


 SELECT 
    id_prov, 
    nom_prov, 
    ape1_prov, 
    val_cupocre,
    CASE 
        WHEN val_cupocre >= 5000000 THEN 'Cupo Alto'
        WHEN val_cupocre BETWEEN 3000000 AND 4999999 THEN 'Cupo Medio'
        ELSE 'Cupo Bajo'
    END AS clasificacion_cupo
FROM tab_prov;

--Combine en un único listado sin duplicados los IDs de los productos pedidos en órdenes de compra y los facturados en detalles de compra

SELECT
id_orden FROM tab_orden_compra
UNION
SELECT id_prod FROM tab_det_compra;

 --Combine en una lista (incluyendo duplicados) los códigos de ciudad asociados a proveedores y los vinculados a encabezados de compra

SELECT
id_ciud FROM tab_prov
UNION ALL
SELECT 
id_ciud_entrega FROM tab_enc_compra;


--Muestre los IDs de las facturas en tab_det_compra que tengan asociadas más de 1 línea de detalle/producto.

SELECT id_factura
FROM tab_det_compra
GROUP BY id_factura
HAVING COUNT(*) > 1;


 --Seleccione los proveedores en tab_prov que tengan al menos una factura registrada en tab_enc_compra

 SELECT * 
FROM tab_prov p
WHERE EXISTS (
    SELECT 1 
    FROM tab_enc_compra e 
    WHERE e.id_prov = p.id_prov
);

 --Liste los proveedores cuyo correo electrónico (campo compuesto datos_prov) contenga la 	subcadena 'tecnosum'

SELECT *
FROM tab_prov
WHERE email_prov ILIKE '%tecnosum%';

--Consulte los encabezados de compra (tab_enc_compra) con fecha de factura entre el 1 de febrero de 2024 y el 29 de febrero de 2024

SELECT *
FROM tab_enc_compra
WHERE fec_factura BETWEEN '2024-02-01' AND '2024-02-29';