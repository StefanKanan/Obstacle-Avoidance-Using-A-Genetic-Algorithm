function reset()
    
    sim.setJointTargetVelocity(leftJointHandle, 0)
    sim.setJointTargetVelocity(rightJointHandle, 0)

    chromosome = nil
    collisionCount = 0
    distance = 0
end

function getIndex(num)
    for i=1,4,1 do
        if num[i] > 0 then
            num[i] = 1
        else
            num[i] = 0
        end
    end

    value = num[4]*2^3 + num[3]*2^2 + num[2]*2^1 + num[1]
    return value
end

function euclidDistance(pos, pos2)
    x = pos[1] - pos2[1]
    x = x^2
    
    y = pos[2] - pos2[2]
    y = y^2
    
    c = math.sqrt(x+y)
    return c
end

function sysCall_init() 
    leftJointHandle=sim.getObjectHandle("dr12_leftJoint_")
    rightJointHandle=sim.getObjectHandle("dr12_rightJoint_")
    bumperSensorHandle=sim.getObjectHandle("dr12_bumperForceSensor_")
    robot = sim.getObjectHandle('dr12')
    backwardModeUntilTime=0

    r = sim.saveModel(robot)

    communicationTube=sim.tubeOpen(0,'robotGeneTube#0',1) --todo change name

    proxSensorHandles={-1,-1,-1,-1}
    for i=1,4,1 do
        proxSensorHandles[i]=sim.getObjectHandle(string.format('dr12_proxSensor%d', i)) --todo change
    end

    collisionCount = 0
    distance = 0
    prevPos = sim.getObjectPosition(robot, -1)
    Origin = sim.getObjectPosition(robot, -1)
    OriginOrientation = sim.getObjectOrientation(robot, -1)

    isFitnessSent = 1
    flag = 0
end

function sysCall_cleanup() 
 
end 

function sysCall_actuation()

    --communication tube
    --flag == 0 generation is complete, wait for new chromosome
    --flag == 1 read chromosome
    --flag == 2 start

    phaseFlag = sim.tubeRead(communicationTube)
    phaseFlag = tonumber(phaseFlag)

    if phaseFlag then
        flag = phaseFlag
    end

    if flag == 0 then
        if isFitnessSent == 0 then
            --send fitness (collisionCount counts about 3 times for one collision)
            local data = sim.packFloatTable({distance, collisionCount/3})
            sim.setStringSignal("dr12_fitness#0", data)
            isFitnessSent = 1

            reset()
        end
    elseif flag == 1 and not chromosome then
        chromosome = sim.getStringSignal("dr12_chromosome#0")
        if chromosome then
            isFitnessSent = 0
            chromosome = sim.unpackFloatTable(chromosome)
        end
    else
    
        currentTime=sim.getSimulationTime()
        result,f,t=sim.readForceSensor(bumperSensorHandle)


        --calculate distance
        newPos = sim.getObjectPosition(robot, -1)
        newDistance = euclidDistance(prevPos, newPos)
        if newDistance > 0.2 then
            distance = distance + newDistance
            prevPos = newPos
        end

        --read sensors
        r4, d = sim.readProximitySensor(proxSensorHandles[1])
        r3, d = sim.readProximitySensor(proxSensorHandles[2])
        r2, d = sim.readProximitySensor(proxSensorHandles[3])
        r1, d = sim.readProximitySensor(proxSensorHandles[4])

        index = getIndex({r4, r3, r2, r1})
        index = index*2 + 1--todo can optimize

        if (result>0) then
            if (math.abs(f[2])>1) or (math.abs(f[3])>1) then
                backwardModeUntilTime=currentTime+2 -- 2 seconds backwards
            end

            if (math.abs(f[2])>5) or (math.abs(f[3])>5) then
                collisionCount = collisionCount + 1
            end
        end

        if (currentTime<backwardModeUntilTime) then
            sim.setJointTargetVelocity(leftJointHandle,-100*math.pi/180)
            sim.setJointTargetVelocity(rightJointHandle,-50*math.pi/180)
        else
            --Motor1, Motor2
            local M1 = chromosome[index]
            local M2 = chromosome[index+1]
            
            sim.setJointTargetVelocity(leftJointHandle,M1*math.pi/180)
            sim.setJointTargetVelocity(rightJointHandle,M2*math.pi/180)
        end
    end
end 
