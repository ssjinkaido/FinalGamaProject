# Butterfly color evolution
### Student Name: Nguyen Xuan Tung
### Student ID: M22.ICT.006

### Base Model
- The butterflies are moving based on their active time.
- The reproduction is working and smooth.
- The predators hunt the prey at night.

### Extension 1
- The predators are now targeting the most color-dominant butterflies within a diameter of 2. 
- If it meets other butterflies on its way, it still eats that butterfly.

### Extension 2
- Add horizontal (left-to-right) color transition.

### Extension 3
- Add predation pressures, which is a mix of dominant hunting and random hunting.
- Add different types of color transitions.
- Optimize the butterfly population with the Tabu search algorithm.

### Results
| Simulation| White butterfly Population | Black butterfly Population | Gray butterfly Population |
|----------|----------|----------|----------|
| Base model  | 196      | 197.5    | 204.6875 |
| Extension 1 | 222.125  | 187.562  | 233.5625 |
| Extension 2 | 147.0625 | 149.5625 | 164.6875 |
| Extension 3 | 148.1875 | 151.625  | 145.125  |
