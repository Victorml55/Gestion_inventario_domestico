<div align="center">

# Mi Alacena

### Inventario doméstico y control de caducidades

Aplicación móvil para organizar los productos de casa, cuidar las fechas de vencimiento
y llevar un mejor control de las compras.

<br>

![Flutter](https://img.shields.io/badge/Flutter-framework-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-lenguaje-0175C2?logo=dart&logoColor=white)
![Estado](https://img.shields.io/badge/Estado-Practica%202-00897B?logo=github)

**Practica 2: Práctica de Base de Datos LOCAL**

</div>

---

## Acerca del proyecto

**Mi Alacena** es una aplicación desarrollada con Flutter para administrar un inventario doméstico desde el celular. Permite registrar productos y sus lotes, consultar existencias, anticipar caducidades y organizar las compras.

El proyecto aplica conceptos de desarrollo móvil y persistencia de datos. **La versión actual almacena la información localmente con SQLite; todavía no incluye un servicio en la nube ni sincronización entre dispositivos.**

## Funcionalidades

- **Inventario:** administra productos, categorías, unidades, existencias mínimas e imágenes.
- **Control por lotes:** registra cantidades y fechas de caducidad; también admite productos no perecederos.
- **Consumo FEFO:** descuenta primero los lotes que caducan antes (*First Expired, First Out*).
- **Alertas de caducidad:** consulta productos próximos a caducar o ya caducados desde el inicio y el inventario.
- **Notificaciones locales:** programa avisos para el día de caducidad y permite abrir desde ellos las alertas de esa fecha.
- **Calendario:** visualiza las fechas de caducidad de los productos.
- **Lista de compra:** agrega productos manualmente o sugiere artículos agotados o por agotarse.
- **Registro de compras:** guarda tienda, cantidad, precio y fecha, y agrega la compra como lote al inventario.
- **Historial y estadísticas:** revisa compras anteriores y compara el gasto por tienda.
- **Catálogos configurables:** organiza productos con categorías y tiendas.

## Tecnologías

| Tecnología | Uso |
| --- | --- |
| [Flutter](https://flutter.dev/) | Interfaz y desarrollo multiplataforma |
| [Dart](https://dart.dev/) | Lenguaje de programación |
| SQLite con `sqflite` | Persistencia local de productos, lotes y compras |
| Provider | Estado y acceso a repositorios |
| `flutter_local_notifications` | Notificaciones locales de caducidad |
| `table_calendar` | Calendario de alertas |

## Organización del proyecto

El código de la aplicación está organizado por responsabilidades:

```text
lib/
├── core/           # Utilidades, rutas, fechas y formato
├── data/
│   ├── database/   # Configuración y creación de SQLite
│   ├── models/     # Modelos de datos
│   ├── repositories/  # Acceso a datos y operaciones del dominio
│   └── services/   # Servicios, como las notificaciones
└── ui/
    ├── providers/  # Estado de la interfaz
    ├── screens/    # Pantallas de la aplicación
    └── widgets/    # Componentes reutilizables
```

La interfaz consume repositorios mediante Provider. Estos repositorios trabajan con la base de datos local y con los servicios de la aplicación.

## Cómo ejecutar

### Requisitos

- Flutter instalado y configurado.
- Dart SDK `>=3.0.0 <4.0.0` (incluido con Flutter).
- Un emulador o dispositivo conectado.

### Pasos

```bash
git clone https://github.com/Victorml55/Gestion_inventario_domestico.git
cd Gestion_inventario_domestico
flutter pub get
flutter run
```

Para verificar el código y ejecutar las pruebas disponibles:

```bash
flutter analyze
flutter test
```

> La base de datos `alacena.db` se crea en el almacenamiento de la aplicación al iniciarla por primera vez. El proyecto utiliza plugins nativos; las notificaciones y otras integraciones pueden requerir configuración adicional según la plataforma y el dispositivo.

---

<div align="center">

Hecho con Flutter

</div>
