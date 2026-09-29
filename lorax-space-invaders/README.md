# Lorax: Deforestationders

A Space Invaders-style arcade shooter built with Godot 4 and GDScript, themed around *The Lorax*: defend the last trees from waves of invaders.

Developed as a course project for the Computer Science program at Universidade de Fortaleza (Unifor). It started from a base project provided in class and was expanded with original gameplay systems, pixel art and sound.

## Features

- 4x8 alien formation that sweeps side to side and descends over time
- Wave system with progressive difficulty
- Armored aliens (2 hits) and corner snipers in later waves
- Boss fight against the Lorax, who throws explosive trees
- Chainsaw power-up with area damage, plus heart pickups that restore lives
- Destructible shields, floating score popups, screen shake and hit-stop
- Intro video, animated title screen, pause menu and game over screen

## Controls

| Action | Keys |
|---|---|
| Move | `A` / `D` or `←` / `→` |
| Shoot | `Space` |
| Pause | `Esc` / `P` |
| Start / confirm | `Enter` |
| Skip intro | `Space` / `Enter` |

## Running the project

1. Install [Godot 4.7](https://godotengine.org/download) (standard version, not .NET).
2. Clone the repository:
   ```bash
   git clone https://github.com/histuan/projects.git
   ```
3. In the Godot Project Manager, click **Import** and select `lorax-space-invaders/project.godot`.
4. Press **F5** to play.

On first launch Godot re-imports all assets, which may take a moment.

## Project structure

Folder names are in Portuguese.

```
lorax-space-invaders/
├── cenas/                   # scenes (alien, player, geral)
├── scripts/                 # GDScript files, mirroring cenas/
├── recursos/                # custom resources (power-up data)
├── meus sprites/            # pixel art
├── lorax/                   # boss art, title screen and intro video
├── efeitos sonoros reais/   # music and sound effects
├── fonts/                   # pixel fonts
└── project.godot
```

## Credits

- Code, pixel art and most sound effects: Thiago Uchoa Gomes
- Base project: provided by the course instructor

*The Lorax* is a creation of Dr. Seuss. This is a non-commercial student project with no affiliation with the rights holders.
