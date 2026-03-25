# Pipeline
Create a modular pipeline for the whole project:
- training data
- input features
- U-Net architecture
- validation - indicators / metrics for baseline

Input data: current-day images degraded to past quality
Training data: current-day habitats
Structure: hierarchical - make U-Net detect level 1 and from there, modularize and containerize further U-Nets
Goal: see what we can do on level 1 and go further from there

Other ideas:
- use photographs overlaid with landscape for more difficult habitats
