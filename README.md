# Block Popper

A block puzzle game for iOS built entirely with AI assistance to explore the capabilities of [Claude Code](https://claude.ai/claude-code) and [oh-my-claudecode](https://github.com/anthropics/oh-my-claudecode).

## The Experiment

This project started as an experiment to see how far AI-assisted development could go when recreating a polished mobile game from scratch. The reference was **Block Crush**, a popular block puzzle game. The entire codebase — game logic, rendering, animations, sound synthesis, and an intelligent piece selection engine — was built through a conversational workflow with Claude Code. From the initial SpriteKit scaffold to the final tuning of drag offsets and phase transition flags, every line of code was authored collaboratively between a human game designer and an AI pair programmer. The process revealed that AI excels at rapid iteration cycles: describe a feature, see it on device, tweak it, repeat — all within the same conversation.

## The Goal

My goal with this project was to understand how a seasoned backend developer would do when entering the game developing world. This is the first game I have ever built, and I didn't dive deep into concepts like the sound and musics, and also went very briefly into the animations required for a flagship game like the famous ones. **This was built in about 6h of prompting of Claude Code and oh-my-claudecode.**

## Result

<p align="center">
  <img src="readme_images/final_result.gif" alt="Block Popper gameplay" width="300"/>
</p>

## Features

- **8x8 grid** with drag-and-drop block placement
- **23 piece types** including L-shapes, Z-shapes, pyramids, and large blocks
- **Phase progression** with increasing score targets (100, 120, 140...)
- **Hack system** — earn hacks every 100 points to Flush (swap pieces) or Erase (remove a cell)
- **Intelligent piece engine** that analyzes board state, favors fitting pieces, and scales difficulty
- **Hard phases** every 10 levels with reduced help from the engine
- **Animated line clears** with white sweep + firework particles
- **Phase completion flag** with victory fanfare, stars, and fireworks
- **Synthesized sound effects** — no audio assets needed
- **Bamboo-themed UI** with raised/recessed button states
