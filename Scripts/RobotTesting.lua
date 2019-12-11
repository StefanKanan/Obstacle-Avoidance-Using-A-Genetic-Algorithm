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

function sysCall_init() 
    leftJointHandle=sim.getObjectHandle("dr12_leftJoint_")
    rightJointHandle=sim.getObjectHandle("dr12_rightJoint_")
    bumperSensorHandle=sim.getObjectHandle("dr12_bumperForceSensor_")
    robot = sim.getObjectHandle('dr12')
    backwardModeUntilTime=0
    chromosome = {42, 125.75, 98, 80, 84.8125, 77.4375, 32, 56, 78, 78, 291, 148, 291, 177, 266.4375, 137.6875, 174, 281, 47, 110.75, 165, 329, 227, 257.25, 147, 152, 49, 39, 82, 41, 110, 188}

    communicationTube=sim.tubeOpen(0,'robotGeneTube#3',1) --todo change name

    proxSensorHandles={-1,-1,-1,-1}
    for i=1,4,1 do
        proxSensorHandles[i]=sim.getObjectHandle(string.format('dr12_proxSensor%d', i)) --todo change
    end

end

function sysCall_cleanup() 
 
end 

function sysCall_actuation()

    --communication tube
    --flag == 0 generation is complete, wait for new chromosome
    --flag == 1 read chromosome
    --flag == 2 start

    currentTime=sim.getSimulationTime()
    result,f,t=sim.readForceSensor(bumperSensorHandle)

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
