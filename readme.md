# Snaily Tracker - System Napadów na Furgonetki

## Opis
Snaily Tracker to zaawansowany system napadów na furgonetki dla FiveM. System oferuje progresję poziomów, umiejętności, system kolejkowania oraz dwa poziomy trudności misji.

## Funkcje
- 🎮 Dwa poziomy trudności (łatwy i trudny)
- 📈 System progresji z 4 poziomami specjalizacji
- 🎯 System umiejętności z możliwością ulepszania:
  - Szybkie palce (skraca czas wykonywania akcji)
  - Informator (zmniejsza obszar poszukiwań)
- ⏱️ System kolejkowania graczy
- 💰 Skalowalne nagrody bazowane na poziomie gracza
- 🔄 System cooldownów między zleceniami

## Wymagania
- ox_lib
- ox_target
- ox_inventory

## Instalacja
1. Skopiuj folder `snaily-tracker` do katalogu `resources`
2. Dodaj `ensure snaily-tracker` do server.cfg
3. Zaimportuj item 'thermite' do ox_inventory
```lua
['thermite'] = {
		label = 'Termit',
		weight = 1000,
		description = 'Ładunek wybuchowy służący do wysadzania drzwi',
		stack = false,
		close = true,
	},
```
4. Wystartuj serwer

## Konfiguracja
Wszystkie ustawienia znajdują się w pliku `config.lua`:
- Lokalizacje furgonetki
- Nagrody i cooldowny
- Parametry strażników
- Wymagania poziomów
- Ceny i bonusy umiejętności

## Użytkowanie
1. Udaj się do NPC oznaczonego na mapie
2. Wybierz poziom trudności misji
3. Zlokalizuj furgonetkę w zaznaczonym obszarze
4. Użyj termitu aby wysadzić drzwi
5. Zbierz pieniądze i uciekaj przed strażnikami

## Licencja
MIT License

## Autor
SnailyDevelopment

## Wsparcie
W razie problemów lub pytań, utwórz issue na GitHubie lub dołącz do naszego Discorda [https://discord.gg/KCykBSAPsY]

# Snaily Tracker - Van Heist System

## Description
Snaily Tracker is an advanced van heist system for FiveM. The system features level progression, skills, queue system, and two difficulty levels for missions.

## Features
- 🎮 Two difficulty levels (easy and hard)
- 📈 Progression system with 4 specialization levels
- 🎯 Skill system with upgrade options:
  - Fast Fingers (reduces action execution time)
  - Informant (reduces search area)
- ⏱️ Player queue system
- 💰 Scalable rewards based on player level
- 🔄 Mission cooldown system

## Dependencies
- ox_lib
- ox_target
- ox_inventory

## Installation
1. Copy the `snaily-tracker` folder to your `resources` directory
2. Add `ensure snaily-tracker` to server.cfg
3. Import 'thermite' item to ox_inventory
```lua
['thermite'] = {
    label = 'Thermite',
    weight = 1000,
    description = 'Explosive charge used for blasting doors',
    stack = false,
    close = true,
},
```
4. Start the server

## Configuration
All settings can be found in `config.lua`:
- Van locations
- Rewards and cooldowns
- Guard parameters
- Level requirements
- Skill prices and bonuses

## Usage
1. Go to the NPC marked on the map
2. Choose mission difficulty
3. Locate the van in the marked area
4. Use thermite to blast the doors
5. Collect the money and escape from the guards

## License
MIT License

## Author
SnailyDevelopment

## Support
For issues or questions, create an issue on GitHub or join our Discord [https://discord.gg/KCykBSAPsY]
