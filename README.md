# Obstacle Avoidance Using A Genetic Algorithm (Requires CoppeliaSim for the simulations)
Robots that learn how to avoid obstacles using a genetic algorithm.
There are 12 robots in total, spread over 3 obstacle courses. At the beginning of the simulation each robot gets a genome generated at random, the values of which drive the robot wheels. In each generation the robots calculate how many times they've colided with an obstacle and compare that with the distance the robot has travelled using the formula<sup>1</sup>:

![equation](https://latex.codecogs.com/png.latex?f%20%3D%20%5Cfrac%7Bdistance%7D%7B1%20&plus;%20collisions*penalty%7D)

The displacement/distance value is taken every 0.2 distance units. The best few robots' genomes are kept for the next generation but the rest of them are paired and modified<sup>2</sup> (crossover, mutation). Each generation/epoch lasts for 10 minutes.

The 'Script' folder contains<sup>3</sup>:
  1. The main script which is responsible for starting and ending each epoch, calculating the fitness of every robot and generating the new genomes
  2. The robot script which each robot possesses, counts collisions, distance and moves the robot using the gene values
  3. The robot script for testing the best performing genome

This algorithm was developed as an assigment during an undergrad Robotics course.

<hr>

<sup>1</sup> The formula is derived in part from https://doi.org/10.1016/j.procs.2016.05.404

<sup>2</sup> The position at which the two genomes are seamed is chosen at random, its gene values are chosen using a formula from  https://laboratoriomatematicas.uniandes.edu.co/metodos/contenido/contenido/s5a.pdf. 20% of the population of genomes are point mutated (only a single value -for both wheels- in the genome is mutated)

<sup>3</sup> The Script folder is put here for convienience only, the actual scripts are in the CoppeliaSim files
