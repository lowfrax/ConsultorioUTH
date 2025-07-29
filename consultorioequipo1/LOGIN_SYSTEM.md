# Sistema de Login - UTH Consultorio Jurídico

## Descripción General

El sistema de login implementado utiliza Firebase Firestore como base de datos y sigue la estructura de colecciones especificada. El sistema verifica las credenciales del usuario y su rol antes de permitir el acceso.

## Estructura de Base de Datos

### Colecciones de Firebase

1. **Cuatrimestres**
   - Campos: `n_cuatrimestre`, `year`, `eliminado`, `creado_el`, `actualizado_el`

2. **Clase**
   - Campos: `codigo_clase`, `nombre_clase`, `eliminado`, `creado_el`, `actualizado_el`

3. **Rol_Procurador**
   - Campos: `rol`, `eliminado`, `creado_el`, `actualizado_el`

4. **Procuradores**
   - Campos: `nombre`, `usuario`, `password`, `email`, `telefono`, `n_cuenta`, `id_clase`, `id_cuatrimestre`, `id_rol`, `eliminado`, `creado_el`, `actualizado_el`

## Proceso de Autenticación

### 1. Verificación de Conexión
- Se verifica la conectividad a internet
- Se valida la conexión a Firebase Firestore
- Se manejan errores de timeout y conectividad

### 2. Validación de Credenciales
- Se busca en la colección `Procuradores` un documento que coincida con:
  - `usuario` = usuario ingresado
  - `password` = contraseña ingresada
  - `eliminado` = false

### 3. Verificación de Estado
- Se verifica que el procurador no esté marcado como eliminado
- Se valida que tenga un rol asignado (`id_rol` no sea null)

### 4. Validación de Rol
- Se obtiene el documento de rol referenciado en `Rol_Procurador`
- Se verifica que el rol no esté eliminado
- Se valida que el rol sea exactamente "alumno"

### 5. Resultado
- Si todas las validaciones pasan: Login exitoso
- Si alguna falla: Se muestra mensaje de error específico

## Archivos Implementados

### Modelos de Datos
- `lib/data/modelos/procurador.dart` - Modelo para Procuradores
- `lib/data/modelos/rol_procurador.dart` - Modelo para Rol_Procurador
- `lib/data/modelos/clase.dart` - Modelo para Clase

### Servicios
- `lib/data/recursos/auth_service.dart` - Servicio de autenticación
- `lib/data/recursos/firebase_service.dart` - Servicio de conexión Firebase

### Pantallas
- `lib/screens/login_screen.dart` - Pantalla de login actualizada

## Credenciales de Prueba

Para probar el sistema, puedes usar las siguientes credenciales que coinciden con los datos en Firebase:

- **Usuario:** `lowfrax`
- **Contraseña:** `casa`

## Flujo de Validación

```
1. Usuario ingresa credenciales
   ↓
2. Verificar conexión a Firebase
   ↓
3. Buscar procurador por usuario y password
   ↓
4. Verificar que no esté eliminado
   ↓
5. Obtener rol referenciado
   ↓
6. Verificar que rol no esté eliminado
   ↓
7. Verificar que rol sea "alumno"
   ↓
8. Login exitoso → Navegar al Dashboard
```

## Manejo de Errores

El sistema maneja los siguientes tipos de errores:

- **Error de conexión:** "Error de conexión. Verifica tu internet."
- **Credenciales incorrectas:** "Usuario o contraseña incorrectos"
- **Cuenta deshabilitada:** "Cuenta deshabilitada"
- **Sin rol asignado:** "Usuario sin rol asignado"
- **Rol no encontrado:** "Rol no encontrado"
- **Rol deshabilitado:** "Rol deshabilitado"
- **Acceso denegado:** "Acceso denegado: Solo alumnos pueden acceder"
- **Error inesperado:** "Error inesperado. Intenta nuevamente."

## Características de Seguridad

- Validación de credenciales en tiempo real
- Verificación de estado de eliminación
- Validación de roles específicos
- Manejo robusto de errores de conexión
- Timeouts para evitar bloqueos
- Logs detallados para debugging

## Configuración

El sistema utiliza la configuración de Firebase definida en:
- `lib/firebase_options.dart`
- `pubspec.yaml` (dependencias de Firebase)

## Dependencias Requeridas

```yaml
firebase_core: ^3.15.2
firebase_auth: ^5.7.0
cloud_firestore: ^5.6.12
``` 