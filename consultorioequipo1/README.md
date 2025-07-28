# UTH Consultorio Jurídico

Aplicación Flutter para la gestión de casos jurídicos del consultorio UTH.

## 🚀 Características Principales

### ✅ Sistema de Autenticación
- **Pantalla de Login** con diseño moderno y gradiente
- **Credenciales de prueba**: Usuario: `1`, Contraseña: `1`
- **Validación de formularios** con mensajes de error
- **Indicador de carga** durante el proceso de login
- **Navegación segura** entre pantallas

### ✅ Dashboard Mejorado
- **Estadísticas visuales** de casos por estado
- **Búsqueda en tiempo real** de casos
- **Gestión de estados** con tap largo
- **Navegación entre secciones** (Dashboard y Expedientes)
- **Botón de logout** con confirmación

### ✅ Verificación de Conexión Firebase
- **Verificación rápida** con diálogos emergentes
- **Prueba exhaustiva** con análisis detallado
- **Detección de problemas** de conectividad
- **Timeouts configurables** para detección rápida
- **Mensajes específicos** por tipo de error

### ✅ Navegación Mejorada
- **Barra de navegación** entre Dashboard y Expedientes
- **Indicador visual** de la sección activa
- **Transiciones suaves** entre pantallas
- **Diseño consistente** en toda la aplicación

## 📱 Pantallas Disponibles

### 1. Login Screen (`login_screen.dart`)
- **Diseño moderno** con gradiente verde
- **Validación de campos** obligatorios
- **Credenciales de prueba** visibles
- **Indicador de carga** durante login
- **Mensajes de error** para credenciales incorrectas

### 2. Dashboard Screen (`dashboard_screen.dart`)
- **Estadísticas de casos** por estado
- **Búsqueda de casos** en tiempo real
- **Gestión de estados** con tap largo
- **Botones de verificación** Firebase
- **Navegación a Expedientes**

### 3. Expedientes Screen (`expedientes_screen.dart`)
- **Pantalla placeholder** para futuras funcionalidades
- **Diseño consistente** con el resto de la app
- **Información de desarrollo** visible

## 🔧 Funcionalidades Técnicas

### Sistema de Autenticación
```dart
// Credenciales de prueba
Usuario: 1
Contraseña: 1
```

### Verificación Firebase
- **Verificación rápida**: Botón de nube en AppBar
- **Prueba exhaustiva**: Botón de analytics en AppBar
- **Diálogos emergentes**: Resultados detallados
- **Manejo de errores**: Try-catch mejorado

### Navegación
- **Dashboard**: Pantalla principal con estadísticas
- **Expedientes**: Sección en desarrollo
- **Logout**: Botón con confirmación

## 🎨 Diseño y UX

### Colores Principales
- **Verde**: Color principal (#4CAF50)
- **Blanco**: Fondo principal
- **Gris**: Elementos secundarios

### Componentes
- **Cards**: Para estadísticas y casos
- **Diálogos**: Para confirmaciones y resultados
- **SnackBars**: Para mensajes temporales
- **Gradientes**: En pantalla de login

## 📊 Estructura de Archivos

```
lib/
├── main.dart                          # Punto de entrada con login
├── screens/
│   ├── login_screen.dart              # Pantalla de autenticación
│   ├── dashboard_screen.dart          # Dashboard principal
│   ├── expedientes_screen.dart        # Pantalla de expedientes
│   └── case_form_screen.dart          # Formulario de casos
├── models/
│   └── caso.dart                      # Modelo de datos
└── data/
    └── recursos/
        └── firebase_service.dart      # Servicios de Firebase
```

## 🚀 Cómo Usar

### 1. Iniciar la Aplicación
```bash
flutter run
```

### 2. Login
- Usar credenciales: `1` / `1`
- Los campos son obligatorios
- El botón se deshabilita durante el login

### 3. Dashboard
- **Ver estadísticas** de casos por estado
- **Buscar casos** usando el campo de búsqueda
- **Cambiar estado** de casos con tap largo
- **Verificar conexión** Firebase con los botones del AppBar
- **Navegar a Expedientes** usando la barra de navegación

### 4. Verificación Firebase
- **Verificación Rápida**: Resultado inmediato
- **Prueba Exhaustiva**: Análisis detallado con porcentajes
- **Ver Detalles**: Diálogo con información completa

## 🔧 Configuración

### Dependencias Requeridas
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.15.2
  firebase_auth: ^5.7.0
  cloud_firestore: ^5.6.12
  sqflite: ^2.3.0
  path: ^1.8.3
```

### Configuración Firebase
1. **firebase_options.dart**: Configurado correctamente
2. **Reglas de Firestore**: Permitir lectura en colección 'test'
3. **Conexión a Internet**: Requerida para verificaciones

## 🎯 Características Destacadas

### ✅ UX Mejorada
- **Diálogos emergentes** en lugar de SnackBars para información importante
- **Indicadores de carga** durante operaciones
- **Confirmaciones** para acciones críticas
- **Navegación intuitiva** entre secciones

### ✅ Detección Robusta
- **Verificación de internet** antes de probar Firebase
- **Timeouts configurables** para detección rápida
- **Mensajes específicos** por tipo de error
- **Análisis detallado** con porcentajes de éxito

### ✅ Diseño Consistente
- **Colores uniformes** en toda la aplicación
- **Componentes reutilizables** para estadísticas
- **Tipografía consistente** en todas las pantallas
- **Espaciado uniforme** entre elementos

## 🔄 Flujo de Usuario

1. **Inicio** → Pantalla de login con gradiente
2. **Login** → Validación de credenciales (1/1)
3. **Dashboard** → Estadísticas y gestión de casos
4. **Navegación** → Cambio entre Dashboard y Expedientes
5. **Verificación** → Botones para probar conexión Firebase
6. **Logout** → Confirmación y regreso al login

## 📝 Notas de Desarrollo

### Próximas Funcionalidades
- **Sistema de expedientes** completo
- **Autenticación real** con Firebase Auth
- **Sincronización** de datos con Firestore
- **Notificaciones** push para casos urgentes

### Mejoras Técnicas
- **Estado global** con Provider o Riverpod
- **Caché local** para datos offline
- **Validaciones** más robustas
- **Tests unitarios** y de integración

## 🎉 Resultado Final

La aplicación ahora incluye:
- ✅ **Sistema de login** funcional con credenciales de prueba
- ✅ **Dashboard mejorado** con navegación y estadísticas
- ✅ **Verificación Firebase** con diálogos emergentes
- ✅ **Navegación entre pantallas** con diseño consistente
- ✅ **UX mejorada** con confirmaciones y indicadores de carga
