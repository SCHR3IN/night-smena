#!/usr/bin/env python3
"""Generate MIDI sound files for Night Shift (Ночная смена) game.
Creates .mid files for all game sounds: ambience, SFX, and music.
These can then be converted to .ogg/.wav via fluidsynth or similar."""

from midiutil import MIDIFile
import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "assets", "audio")


def ensure_dirs():
    for sub in ["music", "sfx", "ambient"]:
        os.makedirs(os.path.join(OUTPUT_DIR, sub), exist_ok=True)


def create_tension_music():
    """Тревожная фоновая музыка — минорные тона, низкие ноты"""
    midi = MIDIFile(2)

    # Track 0: Deep bass drone
    midi.addTempo(0, 0, 60)
    midi.addProgramChange(0, 0, 0, 89)  # Pad 2 (warm)
    for i in range(32):
        note = [36, 34, 31, 33][i % 4]  # C2, Bb1, G1, A1
        midi.addNote(0, 0, note, i * 4, 4, 40)

    # Track 1: Sparse high eerie notes
    midi.addTempo(1, 0, 60)
    midi.addProgramChange(1, 1, 0, 91)  # Pad 4 (choir)
    eerie_notes = [72, 75, 70, 67, 74, 71, 68, 73]
    for i, note in enumerate(eerie_notes):
        midi.addNote(1, 1, note, i * 16, 8, 25)

    path = os.path.join(OUTPUT_DIR, "music", "tension_loop.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")


def create_ambient_hum():
    """Гудение ламп и вентиляции"""
    midi = MIDIFile(1)
    midi.addTempo(0, 0, 60)
    midi.addProgramChange(0, 0, 0, 92)  # Pad 5 (bowed)
    # Continuous low drone
    for i in range(16):
        midi.addNote(0, 0, 24, i * 8, 8, 20)  # Very low C
        midi.addNote(0, 0, 31, i * 8, 8, 15)  # G

    path = os.path.join(OUTPUT_DIR, "ambient", "hum_loop.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")


def create_door_sounds():
    """Звуки открытия/закрытия двери"""
    # Door close: heavy mechanical sound
    midi = MIDIFile(1)
    midi.addTempo(0, 0, 120)
    midi.addProgramChange(0, 0, 0, 119)  # Reverse cymbal
    midi.addNote(0, 0, 36, 0, 0.5, 100)
    midi.addNote(0, 0, 24, 0.2, 0.3, 120)
    midi.addNote(0, 0, 28, 0.4, 0.2, 90)

    path = os.path.join(OUTPUT_DIR, "sfx", "door_close.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")

    # Door open
    midi = MIDIFile(1)
    midi.addTempo(0, 0, 120)
    midi.addProgramChange(0, 0, 0, 119)
    midi.addNote(0, 0, 28, 0, 0.3, 80)
    midi.addNote(0, 0, 36, 0.2, 0.5, 70)

    path = os.path.join(OUTPUT_DIR, "sfx", "door_open.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")


def create_light_sounds():
    """Звуки включения/выключения света"""
    midi = MIDIFile(1)
    midi.addTempo(0, 0, 120)
    midi.addProgramChange(0, 0, 0, 115)  # Woodblock
    midi.addNote(0, 0, 76, 0, 0.1, 100)

    path = os.path.join(OUTPUT_DIR, "sfx", "light_click.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")


def create_tablet_sounds():
    """Звуки планшета"""
    # Tablet up
    midi = MIDIFile(1)
    midi.addTempo(0, 0, 120)
    midi.addProgramChange(0, 0, 0, 98)  # FX 3 (crystal)
    midi.addNote(0, 0, 60, 0, 0.3, 60)
    midi.addNote(0, 0, 64, 0.1, 0.3, 50)
    midi.addNote(0, 0, 67, 0.2, 0.3, 40)

    path = os.path.join(OUTPUT_DIR, "sfx", "tablet_up.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")

    # Tablet down
    midi = MIDIFile(1)
    midi.addTempo(0, 0, 120)
    midi.addProgramChange(0, 0, 0, 98)
    midi.addNote(0, 0, 67, 0, 0.3, 40)
    midi.addNote(0, 0, 64, 0.1, 0.3, 50)
    midi.addNote(0, 0, 60, 0.2, 0.3, 60)

    path = os.path.join(OUTPUT_DIR, "sfx", "tablet_down.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")


