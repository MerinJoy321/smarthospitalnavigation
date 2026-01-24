
## Phase E: Realistic Camera Turns (Street View Style)
To simulate a camera turning (like Google Street View), we need to:
1.  **Stop forward movement** when a turn instruction is active.
2.  **Animate the "Center of Perspective"**: Instead of just rotating walls, we shift the vanishing point horizontally.
    - Turning **LEFT**: Vanishing point moves **RIGHT** (off-screen).
    - Turning **RIGHT**: Vanishing point moves **LEFT**.
    - New corridor "slides" in from the side.
3.  **Update `NavigationVisualizer`**: Use `turnProgress` (0.0 to 1.0) to interpolate the vanishing point X-coordinate.

### Visual Logic
- **Straight**: Vanishing Point X = `size.width / 2`
- **Turn Left (Progress 0->1)**: Vanishing Point X moves from Center -> `size.width * 1.5`
- **Turn Right (Progress 0->1)**: Vanishing Point X moves from Center -> `-size.width * 0.5`
