## NightConfig — ресурс с параметрами ночной смены
## Все значения настраиваются без изменения кода
class_name NightConfig
extends Resource

@export_group("Time")
@export var start_hour: int = 1
@export var end_hour: int = 6
@export var seconds_per_hour: float = 90.0  # 90 сек = 1 игровой час

@export_group("Power")
@export var max_power: float = 100.0
@export var base_drain_rate: float = 0.08  # в секунду (постоянный расход)
@export var door_drain_rate: float = 0.15  # за каждую закрытую дверь
@export var light_drain_rate: float = 0.12  # за каждый включённый свет
@export var tablet_drain_rate: float = 0.05  # планшет поднят

@export_group("Doors")
@export var door_close_time: float = 0.4  # секунды анимации закрытия
@export var door_open_time: float = 0.3

@export_group("Tablet")
@export var tablet_open_time: float = 0.5
@export var tablet_close_time: float = 0.4

@export_group("Animatronics")
@export var check_interval_base: float = 5.0  # базовый интервал проверки движения
@export var move_probability_base: float = 0.3  # базовая вероятность шага
@export var attack_delay: float = 3.0  # задержка атаки у открытой двери
@export var retreat_delay: float = 8.0  # время отступления от закрытой двери

@export_group("Camera")
@export var camera_switch_time: float = 0.3
@export var static_noise_intensity: float = 0.5
