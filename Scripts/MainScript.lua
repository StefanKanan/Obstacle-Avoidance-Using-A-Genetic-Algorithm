-- DO NOT WRITE CODE OUTSIDE OF THE if-then-end SECTIONS BELOW!! (unless the code is a function definition)

function printPopulation(population)
    for i=1,#population,1 do
        local chromosome = population[i]
        print(chromosome)
    end
end

function printDetails()
    print('generation: ', generation)
    print('best fitness: ', best_fitness)
    print('best chromosome: ', best_chromosome)
    print('best current fitness: ', best_fitness_current)
    print('best current chromosome: ', best_chromosome_current)
end

function pickRandom()
    local available = {}
    local j = 1
    for key, value in pairs(couples) do --for keys
        if couples[key] == false then
            available[j] = key
            j = j + 1
        end
    end
    
    j = math.random(#available)
    couples[available[j]] = true
    return available[ j ]
end

function randomSample(length, range)
    a = range[1]
    b = range[2]

    local data = {}

    for i=1, length, 1 do
        local j = math.floor( math.random(a, b) )
        data[i] = j
    end

    return data
end

function isFitnessSent(population)
    
    local flag = true
    for i=1, #population, 1 do
        local j = i-1

        local fitness = sim.getStringSignal("dr12_fitness#"..j)
        if not fitness then
            return false
        end

        fitness = sim.unpackFloatTable(fitness)
        if fitness[i] == -1 then
            flag = false
        end
    end

    return flag
end

function destroyFitness(population)
    for i=1, #population, 1 do
        local j = i-1

        local signal = sim.packFloatTable({-1})
        sim.setStringSignal("dr12_fitness#"..j, signal)
    end

    return flag
end

function getFitnesses(population)
    fitnesses = {}

    for i=1, #population, 1 do
        local j = i-1
        local fitness = sim.getStringSignal("dr12_fitness#"..j)
        fitness = sim.unpackFloatTable(fitness)

        distance = fitness[1]
        collisions = fitness[2]

        fitness = distance/(1 + collisions*penalty)

        fitnesses[i] = fitness
    end

    return fitnesses
end

--todo math.floor
function calculateFitness(population)
    local fitnesses = getFitnesses(population)
    local populace = {}
    
    for i=1,#population, 1 do
        populace[i] = {chromosome=population[i], fitness=fitnesses[i]}    
    end
    
    return populace
end

function mutate(population)
    local mutations = math.ceil(0.2*#population)
    local individuals = {}
    local length = #population[1]/2 - 1

    for i=1,mutations,1 do
        individuals[i] = math.floor( math.random(1, #population) )
    end

    for i=1,mutations,1 do
        index = individuals[i]
        local position = math.floor( math.random(0, length) )*2 + 1
        local value = math.floor( math.random(0, 360) )

        population[index][position] = value
    end

    return population
        
end

function sign(num)
    if num == 0 then
        return 1
    end

    local val = num/math.abs(num)
    return val
end

--todo try with random Beta
function reproduce(parents)
    local length = #parents[1]/2 - 1

    for i=1,parents_size,2 do
        crossover = math.floor( math.random(0, length) )*2 + 1
        
        local parent1 = parents[i]
        local parent2 = parents[i+1]

        local pnewM1 = parent1[crossover] - Beta*(parent1[crossover] - parent2[crossover])
        local pnewM2 = parent1[crossover+1] - Beta*(parent1[crossover+1] - parent2[crossover+1])

        pnewM1 = math.abs(pnewM1) % 360
        pnewM2 = math.abs(pnewM2) % 360

        parent1[crossover] = pnewM1
        parent1[crossover+1] = pnewM2

        --pnew2
        pnewM1 = parent2[crossover] + Beta*(parent1[crossover] - parent2[crossover])
        pnewM2 = parent2[crossover+1] + Beta*(parent1[crossover+1] - parent2[crossover+1])

        pnewM1 = math.abs(pnewM1) % 360
        pnewM2 = math.abs(pnewM2) % 360
        
        parent2[crossover] = pnewM1
        parent2[crossover+1] = pnewM2

        for j=crossover+2,#parent1,1 do
            local store = parent1[j]
            
            parent1[j] = parent2[j]
            parent2[j] = store
        end

        parents[i] = parent1
        parents[i+1] = parent2
    end

    return parents
end

--
function sendFlags(flag)
    for i=1,#population, 1 do
        sim.tubeWrite(tube[i], flag)
    end
end

--
function armChromosomes(population)
    for i=1,#population, 1 do
        local j = i-1

        local data = population[i]
        data = sim.packFloatTable(data)
        sim.setStringSignal("dr12_chromosome#"..j, data)
    end
end

function generateChildren(population)
    population = calculateFitness(population)
    table.sort(population, function(a, b) return a.fitness > b.fitness end)

    best_fitness_current = population[1].fitness
    best_chromosome_current = population[1].chromosome
    if population[1].fitness > best_fitness then
        best_fitness = population[1].fitness
        best_chromosome = population[1].chromosome
    end

    local newPopulation = {}
    for i=1, elite_size, 1 do
        newPopulation[i] = population[i].chromosome
    end

    couples = {}    
    for i=elite_size+1, #population, 1 do
        couples[i] = false
    end

    local sample = {}
    for i=1, parents_size, 1 do
        j = pickRandom()
        sample[i] = population[j].chromosome
    end

    local children = reproduce(sample)
    for i=1, #children, 1 do
        newPopulation[elite_size + i] = children[i]
    end

    newPopulation = mutate(newPopulation)
    return newPopulation
end

function generatePopulation(length, populationSize)
    population = {}
    
    for i=1, populationSize, 1 do
        population[i] = randomSample(length, {0, 360} )
    end

    return population
end

if (sim_call_type==sim.syscb_init) then

    --tubes
    tube = {}
    tube[1] = sim.tubeOpen(0,'robotGeneTube#0',1)
    tube[2] = sim.tubeOpen(0,'robotGeneTube#1',1)
    tube[3] = sim.tubeOpen(0,'robotGeneTube#2',1)
    tube[4] = sim.tubeOpen(0,'robotGeneTube#3',1)
    tube[5] = sim.tubeOpen(0,'robotGeneTube#4',1)
    tube[6] = sim.tubeOpen(0,'robotGeneTube#5',1)
    tube[7] = sim.tubeOpen(0,'robotGeneTube#6',1)
    tube[8] = sim.tubeOpen(0,'robotGeneTube#7',1)
    tube[9] = sim.tubeOpen(0,'robotGeneTube#8',1)
    tube[10] = sim.tubeOpen(0,'robotGeneTube#9',1)
    tube[11] = sim.tubeOpen(0,'robotGeneTube#10',1)
    tube[12] = sim.tubeOpen(0,'robotGeneTube#11',1)

    population = generatePopulation(32, 12)
    penalty = 1
    Beta = 0.5

    generation = 0
    best_fitness = 0 --fitness
    best_chromosome = 0 --print chromosome
    best_fitness_current = 0
    best_chromosome_current = 0
    elite_size = 4
    parents_size = 8
    --first run
    armChromosomes(population)
    sendFlags(1)

    printDetails()
    printPopulation(population)
    
    generationTime = 10*60 --minutes
    simulationTime = sim.getSimulationTime() + generationTime

    flag = 0
end

if (sim_call_type==sim.syscb_actuation) then
    ttime = sim.getSimulationTime()

    if ttime >= simulationTime then
        if flag == 0 then
            sendFlags(0)
            flag = 1
        elseif isFitnessSent(population) then
            population = generateChildren(population)
            armChromosomes(population)
            sendFlags(1)
            
            generation = generation + 1
            printDetails()
            printPopulation(population)

            destroyFitness(population)
            flag = 0
            simulationTime = sim.getSimulationTime() + generationTime
        end
    end
end


if (sim_call_type==sim.syscb_sensing) then

    -- Put your main SENSING code here

end


if (sim_call_type==sim.syscb_cleanup) then

    -- Put some restoration code here

end