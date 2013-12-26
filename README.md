# voxel-use

Use items and blocks (voxel.js addon)

Requires [voxel-reach](https://github.com/deathcap/voxel-reach), [voxel-registry](https://github.com/deathcap/voxel-registry), [voxel-inventory-hotbar](https://github.com/deathcap/voxel-inventory-hotbar)

## Usage

voxel-use handles "using" items and blocks, by right-clicking (default firealt interact keybinding).
Compare to [voxel-mine](https://github.com/deathcap/voxel-mine) which handles left-clicking to mine. Supported actions:

* Right-click a voxel in the world to "open" it, if possible (calls interaction handler, example: [voxel-workbench](https://github.com/deathcap/voxel-workbench))
 * Hold shift (crouch) to suppress this behavior
* Right-click while holding a block item (in your [voxel-inventory-hotbar](https://github.com/deathcap/voxel-inventory-hotbar)) to place it in the world on the voxel face clicked
* Right-click while holding a (non-block) item to do nothing (yet)

## License

MIT

