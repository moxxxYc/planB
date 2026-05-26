import Phaser from 'phaser';
import { svgAssets } from '../rendering/assets';
import { PrototypeScene } from './PrototypeScene';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('BootScene');
  }

  preload() {
    for (const [key, path, width, height] of svgAssets) {
      this.load.svg(key, path, { width, height });
    }
    this.load.image('generated_asset_sheet', '/assets/generated/reference/generated-asset-sheet.png');
  }

  create() {
    this.scene.add('PrototypeScene', PrototypeScene, true);
  }
}
