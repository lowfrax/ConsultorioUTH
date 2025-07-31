# UTH Consultorio Jurídico

Sistema de gestión de casos jurídicos desarrollado en Flutter con Firebase.

## Funcionalidades Implementadas

### 🔐 Sistema de Autenticación
- Login funcional con Firebase Auth
- Verificación de usuarios existentes
- Manejo de sesiones

### 📋 Gestión de Casos - Formulario de 3 Pasos
1. **Adjuntar archivos**: Selección de PDFs e imágenes desde almacenamiento o cámara
2. **Crear expediente**: Asignar nombre al expediente y subir archivos a Firebase Storage
3. **Información del caso**: Completar datos del caso con dropdowns conectados a Firebase

### 📁 Gestión de Expedientes
- Visualización de expedientes como carpetas
- Lista de archivos por expediente
- Vista previa de archivos (PDFs e imágenes)

### 📊 Dashboard Mejorado
- **Estadísticas en tiempo real** desde Firebase
- **Lista de casos** con búsqueda por nombre, tipo o procurador
- **Cambio de estado** con persistencia en Firebase
- **Contadores reales** en lugar de datos de prueba
- **Botón para crear datos de prueba** en la base de datos

### 🔧 Estructura de Base de Datos Completa
- **8 colecciones Firebase** implementadas
- **Modelos actualizados** para compatibilidad con Firebase
- **Relaciones entre entidades** funcionando
- **Servicios centralizados** para todas las operaciones

### 🚀 Características Técnicas Avanzadas
- **Subida de archivos** a Firebase Storage
- **Relaciones entre entidades** en Firestore
- **Estadísticas en tiempo real**
- **Búsqueda y filtrado**
- **Cambio de estados** con persistencia
- **Validación de formularios** completa

## 📱 Interfaz de Usuario Moderna
- **Stepper** para formulario de casos
- **ExpansionTile** para expedientes
- **Cards** para casos con estados visuales
- **Dropdowns** conectados a Firebase
- **Búsqueda** en tiempo real
- **Indicadores de carga**

## 🔄 Flujo de Trabajo Completo
1. **Login** → Autenticación con Firebase
2. **Dashboard** → Vista de estadísticas y casos
3. **Nuevo Caso** → Formulario de 3 pasos
4. **Gestión** → Cambio de estados y búsqueda
5. **Expedientes** → Visualización de archivos

## 🛠️ Configuración Lista
- Todas las dependencias actualizadas
- Firebase configurado correctamente
- Modelos compatibles con Firestore
- Servicios centralizados implementados

## 📋 Estructura de Base de Datos

### Colecciones Firebase:
- **Casos**: Información completa de casos jurídicos
- **Expedientes**: Expedientes asociados a casos
- **ArchivoExpediente**: Archivos subidos al Storage
- **TipoCaso**: Tipos de casos (Civil, Penal, Laboral, etc.)
- **Juzgados**: Información de juzgados
- **Legitarios**: Demandantes y demandados
- **Rol_Legitario**: Roles de legitarios
- **Procuradores**: Procuradores del sistema

### Modelos de Datos:
- `Caso`: Caso jurídico con relaciones a expediente, procurador, juzgado, etc.
- `Expediente`: Expediente con archivos asociados
- `ArchivoExpediente`: Archivo subido al Storage con metadatos
- `TipoCaso`: Tipos de casos disponibles
- `Juzgado`: Información de juzgados
- `Legitario`: Demandantes y demandados
- `RolLegitario`: Roles de legitarios
- `Procurador`: Procuradores del sistema

## 🚀 Características Técnicas

### Servicios Firebase:
- **CasoService**: Manejo completo de casos, expedientes y archivos
- **FirebaseService**: Verificación de conexiones y pruebas
- **AuthService**: Autenticación de usuarios

### Funcionalidades Avanzadas:
- **Subida de archivos** a Firebase Storage
- **Relaciones entre entidades** en Firestore
- **Estadísticas en tiempo real**
- **Búsqueda y filtrado**
- **Cambio de estados** con persistencia
- **Validación de formularios**

### 📱 Interfaz de Usuario

#### Pantallas Principales:
1. **LoginScreen**: Autenticación de usuarios
2. **DashboardScreen**: Vista principal con estadísticas y lista de casos
3. **CaseFormScreen**: Formulario de 3 pasos para crear casos
4. **ExpedientesScreen**: Gestión de expedientes y archivos
5. **TestFirebaseScreen**: Pruebas de conexión y datos de prueba

#### Características UI:
- **Stepper** para formulario de casos
- **ExpansionTile** para expedientes
- **Cards** para casos con estados visuales
- **Dropdowns** conectados a Firebase
- **Búsqueda** en tiempo real
- **Indicadores de carga**

### 🔄 Flujo de Trabajo

1. **Login** → Autenticación con Firebase
2. **Dashboard** → Vista de estadísticas y casos
3. **Nuevo Caso** → Formulario de 3 pasos:
   - Adjuntar archivos
   - Crear expediente
   - Completar información del caso
4. **Gestión** → Cambio de estados y búsqueda
5. **Expedientes** → Visualización de archivos

### 🛠️ Configuración

#### Dependencias:
```yaml
firebase_core: ^2.24.2
cloud_firestore: ^4.13.6
firebase_auth: ^4.15.3
firebase_storage: ^11.5.6
file_picker: ^6.1.1
image_picker: ^1.0.4
camera: ^0.10.5+5
```

#### Configuración Firebase:
- Firebase Core inicializado
- Firestore configurado
- Storage configurado
- Auth configurado

### 📝 Notas de Desarrollo

- **Modelos actualizados** para compatibilidad con Firebase
- **Servicios centralizados** para operaciones de base de datos
- **Manejo de errores** robusto
- **Validación de formularios** completa
- **Interfaz responsiva** y moderna

### 🎯 Próximas Mejoras

- [ ] Visualización de PDFs en la app
- [ ] Notificaciones push
- [ ] Reportes y estadísticas avanzadas
- [ ] Exportación de datos
- [ ] Backup automático
- [ ] Roles y permisos avanzados

---

**Desarrollado para UTH Consultorio Jurídico**
