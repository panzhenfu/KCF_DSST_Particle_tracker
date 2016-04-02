function [ St ] = particle_init( position,N )
%PARTICLE_INIT particle initial
%   position :the original position of the target
%   targetsz :the size of the target window
%   N        :the number of the particle
%   潘振福 华北电力大学 2016
POSITION_DISTURB = 0.00125;%位置扰动幅度
VELOCITY_DISTURB = 0.0125;%速度扰动幅度
for i = 1:N,
    for j = 1:4,
        R = normrnd(0,1,4,1); %产生4×4的标准正态分布矩阵
    end
    St(i).pos(1) = position(1) + R(1)*POSITION_DISTURB;
    St(i).pos(2) = position(2) + R(2)*POSITION_DISTURB;
    St(i).vx = 0.0 + R(3)*VELOCITY_DISTURB; 
    St(i).vy = 0.0 + R(4)*VELOCITY_DISTURB;
    St(i).psr = 0.0;
    St(i).weight = 1/N;
end
end

