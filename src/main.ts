import Phaser from 'phaser';
import { BootScene } from './scenes/BootScene';
import './style.css';

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.CANVAS,
  parent: 'app',
  width: 1280,
  height: 720,
  backgroundColor: '#10151f',
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  physics: {
    default: 'matter',
    matter: {
      gravity: { x: 0, y: 1.65 },
      debug: false,
    },
  },
  scene: [BootScene],
};

new Phaser.Game(config);