def create_camera_switch():
    """Звук переключения камеры"""
    midi = MIDIFile(1)
    midi.addTempo(0, 0, 120)
    midi.addProgramChange(0, 0, 0, 121)  # Guitar fret noise
    midi.addNote(0, 0, 48, 0, 0.15, 80)
    midi.addNote(0, 0, 60, 0.05, 0.1, 60)

    path = os.path.join(OUTPUT_DIR, "sfx", "camera_switch.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")


def create_footsteps():
    """Шаги аниматроника"""
    for i in range(3):
        midi = MIDIFile(1)
        midi.addTempo(0, 0, 120)
        midi.addProgramChange(0, 0, 0, 117)  # Taiko drum
        note = 36 + i * 2
        midi.addNote(0, 0, note, 0, 0.2, 70 + i * 10)

        path = os.path.join(OUTPUT_DIR, "sfx", f"footstep_{i+1}.mid")
        with open(path, "wb") as f:
            midi.writeFile(f)
        print(f"  Created: {path}")


def create_screamer():
    """Скример — резкий пугающий звук"""
    midi = MIDIFile(2)
    midi.addTempo(0, 0, 180)

    # Track 0: Harsh stab
    midi.addProgramChange(0, 0, 0, 30)  # Distortion guitar
    for i in range(8):
        midi.addNote(0, 0, 36 + i * 3, i * 0.1, 0.5, 127)

    # Track 1: High screech
    midi.addProgramChange(1, 1, 0, 70)  # Bassoon (for low menace)
    midi.addNote(1, 1, 84, 0, 1.0, 127)
    midi.addNote(1, 1, 90, 0.2, 0.8, 120)

    path = os.path.join(OUTPUT_DIR, "sfx", "screamer.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")


def create_victory_chime():
    """Музыкальный сигнал победы — 6:00"""
    midi = MIDIFile(1)
    midi.addTempo(0, 0, 100)
    midi.addProgramChange(0, 0, 0, 14)  # Tubular bells
    chime_notes = [72, 76, 79, 84]  # C5, E5, G5, C6
    for i, note in enumerate(chime_notes):
        midi.addNote(0, 0, note, i * 0.5, 1.5, 80)

    path = os.path.join(OUTPUT_DIR, "sfx", "victory_chime.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")


def create_power_down():
    """Звук отключения энергии"""
    midi = MIDIFile(1)
    midi.addTempo(0, 0, 60)
    midi.addProgramChange(0, 0, 0, 89)  # Pad 2
    # Descending notes representing power dying
    for i in range(6):
        note = 60 - i * 5
        vol = 80 - i * 12
        midi.addNote(0, 0, note, i * 0.8, 1.0, max(vol, 10))

    path = os.path.join(OUTPUT_DIR, "sfx", "power_down.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")


def create_breathing():
    """Дыхание аниматроника у двери"""
    midi = MIDIFile(1)
    midi.addTempo(0, 0, 40)
    midi.addProgramChange(0, 0, 0, 76)  # Bottle blow
    for i in range(8):
        midi.addNote(0, 0, 48, i * 2, 1.0, 30 + (i % 2) * 15)
        midi.addNote(0, 0, 50, i * 2 + 1, 0.8, 20 + (i % 2) * 10)

    path = os.path.join(OUTPUT_DIR, "sfx", "breathing.mid")
    with open(path, "wb") as f:
        midi.writeFile(f)
    print(f"  Created: {path}")


def create_metal_creak():
    """Случайные металлические скрипы"""
    for i in range(3):
        midi = MIDIFile(1)
        midi.addTempo(0, 0, 60)
        midi.addProgramChange(0, 0, 0, 120)  # Guitar fret noise
        midi.addNote(0, 0, 50 + i * 7, 0, 0.5, 40)

        path = os.path.join(OUTPUT_DIR, "ambient", f"metal_creak_{i+1}.mid")
        with open(path, "wb") as f:
            midi.writeFile(f)
        print(f"  Created: {path}")


if __name__ == "__main__":
    print("Generating MIDI sounds for Night Shift...")
    ensure_dirs()
    create_tension_music()
    create_ambient_hum()
    create_door_sounds()
    create_light_sounds()
    create_tablet_sounds()
    create_camera_switch()
    create_footsteps()
    create_screamer()
    create_victory_chime()
    create_power_down()
    create_breathing()
    create_metal_creak()
    print("\nDone! Generated all MIDI sounds.")
    print("To convert to OGG: fluidsynth -ni soundfont.sf2 input.mid -F output.wav && ffmpeg -i output.wav output.ogg")
