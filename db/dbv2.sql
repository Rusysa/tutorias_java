-- Configuración inicial
PRAGMA foreign_keys = ON;


-- 1. USUARIOS Y PERFILES


CREATE TABLE IF NOT EXISTS User (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    correo TEXT UNIQUE NOT NULL, -- UNIQUE se maneja con índice parcial abajo
    pass TEXT NOT NULL,
    role TEXT CHECK(role IN ('Admin', 'Tutorado', 'Tutor')) NOT NULL,
    creado_el TEXT DEFAULT CURRENT_TIMESTAMP,
    eliminado INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Administrador (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    eliminado INTEGER DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Tutor (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    apellido_paterno TEXT NOT NULL,
    apellido_materno TEXT NOT NULL,
    eliminado INTEGER DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Tutorados (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    tutor_id INTEGER, -- El profesor dueño del registro
    matricula TEXT NOT NULL, -- UNIQUE se maneja con índice parcial abajo
    nombre TEXT NOT NULL,
    apellido_paterno TEXT NOT NULL,
    apellido_materno TEXT NOT NULL,
    telefono TEXT, -- Quitamos UNIQUE estricto por si comparten cel (hermanos) o se maneja en lógica
    telefono_emergencia TEXT,
    fecha_inscripcion TEXT, -- Formato YYYY-MM-DD
    afis INTEGER DEFAULT 0,
    promedio_general REAL DEFAULT 0.0,
    eliminado INTEGER DEFAULT 0, -- Soft Delete para borrarlo visualmente de TODA la app
    FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE,
    FOREIGN KEY (tutor_id) REFERENCES Tutor(id) ON DELETE SET NULL
);

-- 2. GESTIÓN DE TIEMPO


CREATE TABLE IF NOT EXISTS Periodo (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ciclo TEXT NOT NULL, -- Ej: "2024-B"
    fecha_inicio TEXT NOT NULL,
    fecha_fin TEXT NOT NULL,
    es_activo INTEGER DEFAULT 0, -- Controlar lógica en Java (solo 1 activo)
    eliminado INTEGER DEFAULT 0
);


-- 3. ACADÉMICO (EL CORAZÓN DEL SISTEMA)


-- Esta tabla define si el alumno es "tuyo" en el periodo actual
CREATE TABLE IF NOT EXISTS Inscripciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tutorado_id INTEGER NOT NULL,
    periodo_id INTEGER NOT NULL,
    semestre INTEGER NOT NULL,
    estado_pago INTEGER DEFAULT 0,
    promedio_semestral REAL DEFAULT 0.0,
    num_justificantes INTEGER DEFAULT 0,
    eliminado INTEGER DEFAULT 0,
    FOREIGN KEY (tutorado_id) REFERENCES Tutorados(id) ON DELETE CASCADE,
    FOREIGN KEY (periodo_id) REFERENCES Periodo(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS Sesiones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    periodo_id INTEGER NOT NULL,
    tutor_id INTEGER NOT NULL,
    tipo_sesion TEXT NOT NULL, -- Ej: 'Individual', 'Grupal'
    fecha TEXT NOT NULL,       -- Formato YYYY-MM-DD HH:MM:SS
    tema TEXT,
    comentarios TEXT,
    eliminado INTEGER DEFAULT 0,
    FOREIGN KEY (periodo_id) REFERENCES Periodo(id),
    FOREIGN KEY (tutor_id) REFERENCES Tutor(id)
);

CREATE TABLE IF NOT EXISTS Asistencias (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sesion_id INTEGER NOT NULL,
    inscripcion_id INTEGER NOT NULL,
    estado TEXT CHECK(estado IN ('Falta', 'Asistio', 'Justificado')),
    eliminado INTEGER DEFAULT 0,
    FOREIGN KEY (sesion_id) REFERENCES Sesiones(id) ON DELETE CASCADE,
    FOREIGN KEY (inscripcion_id) REFERENCES Inscripciones(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Calificaciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    inscripcion_id INTEGER NOT NULL,
    valor REAL NOT NULL,
    tipo TEXT, -- Ej: 'Parcial 1', 'Final'
    eliminado INTEGER DEFAULT 0,
    FOREIGN KEY (inscripcion_id) REFERENCES Inscripciones(id) ON DELETE CASCADE
);

-- 4. DOCUMENTACIÓN Y REPORTES


CREATE TABLE IF NOT EXISTS Documentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tutorado_id INTEGER NOT NULL,
    periodo_id INTEGER, -- Cambiado nombre de ciclo_escolar_id a periodo_id para consistencia
    doc_tipo TEXT,
    ruta TEXT NOT NULL,
    nombre_original TEXT,
    eliminado INTEGER DEFAULT 0,
    FOREIGN KEY (tutorado_id) REFERENCES Tutorados(id) ON DELETE CASCADE,
    FOREIGN KEY (periodo_id) REFERENCES Periodo(id)
);

CREATE TABLE IF NOT EXISTS Reportes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tutor_id INTEGER NOT NULL,
    tutorado_id INTEGER NOT NULL,
    periodo_id INTEGER, -- AGREGADO: Para saber en qué semestre se hizo el reporte
    fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP,
    cuerpo_reporte TEXT,
    eliminado INTEGER DEFAULT 0,
    FOREIGN KEY (tutor_id) REFERENCES Tutor(id),
    FOREIGN KEY (tutorado_id) REFERENCES Tutorados(id),
    FOREIGN KEY (periodo_id) REFERENCES Periodo(id)
);


-- 5. AUDITORÍA


CREATE TABLE IF NOT EXISTS HistorialCambios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tabla_nombre TEXT NOT NULL,
    id_valor_modificado INTEGER NOT NULL,
    accion TEXT CHECK(accion IN ('INSERT', 'UPDATE', 'DELETE')),
    valor_antiguo TEXT,
    nuevo_valor TEXT,
    fecha_cambio TEXT DEFAULT CURRENT_TIMESTAMP
);
